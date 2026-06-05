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
  prometheusSlurmExporter = pkgs.callPackage ../../modules/slurm-node-exporter { };
in
{
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
      ExecStart = "${prometheusSlurmExporter}/bin/prometheus-slurm-exporter";
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
      security =
        if userConfig.headnode.grafana_enable_admin then
          {
            admin_user = userConfig.headnode.grafana_admin;
            admin_password = userConfig.headnode.grafana_password;
            admin_email = "${userConfig.headnode.grafana_admin}@headnode.${userConfig.tailscale.domain}";
          }
        else
          {
            disable_initial_admin_creation = true;
          };

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
      dashboards.settings = {
        providers = [
          {
            name = "headnode control";
            options.path = sdc-overview;
          }
          {
            name = "slurm dashboard";
            options.path = slurm-dashboard;
          }
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
        job_name = "headnode";
        static_configs = [
          {
            targets = [
              "127.0.0.1:${toString config.services.prometheus.exporters.node.port}"
            ];
          }
        ];
      }
      {
        job_name = "SlurmExporter";
        static_configs = [ { targets = [ "127.0.0.1:9092" ]; } ];
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
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 28183;
        grpc_listen_port = 0;
      };
      clients = [
        {
          url = "http://localhost:${builtins.toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
        }
      ];
      positions = {
        filename = "/tmp/positions.yaml";
      };
      scrape_configs = [
        {
          job_name = "journal";
          journal = {
            max_age = "12h";
            labels = {
              job = "systemd-journal";
              host = "headnode";
            };
          };
          relabel_configs = [
            {
              source_labels = [ "__journal__systemd_unit" ];
              target_label = "unit";
            }
          ];
        }
      ];
    };
  };
  networking.firewall = {
    allowedTCPPorts = [
      config.services.promtail.configuration.server.http_listen_port
      config.services.loki.configuration.server.http_listen_port
      config.services.prometheus.port
      config.services.prometheus.exporters.node.port
      config.services.grafana.settings.server.http_port
    ];
  };
}
