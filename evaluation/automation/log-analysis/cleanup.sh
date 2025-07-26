#!/bin/bash

cd "$(realpath $(dirname "$0"))"

PURGE=0
for arg in "$@"; do
  [[ "$arg" == "--purge" ]] && PURGE=1
done

rm -rf ./outputs
# hdfs dfs -rm -r /log-analysis

if [[ $PURGE -eq 1 ]]; then
  rm -rf ./inputs
  hdfs dfs -rm -r /log-analysis 2>/dev/null || true
fi

