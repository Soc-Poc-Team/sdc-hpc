{ warn, ... }:
# userConfig =
let
  prodConfig = builtins.fromTOML (builtins.readFile ./config.toml);
  devConfigString = builtins.getEnv "SDC_SECRETS";

  # TODO: remane back to userConfig as soon as it is suported again
  tmpConfig =
    if devConfigString != "" then
      warn "using impure SDC_SECRETS from environment" (builtins.fromJSON devConfigString)
    else
      prodConfig;
in
# See https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/94#note_306186
if tmpConfig.worker.acceptDHCPHostnames == true then
  builtins.throw "Invalid configuration: worker.acceptDHCPHostnames must not be enabled. See https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/94"
else
  tmpConfig
