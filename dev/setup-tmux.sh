#!/usr/bin/env bash

SESSION="small-data-cluster"

FORCE_Y=0
FORCE_N=0

while getopts "yn" opt; do
  case "$opt" in
  y) FORCE_Y=1 ;;
  n) FORCE_N=1 ;;
  *) ;;
  esac
done

if tmux has-session -t "$SESSION" 2>/dev/null; then

  if [[ $FORCE_Y -eq 1 ]]; then
    tmux kill-session -t "$SESSION"

  elif [[ $FORCE_N -eq 1 ]]; then
    exit 0

  else
    read -rp "Session '$SESSION' exists. Recreate? (y/N): " answer

    if [[ $answer =~ ^[Yy]$ ]]; then
      tmux kill-session -t "$SESSION"
    else
      exit 0
    fi
  fi
fi

tmux new-session -d -s "$SESSION" -n "vms"

tmux select-window -t "$SESSION:vms"
tmux split-window -v
tmux send-keys -t "$SESSION:vms.0" "./results/vm_workernode/bin/run-unnamed-vm"
tmux send-keys -t "$SESSION:vms.1" "./results/vm_headnode/bin/run-headnode-vm"
tmux select-layout -t "$SESSION:vms" even-horizontal

tmux new-window -t "$SESSION" -n "flash"
tmux send-keys -t "$SESSION:flash" "cd dev" C-m
tmux send-keys -t "$SESSION:flash" "./flash.sh"

tmux new-window -t "$SESSION" -n "batch-build"
tmux send-keys -t "$SESSION:batch-build" "./build-batch.sh --impure"

echo "tmux session $SESSION was setup"
