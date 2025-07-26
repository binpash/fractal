#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

PURGE=0
for arg in "$@"; do
  [[ "$arg" == "--purge" ]] && PURGE=1
done

# Always clear outputs
rm -rf ./outputs

# Remove inputs and HDFS data only if --purge specified
if [[ $PURGE -eq 1 ]]; then
  rm -rf ./inputs
  hdfs dfs -rm -r -f /nlp 2>/dev/null || true
fi

echo "[cleanup] nlp done (purge=$PURGE)"
