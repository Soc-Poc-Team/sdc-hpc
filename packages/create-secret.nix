{ writeShellScriptBin }:
writeShellScriptBin "create-secret" ''
  set -euo pipefail

  usage() {
    echo "Употреба: create-secret [--user USER] [--force]"
    exit 1
  }

  USER_OVERRIDE=""
  FORCE=0

  CODEOWNERS="CODEOWNERS"

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
    read -r -p "Моля, въведете публичния ключ на age: " PUB_KEY
  done


  echo "Използва се публичен ключ, завършващ на: ...''${PUB_KEY: -5}"

  if [ ! -f "$TEMPLATE" ]; then
    echo "Липсва $TEMPLATE"
    exit 1
  fi

  if [ ! -f "$SOPS_CONFIG" ]; then
    echo "Липсва $SOPS_CONFIG"
    exit 1
  fi

  if [ -e "$TARGET" ] && [ "$FORCE" -ne 1 ]; then
    echo "$TARGET вече съществува. Използвайте --force, за да го презапишете."
    exit 1
  fi

  if ! grep -F "path_regex: secrets(/|\\\\)$U\\.json$" "$SOPS_CONFIG" >/dev/null; then
    printf '\n  - path_regex: secrets(/|\\\\)%s\\.json$\n    key_groups:\n      - age:\n          - %s\n' "$U" "$PUB_KEY" >> "$SOPS_CONFIG"
    echo "Добавено е правило за създаване за $U"
  fi

  cp -f "$TEMPLATE" "$TARGET"

  echo "Създаване на нов файл със тайни..."

  if ! grep -q "sops:" "$TARGET" 2>/dev/null; then
    sops -e -i "$TARGET"
  fi

  sops "$TARGET"

  if command -v direnv >/dev/null 2>&1; then
    direnv reload >/dev/null 2>&1 || true
  fi

  GIT_EMAIL="$(git config --get user.email || true)"

  if [ -z "$GIT_EMAIL" ]; then
    echo "Няма конфигуриран Git имейл. Моля, задайте 'git config user.email'."
    exit 1
  fi

  echo "Настройване на правило за CODEOWNERS..."
  touch "$CODEOWNERS"

  ENTRY="/secrets/$U.json $GIT_EMAIL"

  grep -Fxq "$ENTRY" "$CODEOWNERS" || {
    grep -v "^/secrets/$U\.json " "$CODEOWNERS" > "$CODEOWNERS.tmp"
    printf "%s\n" "$ENTRY" >> "$CODEOWNERS.tmp"
    mv "$CODEOWNERS.tmp" "$CODEOWNERS"
  }

  echo "CODEOWNER беше настроен според имейла ви '$GIT_EMAIL'. Ако искате да използвате друг имейл или потребителско име, моля, актуализирайте файла CODEOWNERS сега!"

  echo "OK: $TARGET"
''
