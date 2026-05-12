{ pkgs, modulesPath, ... }:
let
  persistToDisk = pkgs.writeShellScriptBin "persist-to-disk" ''
    set -euo pipefail

    usage() {
      echo "Usage: persist-to-disk <disk-path>"
      echo "Example: persist-to-disk /dev/disk/by-id/disk1id"
      exit 1
    }

    if [ "$#" -ne 1 ]; then
      echo "Error: Missing disk path argument."
      usage
    fi

    DISK_PATH="$1"

    if [ ! -b "$DISK_PATH" ]; then
      echo "Error: '$DISK_PATH' is not a valid block device."
      exit 1
    fi

    echo "Preparing to persist configuration to disk at: $DISK_PATH"
    echo "This will erase all data on the specified disk."
    read -r -p "Are you sure you want to continue? [y/N] " confirm
    case "$confirm" in
      [yY][eE][sS]|[yY])
        ;;
      *)
        echo "Aborted by user."
        exit 0
        ;;
    esac

    echo "Running disko-install with flake 'small-data-cluster#headnode'..."
    nix run 'github:nix-community/disko/latest#disko-install' -- --flake '/iso/repo/small-data-cluster#headnode' --disk main "$DISK_PATH"
    status=$?

    if [ "$status" -eq 0 ]; then
      echo "Disk installation completed successfully."
    else
      echo "Error: Disk installation failed with exit code $status."
      exit "$status"
    fi
  '';
in
{
  imports = [
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
    ./services/jupyterhub.nix
    ./services/userhomes.nix
    ./services/grafana.nix
    ./services/slurmctld.nix
    ./services/dashboard.nix
    ./services/telemetry.nix
  ];
  environment.systemPackages = [ persistToDisk ];

  networking = {
    hostName = "headnode";
  };

  services.dask.scheduler.enable = true;

  isoImage = {
    makeEfiBootable = true;
    makeUsbBootable = true;
    compressImage = false; # TURN ON FOR VM TODO
    # isoName = nixpkgs.lib.mkForce "headnode.iso";
    appendToMenuLabel = " Headnode";
    squashfsCompression = "zstd -Xcompression-level 6";
    contents = [
      {
        source = ./.; # mount the whole repo inside the iso for disko install with grub
        target = "/repo/small-data-cluster";
      }
    ];
  };

}
