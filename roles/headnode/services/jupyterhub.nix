{
  config,
  pkgs,
  lib,
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

  profileConfig = builtins.fromTOML (builtins.readFile ../../../profiles.toml);

  defaults = profileConfig.defaults or { };

  mkProfile =
    rawProfile:
    let
      profile = defaults // rawProfile;

      cores = profile.cores or 1;
      gpus = profile.gpus or 0;

      coreLabel = "${toString cores} core" + lib.optionalString (cores != 1) "s";

      gpuLabel = lib.optionalString (gpus > 0) (
        ", ${toString gpus} GPU" + lib.optionalString (gpus != 1) "s"
      );

      generatedLabel = "${profile.name}: ${coreLabel}, ${profile.memory}${gpuLabel}";

      gres =
        if profile ? gres then
          profile.gres
        else if gpus == 0 then
          null
        else if profile ? gpu_type then
          "gpu:${profile.gpu_type}:${toString gpus}"
        else
          "gpu:${toString gpus}";
    in
    {
      display = profile.label or generatedLabel;
      key = profile.id;

      options = {
        req_partition = profile.partition;
        req_nprocs = toString cores;
        req_runtime = profile.runtime;
        req_memory = profile.memory;
      }
      // lib.optionalAttrs (gres != null) {
        req_gres = gres;
      };
    };

  profiles = map mkProfile profileConfig.profiles;

  profilesJson = builtins.toJSON profiles;

  jupyterhubConfig = pkgs.writeText "jupyterhub_config.py" ''
    import batchspawner
    import json
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

    # https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/175
    profiles = json.loads(${builtins.toJSON profilesJson})
    c.ProfilesSpawner.profiles = [
        (
            profile["display"],
            profile["key"],
            "batchspawner.SlurmSpawner",
            profile["options"],
        )
        for profile in profiles
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
