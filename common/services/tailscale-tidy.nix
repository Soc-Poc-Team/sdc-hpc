{
  userConfig,
  ...
}:
{
  systemd.services.tailscale-tidy = {
    description = "clear machine entry on tailscale api";

    requiredBy = [
      "tailscale-autoconnect.service"
    ];

    requires = [
      "network-online.target"
    ];

    after = [
      "network-online.target"
    ];

    serviceConfig.Type = "oneshot";

    path = [ ];
    script =
      let
        apiKey = userConfig.tailscale.apiKey;
        domain = userConfig.tailscale.domain;
      in
      ''
        #!/usr/bin/env python3
        import requests
        import sys
        import os
        import socket

        API_KEY = "${apiKey}"
        TAILNET = "${domain}"
        BASE_URL = f"https://api.tailscale.com/api/v2/tailnet/{TAILNET}"

        # https://docs.python.org/3/library/socket.html
        HOSTNAME = socket.gethostname()
        def api_get(path):
            return requests.get(
                f"{BASE_URL}{path}",
                auth=(API_KEY, "")
            )

        def api_delete(url):
            return requests.delete(
                url,
                auth=(API_KEY, "")
            )

        def get_devices():
            r = api_get("/devices")
            r.raise_for_status()
            return r.json()["devices"]

        def delete_by_hostname(hostname):
            matches = [
                d for d in get_devices()
                if d["hostname"] == hostname
            ]

            if not matches:
                print(f"No device found: {hostname}")
                sys.exit(1)

            if len(matches) > 1:
                print("Multiple matches found:")
                for d in matches:
                    print(f"{d['hostname']}  {d['id']}")
                sys.exit(1)

            device = matches[0]
            url = f"https://api.tailscale.com/api/v2/device/{device['id']}"

            r = api_delete(url)

            if r.status_code == 200:
                print(f"Deleted {hostname}")
            else:
                print(f"Failed: {r.status_code} {r.text}")

        delete_by_hostname(HOSTNAME)
      '';
  };
}
