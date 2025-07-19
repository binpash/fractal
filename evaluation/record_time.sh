#!/usr/bin/env bash
# record_time <benchmark> <script> <system> <nodes> <persistence_mode> <time>
#
# Appends one timing record as CSV. If SUITE_CSV_PATH is set, we write there;
# otherwise we fall back to evaluation/results/all_times.csv (legacy global).
set -e

header="benchmark,script,system,persistence_mode,time"

# Determine target CSV – honour per-suite override.
csv="${SUITE_CSV_PATH:-$(dirname "$0")/results/raw_times.csv}"

# Ensure directory exists
mkdir -p "$(dirname "$csv")"

# Write header if file is new or empty
if [ ! -s "$csv" ]; then
  echo "$header" > "$csv"
fi

# $1 benchmark  $2 script  $3 system  $4 persistence  $5 time
sys="$3"
case "$sys" in
  dynamic)    sys="fractal" ;;
  dynamic-m)  sys="fractal-m" ;;
  dynamic-r)  sys="fractal-r" ;;
esac

printf "%s,%s,%s,%s,%s\n" "$1" "$2" "$sys" "$4" "$5" >> "$csv" 