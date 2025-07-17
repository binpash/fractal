# Distributed File Reader (DFS Split Reader)

FRACTAL executes scripts over HDFS and therefore needs a way to read *logical
splits* (map-style partitions) directly from the local DataNode without
incurring `hdfs dfs -get` overheads.  The **DFS Split Reader** provides this
capability.

*Relevant sources*
- `client/dfs_split_reader.go` – thin CLI wrapper used by shell scripts.
- `server/` – gRPC service running on every executor node.
- `proto/` – protobuf definitions and generated code.
- `scripts/dfs_split_reader.sh` – convenience wrapper leveraged by PaSh-generated shell code.

## Protocol
1. The client sends `(filePath, splitIdx, splitSize)`.
2. The server mmap’s the HDFS block file (files are exposed via host bind-mount)
   and streams exactly `splitSize` bytes starting at `splitIdx*splitSize`.
3. A terminating Remote-Pipe sentinel is appended so downstream can merge.