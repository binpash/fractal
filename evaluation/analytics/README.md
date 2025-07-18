# Analytics Benchmark Suite

This meta-suite bundles two data-analytics workloads that together stress Fractal’s heavy-join and streaming-aggregation path:

1. **COVID-MTS**  (`evaluation/analytics/covid-mts`) – Mass-transit mobility analytics during COVID.
2. **Max-Temp**  (`evaluation/analytics/max-temp`) – NOAA weather statistics over large CSV logs.

Wrapper scripts (`run.sh`, `inputs.sh`, `verify.sh`, `cleanup.sh`) simply invoke the corresponding helpers inside each sub-suite so existing code remains unchanged. 