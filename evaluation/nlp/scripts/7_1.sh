#!/bin/bash
# tag: count_morphs
# set -e

IN=${IN:-/nlp/pg/}
OUT=${1:-$PASH_TOP/evaluation/nlp/outputs/7_1/}
ENTRIES=${ENTRIES:-1000}
mkdir -p "$OUT"

for input in $(hdfs dfs -ls -C ${IN} | head -n ${ENTRIES} | xargs -I arg1 basename arg1)
do
    hdfs dfs -cat -ignoreCrc $IN/$input | sed 's/ly$/-ly/g' | sed 's/ .*//g' | sort | uniq -c > ${OUT}/${input}.out
done

echo 'done';
# rm -rf ${OUT}
