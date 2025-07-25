# Fractal: Fault-Tolerant Shell-Script Distribution
[Overview](#overview) | [Quick Setup](#quick-setup) | [More Info](#more-information) | [Structure](#repository-structure) | [Community](#community-and-more) | [Citing](#citing-fractal) | [License & Contributions](#license-and-contributing)

> For issues and ideas, email [fractal@brown.edu](mailto:fractal@brown.edu) or, better, [open a GitHub issue](https://github.com/binpash/fractal/issues/new/choose).
>

Fractal executes unmodified POSIX shell scripts across a cluster and recovers automatically from node failures.
It bolts failre tolerance on top of DiSh, a state-of-the-art shell-script distribution system, and is described in an upcoming [NSDI'26](https://www.usenix.org/conference/nsdi26) [paper](#citing-fractal).

## Overview:

Fractal is an open source, MIT-licensed system that offers fault-tolerant distributed execution of unmodified shell scripts. 
It first identifies recoverable regions from side-effectful ones, and augments them with additional runtime support aimed at fault recovery.
It employs precise dependency and progress tracking at the subgraph level to offer sound and efficient fault recovery.
It minimizes the number of upstream regions that are re-executed during recovery and ensures exactly-once semantics upon recovery for downstream regions. 
Fractal's fault-free performance is comparable to state-of-the-art failure-intolerant distributed shell-script execution engines, while in cases of failures it recoveres 7.8–16.4× compared to Hadoop Streaming.

At a glance:
- [x] No script changes – full POSIX shell semantics.  
- [x] Exactly-once semantics via remote pipes and replay suppression.  
- [x] Per-subgraph dynamic decision to persist or stream data
- [x] Millisecond-scale re-scheduling driven by HDFS heartbeats + 17-byte events.

## Quick Setup
To quickly set up Fractal on a single host (Docker Compose, tested on Linux):

```bash
# Clone with submodule so PaSh code is present
$ git clone --recurse-submodules https://github.com/binpash/dish.git
$ cd dish/docker-hadoop
# Spin up 1 namenode, 1 datanode, 1 client container
$ ./setup-compose.sh
```

To tear Fractal down: `./stop-compose.sh` (add `-v` to prune volumes).

## More Information

After installing fractal, run it inside the client container:

```bash
# put a sample file in HDFS
hdfs dfs -put /etc/hosts /hosts
# Execute a tiny script with fault tolerance on (dynamic persistence)
cd /opt/dish
./di.sh --ft dynamic scripts/sample.sh   # output identical to bash
```
Inject a fail-stop fault: `./di.sh --ft dynamic --kill regular scripts/sample.sh`.


## Repository Structure

Here are the key components of the Fractal repository:

* [`pash/`](pash/): PaSh submodule – compiler & JIT groundwork
* [`runtime/`](runtime/): Remote Pipe, DFS reader, Go libraries
* [`pash/compiler/dspash/`](pash/compiler/dspash/): Fractal scheduler, executor, along with health and progress monitors
* [`docker-hadoop/`](docker-hadoop/): Local and CloudLab cluster bootstrap
* [`evaluation/`](evaluation/): Benchmarks & fault-injection scripts
* [`scripts/`](scripts/): Miscallencous helper scripts

**Detailed system architecture:** The figure below describes Fractal's key components. A1–A6 annotate control-plane stages; B1-4 run on each executor.

![Fractal architecture](ae-data/tech-outline.png)


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

## Community and More

Fractal is a member of the PaSh family of systems, availabile by the [Linux Foundation](). Please join the community:

* Chat: [Discord](http://join.binpa.sh/) 
* Email: [fractal@brown.edu](mailto:fractal@brown.edu) 
* Issues: [Open a GitHub issue](https://github.com/binpash/fractal/issues/new/choose)

## Citing Fractal

Fractal is backed up by state-of-the-art research—if you are using it to accelerate your processing, consider citing the following paper:

```bibtex
@inproceedings{fractal:nsdi:2026,
 author = {Zhicheng Huang and Ramiz Dundar and Yizheng Xie and Konstantinos Kallas and Nikos Vasilakis},
 title = {Fractal: Fault-Tolerant Shell-Script Distribution},
 booktitle = {23rd USENIX Symposium on Networked Systems Design and Implementation (NSDI 26)},
 year = {2026},
 address = {Renton, WA},
 publisher = {USENIX Association},
 month = may
}
```

Fractal has been incorporated into an earlier fault-intolerant dstributed system called DiSh:

```bibtex
@inproceedings{dish:nsdi:2023,
 author = {Tammam Mustafa and Konstantinos Kallas and Pratyush Das and Nikos Vasilakis},
 title = {{DiSh}: Dynamic {Shell-Script} Distribution},
 booktitle = {20th USENIX Symposium on Networked Systems Design and Implementation (NSDI 23)},
 year = {2023},
 isbn = {978-1-939133-33-5},
 address = {Boston, MA},
 pages = {341--356},
 url = {https://www.usenix.org/conference/nsdi23/presentation/mustafa},
 publisher = {USENIX Association},
 month = apr
}
```

## License & Contributions

Fractal is an open-source, collaborative, [MIT-licensed](https://github.com/atlas-brown/slowpoke/blob/main/LICENSE) project available by the Linux Foundation and developed by researchers at [Brown University](XXX) and [UCLA](XXX). If you'd like to contribute, please see the [`CONTRIBUTING.md`](XXX) file—we welcome contributions! And _please come talk to us_ if you're looking to optimize shell programs!
