{
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  enable = userConfig.worker.awaitHeadnode;
  headnode = "headnode.${userConfig.tailscale.domain}";
in
{
  config = lib.mkIf enable {
    systemd.services.awaitHeadnode = {
      description = "Wait for headnode to become reachable";

      requiredBy = [
        "pre-cluster.target"
      ];

      before = [
        "pre-cluster.target"
      ];

      after = [
        "network-online.target"
        "tailscale-autoconnect.service"
      ];

      wants = [
        "network-online.target"
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      path = with pkgs; [
        iputils
        coreutils
      ];

      # TODO: We might open a port on headnode as soon as cluster.target is completed there and check for that one instead
      script = ''
        echo "Waiting for ${headnode}..."

        for i in $(seq 1 300); do
          if ping -c1 -W1 ${headnode} >/dev/null 2>&1; then
            echo "Headnode reachable."
            exit 0
          fi

          sleep 2
        done

        echo "Timed out waiting for ${headnode}"
        exit 1
      '';
    };
  };
}
