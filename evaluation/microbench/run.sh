#!/bin/bash
# Microbenchmark runner – executes 4 scenarios measuring dynamic persistence impact
set -e
here="$(dirname "$0")"
out="$here/outputs"
rm -rf "$out"; mkdir -p "$out"

run_case() {
  suite=$1; label=$2; shift 2
  flags="$*"
  echo "[micro] $label ($flags)" | tee -a "$out/log"
  start=$(date +%s)
  ( cd "$here/../$suite" && ./run.sh $flags "$@" )
  end=$(date +%s)
  echo "$label,$((end-start))" >> "$out/results.csv"
}

# NLP – no faults
run_case nlp        nlp-off --ft dynamic --dynamic_switch_force off "$@"
run_case nlp        nlp-on  --ft dynamic --dynamic_switch_force on  "$@"
# Analytics – merger fault
run_case analytics  ana-off --ft dynamic --kill merger --dynamic_switch_force off "$@"
run_case analytics  ana-on  --ft dynamic --kill merger --dynamic_switch_force on  "$@"

echo "Results written to $out/results.csv" 