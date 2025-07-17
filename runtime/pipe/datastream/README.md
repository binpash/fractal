# Datastream (Buffered I/O) Implementation

This sub-directory houses the low-level I/O machinery backing FRACTAL’s Remote Pipe.
It is **performance-critical** because every byte that flows between subgraphs crosses
this code‐path.

*Main file*: `datastream.go`

## Responsibilities
1. Efficiently splice bytes between the network/file descriptor and the downstream pipe.
2. Detect and strip the 8-byte EOF sentinel appended by writers.
3. Emit 17-byte completion events (EdgeID + dir-flag) once the stream is fully consumed.
4. Offer a *single* public API:  
   `func Read(ctx, edgeID, offset, writerMeta) (io.Reader, error)`  
   `func Write(ctx, edgeID) (io.WriteCloser, error)`

## Buffered-I/O Algorithm
See §5.2 of the paper and implementation in `datastream.go`:
* Socket mode: lines ≈120-156 (`read()`)
* File-backed mode: lines ≈170-212 (`readOptimized()`)
Both variants maintain an 8-byte look-ahead and perform at most one tiny copy per chunk.

## Edge IDs & Offset Accounting
* Edge IDs are 128-bit, hex-encoded strings.
* The reader keeps `offset` in bytes and skips duplicates after reconnect.

## Relation to Paper
Implements the Fig. 3 “Buffered-IO” optimisation (paper §5). 