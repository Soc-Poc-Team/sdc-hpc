{
  pkgs,
  userConfig,
  # flake, - disabled to get build running
  ...
}:
let
  enabled = userConfig.telemetry.enabled;

  telemetryScript = pkgs.writeShellScriptBin "telemetry" ''
    # IDENTIFIER={toString flake.lastModified} - disabled to get build running
    IDENTIFIER="0"
    COMMAND=$(scontrol show nodes --json | jq --arg id "$IDENTIFIER" '{
      type: "de.fh-aachen.bigdata.hpc-on-demand-telemetry",
      cluster: $id,
      nodes: (.nodes // []) | [.[] | {
        cores,
        cpu_load,
        free_mem: .free_mem.number,
        cpus,
        sockets,
        last_busy: .last_busy.number,
        hostname,
        real_memory,
        alloc_memory,
        alloc_cpus,
        alloc_idle_cpus,
        slurmd_start_time: .slurmd_start_time.number,
        tres,
        version,
        state,
        reason,
        reason_set_by_user,
        reason_changed_at
      }]
    }')

    if [ $? -ne 0 ]; then
      echo "telemetry command failed."
      exit 1
    fi

    curl --request POST \
          --url 'https://ingest.bigdata.fh-aachen.de/api/payload' \
          --header 'content-type: application/json' \
          --header 'context: data' \
          --header 'format: json' \
          --data "$COMMAND"

    if [ $? -ne 0 ]; then
      echo "failed sending telemetry data."
      exit 1
    fi

    echo "$COMMAND"
    echo "finished sending periodic telemetry data."
    exit 0
  '';
in
{
  systemd.services.telemetry = {
    enable = enabled;
    description = "Periodically sends anonymous telemetry data to FH Aachen";

    serviceConfig = {
      Type = "simple";
      ExecStart = "${telemetryScript}/bin/telemetry";
    };
    after = [ "slurm-dynamic.service" ];
    wantedBy = [ "default.target" ];

    path = [
      pkgs.curl
      pkgs.slurm
      pkgs.jq
    ];
  };

  systemd.timers."telemetry" = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1m";
      OnUnitActiveSec = "1m";
      Unit = "telemetry.service";
    };
  };
}
