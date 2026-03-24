{ pkgs, ... }:

let
  userConfig = builtins.fromTOML (builtins.readFile ../config.toml);

  configJson = pkgs.writeText "config.json" (builtins.toJSON userConfig);
in
{
  environment.etc."config.json".source = configJson; # expose secrets to runtime
}
