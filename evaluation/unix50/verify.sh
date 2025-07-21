#!/bin/bash

# Exit immediately if a command exits with a non-zero status
# set -e

cd "$(realpath $(dirname "$0"))"

hash_folder="outputs/bash"

if [[ "$@" == *"--generate"* ]]; then
    # Directory to iterate over
    directory="outputs/bash"

    # Loop through all .out files in the directory
    for file in "$directory"/*.out
    do
        # Extract the filename without the directory path and extension
        filename=$(basename "$file" .out)

        # Generate SHA-256 hash
        hash=$(shasum -a 256 "$file" | awk '{ print $1 }')

        # Save the hash to a file
        echo "$hash" > "$hash_folder/$filename.hash"

        # Print the filename and hash
        echo "File: $hash_folder/$filename.hash | SHA-256 Hash: $hash"
    done
fi

# Loop through all directories in the parent directory
for folder in "outputs"/*/
do
    # Remove trailing slash
    folder=${folder%/}

    if [[ $folder == *"bash"* || $folder == *"hadoop"* ]]; then
        continue
    fi 

    # echo "Verifying folder: $folder"

    # Loop through all .out files in the current directory
    for file in "$folder"/*.out
    do
        # Extract the filename without the directory path and extension
        filename=$(basename "$file" .out)

        if [ ! -f "$folder/$filename.hash" ]; then
            # Generate SHA-256 hash
            hash=$(shasum -a 256 "$file" | awk '{ print $1 }')

            # Save the hash to a file
            echo "$hash" > "$folder/$filename.hash"
        fi

        # Compare the hash with the hash in the hashes directory
        if ! diff "$hash_folder/$filename.hash" "$folder/$filename.hash";
        then
            # Print the filename and hash if they don't match
            echo "File: $folder/$filename hash diff failed!"
        fi
    done
done
