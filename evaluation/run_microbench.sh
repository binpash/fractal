#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

# Absolute path to outputs directory for microbench
output_dir="$(pwd)/outputs_microbench"
rm -rf "$output_dir" && mkdir -p "$output_dir"

# Tee stdout/stderr
exec > >(tee -a "$output_dir/run_microbench.all" "$output_dir/run_microbench.out")
exec 2> >(tee -a "$output_dir/run_microbench.all" "$output_dir/run_microbench.err" >&2)

start_time=$(date +%s)

# Detect size flag (though microbench usually forces small)
if [[ "$@" == *"--small"* ]]; then
  params="--small"
else
  params="--full"
fi

for s in nlp analytics; do
  echo "[run_microbench] $s"
  ( cd "$s" && ./run.sh --microbench $params )
  echo "[run_microbench] $s done"
done

end_time=$(date +%s)
duration=$((end_time - start_time))

echo "Total microbench execution time: $duration seconds" | tee -a "$output_dir/run_microbench.time" 