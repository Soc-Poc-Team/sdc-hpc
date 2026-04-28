#!/usr/bin/env python3

import requests
import sys
import os

API_KEY = os.getenv("TAILSCALE_APIKEY")
TAILNET = os.getenv("TAILSCALE_DOMAIN")

def delete_machine(machine_id):
    url = f"https://api.tailscale.com/api/v2/device/{machine_id}"

    response = requests.delete(
        url,
        auth=(API_KEY, "")
    )

    if response.status_code == 200:
        print("Machine deleted successfully.")
    else:
        print(f"Failed: {response.status_code} - {response.text}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: python {sys.argv[0]} <machine_id>")
        sys.exit(1)

    delete_machine(sys.argv[1])
