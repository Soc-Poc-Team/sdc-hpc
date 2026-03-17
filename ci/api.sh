#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: bash api.sh <iso-path>"
  exit 1
fi

ISO_PATH="$1"
NODE=deimos

# Authenticate and get the ticket and CSRF token
response=$(curl -s -k -X POST "$PROXMOX_HOST/api2/json/access/ticket" \
  -d "username=$PROXMOX_USER&password=$PROXMOX_PASSWORD")

# Extract the ticket and CSRFPreventionToken using jq
ticket=$(echo "$response" | jq -r '.data.ticket')
csrf_token=$(echo "$response" | jq -r '.data.CSRFPreventionToken')

echo "listing nodes"
# Get the list of nodes using the ticket and CSRF token
curl -k -X GET "$PROXMOX_HOST/api2/json/nodes" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token"

echo "listing storages"
curl -k -X GET "$PROXMOX_HOST/api2/json/nodes/$NODE/storage" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token"

echo "storage status"

curl -k -X GET "$PROXMOX_HOST/api2/json/nodes/$NODE/storage/status" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token"

echo "uploading iso"

curl -k -X POST "$PROXMOX_HOST/api2/json/nodes/$NODE/storage/local/upload" \
  -H "Authorization: PVEAuthCookie=$ticket" \
  -H "CSRFPreventionToken: $csrf_token" \
  -H "Content-Type: multipart/form-data" \
  -F "content=iso" \
  -F "filename=@$ISO_PATH"
