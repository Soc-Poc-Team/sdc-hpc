#!/usr/bin/env bash
# LICENSE
# This job checks if the date of the LICENSE file matches the current year and if authors are listed in alphabetical order
# Exit codes: 1 = general fail, 2 = fail because of year, 3 = author sorting fail
set -euo pipefail

license_file="LICENSE"
current_year="$(date +%Y)"
copyright_line="$(grep -m1 '^Copyright (c)' "$license_file")"

year="$(sed -E 's/^Copyright \(c\) ([0-9]{4}).*/\1/' <<<"$copyright_line")"
authors="$(sed -E 's/^Copyright \(c\) [0-9]{4} //' <<<"$copyright_line")"
sorted_authors="$(tr ',' '\n' <<<"$authors" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | LC_ALL=C sort | paste -sd ', ' -)"

[[ $year == "$current_year" ]] || {
  echo "LICENSE year is $year; expected $current_year."
  exit 2
}

[[ $authors == "$sorted_authors" ]] || {
  echo "LICENSE authors are not alphabetically ordered."
  echo "Expected: $sorted_authors"
  exit 3
}

echo "LICENSE validation passed."
