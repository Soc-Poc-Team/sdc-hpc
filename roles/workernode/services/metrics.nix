{ tomlConf, ... }:
{ config, ... }:
let tailscaleDomain = tomlConf.tailscale.domain;
in {
  services.prometheus = {
    enable = false;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    scrapeConfigs = [{
      job_name = "worker1";
      static_configs = [{ targets = [ "headnode.${tailscaleDomain}:9001" ]; }];
    }];
  };

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 28183;
        grpc_listen_port = 0;
      };
      clients =
        [{ url = "http://headnode.${tailscaleDomain}:3100/loki/api/v1/push"; }];
      positions = { filename = "/tmp/positions.yaml"; };
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = "worker1";
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
  };
  networking.firewall = {
    allowedTCPPorts = [
      config.services.promtail.configuration.server.http_listen_port
      config.services.prometheus.exporters.node.port
      8080
    ];
  };
}
