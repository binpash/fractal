
### Benchmark Suites (Paper Tab. 2)

| Benchmark | Scripts | LoC | Input (full) | Description & Why it matters |
|-----------|---------|-----|--------------|--------------------------------|
| Classics  | 10 | 103 | 3 GB | Collection of canonical UNIX one-liners.  Exercises built-in utilities and measures FRACTAL overhead on small pipelines. |
| Unix50    | 34 | 34  | 10 GB | Bell Labs “Unix50” scripts; lots of short command chains with `sort`, `uniq`, etc.; good for Remote-Pipe fan-out. |
| NLP       | 22 | 280 | 10 GB | Natural-language processing tutorial pipelines over Project Gutenberg; highlights **parallel pipelines** and dynamic persistence benefits. |
| Analytics | 5  | 62  | 33.4 GB | Mass-transit COVID telemetry & NOAA weather analytics; large join + sort workloads that stress the Distributed File Reader and merger subgraphs. |
| Automation| 6  | 68  | 2.1–30 GB | Media conversion, encryption/compression, log parsing – heavy **black-box binaries** showcase FRACTAL’s language-agnostic support.
| Microbench| 4 cases | – | 0.5–33 GB | Runs NLP & Analytics under four dynamic-persistence settings; reproduces Fig. 8 trade-off.

Each suite sits under `evaluation/<dir>` with the canonical 5 helper scripts (`dependencies.sh`, `inputs.sh`, `run.sh`, `verify.sh`, `cleanup.sh`).
Run with `run.sh --small` for a <1 h check or without flags for full paper-scale inputs.


### Description of Contents

- **suite/**: Contains all the scripts and utilities for the project.
  - **scripts/**: Directory for individual scripts.
    - **script1.sh, script2.sh, script3.sh, ...**: Specific scripts to perform various tasks. Each script should be self-contained and executable.
  - **dependencies.sh**: Script to set up the environment or dependencies required by other scripts.
  - **inputs.sh**: Script to prepare or fetch the input data necessary for the execution of the main script.
  - **run.sh**: Main script to execute the core functionality of the project.
  - **verify.sh**: Script to verify the results or outputs produced by `run.sh`.
  - **cleanup.sh**: Script to clean up the environment, remove temporary files, or revert any changes made during the execution.

### How to Use

> For a detailed explanation of how our automated **fault-injection** and **resurrection** experiments are wired up (the `--kill` flag, 50 %-runtime crash, node comeback, etc.), see [fault_injection_flow.md](fault_injection_flow.md).

First `cd evaluation/<suite>` and use the 5 helper scripts below:
1. **Setup Dependencies**: First, ensure you have all dependencies and environment variables set up (Some suites has no dependencies).
    ```bash
    cd suite
    ./dependencies.sh
    ```

2. **Prepare Inputs**: Prepare or fetch the necessary input data (Both full and small inputs when apply).
    ```bash
    ./inputs.sh
    ```

3. **Run the Main Script**: Execute the core functionality. It creates hash files for each generated output file and then remove the output file to save disk space.
    ```bash
    ./run.sh [-d <debug flag for pash/dish/fish>] [--small <using small inputs>]
    ```

4. **Verify the Output**: Check the results to ensure correctness.
    ```bash
    ./verify.sh [--generate <generating dedicated hash folders>] [--small <using small inputs>]
    ```

5. **Cleanup**: Clean up the environment after the execution.
    ```bash
    ./cleanup.sh
    ```
Alternatively, **all suites can be run at once** with
```bash
cd evaluation
./run_all.sh --small      # or omit --small for full inputs
```
The orchestration script calls the same `inputs.sh/run.sh/verify.sh`
in every suite sequentially and stores consolidated logs under
`evaluation/outputs/`.

### Consolidating Results & Plotting Figures

The evaluation uses **two pre-provisioned clusters**:

| Label | Nodes | Purpose |
|-------|-------|------------------------------------------------|
| `site4`  | 4     | Functional sanity-check, fast fault-free runs |
| `site30` | 30    | Full-scale performance and fault-tolerance    |

Each benchmark suite writes a per-suite `outputs/time.csv` on the
client node.  Follow the steps **on every site** and then merge locally:

1.  _Run suites_ (any subset).
2.  Aggregate timings _on that site_ into a site-labelled file:
    ```bash
    cd evaluation/plotting/scripts
    ./aggregate_times.sh --site 4      # or 30 on the other cluster
    # → ../data/intermediary/raw_times_site4.csv
    ```
3.  Download the resulting `raw_times_site*.csv` to your laptop.

On your **local workstation** (or inside the client if you prefer):

```bash
# Merge the two site files -> raw_times.csv
cd evaluation/plotting/scripts
./merge_sites.sh ../data/intermediary/raw_times_site4.csv ../data/intermediary/raw_times_site30.csv

# 1) pre-process into figure datasets
python preprocess.py                  # rewrites fault_free.csv, fault_soft.csv, microbench.csv

# 2) plot – PDFs land in figures/<timestamp>/
python plot.py
```

The helper scripts take care of deduplication and node-count tagging;
no manual CSV editing is required.  If you add **hard-fault numbers**
edit `evaluation/plotting/data/fault_hard.csv` by hand before re-running
the plot script.

To collect the PDFs from a remote Docker container:
```bash
# On the VM host (outside the container)
docker cp docker-hadoop-client-1:/opt/dish/evaluation/plotting/figures ./plots
scp -i <pem> user@<vm-host>:~/plots/* ./local_plots/
```

### Contributing
See the top-level [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on adding
new suites or adjusting runtime code.
