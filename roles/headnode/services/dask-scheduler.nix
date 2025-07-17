{ tomlConf, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  venvPath = "/opt/venv";
  environment = {
    LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
  };
in
{
  systemd.services.dask-scheduler = {
    enable = true;
    description = "Starts the dask-scheduler";
    unitConfig = {
      Type = "simple";
    };
    path = [
      pkgs.python312Packages.bokeh
      pkgs.gcc-unwrapped
    ];

    inherit environment;

    serviceConfig = {
      ExecStart = "${venvPath}/bin/dask-scheduler --interface tailscale0 --dashboard-address 0.0.0.0:8787";
    };
    after = [ "python-env-setup.service" ];
    wantedBy = [ "default.target" ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      8787
      8786
      8000
    ];
  };
}
