# Automation Benchmark Suite

This meta-suite groups three script-automation workloads that heavily use black-box binaries, stressing Fractal’s language-agnostic support and fault-tolerant streaming:

1. **File-Enc**   (`evaluation/automation/file-enc`) – batch compression + encryption pipelines.
2. **Media-Conv** (`evaluation/automation/media-conv`) – parallel image and audio format conversion.
3. **Log-Analysis** (`evaluation/automation/log-analysis`) – NGINX log and PCAP parsing analytics.

The wrapper scripts in this directory (`inputs.sh`, `run.sh`, `verify.sh`, `cleanup.sh`) simply invoke the corresponding helpers inside each sub-suite so that existing scripts remain unchanged while reviewers can run the entire Automation suite with a single command. 