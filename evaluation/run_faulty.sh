#!/bin/bash

cd "$(realpath $(dirname "$0"))"

# Absolute path to the outputs directory
output_dir="$(pwd)/outputs"

# Remove and recreate the outputs directory
if [ -d "$output_dir" ]; then
    rm -rf "$output_dir"
fi
mkdir -p "$output_dir"

# List of directories to process, you can comment out any directory as needed
dirs=(
    "analytics"
    "automation"
    "classics"
)

# Initialize output files
exec > >(tee -a "$output_dir/run_all.all" "$output_dir/run_all.out")
exec 2> >(tee -a "$output_dir/run_all.all" "$output_dir/run_all.err" >&2)

# Start timing the script
start_time=$(date +%s)

if [[ "$@" == *"--small"* ]]; then
    echo "Running in small mode"
    params="--small"
else
    echo "Running in full mode"
    params="--full"
fi

# Loop through each directory once; the suite will run merger/regular internally
for dir in "${dirs[@]}"; do
    echo "[run_faulty] $dir"
    ( cd "$dir" && ./run.sh --faulty $params )
done

# End timing the script
end_time=$(date +%s)
duration=$((end_time - start_time))

# Save the duration to run_all.time
echo "Total execution time: $duration seconds" | tee -a "$output_dir/run_all.time"
