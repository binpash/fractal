#!/bin/bash
# Microbenchmark runner – executes 4 scenarios measuring dynamic persistence impact
set -e
here="$(dirname "$0")"
out="$here/outputs"
rm -rf "$out"; mkdir -p "$out"
csv="$out/microbench_results.csv"

run_case() {
  suite=$1; label=$2; shift 2
  flags="$*"
  echo "[micro] $label ($flags)" | tee -a "$out/log"
  start=$(date +%s)
  ( cd "$here/../$suite" && ./run.sh --microbench $flags "$@" )
  end=$(date +%s)
  echo "$label,$((end-start))" >> "$csv"
}

# NLP – no faults
run_case nlp        nlp-off --ft dynamic --dynamic_switch_force off "$@"
run_case nlp        nlp-on  --ft dynamic --dynamic_switch_force on  "$@"
# Analytics – merger fault
run_case analytics  ana-off --ft dynamic --kill merger --dynamic_switch_force off "$@"
run_case analytics  ana-on  --ft dynamic --kill merger --dynamic_switch_force on  "$@"

echo "Microbenchmark results written to $csv" 

# Consolidate suite-level timing files into one CSV under microbench
merged="$out/time.csv"
header_written=0
for f in "$here/../nlp/outputs/time_microbench.csv" \
         "$here/../analytics/covid-mts/outputs/time_microbench.csv" \
         "$here/../analytics/max-temp/outputs/time_microbench.csv"; do
  if [[ -f "$f" ]]; then
    if [[ $header_written -eq 0 ]]; then
      cat "$f" > "$merged"
      header_written=1
    fi
    # Rewrite persistence_mode field
    tail -n +2 "$f" | \
      sed -e 's/,dynamic,/,dynamic-microbench,/' \
          -e 's/,enabled,/,enabled-microbench,/' \
          -e 's/,disabled,/,disabled-microbench,/' >> "$merged"
    rm "$f"
  fi
done
echo "Merged per-suite timing into $merged" 