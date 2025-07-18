#!/bin/bash
# Fetch inputs for all Automation workloads
set -e
here="$(dirname "$0")"
for d in file-enc media-conv log-analysis; do
  echo "[automation] fetching inputs for $d"
  ( cd "$here/$d" && ./inputs.sh "$@" )
done 