#!/usr/bin/env nix
#! nix --accept-flake-config --extra-experimental-features ``nix-command flakes`` develop .#ci-basic --command bash
# shellcheck shell=bash
set -euo pipefail
shopt -s nullglob

checks=(ci/checks/*.check.sh)

if ((${#checks[@]} == 0)); then
  echo "No check scripts found." >&2
  exit 1
fi

yaml_quote() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

declare -A used_names

cat <<'YAML'
default:
  image: nixos/nix
  tags:
    - bigdatalab-sdc
  timeout: 10m

stages:
  - check

YAML

for check in "${checks[@]}"; do
  job_name="$(sed -n '2{/^[[:space:]]*#/ { s/^[[:space:]]*#[[:space:]]*//; p; }}' "$check")"

  if [[ -z $job_name ]]; then
    job_name="${check##*/}"
    job_name="${job_name%.check.sh}"
  fi

  if [[ -n ${used_names[$job_name]+x} ]]; then
    echo "Duplicate check job name: $job_name" >&2
    exit 1
  fi

  used_names["$job_name"]=1

  check_command="./$check || { status=\$?; exit \"\$status\"; }"

  printf '%s:\n' "$(yaml_quote "$job_name")"
  printf '  stage: check\n'
  printf '  script:\n'
  printf '    - %s\n' "$(yaml_quote "$check_command")"
  printf '  allow_failure:\n'
  printf '    exit_codes:\n'
  printf '      - 2\n\n'
done
