# Plotting Toolkit (Paper Figures)

This directory contains the CSV datasets, Python scripts, and figure outputs used to recreate the performance graphs that appear in the paper. Everything is self-contained --- no database or external queries are required once the CSV files are present.

## Directory layout

```
plotting/
├── data/            # CSV inputs used by plot.py
│   ├── fault_free.csv      # §7.1 fault-free speedups (Fig. 4/5)
│   ├── fault_hard.csv      # §7.2 hard-fault scatter (Fig. 6)
│   ├── fault_soft.csv      # §7.2 soft-fault violin (Fig. 7)
│   └── microbench.csv      # §7.3 dynamic-persistence microbenchmark (Fig. 8)
├── scripts/
│   └── plot.py      # single entry point that loads all four datasets and emits PDFs
├── figures/         # Auto-generated PDFs land here
├── paper_data/      # Raw archivally-stored copies (unchanged from camera-ready)
└── requirements.txt # minimal PyPI dependencies (see below)
```

*`paper_data/` contains the exact, frozen CSVs that generated the camera-ready figures and should **not be modified**.*  
*`data/` is the working directory read by `plot.py`; reviewers can drop in their own CSVs with the same schema to regenerate plots with new results.*

## Quick-start

1. **Create virtual environment**
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

2. **Install dependencies** (Matplotlib + Seaborn + Pandas is all that is required):
   ```bash
   pip install -r requirements.txt
   ```

3. **Generate all figures**
   ```bash
   cd scripts
   python plot.py
   ```
   The following PDFs will be produced under `figures/{timestamp}`:
   * `eval1dist.pdf`   – Fault-free speed-up distribution (Fig. 5a)
   * `eval1violin.pdf` – Fault-free violin plot (Fig. 5b)
   * `eval2scatter.pdf`– Hard-fault scatter (Fig. 6)
   * `eval3violin.pdf` – Soft-fault violin (Fig. 7)
   * `eval4scatter.pdf`– Microbenchmark trade-off (Fig. 8)

4. **Custom data**

   If you run your own experiments and wish to visualise them, drop the new CSV files into `data/` with the same column schemas and re-run `plot.py`.  The script automatically picks up the files by name.

## CSV naming convention

| Name | Meaning |
|------|---------------------------------------------|
| `fault_free.csv`   | Fault-free performance dataset (§7.1 Fig. 4/5) |
| `fault_hard.csv`   | Hard-fault recovery timings (§7.2 Fig. 6) |
| `fault_soft.csv`   | Soft-fault recovery timings (§7.2 Fig. 7) |
| `microbench.csv`   | Dynamic-persistence microbenchmark (§7.3 Fig. 8) |

The plotting script expects these exact filenames inside `data/`. Replace them with your own results (same schema) to regenerate the figures.
