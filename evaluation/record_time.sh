#!/usr/bin/env bash
# Append one line to evaluation/results/raw_times.csv
# Usage:
#   record_time <benchmark> <script> <system> <nodes> <fault_mode> <fault_pct> <size> <time_sec> [<persistence_mode>]
set -e
dir="$(dirname "$0")/results"
mkdir -p "$dir"
csv="$dir/raw_times.csv"
if [ ! -f "$csv" ]; then
  echo "benchmark,script,system,nodes,fault_mode,fault_pct,size,time,persistence_mode" > "$csv"
fi
printf "%s\n" "$*" >> "$csv" 