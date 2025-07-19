#!/usr/bin/env bash
# Merge multiple site-specific raw_times_site*.csv into evaluation/results/raw_times.csv
# Usage: merge_sites.sh <out.csv> <site1.csv> <site2.csv> [...]
set -euo pipefail

# If first arg is --out <file> use it, else default to ../results/raw_times.csv
if [ "$1" == "--out" ]; then
  out="$2"; shift 2
else
  out="$(dirname "$0")/../results/raw_times.csv"
fi

if [ $# -lt 2 ]; then
  echo "Usage: $0 [--out merged.csv] <site1.csv> <site2.csv> [...]" >&2; exit 1;
fi

header="benchmark,script,system,nodes,persistence_mode,time"

echo "$header" > "$out"

# Concatenate all, skip headers, deduplicate identical lines
awk -F',' 'NR==FNR {next} {if(!seen[$0]++){print}}' "$out" "$@" | grep -v "^$header" >> "$out"

echo "[merge_sites] wrote $(( $(wc -l <"$out") - 1 )) rows to $out" 