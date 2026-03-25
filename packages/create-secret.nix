{ writeShellScriptBin }:
writeShellScriptBin "create-secret" ''
  set -euo pipefail

  usage() {
    echo "Usage: create-secret [--user USER] [--force]"
    exit 1
  }

  get_public_key() {
    # TODO: get public key from line 2 of keys.txt or prompt user for it
    echo "age-public-key"
  }

  USER_OVERRIDE=""
  FORCE=0

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --user)
        shift
        [ "$#" -gt 0 ] || usage
        USER_OVERRIDE="$1"
        ;;
      --force)
        FORCE=1
        ;;
      -h|--help)
        usage
        ;;
      *)
        usage
        ;;
    esac
    shift
  done

  U="''${USER_OVERRIDE:-$USER}"
  PUBKEY="$(get_public_key)"

  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  cd "$ROOT"

  mkdir -p secrets

  TEMPLATE="secrets/template.json"
  TARGET="secrets/$U.json"
  SOPS_CONFIG=".sops.yaml"

  if [ ! -f "$TEMPLATE" ]; then
    echo "Missing $TEMPLATE"
    exit 1
  fi

  if [ -e "$TARGET" ] && [ "$FORCE" -ne 1 ]; then
    echo "$TARGET already exists. Use --force to overwrite."
    exit 1
  fi

  cp -f "$TEMPLATE" "$TARGET"

  if ! grep -q "sops:" "$TARGET" 2>/dev/null; then
    SOPS_AGE_RECIPIENTS="$PUBKEY" sops -e -i "$TARGET"
  fi

  if [ ! -f "$SOPS_CONFIG" ]; then
    echo "Missing $SOPS_CONFIG"
    exit 1
  fi

  RULE="  - path_regex: secrets(/|\\\\)$U\\.json$
    key_groups:
      - age:
          - $PUBKEY"

  if ! grep -q "secrets(/|\\\\)$U\\.json" "$SOPS_CONFIG"; then
    printf "\n%s\n" "$RULE" >> "$SOPS_CONFIG"
  fi

  sops "$TARGET"

  if command -v direnv >/dev/null 2>&1; then
    direnv reload >/dev/null 2>&1 || true
  fi

  echo "OK: $TARGET"
''
