#!/bin/bash
# Run all Automation workloads sequentially, forwarding any flags
set -e
here="$(dirname "$0")"
for d in file-enc media-conv log-analysis; do
  echo "[automation] running $d benchmark"
  ( cd "$here/$d" && ./run-faulty.sh "$@" )
done 