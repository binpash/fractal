#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

PURGE=0
for arg in "$@"; do [[ "$arg" == "--purge" ]] && PURGE=1; done

rm -rf ./outputs

if [[ $PURGE -eq 1 ]]; then
  rm -rf ./inputs
  hdfs dfs -rm -r -f /file-enc 2>/dev/null || true
fi

echo "[cleanup] file-enc done (purge=$PURGE)"