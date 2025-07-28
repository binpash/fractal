#!/usr/bin/env bash
# Merge all per-suite outputs/time.csv into evaluation/plotting/results/all_times.csv
set -euo pipefail

ROOT_DIR="$(dirname "$0")/.."            # evaluation/plotting

usage() {
  echo "Usage: $0 --site <nodes>" >&2; exit 1;
}

if [ "$#" -ne 2 ] || [ "$1" != "--site" ]; then usage; fi
SITE_NODES="$2"
shift 2

python3 $ROOT_DIR/scripts/aggregate_times.py "$SITE_NODES"

# Append micro-bench timings (only exist for the 4-node site)
if [[ "$SITE_NODES" == "4" ]]; then
  mb="$ROOT_DIR/data/intermediary/time_microbench.csv"
  if [[ -f "$mb" ]]; then
    # skip header, enforce nodes=4, and append
    tail -n +2 "$mb" | awk -F',' 'BEGIN{OFS=","}{print $1,$2,$3,4,$4,$5}' >> \
        "$ROOT_DIR/data/intermediary/raw_times_site4.csv"
    echo "[parse] merged microbench rows into raw_times_site4.csv"
  fi
fi

cp "$ROOT_DIR/data/intermediary/raw_times_site${SITE_NODES}.csv" "/var/www/html/raw_times_site${SITE_NODES}.csv"

# # Destination file labelled per site under data/intermediary/
# DEST="$ROOT_DIR/data/intermediary/raw_times_site${SITE_NODES}.csv"
# HEADER="benchmark,script,system,nodes,persistence_mode,time"

# mkdir -p "$(dirname "$DEST")"
# echo "$HEADER" > "$DEST"

# insert_nodes() {
#   awk -F',' -v n="$SITE_NODES" 'BEGIN{OFS=","} {print $1,$2,$3,n,$4,$5}'
# }

# # process each CSV; override nodes=4 for microbench timing
# find "$ROOT_DIR/.." -maxdepth 3 -path '*/outputs/time.csv' | sort | while read -r csv; do
#   if [[ "$csv" == *"microbench/outputs/time.csv" ]]; then
#       tail -n +2 "$csv" | awk -F',' 'BEGIN{OFS=","} {print $1,$2,$3,4,$4,$5}' >> "$DEST"
#   else
#       tail -n +2 "$csv" | insert_nodes >> "$DEST"
#   fi
# done

# echo "[aggregate_times] wrote $(( $(wc -l <"$DEST") - 1 )) rows to $DEST" 