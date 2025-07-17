# Overview  
The paper makes the following claims requiring artifact evaluation on page 2 (Comments to AEC reviewers are after `:`):  

1. **Execution engine**:  FRACTAL's light-weight instrumentation, progress and health monitors, and the executor runtime work together to offer efficient and precise recovery.  
2. **Performance optimizations**: FRACTAL's critical-path components that reduces runtime overhead, including an *event-driven executor design*, *buffered-io sentinel striping*, and *batched scheduling*.  
3. **Fault injection**:  an internal subsystem, *frac*, that enables precise, large-scale characterization of fault recovery behaviors.  
 

This artifact targets the following badges (mirroring [the NSDI26 artifact "evaluation process"](https://www.usenix.org/conference/nsdi26/call-for-artifacts)):  

* [ ] [Artifact available](#artifact-available): Reviewers are expected to confirm public availability of core components (XX minutes)  
* [ ] [Artifact functional](#artifact-functional): Reviewers are expected to verify distributed execution workflow (YY minutes)  
* [ ] [Results reproducible](#results-reproducible): Reviewers are expected to reproduce key fault tolerance metrics (ZZ hours)  
 

<a id="artifact-available"></a>  
# Artifact Available (XX minutes)  
Confirm core components are publicly available.  
 
The implementation described in the NSDI26 paper (FRACTAL) has been incorporated into DiSh, MIT-licensed open-source software. It is part of the PaSh project, hosted by the [Linux Foundation](https://www.linuxfoundation.org/press/press-release/linux-foundation-to-host-the-pash-project-accelerating-shell-scripting-with-automated-parallelization-for-industrial-use-cases). Below are some relevant links:  

- FRACTAL is permanently hosted on the GitHub [binpash](https://github.com/binpash/) organization.  
- FRACTAL's command annotations conform to the format outlined in [PaSh](https://github.com/binpash/pash), a MIT-licensed open-source software.  
- We have a publicly-accessible discord Server ([Invite](http://join.binpa.sh/)) for troubleshooting and feedback.  
 
 

<a id="artifact-functional"></a>  
# Artifact Functional (YY minutes)  

Confirm sufficient documentation, key components as described in the paper, and execution with min inputs (about 20 minutes).  

## Documentation

For developer-focused instructions (e.g.
adding benchmark suites or rebuilding cluster workers) see
[CONTRIBUTING.md](CONTRIBUTING.md).

## Completeness
Fig. 3 of the paper gives an overview of the interaction among different components. Below we map every component to the source code in this repository.

- **Execution engine (§4)**
  - *DFG construction & fault-aware partitioning*: FRACTAL reuses the PaSh-JIT front-end to parse the user script and consult the JSON annotation corpus in `pash/annotations/`.  We then extend that pipeline in
    • `pash/compiler/dspash/ir_helper.py` – `prepare_graph_for_remote_exec`, `split_main_graph`, `add_singular_flags` (edge IDs, remote-pipe vertices, singular tagging, subgraph carving).  
    • `pash/compiler/dspash/worker_manager.py` – subgraph-to-node mapping, dependency tracking, selective re-execution.
  - *Remote pipe* & *Dynamic output persistence*: FRACTAL decides at run time, **per sub-graph**, whether to spill a stream to disk.  The choice is encoded via the `--ft dynamic` flag and a `-s` (singular) tag in each `RemotePipe`.  If dynamic FT is on and the subgraph is not singular, `datastream.go::writeOptimized()` writes to a spill-file whose path is registered in Discovery.  Upon a fault `worker_manager.check_persisted_discovery()` queries Discovery and re-executes only the subgraphs whose outputs were not already persisted.
  - *Executor runtime* & *Progress/Health monitors*: each node runs `pash/compiler/dspash/worker.py` where `EventLoop` launches up to *N* subgraphs and `TimeRecorder` logs execution.  Completion of every send/receive emits a 17-byte event (bottom of `datastream.go`) that `worker_manager.py::__manage_connection` consumes.  Cluster liveness comes from JMX polling in `pash/compiler/dspash/hdfs_utils.py` with callbacks wired into the scheduler.

- **Performance optimizations (§5)**
  - *Event-driven architecture*: `EventLoop` in `worker.py` is lock-free (list ops + atomics) and polls every 0.1 s – precisely the design described in §5.1.
  - *Buffered-IO sentinel stripping*: the 8-byte EOF token is removed on-the-fly inside `datastream.go::read` (≈ 70-130) using a single 4096-byte buffer, matching §5.2.
  - *Batched scheduling*: `worker_manager.py` builds `worker_to_batches` and issues one `Batch-Exec-Graph` RPC per worker, implementing the optimisation in §5.3.

- **Fault injection (§6)**
  - *frac subsystem*: the coordinator exposes `--kill` knobs handled in `worker_manager.py::handle_kill_node`; helpers in `runtime/scripts/killall.sh` terminate full process trees.  Evaluation scripts drive these hooks to reproduce the fault-tolerance experiments of §6.

Together these files (and the PaSh-JIT submodule they build upon) cover every component shown in Fig. 3, demonstrating that the released code fully realises the design presented in the paper.

## Exercisability
### Pre-requisites
1. Set up cloudlab account and have reserved a cluster (note: this will be done by the time ae is submitted)

🚧 YZ: Do we expect users to run the following setup commands in a specific env, e.g., provided docker image? If not, add commands to install dependencies, e.g., installing `clush` using `pip` on MacOS. 

### Set up cloudlab cluster swarm
1. Create a file at `docker-hadoop/manifest.xml` for pasting the cluster manifest from cloudlab
2. Run `cd docker-hadoop`
3. Run `./prepare-cloudlab-notes.sh manifest.xml [cloudlab-username]` (🚧 YZ: 14:08.12 mins)
4. Now all the hostnames in the cluster are in `hostnames.txt` with the first entry being the manager node.
5. Now ssh into that node with something like `ssh [username]@$(head -n 1 hostnames.txt)` (🚧 YZ: explicitly say the first ip in the hostnames.txt?)
6. Run `cd dish/docker-hadoop`
7. Run `sudo ./start-client.sh --eval` where client is `nodemanager`
8. Run `docker exec -it docker-hadoop-client-1 bash` to get inside the client node's container.

### Shutdown
1. Run `sudo docker compose -f docker-compose-client.yml down` to shutdown the client docker image
2. Run `./stop-swarm`
3. Run `docker swarm leave -force`



*(Developer note moved to CONTRIBUTING.md)*

<a id="results-reproducible"></a>  
# Results Reproducible (ZZ minutes)
The key results in this paper's evaluation section are the following:
1. *Fault recovery execution*: FRACTAL provides *correct* and *efficient* recovery
2. *Fault-free execution*: FRACTAL also delivers near state-of-the-art performance in failure-free executions (§6.1, Fig. 4).
3. [Not urgent, nice to have] *Dynamic output persistence*: it demonstrates a subtle balance between accelerated fault recovery and overhead in fault-free execution (§6.3, Fig. 8).

    ⏳ TODO

## [Optional] Hard faults
As shown at the bottom of page 10,

    ⏳ TODO

<a id="meta-documentation"></a>
# Meta-Documentation: Navigating the FRACTAL Codebase

The table below maps the high-level blocks from Fig. 3 of the paper to concrete
code directories and their respective README files.  Reviewers can skim the
first column to decide which internals they wish to dive into.

| Paper Label | Functionality | Source Directory | Detailed README |
|-------------|---------------|------------------|-----------------|
| A1          | DFG augmentation, unsafe-main splitting | `pash/compiler/dspash/ir_helper.py` | [dspash README](pash/compiler/dspash/README.md) |
| A2          | Remote Pipe instrumentation | `runtime/pipe/` | [Remote Pipe](runtime/pipe/README.md) |
| A3          | Dynamic output persistence | `pash/compiler/dspash/worker_manager.py` | [dspash README](pash/compiler/dspash/README.md) |
| A4          | Scheduler & batched dispatch | `pash/compiler/dspash/worker_manager.py` | same |
| A5          | Progress monitor & Discovery | `runtime/pipe/discovery/` | [Discovery README](runtime/pipe/discovery/README.md) |
| A6          | Health monitor | `pash/compiler/dspash/hdfs_utils.py` | [dspash README](pash/compiler/dspash/README.md) |
| B1-4        | Executor event loop & IPC | `pash/compiler/dspash/worker.py` | same |

Minimum reading path (≈15 min): top-level [README](README.md) → Remote Pipe →
dspash.

Full deep dive (≈45-60 min): follow the table left-to-right.

For running the evaluation scripts refer to `evaluation/README.md`; for fault
injection see `runtime/scripts/README.md` and the upcoming `frac` tool docs.
