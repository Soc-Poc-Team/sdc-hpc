{
  pkgs,
  config,
  sops-nix,
  userConfig,
  ...
}:
let

  # Map the users into the required Nix user structure
  nixUsers = builtins.mapAttrs (userName: userData: {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "smalldatacluster"
    ];
    home = "/homes/${userName}";
    createHome = true;
    hashedPassword = userData.passwordHash;
    uid = userData.uid;
  }) userConfig.users;

  jupyterhubEnv = pkgs.python3.withPackages (
    p: with p; [
      jupyterhub
      jupyterlab
      batchspawner
      (callPackage ../roles/headnode/modules/wrapspawner/BAKdefault.nix { })
      jupyter
      jupyter-core
      notebook
    ]
  );
in
{
  imports = [
    (import ./services/dask-worker.nix { tomlConf = userConfig; })
    (import ./services/slurm.nix { tomlConf = userConfig; })
    ./services/python-venv-setup.nix
    ./targets/cluster.nix
    (import ./services/tailscale.nix { tomlConf = userConfig; })
    sops-nix.nixosModules.sops # import sops module for all hosts
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

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
    btop
    zlib
    stdenv.cc.cc
  ];

  programs.fish.enable = true;

  users = {
    defaultUserShell = pkgs.fish; # For developer convenience - may be switched back to bash later
    mutableUsers = false;
    groups = {
      smalldatacluster = { };
    };
    users = nixUsers;
  };

  console.keyMap = pkgs.lib.mkForce "de";

  networking = {
    enableIPv6 = false; # we want to be able to handle networking easy
    firewall.enable = true;
    dhcpcd = {
      # See Issue #82
      setHostname = false;
    };
  };
  # networking.wieless alongside networkmanager is no longer supported. TODO: check NM implementation
  # networking.wireless.enable = enabled;
  # networking.wireless.networks."${userConfig.wifi.ssid}".psk =
  #   "${userConfig.wifi.pwd}";

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
  services.getty.extraArgs = [ "--delay=5" ];
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
