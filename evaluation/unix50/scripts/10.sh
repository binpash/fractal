#!/bin/bash

# 4.4: histogram of Belle's captures (-pawns) by each type of piece
hdfs dfs -cat -ignoreCrc $1 | tr ' ' '\n' | grep 'x' | grep '\.' | cut -d '.' -f 2 | grep '[KQRBN]' | cut -c 1-1 | sort | uniq -c | sort -nr
