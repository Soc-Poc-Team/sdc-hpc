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
            r = requests.get(f"{BASE_URL}{path}", auth=(API_KEY, ""))
            r.raise_for_status()
            return r

        def api_delete(url):
            return requests.delete(url, auth=(API_KEY, ""))

        def get_devices():
            return api_get("/devices").json()["devices"]

        def delete_device(device):
            url = f"https://api.tailscale.com/api/v2/device/{device['id']}"
            r = api_delete(url)

            if r.status_code == 200:
                print(f"Deleted {device['hostname']} ({device['id']})")
                return True
            else:
                print(f"Failed: {r.status_code} {r.text}")
                return False

        def delete_by_hostname(hostname):
            try:
                matches = [d for d in get_devices() if d["hostname"] == hostname]
            except Exception as e:
                print(f"API error: {e}")
                sys.exit(1)

            if not matches:
                print(f"No device found: {hostname}")
                sys.exit(0)

            success = True

            for device in matches:
                if not delete_device(device):
                    success = False

            if not success:
                sys.exit(1)

            sys.exit(0)

        delete_by_hostname(HOSTNAME)
      '';
    in
    {
      description = "clear machine entry on tailscale api";

      requiredBy = [
        "tailscale-autoconnect.service"
      ];

      before = [
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
