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
    sops -e -i "$TARGET"
  fi

  sops "$TARGET"

  if command -v direnv >/dev/null 2>&1; then
    direnv reload >/dev/null 2>&1 || true
  fi

  echo "OK: $TARGET"
''
