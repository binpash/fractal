#!/bin/bash

cd "$(realpath $(dirname "$0"))"
 # dict.txt should not be removed because it is used by the spell script
find ./inputs -mindepth 1 ! -name 'dict.txt' -exec rm -rf {} +
rm -rf ./outputs
# hdfs dfs -rm -r /classics
# hdfs dfs -rm -r /outputs/hadoop-streaming/classics
