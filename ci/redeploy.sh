#!/bin/bash

# Ensure the required parameters are passed (VMID and ISO_PATH)
if [[ -z "$1" || -z "$2" ]]; then
  echo "Missing required parameters. Exiting."
  echo "Usage: $0 <VMID> <ISO_PATH>"
  exit 1
fi

VMID=$1
ISO_PATH=$2
NODE=deimos

# Authenticate and get the ticket and CSRF token
response=$(curl -s -k -X POST "$PROXMOX_HOST/api2/json/access/ticket" \
  -d "username=$PROXMOX_USER&password=$PROXMOX_PASSWORD")

# Extract the ticket and CSRFPreventionToken using jq
ticket=$(echo "$response" | jq -r '.data.ticket')
csrf_token=$(echo "$response" | jq -r '.data.CSRFPreventionToken')

echo -e "\nVM $VMID changing boot iso to $ISO_PATH"
curl -k -X POST "$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$VMID/config" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token" \
  -d "ide2=$ISO_PATH,media%3Dcdrom"

sleep 2

echo -e "\nRebooting VM $VMID"
curl -k -X POST "$PROXMOX_HOST/api2/json/nodes/$NODE/qemu/$VMID/status/reboot" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token"

