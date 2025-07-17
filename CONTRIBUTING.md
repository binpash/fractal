# Contributing to Fractal/Dish

Thank you for your interest in extending the repository!  This document captures
frequently requested developer workflows that do **not** belong in the user‐oriented
README files.

---

## 1  Adding a new Benchmark Suite
FRACTAL suites live under `evaluation/<suite>/` and must expose the following
interface so that automation scripts can discover them:

```
inputs.sh        # download or generate input data, then put it into HDFS
dependencies.sh  # (optional) apt / pip / go install steps
run.sh           # run the workload in one or more modes (bash, dish, pash …)
verify.sh        # exit 0 on success or emit hashes via --generate
cleanup.sh       # remove files from HDFS and local tempdirs
```

Conversion recipe (adapted from the original evaluation README):

1. In `inputs.sh` push raw data to HDFS, e.g.
   ```bash
   hdfs dfs -put local.txt /mysuite/local.txt
   ```
2. In `run.sh` call `pa.sh` / `di.sh` with the desired flags **and** write all
   outputs under `outputs/` so that `verify.sh` can hash and discard them.
3. Every script that needs to read inputs should do so from HDFS (`hdfs dfs -cat`)
   instead of local files.
4. In `cleanup.sh` delete the HDFS paths you created to keep the cluster tidy.

Run your suite with `run.sh --small` first; once it works you can add a row to
the benchmark-summary table in `evaluation/README.md`.

---

## 2  Rebuilding and Restarting the Worker Runtime
When hacking core Go / Python code you often want a *live* cluster without
re-deploying containers.  The following one-liner (from the original
INSTRUCTIONS) restarts the worker processes inside each DataNode container:

```bash
# On every data node (non-manager):
docker ps                # find <CONTAINER_ID> for   hadoop-datanode
docker exec -it <ID> bash -c '
  cd dish && \
  git pull && git submodule update && \
  pkill -f worker && pkill -f discovery && pkill -f filereader && \
  sleep 2 && \
  bash /opt/dish/pash/compiler/dspash/worker.sh &> /worker.log &
'
```

If you changed Go code remember to rebuild:
```bash
/opt/dish/runtime/scripts/build.sh
```
which recompiles `filereader_server`, `datastream`, and `discovery_server`.

---

For questions ping us on Discord: <http://join.binpa.sh/> 