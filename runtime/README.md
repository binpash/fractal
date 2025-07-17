# GRPC File Reader Service

## Executor Runtime, Progress & Health Monitoring

FRACTAL’s *executor runtime* (`pash/compiler/dspash/worker.py`) lives one level
up in the container hierarchy but is tightly coupled with the Go services in
`runtime/`. This section ties together runtime Go code (Remote Pipes, DFS reader) with the
Python scheduler and corresponds to B1–B4 in Fig. 3 of the paper.

## Components
-  Server: Accepts read requests and forwards local files to caller

- Client: The `dfs_split_reader` client takes in a path for a config file (containing file blocks and their hosts) and a split number determining the logical split to read.

### Config File 
The config file looks as follows
```
Config {
    Blocks : Array[Block]
}

Block {
    Path : str
    Hosts : Array[str] (e.g 127.0.0.1)
}
```

Read more [here](https://tammammustafa.notion.site/HDFS-newline-ff2aabde3f9e45c0914760c24f164154)