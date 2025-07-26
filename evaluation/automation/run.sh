#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

MODE_FLAGS=()
SIZE_FLAG="--full"
for arg in "$@"; do
  case "$arg" in
    --small|--full) SIZE_FLAG="$arg";;
    --faultless|--faulty|--microbench) MODE_FLAGS+=("$arg");;
    *) MODE_FLAGS+=("$arg");;
  esac
done

for d in file-enc media-conv log-analysis; do
  echo "[automation] running $d benchmark"
  ( cd "$d" && ./run.sh $SIZE_FLAG "${MODE_FLAGS[@]}" )
  echo "[automation] finished $d"
done 