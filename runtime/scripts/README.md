# Runtime Helper Scripts

This directory glues FRACTAL’s Go back-end to ordinary shell execution.  All
scripts are POSIX-compatible and intentionally dependency-free so they can run
inside slim Debian images.

| Script | Purpose | Referenced From |
|--------|---------|-----------------|
| `remote_read.sh`  | Spawn the DFS Split Reader client and pipe its stdout to the subgraph’s stdin. | auto-generated subgraph scripts |
| `remote_write.sh` | Forward stdout to a Remote Pipe writer, switching to file-mode if `FRACTAL_FT=dynamic`. | auto-generated subgraph scripts |
| `dfs_split_reader.sh` | Convenience wrapper around `runtime/dfs/client/...`. | auto-generated subgraph scripts |
| `killall.sh` | Terminates an entire process-tree given a PID – used by the coordinator when re-scheduling. | `worker_manager.py` |
| `build.sh` | Builds all Go binaries into `/opt/dish/bin` during image build. | Dockerfiles |

## Environment Variables
* `EDGE_ID` – 128-bit hex string identifying the producer–consumer edge.
* `FRACTAL_FT` – `off`, `persistent`, or `dynamic` (default: `dynamic`).
* `BUF_SIZE` – Override the 4096-byte default buffer.

## Failure Handling
`remote_read.sh` and `remote_write.sh` simply exec the compiled `datastream` binary and
return *its* exit status.  Any non-zero value is treated by the Fig. 3-A5 Progress
Monitor as a failed edge and triggers re-execution logic upstream.
 