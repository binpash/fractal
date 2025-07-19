#! /usr/bin/env python3
import pandas as pd, argparse, pathlib, sys

DATA = pathlib.Path(__file__).resolve().parent.parent / 'data'
RAW  = DATA / 'intermediary' / 'raw_times.csv'

FREE_SET  = {'bash','ahs','dish','fractal'}
SOFT_SET  = {'dish','fractal','fractal-m','fractal-r'}

def reshape_one_script(df):
    """
    df == the eight rows belonging to one (benchmark, script, run) group
    columns: benchmark,script,system,nodes,persistence_mode,time,run
    returns a single wide-format row.
    """
    # build a column key like  bash|4   dish|30 ...
    df['key'] = df['system'] + '|' + df['nodes'].astype(str)

    # reshape to two Series: time  and run
    time_wide = df.set_index('key')['time']
    run_wide  = df.set_index('key')['run']

    # interleave:  bash|4,time , bash|4,run , ahs|4,time , ahs|4,run …
    wide = {}
    for k in time_wide.index:          # keeps deterministic order
        wide[f'{k}']   = time_wide[k]
        wide[f'{k}_run'] = run_wide[k]

    # skeleton columns
    wide.update({
        'benchmark': df['benchmark'].iloc[0],
        'script'   : df['script'].iloc[0]
    })
    return pd.Series(wide)

# ------------------------------------------------------------------

FREE_SYSTEMS  = {'bash','ahs','dish','fractal'}
SOFT_SYSTEMS  = {'dish','fractal','fractal-m','fractal-r'}
BENCH_ORDER   = ['Classics','Unix50','Analytics','NLP','Automation']
ORDER_MAP     = {b:i for i,b in enumerate(BENCH_ORDER)}

def add_run_index(df: pd.DataFrame) -> pd.DataFrame:
    """Tag duplicate measurements with cumulative run index."""
    df['run'] = (
        df.groupby(['benchmark','script','nodes','system','persistence_mode'])
          .cumcount() + 1
    )
    return df


def build_fault_free(df: pd.DataFrame) -> pd.DataFrame:
    df = df[df['system'].isin(FREE_SYSTEMS)].copy()

    index_cols = ['size','run','benchmark','script']
    wide = df.pivot_table(index=index_cols,
                          columns=['system','nodes'],
                          values='time',
                          aggfunc='min')

    # rename timing columns to system|site|t
    wide.columns = [f"{sys}|{nodes}|t" for (sys,nodes) in wide.columns]

    # compute speedups versus bash for each system except bash
    for sys in ['ahs','dish','fractal']:
        for nodes in [4,30]:
            base_col = f"bash|{nodes}|t"
            tgt_col  = f"{sys}|{nodes}|t"
            if base_col in wide.columns and tgt_col in wide.columns:
                wide[f"{sys}|{nodes}|s"] = wide[base_col] / wide[tgt_col]

    # order: timings then speedups (deterministic)
    time_cols  = [f"bash|4|t","ahs|4|t","dish|4|t","fractal|4|t",
                  f"bash|30|t","ahs|30|t","dish|30|t","fractal|30|t"]
    speed_cols = [f"ahs|4|s","dish|4|s","fractal|4|s",
                  f"ahs|30|s","dish|30|s","fractal|30|s"]
    ordered = [c for c in time_cols+speed_cols if c in wide.columns]
    wide = wide.reindex(columns=ordered, level=None)

    wide.reset_index(inplace=True)
    wide = wide.sort_values(by=['benchmark'], key=lambda s: s.map(ORDER_MAP))
    return wide


def build_fault_soft(df: pd.DataFrame) -> pd.DataFrame:
    df = df[df['system'].isin(SOFT_SYSTEMS)].copy()

    index_cols = ['run','benchmark','script']
    wide = df.pivot_table(index=index_cols,
                          columns=['system','nodes'],
                          values='time',
                          aggfunc='min')

    wide.columns = [f"{c[0]}|{c[1]}" for c in wide.columns]
    wide.reset_index(inplace=True)
    wide = wide.sort_values(by=['benchmark'], key=lambda s: s.map(ORDER_MAP))
    return wide


def main(raw_path):
    df = pd.read_csv(raw_path)

    # Ensure required columns exist (fill with defaults if missing)
    if 'persistence_mode' not in df.columns:
        df['persistence_mode'] = ''
    df['persistence_mode'] = df['persistence_mode'].fillna('').astype(str)
    if 'size' not in df.columns:
        df['size'] = 'N/A'

    df = add_run_index(df)

    print('[preprocess] Generating fault_free.csv')
    ff_path = DATA / 'fault_free.csv'
    ff_df = build_fault_free(df)
    with ff_path.open('w') as f:
        f.write('# fault_free dataset: per-script timings & speedups\n')
        ff_df.to_csv(f, index=False)

    print('[preprocess] Generating fault_soft.csv')
    fs_path = DATA / 'fault_soft.csv'
    fs_df = build_fault_soft(df)
    with fs_path.open('w') as f:
        f.write('# fault_soft dataset: per-script timings (fault runs)\n')
        fs_df.to_csv(f, index=False)

if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('--raw', default=RAW, type=pathlib.Path)
    a = p.parse_args()
    if not a.raw.exists():
        sys.exit(f'raw file {a.raw} not found')
    main(a.raw)