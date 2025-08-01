#!/bin/bash
# tag: verse_2om_3om_2instances
# set -e
# verses with 2 or more, 3 or more, exactly 2 instances of light.

IN=${IN:-/nlp/pg/}
OUT=${1:-$PASH_TOP/evaluation/nlp/outputs/6_7/}
ENTRIES=${ENTRIES:-1000}
mkdir -p "$OUT"

for input in $(hdfs dfs -ls -C ${IN} | head -n ${ENTRIES} | xargs -I arg1 basename arg1)
do
    hdfs dfs -cat -ignoreCrc $IN/$input | grep -c 'light.\*light'                                 > ${OUT}/${input}.out0
    hdfs dfs -cat -ignoreCrc $IN/$input | grep -c 'light.\*light.\*light'                         > ${OUT}/${input}.out1
    hdfs dfs -cat -ignoreCrc $IN/$input | grep 'light.\*light' | grep -vc 'light.\*light.\*light' > ${OUT}/${input}.out2
done

echo 'done';
# rm -rf ${OUT}
