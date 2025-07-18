#!/bin/bash
# Verify outputs for Automation workloads
set -e
here="$(dirname "$0")"
for d in file-enc media-conv log-analysis; do
  echo "[automation] verifying $d"
  ( cd "$here/$d" && ./verify.sh "$@" )
done 