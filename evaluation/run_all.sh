#!/usr/bin/env bash
set -e
cd "$(realpath $(dirname "$0"))"

output_dir="$(pwd)/outputs_run_all"
rm -rf "$output_dir" && mkdir -p "$output_dir"

exec > >(tee -a "$output_dir/run_all.all" "$output_dir/run_all.out")
exec 2> >(tee -a "$output_dir/run_all.all" "$output_dir/run_all.err" >&2)

start=$(date +%s)

bash ./run_faultless.sh "$@"
bash ./run_faulty.sh    "$@"
bash ./run_microbench.sh "$@"

end=$(date +%s)

echo "[run_all] Completed faultless, faulty, and microbench runs in $((end-start)) seconds" | tee -a "$output_dir/run_all.time"
