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

  clientVersion = builtins.head (
    lib.filter (line: line != "" && !(lib.hasPrefix "#" line)) (
      lib.strings.splitString "\n" (builtins.readFile ../../../VERSION)
    )
  );
in
{
  config = lib.mkIf enable {
    systemd.services.awaitHeadnode = {
      description = "Wait for headnode to become available";

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
        export PHAROS_VERSION=${clientVersion}
        echo "We are at version: ''${PHAROS_VERSION}"
        echo "Waiting for ${headnode}..."

        TIMEOUT_SECONDS=20
        START_TIME=$(date +%s)

        while true; do
          NOW=$(date +%s)
          ELAPSED=$((NOW - START_TIME))

          if [ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]; then
            echo "Timed out waiting for ${headnode}"
            exit 1
          fi

          if output=$(${pharosClient} ${headnode} 1010); then
            rc=0
          else
            rc=$?
          fi

          case "$rc" in
            0)
              echo "Headnode reachable."
              exit 0
              ;;
            1)
              echo "The version of this workernode is not supported by the headnode: ''${output}"
              exit 1
              ;;
            2)
              exit 2
              ;;
            3)
              sleep 2
              continue
              ;;
            *)
              echo "Unexpected exit code: $rc"
              exit "$rc"
              ;;
          esac
        done
      '';
    };
  };
}
