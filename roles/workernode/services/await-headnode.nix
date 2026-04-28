{
  lib,
  config,
  ...
}:
let
  cfg = config.awaitHeadnode; # FIXME: decide on location for this option? Maybe userconfig instead?
in
{
  imports = [ ];

  options = {
  };

  config = lib.mkIf cfg.enable {

  };
}
