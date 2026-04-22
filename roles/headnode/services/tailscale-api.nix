{ pkgs, userConfig, ... }:
let
  apiKey = userConfig.tailscale.apiKey;
  tailscaleDomain = userConfig.tailscale.domain;
in
{
  systemd.services.tailscale-headnode-tidy = {
    description = "Before registering the headnode with tailscale, make sure the device name is free.";

    # FIXME: switch to requiredby after #53 is fixed
    wantedBy = [
      "tailscale-autoconnect.service"
    ];

    wants = [
      "wpa_supplicant.service"
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

      DEVICES_JSON=$(curl -sS -u "$API_KEY:" \
        -w "\n%{http_code}" \
        "$BASE_URL/tailnet/-/devices")

      HTTP_BODY=$(echo "$DEVICES_JSON" | sed '$d')
      HTTP_CODE=$(echo "$DEVICES_JSON" | tail -n1)

      if [[ "$HTTP_CODE" -ne 200 ]]; then
        echo "Failed to fetch devices. HTTP status: $HTTP_CODE"
        exit 1
      fi

      if [[ -z "$HTTP_BODY" ]]; then
        echo "Empty response body."
        exit 1
      fi

      for TARGET_NAME in "''${DEVICES_TO_REMOVE[@]}"; do
        echo "Checking for device: $TARGET_NAME"

        DEVICE_ID=$(echo "$HTTP_BODY" | jq -r --arg name "$TARGET_NAME.$TAILNET" '.devices[] | select(.name == $name) | .id')

        if [[ -n "$DEVICE_ID" && "$DEVICE_ID" != "null" ]]; then
          echo "Found device '$TARGET_NAME' with ID: $DEVICE_ID"
          echo "Deleting device..."

          DELETE_RESP=$(curl -sS -u "$API_KEY:" \
            -X DELETE \
            -w "\n%{http_code}" \
            "$BASE_URL/device/$DEVICE_ID")

          DELETE_BODY=$(echo "$DELETE_RESP" | sed '$d')
          DELETE_CODE=$(echo "$DELETE_RESP" | tail -n1)

          if [[ "$DELETE_CODE" -ne 200 && "$DELETE_CODE" -ne 204 ]]; then
            echo "Failed to delete device '$TARGET_NAME'. HTTP status: $DELETE_CODE"
            echo "Response: $DELETE_BODY"
          else
            echo "Successfully deleted '$TARGET_NAME'"
          fi

        else
          echo "Device '$TARGET_NAME' not found — skipping."
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
