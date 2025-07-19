#!/bin/bash

# Absolute path to the outputs directory
output_dir="$(pwd)/outputs"

# Remove and recreate the outputs directory
if [ -d "$output_dir" ]; then
    rm -rf "$output_dir"
fi
mkdir -p "$output_dir"

# List of directories to process, you can comment out any directory as needed
dirs=(
    "classics"
    "unix50"
    "analytics"
    "nlp"
    "automation"
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

# Loop through each directory in the list
for dir in "${dirs[@]}"; do
    # Change to the directory
    cd "./$dir" || continue

    # Run the evaluation scripts
    ./cleanup.sh
    sleep 10
    ./inputs.sh $params
    sleep 60
    ./run.sh $params

    # # Generate and verify hashes
    # rm -rf hashes/
    # mkdir -p "$output_dir/$dir"
    # ./verify.sh --generate --dish | tee "$output_dir/$dir/verify.out"

    # Move the outputs to the corresponding directory in $output_dir
    # mv outputs/* "$output_dir/$dir"

    # # Do not cleanup cuz it will remove all time files
    # ./cleanup.sh
    # sleep 60

    # Go back to the parent directory
    cd ..
done

# End timing the script
end_time=$(date +%s)
duration=$((end_time - start_time))

# Save the duration to run_all.time
echo "Total execution time: $duration seconds" | tee -a "$output_dir/run_all.time"
