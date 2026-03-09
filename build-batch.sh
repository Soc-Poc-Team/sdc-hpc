#!/usr/bin/env bash
set -euo pipefail

targets=(
  worker
  vm_workernode
  head
  vm_headnode
)

mkdir -p results

for target in "${targets[@]}"; do
  echo "Building ${target}"
  nix build ".#${target}" \
    --out-link "results/${target}" \
    --log-format bar-with-logs
done
