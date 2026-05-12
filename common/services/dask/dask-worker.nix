{
  lib,
  pkgs,
  config,
  userConfig,
  dask-env,
  ...
}:

let
  cfg = config.services.dask.worker;

  environment = {
    LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
  };

  tailscaleDomain = userConfig.tailscale.domain;
in
{
  options.services.dask.worker = {
    enable = lib.mkEnableOption "Dask worker";

    workerPort = lib.mkOption {
      type = lib.types.port;
      default = 3000;
    };

    schedulerHost = lib.mkOption {
      type = lib.types.str;
      default = "headnode.${tailscaleDomain}";
    };

    schedulerPort = lib.mkOption {
      type = lib.types.port;
      default = 8786;
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.dask-worker = {
      enable = true;

      description = "Starts the dask-worker";

      unitConfig = {
        Type = "simple";
      };

      path = dask-env;
      inherit environment;

      script = ''
        exec dask-worker \
          ${cfg.schedulerHost}:${toString cfg.schedulerPort} \
          --worker-port=${toString cfg.workerPort} \
          ${lib.concatStringsSep " " cfg.extraArgs}
      '';

      after = [
        "pre-cluster.target"
      ];

      requires = [
        "pre-cluster.target"
      ];

      # TODO: switch to requiredBy as soon as we start working with dask
      wantedBy = [ "cluster.target" ];
    };

    networking.firewall.allowedTCPPorts = [
      cfg.workerPort
    ];
  };
}
