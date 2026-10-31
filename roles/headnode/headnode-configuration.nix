{ pkgs, ... }:
let
  persistToDisk = pkgs.writeShellScriptBin "persist-to-disk" ''
    set -euo pipefail

    usage() {
      echo "Употреба: persist-to-disk <disk-path>"
      echo "Пример: persist-to-disk /dev/disk/by-id/disk1id"
      exit 1
    }

    if [ "$#" -ne 1 ]; then
      echo "Грешка: липсва аргумент за пътя до диска."
      usage
    fi

    DISK_PATH="$1"

    if [ ! -b "$DISK_PATH" ]; then
      echo "Грешка: '$DISK_PATH' не е валидно блоково устройство."
      exit 1
    fi

    echo "Подготовка за запазване на конфигурацията на диска в: $DISK_PATH"
    echo "Това ще изтрие всички данни на посочения диск."
    read -r -p "Сигурни ли сте, че искате да продължите? [д/Н] " confirm
    case "$confirm" in
      [yY][eE][sS]|[yY])
        ;;
      *)
        echo "Прекъснато от потребителя."
        exit 0
        ;;
    esac

    echo "Изпълняване на disko-install с flake 'small-data-cluster#headnode'..."
    nix run 'github:nix-community/disko/latest#disko-install' -- --flake '/iso/repo/small-data-cluster#headnode' --disk main "$DISK_PATH"
    status=$?

    if [ "$status" -eq 0 ]; then
      echo "Инсталирането на диска завърши успешно."
    else
      echo "Грешка: инсталирането на диска се провали с код на грешка $status."
      exit "$status"
    fi
  '';
in
{
  imports = [
    ./services/jupyterhub.nix
    ./services/userhomes.nix
    ./services/grafana
    ./services/slurmctld.nix
    ./services/dashboard
    ./services/telemetry.nix
    ./services/pharosd
    ./sshKey.nix
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
