{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  authKey = userConfig.tailscale.authKey;
in
{
  services.tailscale.enable = true;
  services.resolved.enable = true;

  # create a oneshot job to authenticate to Tailscale
  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale";

    # make sure tailscale is running before trying to connect to tailscale

    after = [
      "tailscaled.service"
    ];

    requires = [
      "network-online.target"
      "tailscaled.service"
    ];

    wantedBy = [ "pre-cluster.target" ];

    serviceConfig.Type = "oneshot";

    path = [
      pkgs.curl
      pkgs.hostname

    ];

    # Exit codes follow BSD spec
    script = ''
      set -euo pipefail

      SOCK="/var/run/tailscale/tailscaled.sock"
      TS="${lib.getExe pkgs.tailscale}"
      JQ="${lib.getExe pkgs.jq}"

      wait_for() {
        for _ in $(seq 1 30); do
          "$@" && return 0
          sleep 1
        done
        return 1
      }

      fail() {
        echo "$1"
        exit "$2"
      }

      wait_for test -S "$SOCK" || fail "tailscaled is dysfunctional - failing" 69 # BSD Spec: Service unavailable

      [ "$(hostname)" != "nixos" ] || fail "Running on a worker with illegal hostname - failing" 68 # BSD Spec: Hostname error

      status="$($TS status -json | $JQ -r .BackendState || true)"

      [ "$status" = "Running" ] && exit 0

      $TS up -authkey "${authKey}" --hostname="$(hostname)"

      wait_for "$TS" status >/dev/null 2>&1 || fail "tailscaled failed to come up - failing" 69
    '';
  };

  networking.firewall = {
    # always allow traffic from your Tailscale network
    trustedInterfaces = [ "tailscale0" ];
    # allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
