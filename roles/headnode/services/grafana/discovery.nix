{ pkgs, ... }:
let
  slurmWorkerListFile = "/var/lib/prometheus/slurm-workers.json";

  slurmNodeTargets = pkgs.writeShellApplication {
    name = "slurm-node-targets";

    runtimeInputs = [
      pkgs.slurm
      pkgs.gawk
      pkgs.gnused
      pkgs.coreutils
    ];
    text = ''
      set -euo pipefail

      OUT="${slurmWorkerListFile}"
      mkdir -p "$(dirname "$OUT")"

      sinfo -Nh -o "%N" \
        | sort -u \
        | awk '
            BEGIN {
              print "["
              print "  {\"targets\": ["
            }
            {
              if (n++) print ","
              printf "    \"%s:9002\"", $1
            }
            END {
              print ""
              print "  ]}"
              print "]"
            }
          ' > "$OUT"       '';
  };
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
        ExecStart = pkgs.lib.getExe slurmNodeTargets;
      };
    };
  };
}
