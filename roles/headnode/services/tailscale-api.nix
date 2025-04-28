{tomlConf, ...}: {
  config,
  lib,
  pkgs,
  ...
}: let
  apiKey = tomlConf.tailscale.apiKey;
  hasApiKey = tomlConf.tailscale ? apiKey && tomlConf.tailscale.apiKey != null;
  tailscaleDomain = tomlConf.tailscale.domain;
  hostnameSet =
    pkgs.writers.writePython3Bin "hostnameSet" {
      libraries = with pkgs.python3.pkgs; [
        requests
      ];
      flakeIgnore = ["E999" "E111" "E305" "E302" "E303" "E501"]; # E265 block comment should start with '# '
    }
    ''
      from http.server import BaseHTTPRequestHandler, HTTPServer
      import requests
      import os
      x = 0

      TAILSCALE_API_KEY = os.getenv("TAILSCALE_API_KEY")  # Store your API key in an environment variable
      class RequestHandler(BaseHTTPRequestHandler):
          def get_devices(self):
              url = "https://api.tailscale.com/api/v2/tailnet/-/devices"
              response = requests.get(url, auth=(TAILSCALE_API_KEY, ""))

              if response.status_code != 200:
                  print(f"Failed to get devices: {response.status_code} {response.text}")
                  return []

              return response.json().get("devices", [])

          def filter_and_sort_devices(self, devices):
              workers = [
                  device["hostname"]
                  for device in devices
                  if "worker-" in device.get("hostname", "")
              ]
              return sorted(workers)

          def init(self):
            self.current_worker_index = 1
            devices = self.get_devices()
            if devices:
                sorted_workers = self.filter_and_sort_devices(devices)
                if len(sorted_workers) > 0:
                  self.current_worker_index = int(sorted_workers[-1].split("-")[-1])
                else:
                  self.current_worker_index = 0
            print("hostnameSet service initialized")

          def do_GET(self):
            if not hasattr(self, "current_worker_index"):
              self.init()

            global x
            if self.path == '/get-hostname':
              self.current_worker_index = (self.current_worker_index + 1) % 300
              s = "worker-" + str(self.current_worker_index)
              self.send_response(200)
              self.send_header("Content-type", "text/plain")
              self.end_headers()
              self.wfile.write(str(s).encode())
            else:
              self.send_response(404)
              self.end_headers()

      if __name__ == '__main__':
          server = HTTPServer(('0.0.0.0', 9100), RequestHandler)
          print("Server started on port 9100...")
          server.serve_forever()
    '';
in {
  systemd.services.tailscale-headnode-tidy = {
    description = "Before registering the headnode with tailscale, make sure the device name is free.";

    # make sure tailscale is running before trying to connect to tailscale
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    before = ["tailscale-autoconnect.service" "slurmctld.service" "slurmd.service"];
    serviceConfig.Type = "oneshot";

    path = [pkgs.curl pkgs.jq pkgs.hostname];
    # have the job run this shell script
    script = with pkgs; ''
      #!/bin/bash

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
  systemd.services.hostnameSet = {
    enable = true;
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      ExecStart = lib.getExe hostnameSet;
      Environment = [
        "TAILSCALE_API_KEY=${apiKey}"
      ];
    };
  };
  networking.firewall = {
    allowedTCPPorts = [
      9100
    ];
  };
}
