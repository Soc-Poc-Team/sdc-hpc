#!/usr/bin/env bash

ISO="results/worker/iso/workernode.iso"
AUTH_FILE=".write_authorization"
USB_PATH="/dev/disk/by-id"

for dev in "$USB_PATH"/usb-*; do
  [ -e "$dev" ] || continue

  base="$(basename "$dev")"

  if grep -Fxq "$base" "$AUTH_FILE" 2>/dev/null; then
    echo "Authorized: $base -> starting write"

    (
      sudo dd if="$ISO" of="$dev" status=progress conv=fsync
      sync
    ) &
  fi
done

wait
