#!/usr/bin/env python3
"""Pre-process raw benchmark timings into the four figure-ready CSVs.

Usage:
  python preprocess.py [--raw path/to/raw_times.csv]

Takes the consolidated raw_times.csv generated via
  merge_sites.sh
and rewrites three files in ../data/ (plus keeps the manual hard-fault CSV):
  fault_free.csv   --- fault-free speedups (Fig. 4/5)
  fault_soft.csv   --- soft-fault absolute timings (Fig. 7)
  microbench.csv   --- dynamic-persistence microbenchmark (Fig. 8)

The hard-fault dataset (fault_hard.csv) involves manual fault injection and
is **NOT** generated automatically; edit it by hand if you collect extra runs.
"""

import argparse
import pathlib
import sys
import pandas as pd

BASE_DIR = pathlib.Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / 'data'
RESULTS_DIR = BASE_DIR.parent / 'results'  # evaluation/results/
RAW_DEFAULT = RESULTS_DIR / 'raw_times.csv'

SYSTEM_ORDER = [
    'bash', 'ahs', 'dish', 'fractal', 'fractal-m', 'fractal-r'
]

# ----------------------------------------------------------------------

def fault_free(df: pd.DataFrame):
    """Return DataFrame in wide format ready for fault_free.csv"""
    df = df[df['fault_mode'] == 'none'].copy()
    # pivot: rows keyed by (size,run,benchmark,script)
    df['run'] = df.groupby(['benchmark', 'script']).cumcount() + 1
    index_cols = ['size', 'run', 'benchmark', 'script']
    pivot = df.pivot_table(index=index_cols, columns=['system', 'nodes'], values='time', aggfunc='min')
    # compute speedup columns relative to dish
    speed_cols = {}
    for sys in SYSTEM_ORDER:
        if sys == 'dish':
            continue
        for nodes in [4, 30]:
            if ('dish', nodes) in pivot.columns and (sys, nodes) in pivot.columns:
                speed = pivot[('dish', nodes)] / pivot[(sys, nodes)]
                speed_cols[(sys, nodes)] = speed
    # build final DataFrame with multi-value headers similar to original
    wide = pivot.copy()
    for col, series in speed_cols.items():
        wide[(col[0], col[1], 's')] = series
    # Flatten to composite headers like 'bash|4|t'
    wide.columns = [f"{c[0]}|{c[1]}|{'t' if len(c)==2 else c[2]}" if isinstance(c, tuple) else str(c) for c in wide.columns]
    wide.reset_index(inplace=True)
    return wide


def fault_soft(df: pd.DataFrame):
    df = df[df['fault_mode'].isin(['regular', 'merger'])].copy()
    index_cols = ['run', 'benchmark', 'script']
    pivot = df.pivot_table(index=index_cols, columns=['system', 'nodes'], values='time', aggfunc='min')
    # Order the columns similarly
    ordered = []
    for nodes in [4, 30]:
        for sys in ['dish', 'fractal', 'fractal-m', 'fractal-r']:
            col = (sys, nodes)
            if col in pivot.columns:
                ordered.append(col)
    pivot = pivot[ordered]
    pivot.columns = [f"{c[0]}|{c[1]}" for c in pivot.columns]
    pivot.reset_index(inplace=True)
    return pivot


def microbench(df: pd.DataFrame):
    df = df[(df['benchmark'].isin(['NLP', 'Analytics'])) & (df['persistence_mode'].notna())].copy()
    # pivot to enabled/disabled/dynamic columns
    pivot = df.pivot_table(index=['benchmark', 'script'], columns='persistence_mode', values='time', aggfunc='min')
    pivot.reset_index(inplace=True)
    return pivot


# ----------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--raw', type=pathlib.Path, default=RAW_DEFAULT, help='raw_times.csv path')
    args = parser.parse_args()

    if not args.raw.exists():
        sys.exit(f"[preprocess] Raw timing file not found: {args.raw}\nRun benchmarks first.")

    DATA_DIR.mkdir(parents=True, exist_ok=True)

    raw = pd.read_csv(args.raw)

    # Ensure required columns exist (fill with defaults if missing)
    defaults = {
        'fault_mode': 'none',
        'fault_pct' : 0,
        'size'      : '',
        'persistence_mode': ''
    }
    for col, default in defaults.items():
        if col not in raw.columns:
            raw[col] = default
    # Minimal required columns must now be present
    required = {'benchmark', 'script', 'system', 'nodes', 'time'}
    missing = required - set(raw.columns)
    if missing:
        sys.exit(f"[preprocess] Missing mandatory columns in raw_times.csv: {missing}")

    # Generate
    print('[preprocess] Generating fault_free.csv')
    fault_free(raw).to_csv(DATA_DIR / 'fault_free.csv', index=False)

    print('[preprocess] Generating fault_soft.csv')
    fault_soft(raw).to_csv(DATA_DIR / 'fault_soft.csv', index=False)

    print('[preprocess] Generating microbench.csv')
    if 'persistence_mode' in raw.columns:
        microbench(raw).to_csv(DATA_DIR / 'microbench.csv', index=False)
    else:
        print('[preprocess] Skipped microbench --- persistence_mode column missing')

    print('\n  Hard-fault dataset (fault_hard.csv) is unchanged --- edit manually if you collected extra hard-fault runs.')

if __name__ == '__main__':
    main() 