#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
GITHOOKS_DIR="$REPO_ROOT/.githooks"
TARGET_DIR="$REPO_ROOT/.git/hooks"

if [[ ! -d $TARGET_DIR ]]; then
  echo "Error: .git/hooks directory not found."
  exit 1
fi

echo "Installing hooks from $GITHOOKS_DIR to $TARGET_DIR"
echo

for hook in "$GITHOOKS_DIR"/*; do
  [[ -f $hook ]] || continue

  filename="$(basename "$hook")"

  if [[ $filename == *.* ]]; then
    continue
  fi

  target="$TARGET_DIR/$filename"

  if [[ -e $target || -L $target ]]; then
    echo "Hook '$filename' already exists in .git/hooks"

    read -r -p "Overwrite it? [y/N]: " answer
    case "$answer" in
    [yY])
      rm -rf "$target"
      ;;
    *)
      echo "Skipping $filename"
      continue
      ;;
    esac
  fi

  ln -s "$hook" "$target"
  echo "Installed $filename"
done
echo
