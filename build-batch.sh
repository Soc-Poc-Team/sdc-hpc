#!/usr/bin/env bash
set -euo pipefail

clean=false
impure=false
pre_opts=()
nix_opts=()

allowed_opts=(
  --rebuild
  --rebuild-check
  --repair
)

for arg in "$@"; do
  case "$arg" in
  --clean)
    clean=true
    ;;
  --verbose)
    set -o xtrace
    ;;
  --impure)
    pre_opts+=("--impure")
    impure=true # mark dev builds
    ;;
  --*)
    for opt in "${allowed_opts[@]}"; do
      if [[ $arg == "$opt" ]]; then
        nix_opts+=("$arg")
      fi
    done
    ;;
  esac
done

targets=(
  worker
  vm_workernode
  head
  vm_headnode
)

if $impure; then
  echo "Изграждаме резултати в impure режим!"
fi

if $clean; then
  if pgrep -af qemu | grep -q "$(realpath results)" 2>/dev/null; then
    echo "Внимание: открит е qemu процес, който използва директорията с резултати. Може би един от VM-овете все още е стартиран?"
    pgrep -af qemu | grep "$(realpath results)" || true
    echo "Изберете действие:"
    echo "a) продължи с почистването"
    echo "b) спри процеса и продължи"
    echo "c) прекъсни"
    read -r -p "[a/b/c]: " choice

    case "$choice" in
    a) ;;
    b)
      pgrep -af qemu | grep "$(realpath results)" | awk '{print $1}' | xargs -r kill
      ;;
    c)
      echo "Прекъсване."
      exit 1
      ;;
    *)
      echo "Невалидна опция."
      exit 2
      ;;
    esac
  fi

  echo "Изтриване на директорията с резултати..."
  rm -rf results
  echo "Почистването завърши!"
  exit 0
fi

mkdir -p results

for target in "${targets[@]}"; do
  echo "Изграждане на ${target}"
  nix build "${pre_opts[@]}" ".#${target}" \
    --out-link "results/${target}" \
    --log-format bar-with-logs \
    "${nix_opts[@]}"
done
