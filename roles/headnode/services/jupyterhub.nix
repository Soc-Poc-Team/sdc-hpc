{
  config,
  pkgs,
  userConfig,
  ...
}:
let
  tailscaleDomain = userConfig.tailscale.domain;
  userDataDir = "/homes";
  quotedUserNames = map (u: ''"${u}"'') (builtins.attrNames userConfig.users);
  jlabKernels = import ../../../common/environments/jlabkernels.nix { inherit pkgs; };
  jupyterhubEnv = pkgs.python3.withPackages (
    p: with p; [
      jupyterhub
      jupyterlab
      batchspawner
      (callPackage ../modules/wrapspawner/BAKdefault.nix { })
      jupyter
      jupyter-core
      notebook
    ]
  );

  jupyterhubConfig = pkgs.writeText "jupyterhub_config.py" ''
    import batchspawner
    import os

    c.JupyterHub.hub_ip = "headnode.${tailscaleDomain}"
    c.JupyterHub.ip = "0.0.0.0"
    c.JupyterHub.authenticator_class = "jupyterhub.auth.PAMAuthenticator"
    c.JupyterHub.spawner_class = 'wrapspawner.ProfilesSpawner'

    c.Authenticator.allowed_users = set(${"[${builtins.concatStringsSep ", " quotedUserNames}]"})

    c.Spawner.notebook_dir = '${userDataDir}/{username}'
    c.Spawner.http_timeout = 300
    c.Spawner.start_timeout = 600

    c.Spawner.default_url = '/lab'

    c.SlurmSpawner.batch_submit_cmd = "${pkgs.slurm}/bin/sbatch --parsable"
    c.SlurmSpawner.batch_query_cmd = "${pkgs.slurm}/bin/squeue -h -j {job_id} -o '%T %B'"
    c.SlurmSpawner.batch_cancel_cmd = "${pkgs.slurm}/bin/scancel {job_id}"
    c.SlurmSpawner.exec_prefix = "${pkgs.sudo}/bin/sudo -E -u {username}"
    c.SlurmSpawner.batchspawner_singleuser_cmd = '${jupyterhubEnv}/bin/.batchspawner-singleuser-wrapped'
    c.SlurmSpawner.cmd = "${jupyterhubEnv}/bin/.jupyterhub-singleuser-wrapped"
    c.ProfilesSpawner.profiles = [
    ('Small: 1 core, 128 MB', 'slurm1c128mb0gpu', 'batchspawner.SlurmSpawner', dict(req_partition='debug', req_nprocs='1', req_runtime='1-00:00:00', req_memory='128M')),
    ('Medium: 1 core, 2048 MB', 'slurm1c2gb0gpu', 'batchspawner.SlurmSpawner', dict(req_partition='debug', req_nprocs='1', req_runtime='1-00:00:00', req_memory='2048M')),
    ('Medium+: 2 core, 2048 MB', 'slurm2c2gb0gpu', 'batchspawner.SlurmSpawner', dict(req_partition='debug', req_nprocs='2', req_runtime='1-00:00:00', req_memory='2048M')),
    ('GPU: 4 cores, 16 GB, 1 GPU', 'slurm4c16gb1gpu', 'batchspawner.SlurmSpawner', dict(req_partition='debug', req_nprocs='4', req_runtime='1-00:00:00', req_memory='16G', req_gres='gpu:1')),
    ]

    c.SlurmSpawner.batch_script = """#!/usr/bin/env bash

    #SBATCH --output={{homedir}}/jupyterhub_slurmspawner_%j.log
    #SBATCH --job-name=spawner-jupyterhub
    #SBATCH --chdir=/homes/{{username}}
    #SBATCH --export={{keepvars}}
    {% if partition  %}#SBATCH --partition={{partition}}
    {% endif %}{% if runtime    %}#SBATCH --time={{runtime}}
    {% endif %}{% if memory     %}#SBATCH --mem={{memory}}
    {% endif %}{% if gres       %}#SBATCH --gres={{gres}}
    {% endif %}{% if nprocs     %}#SBATCH --cpus-per-task={{nprocs}}
    {% endif %}{% if reservation%}#SBATCH --reservation={{reservation}}
    {% endif %}{% if options    %}#SBATCH {{options}}{% endif %}
    echo "Spawning..."
    export JUPYTERHUB_API_TOKEN JUPYTERHUB_API_URL JPY_API_TOKEN JUPYTERHUB_CLIENT_ID JUPYTERHUB_OAUTH_CALLBACK JUPYTERHUB_USER JUPYTERHUB_BASE_URL JUPYTERHUB_SERVICE_PREFIX
    export JUPYTER_PATH=${jlabKernels}
    export PATH

    echo $JUPYTERHUB_SERVICE_URL

    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}:${
      pkgs.lib.makeLibraryPath [ pkgs.zlib ]
    }";

    export TMPDIR=/homes/{{username}}/.tmp
    mkdir -p "$TMPDIR"
    export PIP_CACHE_DIR=/homes/{{username}}/.pip-cache

    set -euo pipefail
    trap 'echo SIGTERM received' TERM
    {{prologue}}
    ${jupyterhubEnv}/bin/batchspawner-singleuser ${jupyterhubEnv}/bin/.jupyterhub-singleuser-wrapped --debug
    {{epilogue}}
    """
  '';
in
{
  systemd.services.jupyterhub = {
    description = "Jupyterhub development server";

    requires = [ "pre-cluster.target" ];
    after = [ "pre-cluster.target" ];
    requiredBy = [ "cluster.target" ];

    path = [
      jupyterhubEnv
      # https://github.com/NixOS/nixpkgs/tree/nixos-26.05/nixos/modules/system
      config.system.path
    ];

    environment = {
      LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
    };

    serviceConfig = {
      Restart = "always";
      ExecStart = "${jupyterhubEnv}/bin/jupyterhub --config ${jupyterhubConfig}";
      User = "root";
      StateDirectory = "jupyterhub";
      WorkingDirectory = "/var/lib/jupyterhub";
    };
  };

  time.timeZone = "Europe/Amsterdam";

  networking.firewall = {
    allowedTCPPorts = [
      config.services.jupyterhub.port
      8081
    ];
  };
}
