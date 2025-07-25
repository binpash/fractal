#!/bin/bash
# Execute both analytics workloads sequentially, forwarding any flags
set -e
base_dir="$(dirname "$0")"
for d in covid-mts max-temp; do
  echo "[analytics] running $d benchmark"
  (cd "$base_dir/$d" && ./run-faulty.sh "$@")
done