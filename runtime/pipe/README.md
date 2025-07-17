# FRACTAL Remote Pipe

FRACTAL’s Remote Pipe is a distributed, exactly-once replacement for the familiar Unix FIFO.
It connects a *writer* (source subgraph) with a *reader* (destination subgraph) even when the
two run on different nodes and might be re-scheduled after failures.

## Modes of Operation
1. **Transient (socket) mode** – low latency; used on the common fault-free path.
2. **Persistent (file) mode** – the writer streams into an on-node temporary file so that a
   re-scheduled reader can pick up already-produced bytes with no recomputation.
   FRACTAL switches to this mode dynamically when its *dynamic-persistence policy* decides
   that replay would be more expensive than I/O.

The two ends are paired by the Discovery service (§ below) via a *globally unique* 128-bit
EdgeID.  The writer advertises either a TCP endpoint (`ip:port`) or a file path, and the
reader polls Discovery until the metadata appears.  Because the reader keeps track of the
*byte offset already forwarded downstream*, duplicate data is silently discarded when a
writer reconnects after a failure – thus preserving exactly-once semantics.

## Data Stream Format
Every Remote Pipe appends an 8-byte EOF sentinel `0xd1d2d3d4d5d6d7d8` (see
`runtime/pipe/datastream/datastream.go:34`) so that the reader can recognise stream
completion without blocking indefinitely.  The value is fixed at build time and treated as
opaque; payload bytes that collide would be escaped by the writer, making the token effectively unique in the stream.

## Buffered I/O Algorithm
Implementation: `runtime/pipe/datastream/datastream.go` (see read loop lines ≈120-156).
Remote-pipe readers keep an 8-byte look-ahead buffer; on each iteration they:
1. Fill the remainder of a 4 KiB buffer from the socket/file.
2. Forward everything except the trailing 8 bytes.
3. Compare those 8 bytes to the sentinel; if equal → stream done, else slide them to the buffer head and continue.
This costs at most 8 bytes of copying per chunk and zero heap allocations.

## Directory layout
* `datastream/` – gRPC client/server & buffered-I/O implementation
* `discovery/`  – lightweight key-value service for endpoint exchange
* `proto/`      – generated code

## Relation to Paper (Fig. 3)
This directory implements Fig. 3-A2 (remote-pipe instrumentation) and produces the completion events consumed by Fig. 3-A5 Progress Monitor.
