#!/usr/bin/env bash

ISO="results/worker/iso/workernode.iso"
AUTH_FILE=".write_authorization"
USB_PATH="/dev/disk/by-id"

DRY=0

if [[ $1 == "--dry" ]]; then
  DRY=1
  echo "DRY RUN..."
  sleep 0.5
fi

for dev in "$USB_PATH"/usb-*; do
  [ -e "$dev" ] || continue

  base="$(basename "$dev")"

  if grep -Fxq "$base" "$AUTH_FILE" 2>/dev/null; then
    echo "Оторизирано: $base -> започва запис"
    if [[ $DRY -eq 1 ]]; then
      echo "DRY RUN: sudo dd if=\"$ISO\" of=\"$dev\" status=progress conv=fsync && sync"
    else

      (
        sudo dd if="$ISO" of="$dev" status=progress conv=fsync
        sync
      ) &
    fi
  fi
done

wait
