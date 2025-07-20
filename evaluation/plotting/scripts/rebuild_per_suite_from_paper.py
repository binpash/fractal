#!/usr/bin/env python3
"""
Reverse-engineer per-suite outputs/time.csv files from paper_data/{fault_free,fault_soft}.csv
Run from evaluation/plotting/scripts/
"""

import pandas as pd, pathlib, csv, re
import argparse, sys

root      = pathlib.Path(__file__).resolve().parent.parent
paper_dir = root / 'paper_data'
out_root  = root.parent      # evaluation/

def long_fault_free(df):
    # keep only ...|4|t and ...|30|t cols
    long = (df.set_index(['benchmark','script'])
              .filter(regex=r'\|\d+\|t$')
              .stack().reset_index())
    long.columns = ['benchmark','script','col','time']
    long[['system','nodes','_']] = long['col'].str.split('|',expand=True)
    return long[['benchmark','script','system','nodes','time']]

def long_fault_soft(df):
    long = (df.set_index(['benchmark','script'])
              .stack().reset_index())
    long.columns = ['benchmark','script','col','time']
    long[['system','nodes']] = long['col'].str.split('|',expand=True)
    return long[['benchmark','script','system','nodes','time']]

def to_suite_csv(df):
    df['persistence_mode'] = ''                 # blank for all rows
    # map any dynamic aliases if they existed in older data (not present here)
    suites = df.groupby('benchmark')
    for bench, sub in suites:
        suite_dir = out_root / bench.lower() / 'outputs'
        suite_dir.mkdir(parents=True, exist_ok=True)
        csvfile   = suite_dir / 'time.csv'
        cols      = ['benchmark','script','system','persistence_mode','time']
        sub[cols].to_csv(csvfile, index=False, quoting=csv.QUOTE_MINIMAL)
        print('[write]', csvfile)

# -------- microbench reconstruction ------------
def build_microbench(csv_path):
    mb = pd.read_csv(csv_path, skiprows=1)
    out_dir = root.parent / 'microbench' / 'outputs'
    out_dir.mkdir(parents=True, exist_ok=True)
    out_csv = out_dir / 'time.csv'
    with out_csv.open('w') as f:
        f.write('benchmark,script,system,persistence_mode,time\n')
        run=1
        for _,row in mb.iterrows():
            bench=row['benchmark']; script=row['script']
            for mode in ['enabled','disabled','dynamic']:
                if pd.isna(row[mode]):
                    continue
                t=row[mode]
                f.write(f"{bench},{script},fractal,{mode}-microbench,{t}\n")
        print('[write]', out_csv)

ff = pd.read_csv(paper_dir/'fault_free.csv', skiprows=1)
fs = pd.read_csv(paper_dir/'fault_soft.csv', skiprows=1)

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
parser = argparse.ArgumentParser(
    description='Rebuild per-suite outputs/time.csv files from paper_data CSVs, '
                'optionally filtering for a specific cluster size (site).')
parser.add_argument('--site', type=int, choices=[4, 30], default=30,
                    help='Cluster size to keep (4 or 30 nodes). Defaults to 30.')
args = parser.parse_args()

site_str = str(args.site)

# ---------------------------------------------------------------------------
# Transform and filter raw paper data
# ---------------------------------------------------------------------------

long = pd.concat([long_fault_free(ff), long_fault_soft(fs)], ignore_index=True)

# Keep only the requested site (cluster size)
if 'nodes' in long.columns:
    long = long[long['nodes'] == site_str]
    if long.empty:
        sys.exit(f"[error] No rows found for site={site_str}. Ensure the paper_data CSVs contain the chosen cluster size.")

# Write per-suite CSVs
to_suite_csv(long)

# build microbench
build_microbench(paper_dir/'microbench.csv')