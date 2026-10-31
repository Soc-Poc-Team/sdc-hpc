{
  pkgs,
  lib,
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
    openssh.authorizedKeys.keys = userData.sshKeys or [ ];
  }) userConfig.users;

  # https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/146
  sdc-hitman = pkgs.callPackage ../packages/sdc-hitman { };
in
{
  imports = [
    ./iso-image.nix
    ./services/dask
    (import ./services/slurm.nix)
    ./targets/cluster.nix
    (import ./services/tailscale.nix)
    ./services/tailscale-tidy.nix
    ./services/avahi.nix
    sops-nix.nixosModules.sops # import sops module for all hosts
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  documentation.man.cache.enable = false; # https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/109

  boot.kernelPackages = lib.mkIf (lib.versionOlder pkgs.linux.version "6.18.22") (
    lib.mkDefault pkgs.linuxPackages_6_18
  );

  boot.zfs.forceImportRoot = true; # https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/159#note_317456

  system.extraDependencies = [
    (import ./environments/jlabkernels.nix { inherit pkgs; })
    (import ./environments/jlab.nix { inherit pkgs; })
  ];

  environment.systemPackages = with pkgs; [
    git
    # editors
    vim
    neovim
    helix

    # system packages
    gcc-unwrapped
    python313

    # tools
    btop
    sdc-hitman
  ];

  programs.fish.enable = true;

  users = {
    defaultUserShell = pkgs.fish;
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
      setHostname = userConfig.worker.acceptDHCPHostnames;
    };
  };

  services.openssh.enable = true;

  sops.secrets."munge-key" = {
    sopsFile = ../secrets/munge.json;
    format = "json";
    key = "mungeKey";
    owner = "munge";
    group = "munge";
    mode = "0400";
  };
  services.munge.password = config.sops.secrets."munge-key".path;

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
