# Fractal: Fault-Tolerant Shell-Script Distribution

> **Meta-header** – Fractal is integrated into the `dish` codebase. The implementation you see here matches the artifact submitted for NSDI’26.

---

## 1  What is Fractal?
Fractal executes *unmodified* POSIX shell scripts across a cluster **and** recovers automatically from node failures.  It leverages PaSh-JIT to build a data-flow graph (DFG), inserts Remote Pipes for exactly-once delivery, and re-runs only the fragments affected by a fault using byte-level progress metadata.

Key points:
• No script changes – full shell semantics.  
• Exactly-once via Remote Pipe & replay suppression.  
• Per-subgraph *dynamic* decision to persist or just stream.  
• Millisecond-scale re-scheduling driven by HDFS heartbeats + 17-byte events.

---

## 2  Quick Installation
> ⏳ Placeholder for now, to be confirmed!
Single-host demo (Docker Compose, tested on Linux):
```bash
# Clone with submodule so PaSh code is present
$ git clone --recurse-submodules https://github.com/binpash/dish.git -b nsdi26-ae
$ cd dish/docker-hadoop
# Spin up 1 namenode, 1 datanode, 1 client container
$ ./setup-compose.sh
```
Tear-down: `./stop-compose.sh` (add `-v` to prune volumes).

---

## 3  Running Fractal
> ⏳ Placeholder for now, to be confirmed!

Inside the client container:
```bash
# put a sample file in HDFS
hdfs dfs -put /etc/hosts /hosts
# Execute a tiny script with fault tolerance on (dynamic persistence)
cd /opt/dish
./di.sh --ft dynamic scripts/sample.sh   # output identical to bash
```
Inject a fail-stop fault: `./di.sh --ft dynamic --kill regular scripts/sample.sh`.

---

## 4  Repository Structure & Architecture
| Path | Purpose |
|------|---------|
| `pash/` | PaSh submodule – compiler & JIT groundwork |
| `runtime/` | Remote Pipe, DFS reader, Go libs |
| `pash/compiler/dspash/` | Fractal scheduler, executor, health/progress monitors |
| `docker-hadoop/` | Local / CloudLab cluster bootstrap |
| `evaluation/` | Benchmarks & fault-injection scripts |
| `scripts/` | Misc helper scripts |

![Fractal architecture](ae-data/tech-outline.pdf)

*Fig. 3 — FRACTAL architecture (paper).*  A1–A6 annotate control-plane stages; B1-4 run on each executor.

### Fig. 3 Component Cheat-Sheet

| Label | Role in the system | Key code locations |
|-------|--------------------|--------------------|
| **A1** | DFG augmentation & isolation of the *unsafe-main* subgraph | `pash/compiler/dspash/ir_helper.py::prepare_graph_for_remote_exec` |
| **A2** | Remote Pipe instrumentation – injects read/write nodes that track byte offsets | `definitions/ir/nodes/remote_pipe.py`, `runtime/pipe/` |
| **A3** | Dynamic output persistence – heuristic chooses spill-to-disk vs. stream | `pash/compiler/dspash/add_singular_flags`, `worker_manager.py::check_persisted_discovery`, `runtime/pipe/datastream/writeOptimized()` |
| **A4** | Scheduler & batched dispatch of subgraphs to executors | `pash/compiler/dspash/worker_manager.py` |
| **A5** | Progress monitor + Discovery: 17-byte completion events & endpoint registry | `runtime/pipe/discovery/`, `runtime/pipe/datastream/datastream.go` (EmitCompletion) |
| **A6** | Health monitor – polls HDFS Namenode JMX and flags slow/failed nodes | `pash/compiler/dspash/hdfs_utils.py` |
| **B1** | Executor event loop – non-blocking, launches subgraphs | `pash/compiler/dspash/worker.py::EventLoop` |
| **B2** | Remote Pipe data path within executor (socket/file, buffered I/O) | `runtime/pipe/datastream/datastream.go` |
| **B3** | Distributed File Reader – streams HDFS splits locally | `runtime/dfs/` |
| **B4** | On-node cache of persisted outputs; avoids re-computation after faults | `writeOptimized()` spill files under `$FISH_OUT_PREFIX`

---

## 5  Community & More
Chat: [Discord](http://join.binpa.sh/) •  GitHub issues welcome.  

---

## 6  Citing
Fractal has been incorporated into an earlier system **DiSh**;
> ⏳ Placeholder for now, to be confirmed!

```bibtex
@inproceedings{fractal2026nsdi,
  booktitle = {USENIX NSDI '26},
  year      = {2026},
  note      = {Conditionally accepted.  DOI & pages TBD}
}

@inproceedings{dish2023nsdi,
  author    = {Mustafa, Tammam and Kallas, Konstantinos and Das, Pratyush and Vasilakis, Nikos},
  title     = {{DiSh}: Dynamic {Shell-Script} Distribution},
  booktitle = {USENIX NSDI '23},
  pages     = {341--356}
}
```
