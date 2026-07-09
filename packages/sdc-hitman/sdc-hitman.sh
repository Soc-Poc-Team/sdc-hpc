#!/usr/bin/env bash
# The Shebang will be ignored by the final nix generated script file. Nix will use an absolute path instead

set -e

NOW=0
DIRTY=0
NODES=()

usage() {
  echo "Usage: $0 [--now] [--dirty] <node names|ALL>"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --now)
    NOW=1
    ;;
  --dirty)
    DIRTY=1
    ;;
  ALL)
    NODES=("ALL")
    ;;
  *)
    NODES+=("$1")
    ;;
  esac
  shift
done

[[ ${#NODES[@]} -eq 0 ]] && usage

# Resolve nodes
if [[ ${NODES[0]} == "ALL" ]]; then
  TARGETS=$(scontrol show nodes | awk '/NodeName=/ {print $1}' | cut -d= -f2)
else
  TARGETS=""
  ALL_NODES=$(scontrol show nodes | awk '/NodeName=/ {print $1}' | cut -d= -f2)

  for pattern in "${NODES[@]}"; do
    MATCH=$(echo "$ALL_NODES" | grep -E "^${pattern//\*/.*}$" || true)
    TARGETS+=" $MATCH"
  done
fi

TARGETS=$(echo "$TARGETS" | xargs)

if [[ -z $TARGETS ]]; then
  echo "No nodes matched."
  exit 1
fi

echo "The following nodes will be shut down:"
echo "$TARGETS"
echo

read -rp "Continue? (y/n): " ANSWER

if [[ ! $ANSWER =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

echo "Draining nodes..."
for node in $TARGETS; do
  scontrol update NodeName="$node" State=DRAIN Reason="sdc-hitman shutdown"
done

if [[ $NOW -eq 0 ]]; then
  echo "Waiting for nodes to drain..."

  while true; do
    BUSY=0

    for node in $TARGETS; do
      STATE=$(scontrol show node "$node" | awk -F= '/State=/ {print $2}' | awk '{print $1}')

      if [[ $STATE != "IDLE" && $STATE != "DOWN" ]]; then
        BUSY=1
        break
      fi
    done

    [[ $BUSY -eq 0 ]] && break

    sleep 10
  done
fi

if [[ $DIRTY -eq 0 ]]; then
  echo "Removing nodes from Slurm..."

  for node in $TARGETS; do
    scontrol delete NodeName="$node"
  done
fi

echo "Shutting down nodes..."

for node in $TARGETS; do
  echo "Stopping $node..."

  if [[ $node == "headnode" ]]; then
    ssh "$node" halt
  else
    ssh "$node" halt -f
  fi
done

echo "Shutdown complete."
