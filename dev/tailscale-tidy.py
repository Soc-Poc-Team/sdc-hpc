#!/usr/bin/env python3

import requests
import sys
import os

API_KEY = os.getenv("TAILSCALE_APIKEY")
TAILNET = os.getenv("TAILSCALE_DOMAIN")

if not API_KEY or not TAILNET:
    print("Задайте TAILSCALE_APIKEY и TAILSCALE_DOMAIN. Може би опитайте `direnv allow`?")
    sys.exit(1)

BASE_URL = f"https://api.tailscale.com/api/v2/tailnet/{TAILNET}"

def api_get(path):
    return requests.get(
        f"{BASE_URL}{path}",
        auth=(API_KEY, "")
    )

def api_delete(url):
    return requests.delete(
        url,
        auth=(API_KEY, "")
    )

def get_devices():
    r = api_get("/devices")
    r.raise_for_status()
    return r.json()["devices"]

def list_devices():
    devices = sorted(get_devices(), key=lambda d: d["hostname"].lower())
    for d in devices:
        print(f"{d['hostname']:<30} {d['id']}")

def delete_by_hostname(hostname):
    matches = [
        d for d in get_devices()
        if d["hostname"] == hostname
    ]

    if not matches:
        print(f"Не е открито устройство: {hostname}")
        sys.exit(1)

    if len(matches) > 1:
        print("Открити са множество съвпадения:")
        for d in matches:
            print(f"{d['hostname']}  {d['id']}")
        sys.exit(1)

    device = matches[0]
    url = f"https://api.tailscale.com/api/v2/device/{device['id']}"

    r = api_delete(url)

    if r.status_code == 200:
        print(f"Изтрихме {hostname}")
    else:
        print(f"Неуспех: {r.status_code} {r.text}")

def usage():
    print(f"""
Употреба:
  {sys.argv[0]} list
  {sys.argv[0]} delete <hostname>
""".strip())

if __name__ == "__main__":
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)

    cmd = sys.argv[1]

    if cmd == "list":
        list_devices()

    elif cmd == "delete" and len(sys.argv) == 3:
        delete_by_hostname(sys.argv[2])

    else:
        usage()
        sys.exit(1)
