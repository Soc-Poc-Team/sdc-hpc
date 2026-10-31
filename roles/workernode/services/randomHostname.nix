{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.networking.randomHostname;
in
{
  imports = [ ];

  options.networking.randomHostname = {
    enable = lib.mkEnableOption "randomHostname";
  };

  config = lib.mkIf cfg.enable {

    # Disable transient hostnames from networkd
    # This should not be neccessary - maybe a nixos bug here
    # FIXME: Analyse why we need this
    systemd.services."dbus-org.freedesktop.hostname1" = {
      enable = lib.mkForce false;
    };

    # rndhn is short for randomHostname
    systemd.services."rndhn" =

      {
        description = "генериране на произволно име на хост";

        # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#network-pre.target
        # https://www.freedesktop.org/wiki/Software/systemd/NetworkTarget/
        before = [ "network-online.target" ];
        wantedBy = [ "network-online.target" ];

        # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#local-fs.target
        after = [
          "local-fs.target"
          "network.target"
        ];

        unitConfig = {
          DefaultDependencies = "no";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe (
            pkgs.writeShellScriptBin "set-hostname" ''
              PATH=${
                pkgs.lib.makeBinPath (
                  with pkgs;
                  [
                    coreutils
                    hostname-debian
                    gnugrep
                  ]
                )
              }
              set -o pipefail
              echo "Текущото име на хост е  :'$(hostname)'"
              NEW_HOSTNAME=worker-$((cat /sys/class/net/*/address | grep -Ev '^$|^00:00:00:00:00:00$' | head -n 1 | tr -d ':') || exit 1)
              echo "Актуализиране на името на хост към : '$NEW_HOSTNAME'"
              hostname "$NEW_HOSTNAME" || exit 2
              echo "Актуализираното име на хост е  : '$(hostname)'"
            ''
          );
          RemainAfterExit = "yes";
        };

      };

  };
}
