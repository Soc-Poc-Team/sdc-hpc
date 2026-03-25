{ writeShellScriptBin }:
writeShellScriptBin "create-secret" ''
  set -euo pipefail

  usage() {
    echo "Usage: create-secret [--user USER] [--force]"
    exit 1
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

  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  cd "$ROOT"

  mkdir -p secrets

  TEMPLATE="secrets/template.json"
  TARGET="secrets/$U.json"
  SOPS_CONFIG=".sops.yaml"

  KEYS_FILE="$HOME/.config/sops/age/keys.txt"

  PUB_KEY=""
  if [ -f "$KEYS_FILE" ]; then
    PUB_KEY="$(grep '^# public key:' "$KEYS_FILE" | head -n1 | cut -d':' -f2- | xargs || true)"
  fi

  while [ -z "''${PUB_KEY:-}" ]; do
    read -r -p "Please enter your age public key: " PUB_KEY
  done


  echo "Using public key ending in: ...''${PUB_KEY: -5}"

  if [ ! -f "$TEMPLATE" ]; then
    echo "Missing $TEMPLATE"
    exit 1
  fi

  if [ ! -f "$SOPS_CONFIG" ]; then
    echo "Missing $SOPS_CONFIG"
    exit 1
  fi

  if [ -e "$TARGET" ] && [ "$FORCE" -ne 1 ]; then
    echo "$TARGET already exists. Use --force to overwrite."
    exit 1
  fi

  if ! grep -q "secrets(/|\\\\)$U\\.json" "$SOPS_CONFIG"; then
    printf '\n  - path_regex: secrets(/|\\\\)%s\\.json$\n    key_groups:\n      - age:\n          - %s\n' "$U" "$PUB_KEY" >> "$SOPS_CONFIG"
    echo "Added creation rule for $U"
  fi

  cp -f "$TEMPLATE" "$TARGET"

  echo "Creating new secrets file..."

  if ! grep -q "sops:" "$TARGET" 2>/dev/null; then
    sops -e -i "$TARGET"
  fi

  sops "$TARGET"

  if command -v direnv >/dev/null 2>&1; then
    direnv reload >/dev/null 2>&1 || true
  fi

  echo "OK: $TARGET"
''
