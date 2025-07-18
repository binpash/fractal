#!/bin/bash
# Fetch inputs for both analytics workloads
set -e
base_dir="$(dirname "$0")"
for d in covid-mts max-temp; do
  echo "[analytics] fetching inputs for $d"
  (cd "$base_dir/$d" && ./inputs.sh "$@")
done 