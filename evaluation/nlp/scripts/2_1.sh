#!/bin/bash
# tag: merge_upper
# set -e

# Merge upper and lower counts
IN=${IN:-/nlp/pg/}
OUT=${1:-$PASH_TOP/evaluation/nlp/outputs/2_1/}
ENTRIES=${ENTRIES:-1000}
mkdir -p "$OUT"

for input in $(hdfs dfs -ls -C ${IN} | head -n ${ENTRIES} | xargs -I arg1 basename arg1)
do
    hdfs dfs -cat -ignoreCrc $IN/$input | tr '[a-z]' '[A-Z]' |  tr -c 'A-Za-z' '[\n*]' | grep -v "^\s*$" | sort | uniq -c > ${OUT}/${input}.out
done

echo 'done';
# rm -rf "$OUT"
