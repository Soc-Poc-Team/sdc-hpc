{
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

  };
}
