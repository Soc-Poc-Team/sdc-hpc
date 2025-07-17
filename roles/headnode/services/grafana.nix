{
  config,
  pkgs,
  ...
}:
let
  # this dashboard has to be exported from grafana
  # Steps:
  # 1. sign in with admin:admin
  # 2. edit the dashboard
  ourDashboard2 = pkgs.writeText "config.json" ''
          {
      "annotations": {
        "list": [
          {
            "builtIn": 1,
            "datasource": {
              "type": "grafana",
              "uid": "-- Grafana --"
            },
            "enable": true,
            "hide": true,
            "iconColor": "rgba(0, 211, 255, 1)",
            "name": "Annotations & Alerts",
            "type": "dashboard"
          }
        ]
      },
      "editable": true,
      "fiscalYearStartMonth": 0,
      "graphTooltip": 0,
      "id": 1,
      "links": [],
      "panels": [
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 0
          },
          "id": 1,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"slurmctld.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "slurmctld",
          "type": "logs"
        },
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 0
          },
          "id": 2,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"slurm-dynamic.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "Slurmd",
          "type": "logs"
        },
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 8
          },
          "id": 4,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"munged.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "munged",
          "type": "logs"
        },
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 8
          },
          "id": 5,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"tailscale-autoconnect.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "tailscale-autoconnect",
          "type": "logs"
        },
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 14,
            "w": 12,
            "x": 0,
            "y": 16
          },
          "id": 3,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"jupyterhub.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "jupyterhub",
          "type": "logs"
        },
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 16
          },
          "id": 6,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"tailscaled.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "tailscaled service",
          "type": "logs"
        }
      ],
      "refresh": "5s",
      "schemaVersion": 39,
      "tags": [],
      "templating": {
        "list": []
      },
      "time": {
        "from": "now-1h",
        "to": "now"
      },
      "timepicker": {},
      "timezone": "browser",
      "title": "small-data-cluster",
      "uid": "cefeq4w1vgu80f",
      "version": 1,
      "weekStart": ""
    }
  '';
  ourDashboard = pkgs.writeText "config.json" ''
    {
      "annotations": {
        "list": [
          {
            "builtIn": 1,
            "datasource": {
              "type": "grafana",
              "uid": "-- Grafana --"
            },
            "enable": true,
            "hide": true,
            "iconColor": "rgba(0, 211, 255, 1)",
            "name": "Annotations & Alerts",
            "type": "dashboard"
          }
        ]
      },
      "editable": true,
      "fiscalYearStartMonth": 0,
      "graphTooltip": 0,
      "id": 1,
      "links": [],
      "panels": [
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 0
          },
          "id": 1,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"slurmctld.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "slurmctld",
          "type": "logs"
        },
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 12,
            "y": 0
          },
          "id": 2,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"slurmd.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "Slurmd",
          "type": "logs"
        },
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 8,
            "w": 12,
            "x": 0,
            "y": 8
          },
          "id": 4,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"munged.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "munged",
          "type": "logs"
        },
        {
          "datasource": {
            "type": "loki",
            "uid": "loki"
          },
          "gridPos": {
            "h": 14,
            "w": 12,
            "x": 0,
            "y": 16
          },
          "id": 3,
          "options": {
            "dedupStrategy": "none",
            "enableLogDetails": true,
            "prettifyLogMessage": false,
            "showCommonLabels": false,
            "showLabels": false,
            "showTime": false,
            "sortOrder": "Descending",
            "wrapLogMessage": false
          },
          "targets": [
            {
              "datasource": {
                "type": "loki",
                "uid": "loki"
              },
              "editorMode": "builder",
              "expr": "{unit=\"jupyterhub.service\"} |= ``",
              "queryType": "range",
              "refId": "A"
            }
          ],
          "title": "jupyterhub",
          "type": "logs"
        }
      ],
      "refresh": "auto",
      "schemaVersion": 39,
      "tags": [],
      "templating": {
        "list": []
      },
      "time": {
        "from": "now-1h",
        "to": "now"
      },
      "timepicker": {},
      "timezone": "browser",
      "title": "small-data-cluster",
      "uid": "cefeq4w1vgu80f",
      "version": 1,
      "weekStart": ""
    }
  '';

  prometheusSlurmExporter = pkgs.buildGoModule (finalAttrs: {
    pname = "prometheus-slurm-exporter";
    version = "0.20";

    src = pkgs.fetchFromGitHub {
      owner = "vpenso";
      repo = "prometheus-slurm-exporter";
      tag = finalAttrs.version;
      hash = "sha256-KS9LoDuLQFq3KoKpHd8vg1jw20YCNRJNJrnBnu5vxvs=";
    };

    vendorHash = "sha256-A1dd9T9SIEHDCiVT2UwV6T02BSLh9ej6LC/2l54hgwI=";

    doCheck = false;

  });
in
{
  systemd.services.slurm-exporter = {
    description = "Slurm Prometheus Exporter";
    wantedBy = [ "multi-user.target" ];
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
      # http://10.0.0.64:2342/public-dashboards/ad44e1c6ea8045a0a3a8b5d391d84608
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
            options.path = ourDashboard2;
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
    scrapeConfigs = [
      {
        job_name = "headnode";
        static_configs = [
          {
            targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
          }
        ];
      }
      {
        job_name = "SlurmExporter";
        static_configs = [
          {
            targets = [ "127.0.0.1:8080" ];
          }
        ];
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
