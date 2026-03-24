{ pkgs }:
{
  decrypt =
    let
      pythonWithToml = pkgs.python3.withPackages (ps: [ ps.toml ]);
    in
    pkgs.runCommand "user-config"
      {
        buildInputs = [
          pkgs.sops
          pythonWithToml
        ];
        src = ./.;
      }
      ''
        set -euo pipefail
        mkdir -p $out
        SECRETS_DIR=''${src}/secrets
        found=false
        for f in "$SECRETS_DIR"/*.json; do
          [ -e "$f" ] || continue
          echo "Attempting to decrypt $f" >&2
          if sops -d "f">"f" > "f">"out/_decrypted.json" 2>/dev/null; then
            echo "Decrypted $f" >&2
            mv "out/decrypted.json""out/_decrypted.json" "out/d​ecrypted.json""out/config.json"
            found=true
            break
          else
            echo "Could not decrypt $f" >&2
          fi
        done
        if [ "$found" = "false" ]; then
          if [ -f "''${src}/config.toml" ]; then
            echo "No decryptable JSON found — converting config.toml to config.json" >&2
            python -c 'import toml, json, sys; print(json.dumps(toml.load(open(sys.argv[1]))))' "src/config.toml">"{src}/config.toml" > "src/config.toml">"out/config.json"
          else
            echo "No decryptable JSON and no config.toml; writing empty config.json" >&2
            echo '{}' > $out/config.json
          fi
        fi
      '';
  userConfig = builtins.fromTOML (builtins.readFile ./config.toml);
}
