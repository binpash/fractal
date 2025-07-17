
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

### Benchmark Suites (Paper Tab. 2)

| Benchmark | Scripts | LoC | Input (full) | Description & Why it matters |
|-----------|---------|-----|--------------|--------------------------------|
| Classics  | 10 | 103 | 3 GB | Collection of canonical UNIX one-liners.  Exercises built-in utilities and measures FRACTAL overhead on small pipelines. |
| Unix50    | 34 | 34  | 10 GB | Bell Labs “Unix50” scripts; lots of short command chains with `sort`, `uniq`, etc.; good for Remote-Pipe fan-out. |
| NLP       | 22 | 280 | 10 GB | Natural-language processing tutorial pipelines over Project Gutenberg; highlights **parallel pipelines** and dynamic persistence benefits. |
| Analytics | 5  | 62  | 33.4 GB | Mass-transit COVID telemetry & NOAA weather analytics; large join + sort workloads that stress the Distributed File Reader and merger subgraphs. |
| Automation| 6  | 68  | 2.1–30 GB | Media conversion, encryption/compression, log parsing – heavy **black-box binaries** showcase FRACTAL’s language-agnostic support.

Each suite sits under `evaluation/<dir>` with the canonical 5 helper scripts (`dependencies.sh`, `inputs.sh`, `run.sh`, `verify.sh`, `cleanup.sh`).
Run with `run.sh --small` for a <1 h check or without flags for full paper-scale inputs.

### Contributing
See the top-level [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on adding
new suites or adjusting runtime code.


