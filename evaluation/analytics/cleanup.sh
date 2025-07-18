#!/bin/bash
# Cleanup temporary data for analytics workloads
set -e
base_dir="$(dirname "$0")"
for d in covid-mts max-temp; do
  echo "[analytics] cleaning $d"
  (cd "$base_dir/$d" && ./cleanup.sh "$@")
done 