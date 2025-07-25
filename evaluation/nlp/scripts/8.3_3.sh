#!/bin/bash
# tag: compare_exodus_genesis.sh
# set -e

IN=${IN:-/nlp/pg}
INPUT2=${INPUT2:-/nlp/exodus}
OUT=${1:-$PASH_TOP/evaluation/nlp/outputs/8.3_3/}
ENTRIES=${ENTRIES:-1000}
mkdir -p $OUT

pure_func() {
    input=$1
    input2=$2
    TEMPDIR=$(mktemp -d)
    cat > ${TEMPDIR}/${input}1.types
    hdfs dfs -cat -ignoreCrc  ${input2} | tr -sc '[A-Z][a-z]' '[\012*]' | sort -u > ${TEMPDIR}/${input}2.types
    sort ${TEMPDIR}/${input}1.types ${TEMPDIR}/${input}2.types ${TEMPDIR}/${input}2.types | uniq -c | head 
    rm -rf ${TEMPDIR}
}
export -f pure_func

for input in $(hdfs dfs -ls -C ${IN} | head -n ${ENTRIES} | xargs -I arg1 basename arg1)
do
    hdfs dfs -cat -ignoreCrc $IN/$input | tr -c 'A-Za-z' '[\n*]' | grep -v "^\s*$" | sort -u | pure_func $input $INPUT2 > ${OUT}/${input}.out
done

echo 'done';
# rm -rf "$OUT"
