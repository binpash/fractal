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
    "classics"
    "unix50"
    "analytics"
    "nlp"
    "automation"
)

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
    
    # Go back to the parent directory
    cd ..
done

