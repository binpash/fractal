#!/bin/bash
# Cleanup outputs of microbenchmark
set -e
here="$(dirname "$0")"
rm -rf "$here/outputs" 