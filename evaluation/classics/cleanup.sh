#!/bin/bash

cd "$(realpath $(dirname "$0"))"
 # dict.txt should not be removed because it is used by the spell script

rm -rf ./outputs

PURGE=0
for arg in "$@"; do
  [[ "$arg" == "--purge" ]] && PURGE=1
done

if [[ $PURGE -eq 1 ]]; then
  rm -rf ./inputs
  hdfs dfs -rm -r /classics  2>/dev/null || true
  hdfs dfs -rm -r /outputs/hadoop-streaming/classics 2>/dev/null || true
fi

