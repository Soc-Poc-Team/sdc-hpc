{
  config,
  userConfig,
  pkgs,
  ...
}:
let
  tailscaleDomain = userConfig.tailscale.domain;
in
{
  services.prometheus = {
    enable = false;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };
    scrapeConfigs = [
      {
        job_name = "worker1";
        static_configs = [ { targets = [ "headnode.${tailscaleDomain}:9001" ]; } ];
      }
    ];
  };

  services.alloy = {
    enable = true;
    configPath = pkgs.writeText "worker-config.alloy" ''
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
                      host = "worker1",
                      job  = "systemd-journal",
              }
      }

      loki.write "default" {
              endpoint {
                      url = "http://headnode.${tailscaleDomain}:3100/loki/api/v1/push"
              }
              external_labels = {}
      }

    '';
  };

  networking.firewall = {
    allowedTCPPorts = [
      config.services.prometheus.exporters.node.port
      8080
    ];
  };
}
