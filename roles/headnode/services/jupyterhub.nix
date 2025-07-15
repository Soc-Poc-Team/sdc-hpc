{ tomlConf, ... }:
{
  config,
  pkgs,
  ...
}:
let
  tailscaleDomain = tomlConf.tailscale.domain;
  userDataDir = "/homes";
  quotedUserNames = map (u: ''"${u}"'') (builtins.attrNames tomlConf.users);
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

  jlabKernels = pkgs.jupyter-kernel.create {
    definitions = {
      python312Kernel = (
        let
          env = pkgs.python312.withPackages (
            p: with p; [
              ipykernel
              dask-gateway
              numpy
              scipy
              pandas
              dask
              pip
              distributed
              torch
              torchvision
              # tensorflow #error: tensorflow-2.13.0 not supported for interpreter python3.12
              # keras #error: tensorflow-2.13.0 not supported for interpreter python3.12
              #matplotlib
              scikit-learn
              skorch
              plotly
              pyarrow
              beautifulsoup4
            ]
          );
        in
        {
          displayName = "Python 3.12";
          argv = [
            "${env.interpreter}"
            "-m"
            "ipykernel_launcher"
            "-f"
            "{connection_file}"
          ];
          language = "python";
          logo32 = "${env}/${env.sitePackages}/ipykernel/resources/logo-32x32.png";
          logo64 = "${env}/${env.sitePackages}/ipykernel/resources/logo-64x64.png";
        }
      );
    };
  };

  jupyterhubConfig = pkgs.writeText "jupyterhub_config.py" ''
    import batchspawner
    import os

    c.JupyterHub.hub_ip = "headnode.${tailscaleDomain}"
    c.JupyterHub.ip = "0.0.0.0"
    c.JupyterHub.authenticator_class = "jupyterhub.auth.PAMAuthenticator"
    #c.JupyterHub.spawner_class = 'batchspawner.SlurmSpawner'
    c.JupyterHub.spawner_class = 'wrapspawner.ProfilesSpawner'

    c.Authenticator.allowed_users = set(${"[${builtins.concatStringsSep ", " quotedUserNames}]"})


    c.Spawner.notebook_dir = '${userDataDir}/{username}'
    c.SlurmSpawner.notebook_dir = '${userDataDir}/{username}'

    c.Spawner.default_url = '/lab'

    c.SlurmSpawner.environment = {
        'JUPYTER_PATH': '${jlabKernels}'
    }

    # c.SlurmSpawner.batch_submit_cmd = ['sbatch', '--parsable']
    c.SlurmSpawner.batchspawner_singleuser_cmd = '${jupyterhubEnv}/bin/.batchspawner-singleuser-wrapped'
    c.SlurmSpawner.cmd = "${jupyterhubEnv}/bin/.jupyterhub-singleuser-wrapped"
    c.ProfilesSpawner.profiles = [
    ('Small: 1 core, 128 MB', 'slurm4c64gb1gpu', 'batchspawner.SlurmSpawner', dict(req_partition='debug', req_nprocs='1', req_runtime='1-00:00:00', req_memory='2048M')),
    ]

    c.SlurmSpawner.batch_script = """#!/usr/bin/env bash

    #SBATCH --output={{homedir}}/jupyterhub_slurmspawner_%j.log
    #SBATCH --job-name=spawner-jupyterhub
    ##SBATCH --chdir={{homedir}}
    #SBATCH --chdir=/homes/{{username}}
    #SBATCH --export={{keepvars}}
    #SBATCH --get-user-env=L
    #SBATCH --mem={{memory}}

    {% if partition  %}#SBATCH --partition={{partition}}
    {% endif %}{% if runtime    %}#SBATCH --time={{runtime}}
    {% endif %}{% if memory     %}#SBATCH --mem={{memory}}
    {% endif %}{% if gres       %}#SBATCH --gres={{gres}}
    {% endif %}{% if nprocs     %}#SBATCH --cpus-per-task={{nprocs}}
    {% endif %}{% if reservation%}#SBATCH --reservation={{reservation}}
    {% endif %}{% if options    %}#SBATCH {{options}}{% endif %}

    export JUPYTERHUB_API_TOKEN=$JUPYTERHUB_API_TOKEN
    export JUPYTERHUB_API_URL=$JUPYTERHUB_API_URL
    export JPY_API_TOKEN=$JPY_API_TOKEN
    export JUPYTERHUB_CLIENT_ID=$JUPYTERHUB_CLIENT_ID
    export JUPYTERHUB_OAUTH_CALLBACK=$JUPYTERHUB_OAUTH_CALLBACK
    export JUPYTERHUB_USER=$JUPYTERHUB_USER
    export JUPYTERHUB_BASE_URL=$JUPYTERHUB_BASE_URL
    export JUPYTERHUB_SERVICE_PREFIX=$JUPYTERHUB_SERVICE_PREFIX

    echo $JUPYTERHUB_API_TOKEN
    echo $JUPYTERHUB_API_URL
    echo $JPY_API_TOKEN
    echo $JUPYTERHUB_CLIENT_ID
    echo $JUPYTERHUB_OAUTH_CALLBACK
    echo $JUPYTERHUB_USER
    echo $JUPYTERHUB_BASE_URL
    echo $JUPYTERHUB_SERVICE_PREFIX

    echo $JUPYTERHUB_SERVICE_URL
    echo $JUPYTERHUB_SERVICE_URL
    echo $JUPYTERHUB_SERVICE_URL
    echo $JUPYTERHUB_SERVICE_URL
    echo $JUPYTERHUB_SERVICE_URL
    echo $JUPYTERHUB_SERVICE_URL

    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}:${
      pkgs.lib.makeLibraryPath [ pkgs.zlib ]
    }";

    export TMPDIR=/homes/{{username}}/.tmp
    export PIP_CACHE_DIR=/homes/{{username}}/.pip-cache

    set -euo pipefail
    trap 'echo SIGTERM received' TERM
    {{prologue}}
    ${jupyterhubEnv}/bin/batchspawner-singleuser ${jupyterhubEnv}/bin/.jupyterhub-singleuser-wrapped --debug
    echo "jupyterhub-singleuser ended gracefully"
    {{epilogue}}

    """
  '';
in
{
  systemd.services.jupyterhub = {
    description = "Jupyterhub development server";

    after = [
      "network.target"
      "tailscale-autoconnect.service"
    ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      python3Packages.jupyterlab
      python3Packages.jupyterhub
      python3Packages.jupyter
      python3Packages.notebook
      sudo
    ];

    environment = {
      LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}";
    };
    serviceConfig = {
      Restart = "always";
      ExecStart = "${jupyterhubEnv}/bin/jupyterhub --config ${jupyterhubConfig}";
      User = "root";
      StateDirectory = "jupyterhub";
      WorkingDirectory = "/var/lib/jupyterhub";
      Environment = "PATH=${jupyterhubEnv}/bin:/run/current-system/sw/bin/:$PATH";
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
