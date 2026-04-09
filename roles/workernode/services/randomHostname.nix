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

        # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#sysinit.target
        before = [ "sysinit.target" ];
        wantedBy = [ "sysinit.target" ];

        # https://www.freedesktop.org/software/systemd/man/latest/systemd.special.html#local-fs.target
        after = [ "local-fs.target" ];

        unitConfig = {
          DefaultDependencies = "no";
        };
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe (
            pkgs.writeShellScriptBin "set-random-hostname.sh" ''
              echo "Current hostname is $(hostname)"
            ''
          );
          RemainAfterExit = "yes";
        };

      };
  };
}
