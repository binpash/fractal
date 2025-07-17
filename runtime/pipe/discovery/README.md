# Discovery Service

The Discovery sub-package exposes a minimal gRPC key-value service that allows
Remote-Pipe endpoints to *find each other* after (re)scheduling.

*File*: `discovery_server.go`

## API
```
Put(edgeID string, meta *Endpoint)   // Writer publishes its socket OR file path
Get(edgeID string) (*Endpoint, err)  // Reader polls until available
```
`Endpoint` is defined in `proto/data_stream.proto` and encodes its data in the single `Addr` string:
• Transient mode: `Addr = "ip:port"`
• Persistent mode: `Addr = "ip,absoluteFilePath"` (comma-separated host and path)

## Consistency Guarantees
1. *At-most-once* registration: Writers call `Put` exactly once per execution attempt.
2. *Monotonic* updates: If the writer is rescheduled it overwrites the previous value.
3. *Eventually consistent* reads: Readers retry with back-off until a value appears.

## Interaction with Progress Monitor
After completing a send/receive the subgraph emits the 17-byte completion record to
the Progress Monitor.  The monitor garbage-collects discovery entries once **both**
directions have completed.

## Deployment
• Runs embedded inside every executor node (local unix-socket).  
• Coordinator queries remote nodes over SSH-tunnels when necessary.

## Relation to Paper (Fig. 3)
Implements the *Discovery* part of A5 and backs Remote Pipe reconnection logic (A2). 