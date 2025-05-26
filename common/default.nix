{
  pkgs,
  config,
  ...
}: let
  tomlConfig = builtins.fromTOML (builtins.readFile ../config.toml);
  enabled = tomlConfig.wifi.enabled;

  # Map the users into the required Nix user structure
  nixUsers =
    builtins.mapAttrs (userName: userData: {
      isNormalUser = true;
      extraGroups = ["wheel" "smalldatacluster"];
      home = "/homes/${userName}";
      createHome = true;
      hashedPassword = userData.passwordHash;
      uid = userData.uid;
    })
    tomlConfig.users;

  jupyterhubEnv = pkgs.python3.withPackages (p:
    with p; [
      jupyterhub
      jupyterlab
      batchspawner
      (callPackage ../roles/headnode/modules/wrapspawner/BAKdefault.nix {})
      jupyter
      jupyter-core
      notebook
    ]);

  hostsEntries = map (ip: "${ip}  ${builtins.concatStringsSep ", " (tomlConfig.hosts.${ip})}") (builtins.attrNames tomlConfig.hosts);
in {
  imports = [
    (import ./services/dask-worker.nix {tomlConf = tomlConfig;})
    (import ./services/slurm.nix {tomlConf = tomlConfig;})
    ./services/python-venv-setup.nix
    (import ./services/tailscale.nix {tomlConf = tomlConfig;})
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    git
    ncdu
    vim
    wget
    ranger
    jq
    neovim
    gcc-unwrapped
    nfs-utils
    python312
    python312Packages.pip
    virtualenv
    jupyterhubEnv

    zlib
    stdenv.cc.cc
  ];

  users = {
    defaultUserShell = pkgs.bashInteractive;
    mutableUsers = false;
    groups = {
      smalldatacluster = {};
    };
    users = nixUsers;
  };

  networking.enableIPv6 = false; # we want to be able to handle networking easy
  networking.firewall.enable = true;

  # TODO: make this configurable via config.toml
  networking.wireless.enable = enabled;
  networking.wireless.networks."${tomlConfig.wifi.ssid}".psk = "${tomlConfig.wifi.pwd}";

  # networking.extraHosts = ''
  # ${builtins.concatStringsSep "\n" hostsEntries}
  # '';
  services.openssh.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };

  environment.interactiveShellInit = ''
    alias jkl='sudo loadkeys colemak'
    alias logf='sudo journalctl --no-pager -f -u'
    alias log='sudo journalctl --no-pager -u'
    alias sstatus='sudo systemctl status'
    alias srestart='sudo systemctl restart'
  '';

  environment.etc."munge/munge.key" = {
    mode = "0600";
    uid = config.users.users.munge.uid;
    text = ''
      bigdatalabbigdatalab
      bigdatalabbigdatalab
      bigdatalabbigdatalab
      bigdatalabbigdatalab
      bigdatalabbigdatalab
      bigdatalabbigdatalab
      bigdatalabbigdatalab
      bigdatalabbigdatalab
      bigdatalabbigdatalab
    '';
  };

  environment.etc."slurm/test-submit.sh" = {
    mode = "0777";
    text = ''
      #!/usr/bin/env bash
      #SBATCH --job-name=hello_world     # Job name
      #SBATCH --output=hello_world.out    # Output file
      #SBATCH --error=hello_world.err      # Error file
      #SBATCH --partition=debug            # Partition name
      #SBATCH --ntasks=1                   # Number of tasks
      #SBATCH --time=00:01:00              # Time limit (hh:mm:ss)


      echo "Hello, World from SLURM!!"
    '';
  };
  services.getty.extraArgs = ["--delay=5"];
  environment.etc.issue.text = ''
    ███████╗███╗   ███╗ █████╗ ██╗     ██╗         ██████╗  █████╗ ████████╗ █████╗      ██████╗██╗     ██╗   ██╗███████╗████████╗███████╗██████╗
    ██╔════╝████╗ ████║██╔══██╗██║     ██║         ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗    ██╔════╝██║     ██║   ██║██╔════╝╚══██╔══╝██╔════╝██╔══██╗
    ███████╗██╔████╔██║███████║██║     ██║         ██║  ██║███████║   ██║   ███████║    ██║     ██║     ██║   ██║███████╗   ██║   █████╗  ██████╔╝
    ╚════██║██║╚██╔╝██║██╔══██║██║     ██║         ██║  ██║██╔══██║   ██║   ██╔══██║    ██║     ██║     ██║   ██║╚════██║   ██║   ██╔══╝  ██╔══██╗
    ███████║██║ ╚═╝ ██║██║  ██║███████╗███████╗    ██████╔╝██║  ██║   ██║   ██║  ██║    ╚██████╗███████╗╚██████╔╝███████║   ██║   ███████╗██║  ██║
    ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝     ╚═════╝╚══════╝ ╚═════╝ ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝


    \d \t

    IP: \4{ens18}
  '';
}
