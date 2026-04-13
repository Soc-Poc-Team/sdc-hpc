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
    # rndhn is short for randomHostname
    systemd.services."rndhn" =

      {
        description = "random hostname generation";

        # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#network-pre.target
        before = [ "network-pre.target" ];
        wantedBy = [ "network-pre.target" ];

        # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#local-fs.target
        after = [ "local-fs.target" ];

        unitConfig = {
          DefaultDependencies = "no";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe (
            pkgs.writeShellScriptBin "set-random-hostname.sh" ''
              PATH=${
                pkgs.lib.makeBinPath (
                  with pkgs;
                  [
                    iproute2
                    gawk
                    coreutils
                    gnused
                    hostname-debian
                  ]
                )
              }

              echo "Current hostname is $(hostname)"
              NEW_HOSTNAME=$(ip link | awk '/link\/ether/ {printf "%s ", $2}' | sed 's/://g' | cut -c 1-12)
              hostname "$NEW_HOSTNAME"
              echo "Updated hostname is $(hostname)"
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
