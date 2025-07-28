#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

# Detect flags
SIZE_FLAG="--full"; PURGE_FLAG=""
for arg in "$@"; do
  case "$arg" in
    --small|--full) SIZE_FLAG="$arg";;
    --purge) PURGE_FLAG="--purge";;
  esac
done

echo "[cleanup_all] size=$SIZE_FLAG purge=${PURGE_FLAG:-no}"

# Suites to clean
suites=(analytics automation classics unix50 nlp)

for s in "${suites[@]}"; do
  echo "[cleanup_all] cleaning $s"
  ( cd "$s" && ./cleanup.sh $SIZE_FLAG $PURGE_FLAG )
  echo "[cleanup_all] $s done"
done

rm -rf outputs 2>/dev/null || true
rm -rf outputs_microbench 2>/dev/null || true
rm -rf results 2>/dev/null || true

rm classics/scripts/hadoop-streaming/*out.txt 2>/dev/null || true
rm unix50/scripts/hadoop-streaming/*out.txt 2>/dev/null || true

# Remove plotting artefacts
rm -rf plotting/data plotting/figures 2>/dev/null || true
rm -f /var/www/html/*.pdf /var/www/html/*.csv 2>/dev/null || true

