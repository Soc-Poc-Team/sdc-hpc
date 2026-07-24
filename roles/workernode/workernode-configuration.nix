(
  {
    pkgs,
    lib,
    userConfig,
    ...
  }:
  {
    imports = [
      ./services/mount-nfs.nix
      ./services/metrics.nix
      ./services/randomHostname.nix
      ./services/journal.nix
      ./services/await-headnode.nix
    ];

    users = {
      users = {

        # use a static uid as default to ensure it is the same on all nodes.. nix has reservations for this
        slurm = {
          name = "slurm";
          group = "slurm";
          uid = 307; # https://github.com/NixOS/nixpkgs/blob/0d6d1ce1e3bf7ee9125b42ec42706af8e62f3794/nixos/modules/misc/ids.nix#L341C15-L341C18
        };
        root = {
          openssh.authorizedKeys.keys = [
            userConfig.worker.public_ssh_key
          ];
        };
      };
      groups.slurm.gid = 307;
    };

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

    services.dask.worker.enable = true;

    systemd.services."tailscale-autoconnect" = lib.mkIf userConfig.worker.acceptDHCPHostnames {
      path = [
        pkgs.hostname-debian
      ];
      preStart = ''
        start=$(date +%s)

        while true; do
          out=$(hostname)
          now=$(date +%s)

          if [ "$out" != "nixos" ]; then
            echo "hostname detected: '$out' took $((now - start))"
            break
          fi

          if (( now - start >= 300 )); then
            echo "Did not recieve a hostname via DHCP. Not joining cluster..."
            echo "If you dont have DHCP configured for hostnames, set worker.acceptDCHPHostnames to false!"
            exit 1
          fi

          sleep 5
        done
      '';
    };
  }
)
