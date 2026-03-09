#!/usr/bin/env bash
# TODO: move this to a nix package and expose via devshell
set -euo pipefail

clean=false
if [[ "${1:-}" == "--clean" ]]; then
  clean=true
fi

targets=(
  worker
  vm_workernode
  head
  vm_headnode
)

if $clean; then
  if pgrep -af qemu | grep -q "$(realpath results)" 2>/dev/null; then
    echo "Warning: qemu process using results directory detected. Maybe one of the VMs is still up?"
    pgrep -af qemu | grep "$(realpath results)" || true
    echo "Choose action:"
    echo "a) continue with cleanup"
    echo "b) kill process and continue"
    echo "c) abort"
    read -r -p "[a/b/c]: " choice

    case "$choice" in
      a) ;;
      b)
        pgrep -af qemu | grep "$(realpath results)" | awk '{print $1}' | xargs -r kill
        ;;
      c)
        echo "Aborting."
        exit 1
        ;;
      *)
        echo "Invalid option."
        exit 2
        ;;
    esac
  fi

  echo "Deleting the results directory..."
  rm -rf results
  echo "cleanup completed!"
  exit 0
fi

mkdir -p results

for target in "${targets[@]}"; do
  echo "Building ${target}"
  nix build ".#${target}" \
    --out-link "results/${target}" \
    --log-format bar-with-logs
done
