# Microbenchmark – Dynamic Output Persistence

This helper suite reproduces Fig. 8 of the paper ( §7.3 ).  It runs a trimmed version of the NLP and Analytics benchmarks under four configurations to show the cost-benefit trade-off of Fractal’s dynamic persistence heuristic.

Scenarios executed by `run.sh`:

| Case | Suite | Fault | Persistence Flag |
|------|-------|-------|------------------|
| nlp-off | NLP | none | `--dynamic_switch_force off` |
| nlp-on  | NLP | none | `--dynamic_switch_force on`  |
| ana-off | Analytics | merger fault | `--kill merger --dynamic_switch_force off` |
| ana-on  | Analytics | merger fault | `--kill merger --dynamic_switch_force on`  |

For each case the script captures wall-clock time and appends a CSV line to `outputs/results.csv`.

Steps:
1. `./inputs.sh` – fetch input for NLP and Analytics.
2. `./run.sh`   – execute the four scenarios.