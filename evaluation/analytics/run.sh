#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

# outputs directory dedicated to analytics suite
mkdir -p outputs

# Parse size flag and mode flags; simply forward everything unchanged
MODE_FLAGS=()
SIZE_FLAG="--full"
for arg in "$@"; do
  case "$arg" in
    --small|--full) SIZE_FLAG="$arg";;
    --faultless|--faulty|--microbench) MODE_FLAGS+=("$arg");;
    *) MODE_FLAGS+=("$arg");;
  esac
done

for d in covid-mts max-temp; do
  echo "[analytics] running $d benchmark"
  ( cd "$d" && ./run.sh $SIZE_FLAG "${MODE_FLAGS[@]}" )
  echo "[analytics] finished $d"
done 