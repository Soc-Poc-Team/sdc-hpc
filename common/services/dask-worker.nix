{ tomlConf, ... }:
{ pkgs, ... }:
let
  venvPath = "/opt/venv";
  environment = {
    LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
  };
  dask_worker_port = 3000;

  tailscaleDomain = tomlConf.tailscale.domain;
in
{
  systemd.services.dask-worker = {
    enable = true;
    description = "Starts the dask-worker";
    unitConfig = {
      Type = "simple";
    };

    path = [
      pkgs.python312Packages.bokeh
      pkgs.gcc-unwrapped
    ];

    inherit environment;

    serviceConfig = {
      ExecStart = "${venvPath}/bin/dask-worker headnode.${tailscaleDomain}:8786 --worker-port=${toString dask_worker_port}";
    };
    after = [ "python-env-setup.service" ];
    wantedBy = [ "default.target" ];
  };
  networking.firewall = {
    allowedTCPPorts = [ dask_worker_port ];
  };
}
