# frac – Lightweight Fault-Injection Filter for Unix Pipelines

`frac` lets you *inject faults on demand* into Unix pipelines or remote
nodes so you can observe how the rest of your system behaves under
failure.

The first scenario focuses on **command-level, single-node
faults**.  You can kill any streaming command after it has emitted *N*
bytes and immediately see the impact downstream.

```bash
cat in.txt | \
python -m frac byte-kill --bytes 500 --cmd "tr A-Z a-z" | \
grep 'regex' > out.txt
```

### How it works

```
 stdin ─┬──────────────────────────────┐
        │                              │ 8 KiB chunks (input thread)
        ▼                              │
     tr A-Z a-z        ← upstream cmd  │
        │ 1 byte at a time             │ monitor loop (main thread)
        ▼                              │
  frac-monitor  (LocalStreamingHooks)  │ counts bytes **out of `tr`**
        │                              │ fires kill after 500 bytes
        ▼                              ▼
     grep 'regex'     ← downstream cmd  
```

1. `frac` spawns `tr A-Z a-z` with pipes for stdin/stdout.
2. A background thread **feeds input** (8 KiB chunks) to `tr`.
3. The main thread **reads exactly 1 byte** at a time from
   `tr`’s stdout, counts it, forwards it to `grep`.
4. When the counter reaches the threshold (e.g. 500 bytes) the monitor
   sends `SIGTERM` to `tr`.
5. `grep` receives EOF after the 500-th byte and exits normally.

Because we count the bytes actually delivered *between* `tr` and `grep`,
we have byte-level precision with no buffering surprises.

### Quick start

```bash
# Inside this repo
pip install -e .   # or export PYTHONPATH to point to repo root

bash frac/examples/command-level/test.sh
```

Expected output (snippet):

```
[demo] Found 5 matches
[demo] Ground truth (500 bytes): 5 matches
✅ SUCCESS: Fault injection matches 500-byte ground truth!
```

### CLI synopsis

```
frac byte-kill --bytes N --cmd "CMD …"                 # local fail-stop
frac inject     --node ID --event delay --ms 30000     # remote (plugin)
frac resurrect  --node ID                              # bring a remote node back
```

### Extending to multi-node faults

Copy `frac/skeleton.py`, implement your own `Node`, `RuntimeHooks`, and
`Frac` classes.  The same CLI (`frac inject …`) will work, now targeting
remote workers instead of local commands.

### Design philosophy – keep the core generic

`frac` purposely separates *how to trigger a fault* (the **event**) from
*how to carry it out* (the **node implementation**):

1. **Thin core** – The built-in code only understands byte/time/token
   events and how to call `Node.kill()` / `Node.resurrect()`.  It has **no
   knowledge of your cluster, scheduler, or network layout**.
2. **User plugins** – You write a tiny Python module (see
   `frac/skeleton.py`) that turns whatever *identifies* a worker in *your*
   world into a concrete `Node` object.  That may be an IP address, a
   hostname, a Kubernetes Pod name, a Docker container ID, or even an MPI
   rank.
3. **Opaque `--node` flag** – Because of (2) the CLI treats the argument
   after `--node` as an **opaque string**.  If you *want* to pass a raw
   IP you can:

   ```bash
   frac inject --node 10.1.2.3 --event delay --ms 30000
   ```

   A different deployment might instead run:

   ```bash
   frac inject --node worker-7 --event bytes --bytes 1000000
   ```

   Both commands use the same public interface; only the plugin’s
   `create_node()` function decides what the string means.

This layered design keeps the **core** tiny and reusable while giving you
full freedom to define what a *node* is in your environment.

---
© 2024 The Fractal Project – MIT License 