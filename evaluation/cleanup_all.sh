#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

output_dir="$(pwd)/outputs_cleanup_all"
rm -rf "$output_dir" && mkdir -p "$output_dir"

exec > >(tee -a "$output_dir/cleanup_all.all" "$output_dir/cleanup_all.out")
exec 2> >(tee -a "$output_dir/cleanup_all.all" "$output_dir/cleanup_all.err" >&2)

start=$(date +%s)

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

# Remove plotting artefacts
rm -rf plotting/data plotting/figures 2>/dev/null || true
rm -f /var/www/html/*.pdf /var/www/html/*.csv 2>/dev/null || true

end=$(date +%s)

echo "Total cleanup_all time: $((end-start)) seconds" | tee -a "$output_dir/cleanup_all.time"
