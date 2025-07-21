#! /usr/bin/env python3

import pathlib
from dataclasses import dataclass
import sys

EVAL_DIR = pathlib.Path(__file__).resolve().parent.parent.parent
DATA_DIR = EVAL_DIR / 'plotting' / 'data'
NODE_NUM = sys.argv[1] if len(sys.argv) > 1 else '4'
OUTFILE = DATA_DIR / 'intermediary' / f'raw_times_site{NODE_NUM}.csv'
BENCHMARKS = {
    "automation": ["file-enc", "log-analysis", "media-conv"],
    "analytics": ["covid-mts", "max-tmp"],
    "classics": ["."],
    "nlp": ["."],
    "unix50": ["."]
}
BENCHMARKS_NAME_MAP = {
    "automation": "Automation",
    "analytics": "Analytics",
    "classics": "Classics",
    "nlp": "NLP",
    "unix50": "Unix50"
}
SYS_TO_SYSNAME_PERSISTENCE_MODE = {
    "bash": ["bash", "dynamic"],
    "hadoop": ["ahs", ""],
    "dish": ["dish", "dynamic"],
    "dynamic": ["fractal", "dynamic"],
    "dynamic-m": ["fractal-m", "dynamic"],
    "dynamic-r": ["fractal-r", "dynamic"],
    "dynamic-on": ["fractal", "enabled"],
    "dynamic-off": ["fractal", "disabled"]
}

@dataclass
class Entry:
    benchmark: str
    script: str
    system: str
    nodes: str
    persistence_mode: str
    time: float

def process_single_output_dir(benchmark_output_dir, benchmark, system, persistence_mode, entries):
    if benchmark_output_dir.exists():
        for file_ in benchmark_output_dir.glob('*.time'):
            time = None
            with open(file_, 'r') as f:
                for line in f:
                    try:
                        time = float(line.strip())
                        break
                    except ValueError:
                        continue
            if time is None:
                print(f"  Warning: No valid time found in {file_}, skipping.")
                continue
            script = f"{file_.stem}.sh"
            nodes = '30'
            entries.append(Entry(BENCHMARKS_NAME_MAP[benchmark], script, system, NODE_NUM, persistence_mode, time))

def main():
    header = "benchmark,script,system,nodes,persistence_mode,time"
    entries = []
    for benchmark in BENCHMARKS:
        print(f"Processing Benchmark {benchmark}")
        for sub_dir in BENCHMARKS[benchmark]:
            benchmark_output_dir = EVAL_DIR / benchmark / sub_dir / 'outputs'
            for sys in SYS_TO_SYSNAME_PERSISTENCE_MODE:
                benchmark_per_sys_output_dir = benchmark_output_dir / sys
                system_name, persistence_mode = SYS_TO_SYSNAME_PERSISTENCE_MODE[sys]
                process_single_output_dir(benchmark_per_sys_output_dir, benchmark, system_name, persistence_mode, entries)
    if entries:
        with open(OUTFILE, 'w') as f:
            f.write(header + '\n')
            for entry in sorted(entries, key=lambda e: (e.benchmark, e.system, e.script, e.nodes, e.persistence_mode)):
                f.write(f"{entry.benchmark},{entry.script},{entry.system},{entry.nodes},{entry.persistence_mode},{entry.time:<.3f}\n")
        print(f"Aggregated times written to {OUTFILE}")
    else:
        print("No entries found to aggregate.")
        print("Please check the output directories for the benchmark runs.")

if __name__ == '__main__':
    print(f"Starting aggregation of benchmark times for {NODE_NUM} nodes...")
    main()