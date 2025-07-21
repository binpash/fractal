#!/bin/bash
# Verify outputs for both analytics workloads
set -e
base_dir="$(dirname "$0")"
for d in covid-mts max-temp; do
  # echo "[analytics] verifying $d"
  (cd "$base_dir/$d" && ./verify.sh "$@")
done 