{
  userConfig,
  pkgs,
  ...
}:
{
  systemd.services.tailscale-tidy =
    let
      python = pkgs.python3.withPackages (ps: [ ps.requests ]);

      apiKey = userConfig.tailscale.apiKey;
      domain = userConfig.tailscale.domain;

      script = pkgs.writeText "tailscale-tidy.py" ''
        import requests
        import sys
        import socket

        API_KEY = "${apiKey}"
        TAILNET = "${domain}"
        BASE_URL = f"https://api.tailscale.com/api/v2/tailnet/{TAILNET}"

        HOSTNAME = socket.gethostname()

        def api_get(path):
            return requests.get(f"{BASE_URL}{path}", auth=(API_KEY, ""))

        def api_delete(url):
            return requests.delete(url, auth=(API_KEY, ""))

        def get_devices():
            r = api_get("/devices")
            r.raise_for_status()
            return r.json()["devices"]

        def delete_by_hostname(hostname):
            matches = [d for d in get_devices() if d["hostname"] == hostname]

            if not matches:
                print(f"No device found: {hostname}")
                return

            if len(matches) > 1:
                print("Multiple matches found")
                return

            device = matches[0]
            url = f"https://api.tailscale.com/api/v2/device/{device['id']}"

            r = api_delete(url)

            if r.status_code == 200:
                print(f"Deleted {hostname}")
            else:
                print(f"Failed: {r.status_code} {r.text}")

        delete_by_hostname(HOSTNAME)
      '';
    in
    {
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

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${python}/bin/python3 ${script}";
      };

    };
}
