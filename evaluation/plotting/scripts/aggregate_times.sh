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

# Destination file labelled per site
DEST="$ROOT_DIR/../results/raw_times_site${SITE_NODES}.csv"
HEADER="benchmark,script,system,nodes,persistence_mode,time"

mkdir -p "$(dirname "$DEST")"
echo "$HEADER" > "$DEST"

insert_nodes() {
  awk -F',' -v n="$SITE_NODES" 'BEGIN{OFS=","} {print $1,$2,$3,n,$4,$5}'
}

# Collect per-suite CSVs (without nodes)
find "$ROOT_DIR/.." -maxdepth 3 -path '*/outputs/time.csv' | sort | while read -r csv; do
  tail -n +2 "$csv" | insert_nodes >> "$DEST"
done

echo "[aggregate_times] wrote $(( $(wc -l <"$DEST") - 1 )) rows to $DEST" 