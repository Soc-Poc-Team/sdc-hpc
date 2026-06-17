#!/usr/bin/env bash

IMAGES_ROOT="${IMAGES_ROOT:-./.vml/images}"
PROFILES_ROOT="${PROFILES_ROOT:-./.vml/profiles}"
RUNTIME_ROOT="${RUNTIME_ROOT:-./.vml/runtime}"

mkdir -p "$RUNTIME_ROOT/instances" "$RUNTIME_ROOT/overlays" "$IMAGES_ROOT" "$PROFILES_ROOT"

cmd="$1"

if [[ $cmd == "list" ]]; then
  echo "ISOs:"
  find "$IMAGES_ROOT" -type f -name "*.iso" | sed "s|$IMAGES_ROOT/||"

  echo ""
  echo "Profiles:"
  find "$PROFILES_ROOT" -type f -name "*.conf" | sed "s|$PROFILES_ROOT/||"
  exit 0
fi

img="$1"
profile="$2"

if [[ -z $img || -z $profile ]]; then
  echo "usage:"
  echo "  $0 <iso> <profile>"
  echo "  $0 list"
  exit 1
fi

iso_path=$(find "$IMAGES_ROOT" -type f -iname "${img}.iso" | head -n 1)
profile_path="$PROFILES_ROOT/${profile}.conf"

if [[ ! -f $iso_path ]]; then
  echo "ISO not found: $img"
  exit 1
fi

if [[ ! -f $profile_path ]]; then
  echo "profile not found: $profile"
  exit 1
fi

declare -A cfg
while IFS='=' read -r k v; do
  [[ -z $k || $k =~ ^# ]] && continue
  cfg["$k"]="$v"
done <"$profile_path"

id=$(date +%s%N | tail -c 6)
name="${img}-${profile}-${id}"

disk="$RUNTIME_ROOT/overlays/${name}.qcow2"

qemu-img create -f qcow2 "$disk" "${cfg[DISK_SIZE]:-20G}" >/dev/null

mem="${cfg[MEMORY]:-2048}"
cores="${cfg[CORES]:-2}"
cpu="${cfg[CPU]:-host}"

port=$((2200 + (id % 5000)))
vnc=$((id % 99 + 1))

log="$RUNTIME_ROOT/instances/${name}.log"

nohup qemu-system-x86_64 \
  -name "$name" \
  -m "$mem" \
  -smp "$cores" \
  -cpu "$cpu" \
  -drive file="$disk",if=virtio,format=qcow2 \
  -cdrom "$iso_path" \
  -boot d \
  -netdev user,id=net0,hostfwd=tcp::${port}-:22 \
  -device virtio-net-pci,netdev=net0 \
  -vnc ":${vnc}" \
  "${cfg[EXTRA]}" \
  >"$log" 2>&1 &

echo "started: $name"
echo "iso: $iso_path"
echo "disk: $disk"
echo "ssh: localhost:$port"
echo "vnc: :$vnc"
