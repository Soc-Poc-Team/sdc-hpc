{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.sdc;

  userConfig = if cfg.useToml then builtins.fromTOML (builtins.readFile ../config.toml) else null;

  configJson = if cfg.useToml then builtins.toJSON userConfig else null;
in
{
  options.sdc.useToml = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Use config.toml instead of sops secret";
  };

  config = lib.mkMerge [
    (lib.mkIf (!cfg.useToml) {
      sops.defaultSopsFile = ../secrets/develop.json;
      sops.secrets."" = {
        path = "/run/secrets/config.json";
      };
    })

    (lib.mkIf cfg.useToml {
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
    })
  ];
}
