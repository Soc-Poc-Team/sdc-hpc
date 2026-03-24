{ pkgs }:
{
  userConfig = builtins.fromTOML (builtins.readFile ./config.toml);
}
