{
  config,
  lib,
  pkgs,
  ...
}: let
  venvPath = "/opt/venv";
in {
  systemd.services.python-env-setup = {
    description = "ONESHOT: Installs the python venv for dask";

    wantedBy = ["default.target"];
    after = ["network.target"];

    # set this service as a oneshot job
    serviceConfig.Type = "oneshot";

    script = with pkgs; ''
      if [ -d "${venvPath}" ]; then
        echo "Skipping venv creation, '${venvPath}' already exists"
        echo "Remove '${venvPath}' to force venv recreation with 'rm -rf ${venvPath}'"
      else
        echo "Creating new venv environment in path: '${venvPath}'"
        ${virtualenv}/bin/virtualenv "${venvPath}"
        ${venvPath}/bin/pip install \
          "dask>=2024.9.1" \
          "distributed>=2024.9.1" \
          "ipykernel" \
          "ipython" \
          "bokeh>=3.6.0"
      fi
    '';
  };
}
