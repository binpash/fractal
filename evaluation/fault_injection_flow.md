# Fault Injection & Resurrection Workflow in Fractal Evaluations

This document explains the end-to-end control-flow for the fault-injection experiments that appear in the evaluation scripts (e.g., `evaluation/oneliners/run.sh`).  It covers:

1. How the `--kill` command-line flag is propagated from the benchmark driver to the runtime.
2. How and *when* the selected worker process terminates (≈ 50 % of the fault-free runtime).
3. How the system resurrects the failed node and waits for it to re-join the cluster before the next benchmark begins.

---

## 1. Injecting a Fault – flag propagation

### 1.1 Benchmark driver adds the flag
The evaluation script appends `--kill {merger|regular}` to the PaSh command when it wants to inject a failure:
```115:129:evaluation/oneliners/run.sh
oneliners "dynamic-m"   "--width 8 ... --ft dynamic --kill merger"
oneliners "dynamic-r"   "--width 8 ... --ft dynamic --kill regular"
```

### 1.2 PaSh argument parsing
`pa.sh` forwards all CLI options into the global `config.pash_args` structure.  Nothing special happens here—the string `kill` is simply stored for later.

### 1.3 Worker-Manager receives the flag
When the distributed planner (`WorkerManager`) starts, it clones the parsed arguments:
```70:80:pash/compiler/dspash/worker_manager.py
self.args = copy.copy(config.pash_args)   # ← contains self.args.kill
```
It sends the value to every worker during the initial *Setup* RPC:
```83:91:pash/compiler/dspash/worker_manager.py
request_dict = {
    'type': 'Setup',
    ...
    'kill_target': self.args.kill  # "merger" or "regular"
}
```

### 1.4 Selecting which node to crash
The first time a job is partitioned, `WorkerManager` decides which physical node to terminate:
```300:322:pash/compiler/dspash/worker_manager.py
if self.args.kill == "merger":
    kill_target = merger_worker       # node running the merger subgraph
elif self.args.kill == "regular":
    kill_target = some_regular_worker # any node without the merger
...
kill_target.send_kill_node_request()  # RPC of type "Kill-Node"
```
A witness file (`kill_witness.log`) is written with the target’s IP so that we can resurrect it later.

## 2. Inside the worker – timing the crash
Each worker process keeps a small history of fault-free runtimes:
```25:30:pash/compiler/dspash/worker.py
self.last_exec_time_dict = {"": 5000}  # ms, updated after every successful run
```
When the *Kill-Node* RPC arrives the designated worker schedules a kill thread:
```180:200:pash/compiler/dspash/worker.py
if self.request['kill_delay']:
    delay = float(self.request['kill_delay'])/1000
else:
    delay = self.worker.last_exec_time_dict[self.script_name] / 2  # ≈50 %
Thread(target=self.kill, args=(delay,)).start()
```
`kill()` invokes `runtime/scripts/killall.sh`, killing the entire process tree (worker + HDFS datanode).  The node disappears from HDFS heart-beats, which triggers the fault-tolerance machinery on the coordinator side.

## 3. Failure detection & re-execution
An asynchronous daemon polls the NameNode every second:
```226:274:pash/compiler/dspash/hdfs_utils.py
new_state = get_active_node_addresses(...)
added = new_state - old_state
removed = old_state - new_state  # ← crashed node appears here
```
`addr_removed()` marks the worker offline and calls `handle_crash()` (or the naïve variant).  Sub-graphs that were in-flight on the crashed node are rescheduled on healthy nodes; already-persisted outputs are reused when possible.

## 4. Resurrection – bringing the node back
### 4.1 Benchmark driver triggers resurrection
After a job that included `--kill` finishes, the driver waits ten seconds and then executes:
```60:68:evaluation/oneliners/run.sh
python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
```
`notify_worker.py` reads the victim’s IP from `kill_witness.log` and sends a `{'type': 'resurrect'}` message to that worker process.

### 4.2 Worker restarts its services
Upon receiving the *resurrect* RPC the worker executes the helper script in “resurrect” mode:
```290:300:pash/compiler/dspash/worker.py
subprocess.run("$DISH_TOP/docker-hadoop/datanode/run.sh --resurrect", ...)
```
`docker-hadoop/datanode/run.sh --resurrect` (a) restarts the HDFS datanode process and (b) ensures that the PaSh worker threads are running again.

### 4.3 Cluster rejoins & readiness wait
1. Once the datanode starts sending heart-beats again, the HDFS poller calls `addr_added()`, marking the worker online.
2. The benchmark script sleeps another ten seconds to give the cluster time to stabilise.
3. The next benchmark (or the remainder of the current script when using loops) proceeds with the full set of nodes.

---

## 5. Summary – timeline
1. Evaluation script adds `--kill merger` / `--kill regular`.
2. Flag travels through PaSh → WorkerManager → worker *Setup*.
3. WorkerManager decides which node to crash and issues *Kill-Node*.
4. Target worker waits **½ · T_baseline** and kills itself.
5. HDFS heart-beat loss → WorkerManager reschedules unfinished work.
6. Evaluation driver calls **notify_worker resurrect**.
7. Worker restarts its datanode & worker services.
8. HDFS detects the node, WorkerManager marks it online, evaluation continues.

This flow provides deterministic, middle-of-execution fail-stop faults while keeping the evaluation scripts self-contained and fully automated. 