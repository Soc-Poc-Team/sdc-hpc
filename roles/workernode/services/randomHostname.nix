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
          ExecStart =
            let
              hostname = lib.getExe (pkgs.hostname-debian);
            in
            lib.getExe (
              pkgs.writeShellScriptBin "set-random-hostname.sh" ''
                echo "Current hostname is $(${hostname})"
                echo "Setting hostname to 'newHost'" # FIXME: remove
                ${hostname} newHost
                echo "Updated hostname is  ${hostname}"
              ''
            );
          RemainAfterExit = "yes";
        };

      };
  };
}
