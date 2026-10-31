#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
GITHOOKS_DIR="$REPO_ROOT/.githooks"
TARGET_DIR="$REPO_ROOT/.git/hooks"

if [[ ! -d $TARGET_DIR ]]; then
  echo "Грешка: директорията .git/hooks не беше намерена."
  exit 1
fi

echo "Инсталиране на hook-ове от $GITHOOKS_DIR към $TARGET_DIR"
echo

for hook in "$GITHOOKS_DIR"/*; do
  [[ -f $hook ]] || continue

  filename="$(basename "$hook")"

  if [[ $filename == *.* ]]; then
    continue
  fi

  target="$TARGET_DIR/$filename"

  if [[ -e $target || -L $target ]]; then
    echo "Hook-ът '$filename' вече съществува в .git/hooks"

    read -r -p "Да го презапиша? [д/Н]: " answer
    case "$answer" in
    [yY])
      rm -rf "$target"
      ;;
    *)
      echo "Пропускане на $filename"
      continue
      ;;
    esac
  fi

  ln -s "$hook" "$target"
  echo "Инсталиран $filename"
done
echo
