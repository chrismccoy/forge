# ERLANG facts
Covers: Erlang/OTP (gen_server, gen_statem, ETS, Mnesia, global), distributed Erlang clustering, rebar3 and relx releases, escripts, Cowboy and ranch
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Distribution and security

### ER-01 An open distribution port is remote code execution
- Trap: The cookie secures the cluster, so epmd and distribution ports can be reachable from the network.
- Reality: Starting a distributed node without `-proto_dist inet_tls` "will expose the node to attacks that may give the attacker complete access to the node and by extension the cluster". The cookie is not a cryptographic handshake and traffic is clear text by default. epmd listens on 4369; the node listener uses `inet_dist_listen_min/max`.
- Detect: "cookie-based auth", distribution over the public internet or shared networks, no firewall rules for 4369 or the distribution port range.
- Fix: Keep distribution on a private network with firewalled ports, use TLS distribution across untrusted links, and generate a long random cookie.
- Source: Distributed Erlang (Security) - https://www.erlang.org/doc/system/distributed.html ; epmd - https://www.erlang.org/doc/apps/erts/epmd_cmd.html

### ER-02 Netsplits are slow to detect and resolve destructively
- Trap: Node failure is detected immediately, and global names stay unique through partitions.
- Reality: With the default net_ticktime of 60 s, an unresponsive node is detected after 45 to 75 s. On reconnect, `global` resolves name clashes with `random_exit_name` by default, which kills one of the processes. Since OTP 25, global disconnects nodes to prevent overlapping partitions. Clusters are fully meshed by default.
- Detect: "global registry guarantees a single leader", failover SLAs under 45 s built on node monitoring, large full-mesh clusters.
- Fix: Tune net_ticktime to the SLA, pick a clash resolver on purpose, and keep singleton state in a store that tolerates partitions.
- Source: kernel (net_ticktime) - https://www.erlang.org/doc/apps/kernel/kernel_app.html ; global - https://www.erlang.org/doc/apps/kernel/global.html

### ER-03 Mnesia does not heal partitions
- Trap: Replicated Mnesia tables reconcile after a netsplit.
- Reality: Mnesia raises `{inconsistent_database, running_partitioned_network, Node}` and the default handler only logs it. Choosing which data to keep "is outside the scope of Mnesia"; the application must decide, for example with `mnesia:set_master_nodes/2` and restarts.
- Detect: multi-node Mnesia with no partition-handling section, "Mnesia replicates automatically".
- Fix: Subscribe to Mnesia system events and document a recovery procedure, or use a store with defined partition behavior.
- Source: Mnesia System Information (Recovery from Communication Failure) - https://www.erlang.org/doc/apps/mnesia/mnesia_chap7.html

## Processes and state

### ER-04 Mailboxes grow without back-pressure
- Trap: A single gen_server can absorb any rate of casts or messages.
- Reality: Sending is asynchronous: the message is inserted into the receiver's queue and the sender carries on, so a slow receiver's queue and memory grow. Selective receive walks the whole queue when nothing matches, which gets expensive as queues grow.
- Detect: fire-and-forget casts into one process on a hot path, one gen_server per shared resource with no load shedding.
- Fix: Use calls or demand-based flow (gen_stage, pools) for back-pressure, shard hot processes, and monitor message_queue_len.
- Source: Processes (Signals) - https://www.erlang.org/doc/system/ref_man_processes.html ; A few notes on message passing - https://www.erlang.org/blog/message-passing/

### ER-05 gen_server:call times out after 5 s and kills the caller
- Trap: Calls wait as long as needed.
- Reality: `call/2` uses a 5000 ms timeout. On timeout the calling process exits with `timeout`. Since OTP 24 late replies no longer reach the caller. A gen_server handles one request at a time.
- Detect: slow I/O inside handle_call, long computations behind one registered server, no timeout strategy.
- Fix: Set explicit timeouts, move slow work out of the server (spawned worker, reply later with `gen_server:reply/2`), or shard.
- Source: gen_server - https://www.erlang.org/doc/apps/stdlib/gen_server.html

### ER-06 ETS tables die with their owner
- Trap: An ETS table is a shared cache that outlives crashes and is visible cluster-wide.
- Reality: A table is destroyed when its owner process terminates unless an `heir` is set or ownership is given away. Tables are node-local, and the default access is `protected` (only the owner writes).
- Detect: tables created in short-lived or crash-prone processes, "shared ETS cache across nodes", writes from other processes to a default table.
- Fix: Create tables in a supervised, minimal owner process (or set an heir), use `public` access where needed, and replicate across nodes separately.
- Source: ets - https://www.erlang.org/doc/apps/stdlib/ets.html

### ER-07 Atoms are never garbage-collected
- Trap: Convert JSON keys or user input to atoms for convenience.
- Reality: The atom table has a default limit of 1,048,576 entries (`+t`) and atoms are not garbage-collected; exhausting it crashes the node.
- Detect: `list_to_atom`/`binary_to_atom` on external input, JSON decoders set to atom keys.
- Fix: Keep external keys as binaries or use `binary_to_existing_atom/2`.
- Source: System Limits - https://www.erlang.org/doc/system/system_limits.html

## Releases and deploy

### ER-08 Hot code loading has sharp limits
- Trap: Load new code at any time and running processes keep working.
- Reality: Only two versions of a module (current and old) can exist; loading a third purges the old one and kills processes still running it. Processes switch only on fully qualified calls. Relups need appups, `code_change` state transforms and careful ordering.
- Detect: "hot upgrades for every deploy" in containers or Kubernetes, no appup/relup plan.
- Fix: Prefer rolling restarts; if relups are required, budget for appup authoring and upgrade testing.
- Source: Compilation and Code Loading - https://www.erlang.org/doc/system/code_loading.html ; Release Handling - https://www.erlang.org/doc/system/release_handling.html

### ER-09 Runtime config needs .src templates
- Trap: `sys.config` reads environment variables at startup.
- Reality: relx substitutes `${VAR}` at runtime only in `sys.config.src` and `vm.args.src` (defaults with `${VAR:-DEFAULT}` on OTP 21+). A release with `include_erts` bundles the build host's ERTS; targeting another system needs an ERTS path and `system_libs`.
- Detect: secrets baked into sys.config, releases built on macOS for Linux containers.
- Fix: Use sys.config.src/vm.args.src for environment values and build the release in the target image.
- Source: Releases (rebar3) - https://rebar3.org/docs/deployment/releases/

## HTTP (Cowboy)

### ER-10 read_body returns only part of large bodies
- Trap: One `cowboy_req:read_body/1` call returns the whole request body.
- Reality: By default it reads up to 8 MB or for 15 s, then returns `{more, Data, Req}`. The body is not cached and can be read only once.
- Detect: uploads or large JSON with a single read_body match on `{ok, ...}`, middleware and handler both reading the body.
- Fix: Loop on `{more, ...}` or set `length`/`period`, and enforce a maximum size.
- Source: Reading the request body - https://ninenines.eu/docs/en/cowboy/2.17/guide/req_body/

### ER-11 WebSocket timeouts and frame limits
- Trap: Cowboy keeps idle WebSockets open and sends pings.
- Reality: `idle_timeout` defaults to 60000 ms and Cowboy does not send pings itself. `max_frame_size` defaulted to infinity up to Cowboy 2.16; 2.17+ defaults to 1 MB.
- Detect: long-idle subscriptions with no client ping, no frame size limit on Cowboy 2.16 or older.
- Fix: Send client pings under the idle timeout and set `max_frame_size` explicitly.
- Source: Websocket handlers - https://ninenines.eu/docs/en/cowboy/2.17/guide/ws_handlers/
