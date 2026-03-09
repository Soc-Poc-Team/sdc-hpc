({ modulesPath, lib, ... }:
  let tomlConfig = builtins.fromTOML (builtins.readFile ../../config.toml);
  in {
    imports = [
      (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
      (import ./services/mount-nfs.nix { tomlConf = tomlConfig; })
      (import ./services/metrics.nix { tomlConf = tomlConfig; })
    ];

    # use a static uid as default to ensure it is the same on all nodes.. nix has reservations for this
    users.users.slurm = {
      name = "slurm";
      group = "slurm";
      uid =
        307; # https://github.com/NixOS/nixpkgs/blob/0d6d1ce1e3bf7ee9125b42ec42706af8e62f3794/nixos/modules/misc/ids.nix#L341C15-L341C18
    };
    users.groups.slurm.gid = 307;

    networking = {
      useDHCP = lib.mkForce true; # networkmanager.nix sets this to false
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
  })
