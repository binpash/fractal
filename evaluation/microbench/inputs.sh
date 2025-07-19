#!/bin/bash
# Fetch inputs for microbenchmark suites (NLP + Analytics)
set -e
here="$(dirname "$0")"

# Ensure sub-suite inputs
bash "$here/../nlp/inputs.sh" "$@"
bash "$here/../analytics/inputs.sh" "$@" 