#!/usr/bin/env nix
#! nix --accept-flake-config --extra-experimental-features ``nix-command flakes`` develop .#ci-basic --command bash
# VERSION
# shellcheck shell=bash
# This job checks whether the VERSION file contains at least one non-comment line - means: a primary version is defined
# Exit codes: 1 = general fail, 3 = no non-comment line, (no allowed failures = 2)
set -euo pipefail

version_file="VERSION"

[[ -f $version_file ]] || {
  echo "$version_file does not exist."
  exit 1
}

grep -Eq '^[[:space:]]*[^#[:space:]]' "$version_file" || {
  echo "$version_file does not contain a version."
  exit 3
}

echo "VERSION check passed."
