#!/bin/bash
# Cleanup temporary data for Automation workloads
set -e
here="$(dirname "$0")"
for d in file-enc media-conv log-analysis; do
  echo "[automation] cleaning $d"
  ( cd "$here/$d" && ./cleanup.sh "$@" )
done 