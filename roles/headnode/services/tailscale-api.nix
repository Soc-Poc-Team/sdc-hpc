{ tomlConf, ... }:
{ pkgs, ... }:
let
  apiKey = tomlConf.tailscale.apiKey;
  tailscaleDomain = tomlConf.tailscale.domain;
in
{
  systemd.services.tailscale-headnode-tidy = {
    description = "Before registering the headnode with tailscale, make sure the device name is free.";

    # make sure tailscale is running before trying to connect to tailscale
    after = [ "network-online.target" ];
    wants = [
      "wpa_supplicant.service"
      "network-online.target"
    ];
    wantedBy = [ "multi-user.target" ];
    before = [
      "tailscale-autoconnect.service"
      "slurmctld.service"
      "slurmd.service"
    ];
    serviceConfig.Type = "oneshot";

    path = [
      pkgs.curl
      pkgs.jq
      pkgs.hostname
    ];
    script = ''
      API_KEY=${apiKey}
      TAILNET=${tailscaleDomain}

      DEVICES_TO_REMOVE=("headnode")

      BASE_URL="https://api.tailscale.com/api/v2"

      echo "Fetching devices from Tailscale..."
      DEVICES_JSON=$(curl -s -u "$API_KEY": "$BASE_URL/tailnet/-/devices")

      if [[ -z "$DEVICES_JSON" ]]; then
        echo "❌ Failed to fetch devices. Check API key and tailnet name."
        exit 1
      fi

      for TARGET_NAME in "''${DEVICES_TO_REMOVE[@]}"; do
        echo "🔍 Checking for device: $TARGET_NAME"

        DEVICE_ID=$(echo "$DEVICES_JSON" | jq -r --arg name "$TARGET_NAME.$TAILNET" '.devices[] | select(.name == $name) | .id')
        if [[ -n "$DEVICE_ID" ]]; then
          echo "⚠️  Found device '$TARGET_NAME' with ID: $DEVICE_ID"
          echo "🧹 Expiring device..."

          DELETE_RESP=$(curl -X DELETE "$BASE_URL/device/$DEVICE_ID" -u "$API_KEY:")
        else
          echo "✅ Device '$TARGET_NAME' not found — skipping."
        fi
      done
      echo "finished"
      sleep 2
    '';
  };
  networking.firewall = {
    allowedTCPPorts = [ 9100 ];
  };
}
