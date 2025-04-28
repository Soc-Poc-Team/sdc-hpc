#!/bin/bash

# Check if enough arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: bash create.sh <VM_NAME> <VMID> <ISO_PATH>"
  exit 1
fi

# Assign the command line arguments to variables
VM_NAME=$1      # VM Name
VMID=$2         # VMID
ISO_PATH=$3     # Path to the uploaded ISO

# Authentication and getting the ticket and CSRF token
response=$(curl -s -k -X POST "$PROXMOX_HOST/api2/json/access/ticket" \
  -d "username=$PROXMOX_USER&password=$PROXMOX_PASSWORD")

# Extract the ticket and CSRFPreventionToken using jq
ticket=$(echo "$response" | jq -r '.data.ticket')
csrf_token=$(echo "$response" | jq -r '.data.CSRFPreventionToken')

MEMORY="2048"      # Memory size in MB
CORES="1"          # Number of CPU cores
DISK_SIZE="32G"    # Disk size (adjust as needed)
STORAGE="local-lvm"    # Storage where the disk will be created (e.g., 'local')

# Create the internal networking bridge
echo "Creating vmbr1 for internal networking."
curl -k -X POST "$PROXMOX_HOST/api2/extjs/nodes/pve/network" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token" \
  --data-raw 'type=bridge&iface=vmbr3&autostart=1&bridge_ports=&comments='

# Create the VM
echo "Creating VM $VMID with $MEMORY MB memory, $CORES CPU cores, and $DISK_SIZE disk..."
curl -k -X POST "$PROXMOX_HOST/api2/extjs/nodes/pve/qemu" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token" \
  -d "vmid=$VMID" \
  -d "name=$VM_NAME" \
  -d "ide2=$ISO_PATH,media%3Dcdrom" \
  -d "ostype=l26" \
  -d "scsihw=virtio-scsi-single" \
  -d "scsi0=local-lvm:32,iothread%3Don" \
  -d "sockets=1" \
  -d "cores=$CORES" \
  -d "numa=0" \
  -d "cpu=x86-64-v2-AES" \
  -d "memory=$MEMORY" \
  -d "net0=virtio,bridge%3Dvmbr0,firewall%3D1" \
  -d "net1=virtio,bridge%3Dvmbr3,firewall%3D1"

# Start the VM
echo -e "\nStarting the VM $VMID..."
curl -k -X POST "$PROXMOX_HOST/api2/json/nodes/pve/qemu/$VMID/status/start" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token"

echo -e "\nVM $VMID ($VM_NAME) has been created and started successfully."

