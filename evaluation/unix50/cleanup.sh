#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

PURGE=0
for arg in "$@"; do [[ "$arg" == "--purge" ]] && PURGE=1; done

# always clear outputs
rm -rf ./outputs

if [[ $PURGE -eq 1 ]]; then
  rm -rf ./inputs
  hdfs dfs -rm -r -f /unix50 2>/dev/null || true
  hdfs dfs -rm -r -f /outputs/hadoop-streaming/unix50 2>/dev/null || true
fi

echo "[cleanup] unix50 done (purge=$PURGE)"
