{
  lib,
  pkgs,
  config,
  dask-env,
  ...
}:

let
  cfg = config.services.dask.scheduler;

  environment = {
    LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
  };
in
{
  options.services.dask.scheduler = {
    enable = lib.mkEnableOption "Dask scheduler";

    interface = lib.mkOption {
      type = lib.types.str;
      default = "tailscale0";
    };

    dashboardAddress = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0:8787";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.dask-scheduler = {
      enable = true;

      description = "Starts the dask-scheduler";

      unitConfig = {
        Type = "simple";
      };

      path = dask-env;

      inherit environment;

      serviceConfig = {
        ExecStart = ''
          dask-scheduler \
            --interface ${cfg.interface} \
            --dashboard-address ${cfg.dashboardAddress} \
            ${lib.concatStringsSep " " cfg.extraArgs}
        '';
      };

      requires = [
        "pre-cluster.target"
      ];

      requiredBy = [ "cluster.target" ];
    };

    networking.firewall.allowedTCPPorts = [
      8787
      8786
      8000
    ];
  };
}
