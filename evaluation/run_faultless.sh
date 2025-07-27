#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

# Absolute path to the outputs directory
output_dir="$(pwd)/outputs"

# Remove and recreate the outputs directory
if [ -d "$output_dir" ]; then
    rm -rf "$output_dir"
fi
mkdir -p "$output_dir"

# List of suites to process
suites=(classics unix50 analytics nlp automation)

# Initialize output aggregation files (stdout,stderr)
exec > >(tee -a "$output_dir/run_all.all" "$output_dir/run_all.out")
exec 2> >(tee -a "$output_dir/run_all.all" "$output_dir/run_all.err" >&2)

# Start timing the script
start_time=$(date +%s)

# Detect input size flag (default --full)
if [[ "$@" == *"--small"* ]]; then
    echo "Running in small mode"
    params="--small"
else
    echo "Running in full mode"
    params="--full"
fi

# Loop through each suite
for s in "${suites[@]}"; do
  echo "[run_faultless] $s"
  ( cd "$s" && ./run.sh --faultless $params )
  echo "[run_faultless] $s done"
done

# End timing
end_time=$(date +%s)
duration=$((end_time - start_time))

echo "Total execution time: $duration seconds" | tee -a "$output_dir/run_all.time" 