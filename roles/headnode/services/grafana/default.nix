{
  config,
  pkgs,
  userConfig,
  ...
}:
let
  # this dashboard has to be exported from grafana
  # Steps:
  # 1. sign in with admin:admin
  # 2. edit the dashboard
  sdc-overview = ./sdc-overview.json;
  slurm-dashboard = ./slurm-dashboard.json;
  slurmExporter = pkgs.callPackage ../../modules/slurm-node-exporter { };
  slurmExporterPort = 9092;

in
{

  imports = [
    ./discovery.nix
  ];

  systemd.services.slurm-exporter = {
    description = "Slurm Prometheus Exporter";
    requiredBy = [ "cluster.target" ];
    requires = [ "pre-cluster.target" ];
    after = [ "slurm-dynamic.service" ];
    path = [
      pkgs.slurm
      pkgs.coreutils
    ];
    serviceConfig = {
      ExecStart = "${pkgs.lib.getExe slurmExporter} --web.listen-address=:${builtins.toString slurmExporterPort}";
      Restart = "always";
      DynamicUser = true;
    };
  };
  # grafana configuration
  services.grafana = {
    enable = true;
    settings = {
      "auth.anonymous".enabled = true;
      "auth.anonymous".org_name = "Main Org.";
      "auth.anonymous".org_role = "Viewer";
      server.http_port = 2342;
      server.http_addr = "0.0.0.0";

      # WARNING: These credentials are public in the nix store! Keep this in mind!
      security = {
        # See https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/157
        secret_key = pkgs.lib.mkForce "SW2YcwTIb9zpOOhoPsMm";
      }
      // (
        if userConfig.headnode.grafana_enable_admin then
          {
            admin_user = userConfig.headnode.grafana_admin;
            admin_password = userConfig.headnode.grafana_password;
            admin_email = "${userConfig.headnode.grafana_admin}@headnode.${userConfig.tailscale.domain}";
          }
        else
          {
            disable_initial_admin_creation = true;
          }
      );
    };
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:9001";
            uid = "prometheus";
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://localhost:3100";
            uid = "loki";
          }
        ];
      };
      dashboards.settings =
        let
          provisionGrafanaLabs =
            {
              name ? "grafanalabs-${id}-${revision}",
              id,
              revision,
              hash,
            }:
            {
              inherit name;
              options.path =
                (pkgs.fetchurl {
                  name = "${name}.json";
                  url = "https://grafana.com/api/dashboards/${builtins.toString id}/revisions/${builtins.toString revision}/download";
                  inherit hash;
                }).outPath;
            };
        in
        {
          providers = [
            {
              name = "headnode control";
              options.path = sdc-overview;
            }
            {
              name = "slurm dashboard";
              options.path = slurm-dashboard;
            }
            (provisionGrafanaLabs {
              name = "node exporter full";
              id = 1860;
              revision = 45;
              hash = "sha256-GExrdAnzBtp1Ul13cvcZRbEM6iOtFrXXjEaY6g6lGYY=";
            })
          ];
        };
    };
  };
  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    globalConfig = {
      scrape_interval = "10s";
      scrape_timeout = "5s";
    };

    scrapeConfigs = [
      {
        job_name = "Slurm";
        static_configs = [ { targets = [ "headnode:9092" ]; } ];
      }
    ];
  };
  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      server = {
        http_listen_port = 3100;
        log_level = "warn";
      };
      common = {
        path_prefix = config.services.loki.dataDir;
        storage.filesystem = {
          chunks_directory = "${config.services.loki.dataDir}/chunks";
          rules_directory = "${config.services.loki.dataDir}/rules";
        };
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        ring.instance_addr = "127.0.0.1";
      };

      ingester.chunk_encoding = "snappy";

      limits_config = {
        retention_period = "120h";
        ingestion_burst_size_mb = 16;
        reject_old_samples = true;
        reject_old_samples_max_age = "12h";
      };

      table_manager = {
        retention_deletes_enabled = true;
        retention_period = "120h";
      };

      compactor = {
        retention_enabled = true;
        compaction_interval = "10m";
        working_directory = "${config.services.loki.dataDir}/compactor";
        delete_request_cancel_period = "10m";
        retention_delete_delay = "2h";
        retention_delete_worker_count = 150;
        delete_request_store = "filesystem";
      };

      schema_config.configs = [
        {
          from = "2020-11-08";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index.prefix = "index_";
          index.period = "24h";
        }
      ];

      query_range.cache_results = true;
      limits_config.split_queries_by_interval = "24h";
    };
  };
  services.alloy = {
    enable = true;
    configPath = pkgs.writeText "config.alloy" ''
      discovery.relabel "journal" {
              targets = []

              rule {
                      source_labels = ["__journal__systemd_unit"]
                      target_label  = "unit"
              }
      }

      loki.source.journal "journal" {
              max_age       = "12h0m0s"
              relabel_rules = discovery.relabel.journal.rules
              forward_to    = [loki.write.default.receiver]
              labels        = {
                      host = "headnode",
                      job  = "systemd-journal",
              }
      }

      loki.write "default" {
              endpoint {
                      url = "http://localhost:3100/loki/api/v1/push"
              }
              external_labels = {}
      }

    '';
  };
  networking.firewall = {
    allowedTCPPorts = [
      config.services.loki.configuration.server.http_listen_port
      config.services.prometheus.port
      config.services.prometheus.exporters.node.port
      config.services.grafana.settings.server.http_port
      slurmExporterPort
    ];
  };
}
