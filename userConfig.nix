{ pkgs, warn, ... }:
# userConfig =
let
  prodConfig = builtins.fromTOML (builtins.readFile ./config.toml);
  devConfigString = builtins.getEnv "SDC_SECRETS";

  tmpConfig =
    if devConfigString != "" then
      warn "using impure SDC_SECRETS from environment" (builtins.fromJSON devConfigString)
    else
      prodConfig;

  privateKey = (tmpConfig.headnode or { }).private_ssh_key or "";

  publicKey =
    if privateKey == "" then
      ""
    else
      builtins.replaceStrings [ "\n" ] [ "" ] (
        builtins.readFile (
          pkgs.runCommand "sdc-public-ssh-key"
            {
              nativeBuildInputs = [ pkgs.openssh ];
              inherit privateKey;
              passAsFile = [ "privateKey" ];
            }
            ''
              install -m 600 "$privateKeyPath" private-key
              ssh-keygen -y -f private-key > "$out"
            ''
        )
      );

  userConfig = tmpConfig // {
    worker = tmpConfig.worker // {
      public_ssh_key = publicKey;
    };
  };
in
# See https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/94#note_306186
if userConfig.worker.acceptDHCPHostnames == true then
  builtins.throw "Invalid configuration: worker.acceptDHCPHostnames must not be enabled. See https://git.fh-aachen.de/bigdata/cape-canaveral/small-data-cluster/-/work_items/94"
else
  userConfig
