{
  pkgs,
  lib,
  ...
}:

let
  # TODO: Read from env instad of sops
  userConfig = builtins.fromTOML (builtins.readFile ../config.toml);

  configJson = builtins.toJSON userConfig;
in
{
  config = {
    systemd.services.generate-config = {
      description = "Generate config.json from TOML";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "generate-config" ''
                      install -d -m 0700 /run/secrets
                      cat > /run/secrets/config.json <<'EOF'
          ${configJson}
          EOF
                      chmod 0600 /run/secrets/config.json
        '';
      };
    };
  };

}
