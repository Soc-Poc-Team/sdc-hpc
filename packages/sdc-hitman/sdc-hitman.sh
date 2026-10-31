#!/usr/bin/env bash
# The Shebang will be ignored by the final nix generated script file. Nix will use an absolute path instead

set -e

NOW=0
DIRTY=0
NODES=()

usage() {
  echo "Употреба: $0 [--now] [--dirty] <node names|ALL>"
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

echo "Следните възли ще бъдат изключени:"
echo "$TARGETS"
echo

read -rp "Продължаване? (д/н): " ANSWER

if [[ ! $ANSWER =~ ^[Yy]$ ]]; then
  echo "Прекъснато."
  exit 0
fi

echo "Изваждане на възлите от обслужване..."
for node in $TARGETS; do
  scontrol update NodeName="$node" State=DRAIN Reason="sdc-hitman shutdown"
done

if [[ $NOW -eq 0 ]]; then
  echo "Изчакване на заданията да завършат..."

  while true; do
    BUSY=0

    for node in $TARGETS; do
      CPUALLOC=$(scontrol show node "$node" | awk -F= '/CPUAlloc=/ {print $2}' | awk '{print $1}')
      if [[ ${CPUALLOC:-0} -gt 0 ]]; then
        BUSY=1
        break
      fi
    done

    [[ $BUSY -eq 0 ]] && break

    sleep 1
  done
fi

echo "Маркиране на възлите като DOWN..."

for node in $TARGETS; do
  scontrol update NodeName="$node" State=DOWN Reason="sdc-hitman shutdown"
done

if [[ $DIRTY -eq 0 ]]; then
  echo "Премахване на възлите от Slurm..."

  for node in $TARGETS; do
    scontrol delete NodeName="$node"
  done
fi

echo "Изключване на възлите..."

for node in $TARGETS; do
  echo "Спиране на $node..."

  if [[ $node == "headnode" ]]; then
    ssh "$node" halt
  else
    ssh "$node" halt -f
  fi
done

echo "Изключването завърши."
