#!/usr/bin/env bash
# Merge multiple site-specific raw_times_site*.csv into evaluation/results/raw_times.csv
# Usage: merge_sites.sh <out.csv> <site1.csv> <site2.csv> [...]
set -euo pipefail

# If first arg is --out <file> use it, else default to ../data/raw_times.csv
if [ "$1" == "--out" ]; then
  out="$2"; shift 2
else
  out="$(dirname "$0")/../data/intermediary/raw_times.csv"
fi

if [ $# -lt 2 ]; then
  echo "Usage: $0 [--out merged.csv] <site1.csv> <site2.csv> [...]" >&2; exit 1;
fi

site1="$1"
site2="$2"

temp_file1=$(mktemp)
temp_file2=$(mktemp)
temp_file_mb=$(mktemp)

# Note: microbenchmarks are only run on the 4-node cluster (site1)
wget "http://${site1}/raw_times_site4.csv" -O "$temp_file1"
wget "http://${site2}/raw_times_site30.csv" -O "$temp_file2"
wget "http://${site1}/raw_time_microbench.csv" -O "$temp_file_mb"

# ensure dir
mkdir -p "$(dirname "$out")"

header="benchmark,script,system,nodes,persistence_mode,time"

echo "$header" > "$out"

# Concatenate all, skip headers, deduplicate identical lines
awk -F',' 'NR==FNR {next} {if(!seen[$0]++){print}}' "$out" "$temp_file1" "$temp_file2" "$temp_file_mb" | grep -v "^$header" >> "$out"

echo "[merge_sites] wrote $(( $(wc -l <"$out") - 1 )) rows to $out" 

rm "$temp_file1" "$temp_file2" "$temp_file_mb"