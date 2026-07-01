{
  pkgs,
  lib,
  userConfig,
  ...
}:
let
  enable = userConfig.worker.awaitHeadnode;
  headnode = "headnode.${userConfig.tailscale.domain}";

  pharos = pkgs.callPackage ../../../packages/pharos { };
  pharosClient = "${pharos}/bin/pharos";
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

      path = [ pharos ];

      script = ''
        echo "Waiting for ${headnode}..."

        for i in $(seq 1 ); do
          output=$(${pharosClient} ${headnode} 1010)
          rc=$?

          if [ $rc -eq 0 ]; then
            echo "Headnode reachable."
            exit 0
          elif [ $rc -eq 1 ]; then
            echo "The version of this workernode is not supported by the headnode: ''${output}"
            exit 1
          elif [ $rc -eq 2 ]; then
            exit 2
          elif [ $rc -eq 3 ]; then
            continue
          fi

          sleep 2
        done

        echo "Timed out waiting for ${headnode}"
        exit 1
      '';
    };
  };
}
