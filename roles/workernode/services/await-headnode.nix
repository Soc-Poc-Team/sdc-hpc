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

  timeout = userConfig.worker.headnodeTimeout;
in
{
  config = lib.mkIf enable {
    systemd.services.awaitHeadnode = {
      description = "Изчакване на headnode да стане наличен";

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
        echo "Ние сме на версия: ''${PHAROS_VERSION}"
        echo "Изчакване на ${headnode}..."

        TIMEOUT_SECONDS=${builtins.toString timeout}
        START_TIME=$(date +%s)

        last_stderr=""

        while true; do
          NOW=$(date +%s)
          ELAPSED=$((NOW - START_TIME))

          if [ "$ELAPSED" -ge "$TIMEOUT_SECONDS" ]; then
            echo "Изтече времето за изчакване на ${headnode}"
            exit 1
          fi

          stdout_file=$(mktemp)
          stderr_file=$(mktemp)

          if ${pharosClient} ${headnode} 1010 >"$stdout_file" 2>"$stderr_file"; then
            rc=0
          else
            rc=$?
          fi

          output=$(<"$stdout_file")
          stderr_output=$(<"$stderr_file")

          rm -f "$stdout_file" "$stderr_file"

          if [ -n "$stderr_output" ] && [ "$stderr_output" != "$last_stderr" ]; then
            echo "$stderr_output" >&2
            last_stderr="$stderr_output"
          fi

          case "$rc" in
            0)
              echo "Headnode е достъпен."
              exit 0
              ;;
            1)
              echo "Версията на този workernode не се поддържа от headnode: ''${output}"
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
              echo "Неочакван код на изход: $rc"
              exit "$rc"
              ;;
          esac
        done
      '';
    };
  };
}
