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
        description = "random hostname generation";

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
              echo "Current hostname is  :'$(hostname)'"
              NEW_HOSTNAME=worker-$((cat /sys/class/net/*/address | grep -Ev '^$|^00:00:00:00:00:00$' | head -n 1 | tr -d ':') || exit 1)
              echo "Updating hostname to : '$NEW_HOSTNAME'"
              hostname "$NEW_HOSTNAME" || exit 2
              echo "Updated hostname is  : '$(hostname)'"
            ''
          );
          RemainAfterExit = "yes";
        };

      };

    systemd.targets."pre-cluster" = {
      description = "Ready to start cluster services";

      requires = [ "rndhn.service" ];
    };
  };
}
