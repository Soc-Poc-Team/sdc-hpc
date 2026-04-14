(
  {
    modulesPath,
    lib,
    userConfig,
    ...
  }:
  {
    imports = [
      (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
      ./services/mount-nfs.nix
      ./services/metrics.nix
      ./services/randomHostname.nix
    ];

    # use a static uid as default to ensure it is the same on all nodes.. nix has reservations for this
    users.users.slurm = {
      name = "slurm";
      group = "slurm";
      uid = 307; # https://github.com/NixOS/nixpkgs/blob/0d6d1ce1e3bf7ee9125b42ec42706af8e62f3794/nixos/modules/misc/ids.nix#L341C15-L341C18
    };
    users.groups.slurm.gid = 307;

    networking = {
      useDHCP = lib.mkForce true; # networkmanager.nix sets this to false
      hostName = ""; # See https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/94#note_304364
    };
    image.baseName = lib.mkForce "workernode";

    isoImage = {
      makeEfiBootable = true;
      makeUsbBootable = true;
      # compressImage = true;
      # isoName = lib.mkForce "workernode.iso";
      appendToMenuLabel = " Workernode";
      squashfsCompression = "zstd -Xcompression-level 6";
    };

    networking.randomHostname.enable = !userConfig.worker.acceptDHCPHostnames;
  }
)
