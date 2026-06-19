{ pkgs, ... }:
let
  slurmWorkerListFile = "/var/lib/prometheus/slurm-workers.json";

  slurmNodeTargets = pkgs.writeShellScript "slurm-node-targets" ''
    set -euo pipefail

    OUT="${slurmWorkerListFile}"
    mkdir -p "$(dirname "$OUT")"

    ${pkgs.slurm}/bin/sinfo -Nh -o "%N" \
      | sort -u \
      | awk '{print "\"" $1 ":9002\""}' \
      | awk 'BEGIN { print "["; print "  {\"targets\": [" } 
             { print } 
             END { print "  ]}"; print "]" }' \
      | sed '$!s/$/,/' \
      > "$OUT"
  '';

in
{

  services.prometheus = {
    scrapeConfigs = [
      {
        job_name = "slurm-workers";

        file_sd_configs = [
          {
            files = [ slurmWorkerListFile ];
            refresh_interval = "10s";
          }
        ];
      }

    ];
  };

  systemd = {
    timers.slurm-node-discovery = {
      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnBootSec = "30s";
        OnUnitActiveSec = "30s";
      };
    };

    services.slurm-node-discovery = {
      description = "Discover Slurm nodes for Prometheus node_exporter";
      requiredBy = [ "cluster.target" ];
      requires = [
        "pre-cluster.target"
        "slurm-dynamic.service"
      ];

      after = [
        "pre-cluster.target"
        "slurm-dynamic.service"
      ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = slurmNodeTargets;
      };
    };
  };
}
