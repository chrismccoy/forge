# C Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. HushDNS — recursive DNS resolver

```text
APP_DESCRIPTION: A recursive DNS resolver daemon for edge networks that answers A/AAAA/MX/TXT queries with aggressive negative caching and DNSSEC validation. It manages an in-memory record cache, upstream forwarder pools, and per-client rate buckets, and exposes a control socket for cache flush and stats.
TECH_STACK: C11 + epoll + raw UDP/TCP sockets + OpenSSL for DNSSEC + custom LRU cache + systemd, built with CMake on Linux
APP_TYPE: API service
LANGUAGE: C
SCALE: ~120,000 queries/sec, 2M cached records, sub-millisecond p99 for cache hits
```

## 2. corevault — encrypted file store CLI

```text
APP_DESCRIPTION: A command-line encrypted blob store for backups and secrets on a single host. It chunks input files, deduplicates by content hash, encrypts chunks with AES-256-GCM, and packs them into append-only pack files with an index for fast random restore.
TECH_STACK: C17 + OpenSSL (AES-GCM) + zlib + mmap index + POSIX file APIs, distributed as a static Make-built binary
APP_TYPE: CLI
LANGUAGE: C
SCALE: single host, up to 500 GB of packs, ~2 GB/s hashing on modern CPU
```

## 3. PitWire — CAN-bus telemetry pipeline

```text
APP_DESCRIPTION: A trackside data pipeline that ingests raw CAN-bus frames from a motorsport data logger, decodes signals against a DBC definition, time-aligns channels, and writes columnar session files for later analysis. It handles frame reordering and gap detection across multiple bus segments.
TECH_STACK: C11 + SocketCAN + custom DBC parser + mmap ring buffers + columnar binary output, cross-compiled for an ARM logger board
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 3 CAN segments at ~8,000 frames/sec each, ~4 GB per race weekend
```

## 4. glasswire — packet capture analyzer

```text
APP_DESCRIPTION: A CLI network analyzer that reads live traffic or pcap files, reassembles TCP streams, and classifies flows by protocol heuristics. It emits per-flow byte counts, retransmit rates, and top-talker tables for on-call network engineers.
TECH_STACK: C11 + libpcap + custom TCP reassembly + hash-table flow tracking + ncurses summary view, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: 10 Gbps line rate sampling, ~500,000 concurrent flows tracked
```

## 5. embercache — in-memory key-value server

```text
APP_DESCRIPTION: A single-node in-memory key-value cache server speaking a compact binary protocol. It supports TTL expiry, LRU eviction, atomic counters, and pub/sub channels, with an append-only log for warm restart.
TECH_STACK: C11 + libuv event loop + custom binary wire protocol + slab allocator + AOF persistence, CMake build for Linux/BSD
APP_TYPE: API service
LANGUAGE: C
SCALE: ~800,000 ops/sec on 8 cores, 32 GB working set
```

## 6. slabctl — memory allocator profiler

```text
APP_DESCRIPTION: A profiling CLI that intercepts malloc/free in a target process via LD_PRELOAD, records allocation call stacks and lifetimes, and reports fragmentation, leak candidates, and size-class histograms. It writes a compact trace file for offline inspection.
TECH_STACK: C11 + LD_PRELOAD shim + libunwind for backtraces + mmap trace buffer + POSIX signals, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: traces processes doing ~1M allocs/sec, <8% overhead
```

## 7. TideGauge — sensor ingest pipeline

```text
APP_DESCRIPTION: An embedded-facing data pipeline that collects readings from coastal tide and weather sensors over serial and Modbus, validates ranges, applies calibration curves, and batches records upstream over MQTT. It buffers to flash during connectivity loss.
TECH_STACK: C11 + POSIX termios serial + libmodbus + Mosquitto MQTT client + ring buffer on flash, cross-compiled for embedded Linux
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 64 sensors at 1 Hz, ~5.5M readings/day, 128 MB local buffer
```

## 8. quirkfs — FUSE overlay filesystem

```text
APP_DESCRIPTION: A userspace overlay filesystem that presents a transparent, compressed view of an underlying directory tree. It transparently compresses cold files, keeps a hot-file cache uncompressed, and exposes extended attributes for compression stats.
TECH_STACK: C11 + libfuse3 + zstd + LRU page cache + xattr APIs, CMake build for Linux
APP_TYPE: desktop
LANGUAGE: C
SCALE: mounts trees up to 2 TB, ~1.2 GB/s sequential read on cached files
```

## 9. sparkplug — serial firmware flasher

```text
APP_DESCRIPTION: A cross-platform CLI for flashing firmware to microcontrollers over UART and SWD. It parses Intel HEX and ELF images, verifies checksums, drives the bootloader handshake, and streams pages with progress and retry on NAK.
TECH_STACK: C17 + POSIX serial + libusb + Intel HEX/ELF parsers + CRC verification, Make build with static libs
APP_TYPE: CLI
LANGUAGE: C
SCALE: flashes up to 2 MB images at 921600 baud, verify pass in <20s
```

## 10. auroralog — structured log shipper

```text
APP_DESCRIPTION: A lightweight log-shipping daemon that tails application log files, parses lines against configurable patterns, batches them into a compressed framed protocol, and forwards to a collector with backpressure and at-least-once delivery.
TECH_STACK: C11 + inotify + epoll + zlib framing + custom TCP protocol + on-disk spool, systemd unit, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: ~250,000 log lines/sec across 300 files, 1 GB disk spool
```

## 11. RiptideDB — append-only storage engine

```text
APP_DESCRIPTION: An embeddable append-only storage engine library and CLI for time-ordered records. It provides an LSM-style write path, a memtable, background compaction, and range scans, exposed through a small C API for host applications.
TECH_STACK: C11 + mmap + custom LSM tree + CRC32C + background compaction threads (pthreads), built as static/shared lib via CMake
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: ~400,000 writes/sec, 200 GB dataset, compaction keeps <2x space amp
```

## 12. NickelTUI — terminal spreadsheet

```text
APP_DESCRIPTION: A terminal spreadsheet application for quick tabular analysis without leaving the shell. It supports formulas, cell references, sorting, CSV import/export, and a formula dependency graph with incremental recalculation.
TECH_STACK: C11 + ncurses + custom formula parser/evaluator + sparse cell storage, Make build
APP_TYPE: desktop
LANGUAGE: C
SCALE: sheets up to 1M populated cells, recalc under 50ms for typical edits
```

## 13. copperwave — audio resampler CLI

```text
APP_DESCRIPTION: A batch audio-processing CLI that resamples, normalizes, and transcodes audio files. It decodes common formats, applies a polyphase resampler and loudness normalization, and encodes to a target codec with per-file reports.
TECH_STACK: C11 + libsndfile + libsamplerate + FFmpeg libav codecs + pthreads worker pool, CMake build
APP_TYPE: CLI
LANGUAGE: C
SCALE: batches of 10,000 files, ~40x realtime per core
```

## 14. GridSentry — SCADA protocol gateway

```text
APP_DESCRIPTION: An industrial protocol gateway that bridges Modbus TCP and DNP3 devices to a normalized event stream for monitoring. It polls registers, detects value changes, timestamps events, and forwards them while enforcing per-device poll schedules.
TECH_STACK: C11 + libmodbus + custom DNP3 stack + epoll scheduler + Redis via hiredis for the event bus, cross-compiled for embedded Linux
APP_TYPE: API service
LANGUAGE: C
SCALE: 500 devices polled at 200ms, ~2,500 register reads/sec
```

## 15. cindermon — process resource monitor

```text
APP_DESCRIPTION: A CLI process monitor that samples per-process CPU, memory, I/O, and file-descriptor usage from procfs and renders a live sortable table. It can record sessions to a binary trace and alert when thresholds are crossed.
TECH_STACK: C11 + /proc parsing + ncurses + custom binary trace format, Make build for Linux
APP_TYPE: CLI
LANGUAGE: C
SCALE: monitors 5,000+ processes at 1 Hz with <1% CPU overhead
```

## 16. PolarPack — lossless image compressor

```text
APP_DESCRIPTION: A CLI image compressor that encodes and decodes a custom lossless raster format optimized for screenshots and UI captures. It applies prediction, run-length, and entropy coding, and includes a batch mode with parallel encoding.
TECH_STACK: C17 + custom entropy coder + zlib fallback + SIMD (SSE/AVX) prediction + pthreads, CMake build
APP_TYPE: CLI
LANGUAGE: C
SCALE: encodes 4K frames at ~120 fps per core, ~35% smaller than PNG on UI images
```

## 17. mothlight — MIDI synthesizer engine

```text
APP_DESCRIPTION: A real-time software synthesizer that turns incoming MIDI events into audio through a modular voice engine. It manages polyphonic voices, oscillators, envelopes, and filters, with a low-latency audio callback and preset loading.
TECH_STACK: C11 + PortAudio + PortMidi + fixed-block DSP kernels + lock-free voice pool, CMake build for Linux/macOS
APP_TYPE: desktop
LANGUAGE: C
SCALE: 128-voice polyphony at 48 kHz, <5ms round-trip latency
```

## 18. ferrite — static site build pipeline

```text
APP_DESCRIPTION: A fast static-site build pipeline CLI that reads Markdown content, applies templates, generates an index and tag pages, and writes a hashed asset manifest. It supports incremental rebuilds by tracking file dependencies.
TECH_STACK: C11 + custom Markdown parser + mustache-style template engine + mmap file cache, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: builds 20,000-page sites in <3s, incremental edits under 50ms
```

## 19. Blackcurrent — HTTP load generator

```text
APP_DESCRIPTION: A high-concurrency HTTP load-testing CLI that drives configurable request scenarios against a target and reports latency percentiles, throughput, and error breakdowns. It supports connection reuse, request templating, and scripted sequences.
TECH_STACK: C11 + libuv + custom HTTP/1.1 client + HdrHistogram-style latency recording, CMake build
APP_TYPE: CLI
LANGUAGE: C
SCALE: sustains ~200,000 req/sec from one node, 50,000 concurrent connections
```

## 20. quartzq — message broker daemon

```text
APP_DESCRIPTION: A lightweight persistent message-queue broker exposing publish, subscribe, and durable consumer groups over a binary protocol. It writes messages to segmented log files, tracks consumer offsets, and reclaims space by segment retention.
TECH_STACK: C11 + epoll + segmented commit log + mmap offset index + custom binary protocol, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: ~500,000 messages/sec, 1 TB retained, thousands of consumers
```

## 21. dustdevil — log rotation and archiver

```text
APP_DESCRIPTION: A CLI utility that rotates, compresses, and archives log directories according to size and age policies. It handles safe rename-and-signal rotation for running daemons and uploads archives to an object store endpoint.
TECH_STACK: C11 + POSIX file APIs + zstd + libcurl (S3-compatible PUT) + cron-style scheduler, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: rotates 2,000 files/day totaling 400 GB, ~70% compression
```

## 22. Nautilus — B-tree database core

```text
APP_DESCRIPTION: An embeddable single-file database library implementing a copy-on-write B-tree with ACID transactions and MVCC snapshots. It exposes cursors, range queries, and a WAL, packaged as a static library with a diagnostic CLI.
TECH_STACK: C11 + mmap + copy-on-write B-tree + write-ahead log + fsync durability, CMake, ships as .a/.so
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 100 GB databases, ~150,000 point reads/sec, crash-safe commits
```

## 23. voltcap — GPIO automation daemon

```text
APP_DESCRIPTION: An embedded automation daemon for single-board computers that reacts to GPIO inputs and drives outputs based on rule definitions. It debounces inputs, schedules timed actions, and exposes a local socket for status and manual overrides.
TECH_STACK: C11 + libgpiod + POSIX timers + epoll + Unix domain control socket, cross-compiled for ARM Linux, framed as embedded work
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 40 GPIO lines, sub-millisecond debounce, runs on 256 MB device
```

## 24. hollowpoint — ELF binary inspector

```text
APP_DESCRIPTION: A CLI tool for inspecting ELF binaries: it lists sections, symbols, relocations, and dynamic dependencies, decodes headers, and flags stripped or suspicious segments. Useful for reverse engineering and build debugging.
TECH_STACK: C17 + libelf + custom DWARF-lite reader + hex/disasm dump, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: parses binaries up to 500 MB, full symbol dump in <1s
```

## 25. Cinderpath — geospatial routing engine

```text
APP_DESCRIPTION: A routing engine library that computes shortest and fastest paths over road-network graphs. It loads a preprocessed contraction-hierarchy graph, answers point-to-point and isochrone queries, and exposes a C API plus a benchmark CLI.
TECH_STACK: C11 + contraction hierarchies + mmap graph files + SIMD distance ops, CMake, ships as lib + CLI
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: continent-scale graph (60M edges), <1ms per route query
```

## 26. tinseld — DHCP lease server

```text
APP_DESCRIPTION: A DHCPv4/v6 server daemon for lab and edge networks that manages address pools, static reservations, and lease persistence. It answers DISCOVER/REQUEST cycles, tracks lease expiry, and exposes a query socket for current bindings.
TECH_STACK: C11 + raw UDP sockets + epoll + on-disk lease database + custom binary state file, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 65,000-address pools, ~10,000 lease transactions/min
```

## 27. mercuryscan — port and service scanner

```text
APP_DESCRIPTION: A fast network scanner CLI that performs asynchronous TCP/SYN sweeps and lightweight service banner grabbing across address ranges. It manages a stateless probe engine with adaptive rate limiting and outputs machine-readable results.
TECH_STACK: C11 + raw sockets + custom SYN engine + epoll + adaptive rate limiter, Make build (requires CAP_NET_RAW)
APP_TYPE: CLI
LANGUAGE: C
SCALE: scans a /16 in under 2 minutes, ~1.5M probes/sec
```

## 28. Latchkey — TOTP hardware token daemon

```text
APP_DESCRIPTION: A security daemon that mediates access to a USB hardware token for signing and TOTP generation, presenting a local API to applications. It serializes device access, caches public certificates, and audits every signing request.
TECH_STACK: C11 + libusb + OpenSSL + Unix domain socket API + append-only audit log, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 500 signing requests/sec, single token, full audit trail
```

## 29. driftwood — CSV/columnar converter

```text
APP_DESCRIPTION: A data pipeline CLI that converts large delimited text files into a columnar binary format with type inference, null handling, and dictionary encoding for low-cardinality columns. It streams input to bound memory use.
TECH_STACK: C17 + mmap + SIMD CSV tokenizer + dictionary encoder + zstd column compression, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: converts 100 GB CSV at ~1.5 GB/s, 4x storage reduction
```

## 30. embertone — Opus streaming server

```text
APP_DESCRIPTION: A low-latency audio streaming server that ingests raw PCM, encodes to Opus, and multicasts framed packets to subscribed listeners with jitter buffering hints. It manages per-listener state and adaptive bitrate hints.
TECH_STACK: C11 + libopus + RTP-style framing + epoll + multicast UDP, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 2,000 concurrent listeners, 20ms frames, <60ms end-to-end latency
```

## 31. Ratchet — build system and task runner

```text
APP_DESCRIPTION: A dependency-aware build/task runner CLI that parses a declarative build file, constructs a task DAG, and executes commands in parallel with content-hash caching to skip unchanged work. It reports a build timeline.
TECH_STACK: C11 + custom DAG scheduler + BLAKE-style content hashing + pthreads + mmap cache, Make bootstrap build
APP_TYPE: CLI
LANGUAGE: C
SCALE: 50,000-node graphs, near-linear scaling to 32 cores
```

## 32. Saltmarsh — IoT firmware OTA pipeline

```text
APP_DESCRIPTION: A backend pipeline that manages over-the-air firmware rollouts to fleets of embedded devices. It signs and diffs firmware images, computes binary deltas, assembles staged rollout cohorts, and serves resumable image chunks.
TECH_STACK: C11 + bsdiff-style binary diff + Ed25519 signing (libsodium) + libcurl + SQLite rollout state, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 200,000-device fleet, delta images ~50 KB, staged 5% cohorts
```

## 33. glowbench — microbenchmark harness

```text
APP_DESCRIPTION: A CLI microbenchmark harness for C functions that runs measured iterations, controls CPU affinity, discards warmup, and reports mean, variance, and cycle counts with statistical outlier rejection. It emits comparable JSON results.
TECH_STACK: C17 + RDTSC/clock_gettime + CPU affinity (sched_setaffinity) + custom stats, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: nanosecond-resolution timing, millions of iterations per run
```

## 34. Pinewire — syslog aggregation server

```text
APP_DESCRIPTION: A syslog aggregation server that receives RFC 5424 messages over UDP/TCP/TLS, parses structured data, filters by facility and severity, and writes partitioned files while forwarding selected streams downstream.
TECH_STACK: C11 + epoll + OpenSSL (syslog-TLS) + RFC 5424 parser + partitioned file writer, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: ~180,000 messages/sec, 5,000 sending hosts
```

## 35. quillnest — terminal Markdown editor

```text
APP_DESCRIPTION: A terminal Markdown editor with live preview rendering in the pane, syntax highlighting, incremental parsing, and a rope-based buffer for smooth editing of large documents. It supports split view and export.
TECH_STACK: C11 + ncurses + rope data structure + incremental Markdown parser, Make build
APP_TYPE: desktop
LANGUAGE: C
SCALE: edits 50 MB documents smoothly, <10ms keystroke latency
```

## 36. Brambling — HTTP reverse proxy

```text
APP_DESCRIPTION: A reverse-proxy server that terminates TLS, routes requests by host and path rules, load-balances across upstream pools with health checks, and applies per-route rate limits and header rewrites.
TECH_STACK: C11 + libuv + OpenSSL + custom HTTP/1.1 parser + weighted round-robin balancer, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: ~90,000 req/sec, 40,000 concurrent connections, TLS offload
```

## 37. slagheap — core-dump triage tool

```text
APP_DESCRIPTION: A CLI that ingests core dumps and their binaries to reconstruct stack traces, decode registers, and summarize the crashing thread with symbol resolution. It clusters similar crashes across many dumps by stack signature.
TECH_STACK: C17 + libelf + DWARF unwinder + minidump/core parser + hash-based clustering, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: processes 10,000 dumps/hour, groups into signature clusters
```

## 38. Tallowdrip — video thumbnail pipeline

```text
APP_DESCRIPTION: A media pipeline that scans a video library, decodes keyframes, generates thumbnail sprites and storyboard strips, and extracts basic metadata. It parallelizes across files and skips already-processed assets by hash.
TECH_STACK: C11 + FFmpeg libavcodec/libavformat + libswscale + pthreads pool + SQLite catalog, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 200,000-video library, ~600 videos/min on 16 cores
```

## 39. cobaltd — NTP time server

```text
APP_DESCRIPTION: An NTP server daemon that disciplines the local clock against upstream references and serves time to LAN clients with symmetric-key authentication. It manages a peer poll loop, drift filtering, and stratum reporting.
TECH_STACK: C11 + raw UDP + PLL/FLL clock discipline + adjtimex + HMAC auth, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 20,000 client req/sec, sub-millisecond LAN sync accuracy
```

## 40. wickerframe — packet crafting toolkit

```text
APP_DESCRIPTION: A CLI packet-crafting and injection toolkit for protocol testing. It builds Ethernet/IP/TCP/UDP frames from a compact spec language, injects them on an interface, and captures responses for validation.
TECH_STACK: C11 + AF_PACKET raw sockets + custom checksum offload + libpcap capture, Make build (CAP_NET_RAW)
APP_TYPE: CLI
LANGUAGE: C
SCALE: crafts and injects ~1M packets/sec, arbitrary header fuzzing
```

## 41. Marrowbone — SQLite migration runner

```text
APP_DESCRIPTION: A CLI that applies versioned schema migrations to SQLite databases with transactional safety, checksum verification of applied steps, and rollback support. It embeds migrations or loads them from a directory.
TECH_STACK: C11 + SQLite3 (amalgamation) + custom migration ledger + CRC verification, Make build, single static binary
APP_TYPE: CLI
LANGUAGE: C
SCALE: manages databases up to 50 GB, migrations applied atomically
```

## 42. Frostgrip — thermal telemetry pipeline

```text
APP_DESCRIPTION: An embedded data pipeline for cold-chain logistics that reads temperature and humidity probes, detects excursions against per-shipment thresholds, timestamps events with an RTC, and logs to nonvolatile storage for later upload.
TECH_STACK: C11 + I2C/SPI sensor drivers + FRAM logging + POSIX timers, cross-compiled bare-metal-adjacent for MCU-class Linux, framed as embedded
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 16 probes at 0.1 Hz, 30-day autonomous logging, 4 MB FRAM
```

## 43. Nettleweave — WebSocket fan-out server

```text
APP_DESCRIPTION: A WebSocket server that maintains many long-lived client connections and fans out topic-based messages published by backend producers. It handles framing, ping/pong keepalive, per-topic subscription sets, and backpressure.
TECH_STACK: C11 + libuv + custom RFC 6455 framing + OpenSSL (wss) + topic hash index, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 250,000 concurrent connections, ~1M messages/sec fan-out
```

## 44. quicksilverfs — deduplicating backup engine

```text
APP_DESCRIPTION: A backup CLI that snapshots directory trees, splits files by content-defined chunking, deduplicates against a chunk index, and stores encrypted packs. It supports incremental snapshots and point-in-time restore.
TECH_STACK: C17 + rolling-hash chunker + BLAKE2 + AES-GCM + mmap chunk index + zstd, CMake build
APP_TYPE: CLI
LANGUAGE: C
SCALE: 5 TB source trees, ~90% dedup on incrementals, 1 GB/s hashing
```

## 45. Tarnhelm — TLS certificate rotation daemon

```text
APP_DESCRIPTION: A daemon that manages TLS certificate lifecycles for a host: it requests, renews, and installs certificates via ACME, reloads dependent services, and alerts on approaching expiry. It stores keys with restricted permissions.
TECH_STACK: C11 + OpenSSL + libcurl (ACME/HTTP) + JSON parser + Unix socket control, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: manages 2,000 certificates, renewals batched hourly
```

## 46. Cinderblock — WASM bytecode interpreter

```text
APP_DESCRIPTION: A small WebAssembly interpreter library and CLI that loads .wasm modules, validates them, and executes exported functions in a sandboxed linear memory. It exposes a host-function import mechanism for embedding.
TECH_STACK: C17 + custom stack-based interpreter + bounds-checked linear memory + host import table, CMake, ships lib + CLI
APP_TYPE: CLI
LANGUAGE: C
SCALE: executes modules up to 64 MB memory, ~200M instr/sec
```

## 47. Peatsmoke — flow-based metrics collector

```text
APP_DESCRIPTION: A NetFlow/IPFIX collector daemon that receives exported flow records from routers, decodes templates, aggregates by source/destination/port, and writes rolled-up time buckets for capacity analysis.
TECH_STACK: C11 + UDP + IPFIX template parser + epoll + time-bucketed binary store, systemd, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 500,000 flow records/sec from 200 exporters, 1-minute buckets
```

## 48. lodestone — filesystem indexer and search

```text
APP_DESCRIPTION: A CLI that builds and maintains a fast full-path and content index of local filesystems for instant search. It watches for changes, maintains an inverted index of filenames and a trigram index for content grep.
TECH_STACK: C11 + inotify + trigram inverted index + mmap posting lists, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: indexes 20M files, sub-100ms filename queries, content grep over 500 GB
```

## 49. Emberglass — OpenGL model viewer

```text
APP_DESCRIPTION: A desktop 3D model viewer that loads mesh files, renders with basic PBR shading, and supports orbit navigation, wireframe toggle, and material inspection. It streams large meshes and computes bounding volumes on load.
TECH_STACK: C11 + OpenGL + GLFW + custom glTF/OBJ loader + SIMD math, CMake build for Linux/Windows/macOS
APP_TYPE: desktop
LANGUAGE: C
SCALE: renders meshes up to 20M triangles at 60 fps
```

## 50. Nightjar — raw disk imaging CLI

```text
APP_DESCRIPTION: A CLI for creating and restoring block-level disk images with sparse detection, on-the-fly compression, and integrity hashing. It supports resumable transfers and can clone directly between devices with progress reporting.
TECH_STACK: C17 + O_DIRECT block I/O + zstd + BLAKE3 verification + sparse-hole detection, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: images 2 TB drives, ~800 MB/s with compression, resumable
```

## 51. Saltire — HTTP/2 static file server

```text
APP_DESCRIPTION: A static file server supporting HTTP/2, range requests, ETags, and precompressed asset negotiation. It uses sendfile for zero-copy delivery, caches stat results, and enforces directory jails per virtual host.
TECH_STACK: C11 + epoll + nghttp2 + OpenSSL + sendfile + stat cache, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: ~120,000 req/sec static, saturates 25 GbE with zero-copy
```

## 52. Cogwright — G-code motion planner

```text
APP_DESCRIPTION: A CLI motion planner for CNC and 3D-printer toolpaths that parses G-code, performs look-ahead velocity planning with junction deviation, and emits step/timing tables. It validates limits and simulates the path.
TECH_STACK: C11 + custom G-code parser + trapezoidal/S-curve planner + fixed-point step generation, Make build, embedded-adjacent
APP_TYPE: CLI
LANGUAGE: C
SCALE: plans programs with 5M moves, look-ahead over 256-segment buffer
```

## 53. Brimstone — kernel tracing frontend

```text
APP_DESCRIPTION: A CLI frontend for eBPF-based kernel tracing that loads probe programs, attaches to syscalls and tracepoints, aggregates histograms in kernel maps, and renders latency and count summaries in the terminal.
TECH_STACK: C11 + libbpf + BPF CO-RE + perf ring buffer + ncurses output, CMake build for modern Linux
APP_TYPE: CLI
LANGUAGE: C
SCALE: traces millions of syscalls/sec with in-kernel aggregation
```

## 54. Halyard — MQTT broker

```text
APP_DESCRIPTION: An MQTT 3.1.1/5.0 broker for IoT deployments supporting QoS 0-2, retained messages, last-will, and topic-based ACLs. It persists sessions and queued messages, and exposes a stats topic for monitoring.
TECH_STACK: C11 + epoll + custom MQTT codec + topic trie + on-disk session store, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 100,000 connected devices, ~300,000 publishes/sec
```

## 55. Coalfire — regex log grep engine

```text
APP_DESCRIPTION: A high-speed CLI for searching huge log archives with regex, supporting compressed inputs, multiline patterns, and parallel file scanning. It compiles patterns to a fast NFA/DFA and streams matches with context.
TECH_STACK: C17 + custom DFA regex engine + zstd/gzip streaming + pthreads + mmap, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: searches 1 TB of compressed logs at ~4 GB/s decompressed
```

## 56. Wispmere — sensor fusion pipeline

```text
APP_DESCRIPTION: A robotics data pipeline that fuses IMU, wheel-odometry, and GPS streams into a state estimate using a complementary/Kalman filter. It time-syncs sources, handles dropouts, and publishes pose at a fixed rate.
TECH_STACK: C11 + custom EKF + fixed-rate scheduler + shared-memory transport + POSIX real-time threads, cross-compiled ARM
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: fuses 3 sensors at up to 1 kHz, 200 Hz pose output, deterministic latency
```

## 57. Overcast — S3-compatible object gateway

```text
APP_DESCRIPTION: An object-storage gateway exposing an S3-compatible HTTP API backed by local disks. It handles multipart uploads, range reads, bucket policies, and content hashing, spreading objects across a disk pool with metadata in an embedded DB.
TECH_STACK: C11 + epoll + custom HTTP + OpenSSL (SigV4 auth) + SQLite metadata + spread-across-disks store, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 50 TB across 12 disks, ~15,000 object ops/sec
```

## 58. Tidewheel — Parquet-to-metrics ETL

```text
APP_DESCRIPTION: A batch ETL pipeline that reads columnar data files, applies filter/aggregate transforms defined in a small config DSL, and emits rolled-up metrics tables. It streams column chunks to keep memory bounded.
TECH_STACK: C17 + custom Parquet reader + SIMD aggregation kernels + thread pool + zstd, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: processes 500 GB/day, ~2 GB/s scan throughput
```

## 59. Nickelplate — terminal git TUI

```text
APP_DESCRIPTION: A terminal UI for git that shows status, staged/unstaged diffs, branch graphs, and interactive staging by hunk. It shells to git plumbing and parses output, rendering a keyboard-driven multi-pane interface.
TECH_STACK: C11 + ncurses + libgit2 + diff parser, CMake build
APP_TYPE: desktop
LANGUAGE: C
SCALE: handles repos with 500k commits, instant status refresh
```

## 60. Cinderella — SMTP relay with queuing

```text
APP_DESCRIPTION: An SMTP relay server that accepts mail, enforces SPF/rate policies, queues messages to disk with retry backoff, and delivers to upstream MX hosts over TLS. It exposes a queue-inspection command socket.
TECH_STACK: C11 + epoll + custom SMTP state machine + OpenSSL (STARTTLS) + on-disk spool queue, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 50,000 messages/hour, persistent retry queue up to 100k items
```

## 61. Gravelbox — process sandbox launcher

```text
APP_DESCRIPTION: A CLI that launches untrusted programs inside a restricted sandbox using namespaces, seccomp filters, and cgroup limits. It builds a minimal filesystem view, drops capabilities, and reports resource usage on exit.
TECH_STACK: C11 + Linux namespaces (clone) + seccomp-bpf + cgroups v2 + pivot_root, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: launches thousands of jobs/hour, per-job memory/CPU caps enforced
```

## 62. Thornfield — columnar time-series DB

```text
APP_DESCRIPTION: A time-series database engine for metrics that stores compressed columnar blocks per series, supports delta-of-delta timestamp encoding, and answers range and downsample queries over a query API.
TECH_STACK: C11 + Gorilla-style compression + mmap block store + epoll query server + custom binary protocol, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 10M active series, ~2M samples/sec ingest, 1.3 bytes/sample compressed
```

## 63. Runecarver — font rasterizer library

```text
APP_DESCRIPTION: A font rasterization library and CLI that parses TrueType/OpenType outlines, applies hinting, and renders anti-aliased glyph bitmaps with subpixel positioning. It caches glyph atlases for repeated rendering.
TECH_STACK: C11 + custom TTF/OTF parser + Bezier flattening + coverage-based AA rasterizer + glyph cache, CMake, ships lib + CLI
APP_TYPE: desktop
LANGUAGE: C
SCALE: rasterizes 100,000 glyphs/sec, 4KB-4MB font files
```

## 64. Blackthorn — VPN tunnel daemon

```text
APP_DESCRIPTION: A point-to-point encrypted tunnel daemon that creates a TUN interface, encrypts IP packets with an authenticated cipher, and multiplexes them over UDP with anti-replay and rekeying. It handles NAT keepalive and MTU discovery.
TECH_STACK: C11 + TUN/TAP + libsodium (ChaCha20-Poly1305) + epoll + UDP transport, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: ~5 Gbps throughput per core, rekey every 2 minutes
```

## 65. Quarrystone — disk defrag and analyzer

```text
APP_DESCRIPTION: A CLI that analyzes filesystem fragmentation, reports extent distribution and free-space maps, and can compact files by rewriting them contiguously. It reads filesystem extent maps and visualizes layout in the terminal.
TECH_STACK: C11 + FIEMAP ioctl + extent analysis + ncurses heatmap, Make build for Linux
APP_TYPE: CLI
LANGUAGE: C
SCALE: analyzes 4 TB volumes, extent map over 50M fragments
```

## 66. Emberflint — real-time DSP filter bank

```text
APP_DESCRIPTION: A desktop real-time audio effects processor that applies a configurable chain of DSP filters (EQ, compression, reverb) to live input and output. It provides a GTK control panel with live metering and preset management.
TECH_STACK: C11 + JACK/ALSA + GTK4 + fixed-block DSP kernels + lock-free parameter updates, CMake build
APP_TYPE: desktop
LANGUAGE: C
SCALE: 32-band processing at 96 kHz, <3ms processing latency
```

## 67. Saltpan — CDR billing pipeline

```text
APP_DESCRIPTION: A telecom pipeline that ingests call detail records from switches, deduplicates, rates calls against tariff tables, and aggregates per-subscriber usage for billing. It handles late-arriving records and reconciliation windows.
TECH_STACK: C11 + custom fixed-width/ASN.1 CDR parser + hash-join rating + PostgreSQL via libpq + batch commits, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 100M CDRs/day, ~40,000 records/sec rated
```

## 68. Ironwort — HTTP API gateway with auth

```text
APP_DESCRIPTION: An API gateway that authenticates requests via JWT and API keys, enforces per-key quotas, routes to backend services, and records request metrics. It validates tokens locally and caches decoded claims.
TECH_STACK: C11 + libuv + custom HTTP + OpenSSL (JWT verify) + Redis via hiredis (quotas) + route table, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: ~80,000 req/sec, 10,000 API keys, per-key rate windows
```

## 69. Wanderlight — GPS track processor

```text
APP_DESCRIPTION: A CLI that ingests GPX/NMEA GPS tracks, smooths noisy points, computes distance, elevation gain, and speed profiles, detects stops, and exports cleaned tracks and summary statistics for fitness and survey use.
TECH_STACK: C11 + custom GPX/NMEA parser + Kalman smoothing + Haversine geodesics, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: processes tracks with 1M points in <1s
```

## 70. Coldforge — container image builder

```text
APP_DESCRIPTION: A CLI that builds OCI container images from a declarative spec without a daemon. It assembles layers, computes digests, applies whiteouts, and produces a compliant image tarball ready to push to a registry.
TECH_STACK: C17 + tar/layer assembly + zstd/gzip + SHA-256 digests + libcurl registry push, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: builds 2 GB images, layer dedup, ~500 MB/s layer packing
```

## 71. Nettleburn — DNS zone transfer auditor

```text
APP_DESCRIPTION: A security-focused CLI that audits DNS infrastructure by attempting zone transfers, enumerating records, checking DNSSEC chains, and flagging misconfigurations like open resolvers and dangling delegations.
TECH_STACK: C11 + custom DNS resolver + AXFR client + OpenSSL (DNSSEC validation), Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: audits 10,000 domains/hour, full record enumeration
```

## 72. Amberlens — image processing batch server

```text
APP_DESCRIPTION: An API service that accepts image upload requests and applies resize, crop, format conversion, and filter operations on demand, caching results by operation signature. It streams processed output and enforces size limits.
TECH_STACK: C11 + epoll + custom HTTP + libjpeg-turbo + libpng + libwebp + SIMD resampling + result cache, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: ~8,000 transforms/sec, 90% cache hit rate, 100 GB cache
```

## 73. Slateroot — configuration management agent

```text
APP_DESCRIPTION: A host agent that applies declarative configuration state: it manages packages, files, services, and permissions to match a desired spec pulled from a control server, reporting drift and convergence status.
TECH_STACK: C11 + POSIX system calls + libcurl (control fetch) + JSON parser + idempotent resource handlers, systemd, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: manages 10,000 hosts, convergence run under 5s per host
```

## 74. Peatfire — bitmap font terminal renderer

```text
APP_DESCRIPTION: A GPU-accelerated terminal emulator that renders text with a glyph atlas, supports true color, ligatures, and scrollback, and parses ANSI/VT sequences. It offloads rendering to shaders for smooth scrolling.
TECH_STACK: C11 + OpenGL + custom VT100/VT220 parser + glyph atlas + FreeType, CMake build for Linux
APP_TYPE: desktop
LANGUAGE: C
SCALE: renders 240x80 at 144 fps, 1M-line scrollback
```

## 75. Bellhollow — RADIUS authentication server

```text
APP_DESCRIPTION: A RADIUS server for network access control that authenticates users against a backend, applies policy attributes, and logs accounting records. It supports PAP/CHAP/EAP methods and per-realm routing.
TECH_STACK: C11 + UDP + custom RADIUS codec + OpenSSL (EAP-TLS) + PostgreSQL via libpq, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 30,000 auth req/sec, accounting for 200,000 sessions
```

## 76. Cragmaw — ROM disassembler

```text
APP_DESCRIPTION: A CLI disassembler for retro console and MCU ROMs that decodes instructions for a target architecture, follows control flow to separate code from data, labels jump targets, and emits annotated assembly listings.
TECH_STACK: C17 + custom instruction decoder tables + control-flow tracer + symbol map, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: disassembles 4 MB ROMs, full CFG in <2s
```

## 77. Driftglass — WebRTC SFU media router

```text
APP_DESCRIPTION: A selective forwarding unit that routes WebRTC media between conference participants. It terminates ICE/DTLS, demuxes RTP/RTCP, forwards simulcast layers based on subscriber bandwidth, and handles NACK/PLI.
TECH_STACK: C11 + libsrtp + OpenSSL (DTLS) + custom ICE/STUN + epoll + RTP forwarding, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 500 participants across rooms, ~2 Gbps forwarded media
```

## 78. Hollowmere — journaling key-value store

```text
APP_DESCRIPTION: An embeddable persistent key-value store with a write-ahead journal, hash-indexed data files, and crash recovery. It offers atomic batches, prefix iteration, and compaction, exposed through a C API and a repl CLI.
TECH_STACK: C11 + WAL + extendible hashing + mmap + fsync recovery, CMake, ships lib + CLI
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 300 GB stores, ~250,000 writes/sec, recovery under 10s
```

## 79. Cindertrack — flight ADS-B decoder

```text
APP_DESCRIPTION: A pipeline that decodes ADS-B messages from an SDR receiver, extracting aircraft position, velocity, and identity, deduplicating across receivers, and publishing a live traffic feed with CPR position decoding.
TECH_STACK: C11 + RTL-SDR (librtlsdr) + Mode S/CPR decoder + epoll publisher + ring buffer, cross-compiled ARM, embedded-adjacent
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 2,000 aircraft tracked, ~10,000 messages/sec decoded
```

## 80. Grimswell — malware YARA scanner

```text
APP_DESCRIPTION: A CLI file scanner that matches content against signature rules, walks directory trees, unpacks common archive formats, and reports matches with offsets. It compiles rules to an automaton for fast multi-pattern scanning.
TECH_STACK: C17 + Aho-Corasick automaton + libarchive + mmap file scanning + pthreads, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: scans 1M files/hour, 50,000 signatures, ~3 GB/s throughput
```

## 81. Wrenlight — LDAP directory server

```text
APP_DESCRIPTION: An LDAP directory server that stores an entry tree, answers search/bind/modify operations, enforces access controls, and indexes attributes for fast filter evaluation. It persists the DIT to an embedded backend.
TECH_STACK: C11 + epoll + custom BER/LDAP codec + B-tree index + mmap backend, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 5M directory entries, ~20,000 search ops/sec
```

## 82. Ashenford — river gauge modeling CLI

```text
APP_DESCRIPTION: A scientific CLI that runs hydrological flow models over gauge and rainfall inputs, solving discharge equations on a river network graph and forecasting levels. It ingests time-series, calibrates parameters, and outputs projections.
TECH_STACK: C11 + BLAS/LAPACK + custom finite-difference solver + NetCDF I/O + OpenMP, CMake build
APP_TYPE: CLI
LANGUAGE: C
SCALE: models 5,000-reach networks, 72-hour forecast in <30s
```

## 83. Coppernest — PostgreSQL logical replication tap

```text
APP_DESCRIPTION: A data pipeline daemon that connects to PostgreSQL logical replication, decodes the WAL change stream, transforms rows, and forwards them to downstream sinks with checkpointed offsets and exactly-once semantics.
TECH_STACK: C11 + libpq (logical decoding) + pgoutput parser + epoll + offset checkpoint file, systemd, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: ~150,000 change events/sec, lag under 200ms
```

## 84. Duskbinder — PDF text extraction pipeline

```text
APP_DESCRIPTION: A pipeline that extracts text, tables, and metadata from PDF documents in bulk. It parses the PDF object model, decodes content streams, maps glyphs to Unicode, and reconstructs reading order for downstream indexing.
TECH_STACK: C17 + custom PDF parser + zlib/LZW stream decode + CMap/ToUnicode mapping + pthreads, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 500,000 PDFs/day, ~800 pages/sec on 16 cores
```

## 85. Flintcap — BLE scanner and logger

```text
APP_DESCRIPTION: An embedded-facing CLI that scans Bluetooth Low Energy advertisements, decodes manufacturer and service data, tracks devices by address, and logs presence and sensor beacons to a local store for IoT monitoring.
TECH_STACK: C11 + BlueZ HCI sockets + GATT/advertisement parser + SQLite log, cross-compiled ARM Linux, embedded framing
APP_TYPE: CLI
LANGUAGE: C
SCALE: tracks 5,000 devices, ~2,000 advertisements/sec parsed
```

## 86. Gorsewind — HTTP caching proxy

```text
APP_DESCRIPTION: A forward caching proxy that stores cacheable responses on disk keyed by URL and Vary headers, revalidates with conditional requests, and enforces cache-control semantics. It serves stale-while-revalidate for hot objects.
TECH_STACK: C11 + epoll + custom HTTP + on-disk cache with LRU eviction + OpenSSL, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: ~60,000 req/sec, 500 GB disk cache, 85% hit rate
```

## 87. Marrowlight — raytracing render CLI

```text
APP_DESCRIPTION: A CLI path tracer that renders scenes described in a compact scene file, using a BVH acceleration structure, multiple importance sampling, and tiled multithreaded rendering. It outputs HDR and tonemapped images.
TECH_STACK: C17 + custom BVH + SIMD ray-triangle intersection + pthreads tile scheduler + OpenEXR output, CMake build
APP_TYPE: CLI
LANGUAGE: C
SCALE: renders 4K frames of 5M-triangle scenes, ~50M rays/sec per core
```

## 88. Sootmarrow — kernel module memory scanner

```text
APP_DESCRIPTION: A CLI diagnostic that reads a live process or kernel memory via ptrace/procfs, searches for byte patterns and pointer structures, and dumps annotated regions. It maps memory layout and identifies heap and stack areas.
TECH_STACK: C11 + ptrace + /proc/pid/maps + pattern scanner + region annotator, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: scans 64 GB address spaces, ~5 GB/s pattern search
```

## 89. Emberquay — AIS maritime tracker pipeline

```text
APP_DESCRIPTION: A pipeline that decodes AIS messages from a VHF receiver, extracting vessel positions, headings, and identities, filtering duplicates across receivers, and publishing a live vessel feed with track interpolation.
TECH_STACK: C11 + SDR input + AIS/NMEA 0183 decoder + epoll publisher + ring buffer, cross-compiled ARM, embedded framing
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 10,000 vessels tracked, ~4,000 messages/sec decoded
```

## 90. Thistledown — CoAP IoT server

```text
APP_DESCRIPTION: A CoAP server for constrained IoT devices that exposes resource endpoints, supports observe subscriptions, block-wise transfers, and DTLS security. It manages a resource tree and forwards events to a backend bus.
TECH_STACK: C11 + UDP + custom CoAP codec + tinydtls + epoll + resource trie, cross-compiled embedded Linux
APP_TYPE: API service
LANGUAGE: C
SCALE: 50,000 devices, ~40,000 requests/sec, observe fan-out
```

## 91. Cindershade — HDR photo merge CLI

```text
APP_DESCRIPTION: A CLI that merges bracketed exposures into HDR images, aligns frames, computes a camera response curve, performs tone mapping, and outputs final images. It handles RAW decoding and per-pixel weighting.
TECH_STACK: C17 + LibRaw + custom exposure fusion + SIMD tone mapping + pthreads, CMake build
APP_TYPE: CLI
LANGUAGE: C
SCALE: merges 9-frame brackets of 60MP images in <2s
```

## 92. Willowvane — cluster gossip membership

```text
APP_DESCRIPTION: A library and daemon implementing a SWIM-style gossip protocol for cluster membership and failure detection. It maintains a member list, disseminates state via piggybacked gossip, and exposes membership events to applications.
TECH_STACK: C11 + UDP + SWIM failure detector + epoll + lock-free member table, CMake, ships lib + daemon
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: 2,000-node clusters, failure detection under 3s, low bandwidth
```

## 93. Brackenhold — SQL query engine CLI

```text
APP_DESCRIPTION: A CLI SQL engine that runs queries directly over CSV and columnar files without a server. It parses SQL, builds a plan with predicate pushdown, and executes vectorized operators for joins, filters, and aggregations.
TECH_STACK: C17 + custom SQL parser + vectorized execution + mmap + SIMD, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: queries 100 GB files at ~3 GB/s scan, sub-second aggregates
```

## 94. Nightforge — deterministic build sandbox

```text
APP_DESCRIPTION: A CLI that runs build commands in a hermetic sandbox capturing all file inputs and outputs, producing a reproducible action graph and content-addressed cache. It detects nondeterminism by re-running and comparing hashes.
TECH_STACK: C11 + ptrace/seccomp file tracing + content-addressed store + namespaces, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: tracks builds with 100,000 file accesses, cache hit avoids full rebuild
```

## 95. Saltglow — real-time ECG monitor

```text
APP_DESCRIPTION: An embedded desktop application that acquires ECG signals from a serial front-end, filters baseline wander and noise, detects QRS complexes, computes heart-rate variability, and displays live waveforms with alarms.
TECH_STACK: C11 + POSIX serial + GTK4 + Pan-Tompkins QRS detector + real-time DSP, CMake build, embedded-adjacent
APP_TYPE: desktop
LANGUAGE: C
SCALE: 3 leads at 500 Hz, real-time QRS detection, <100ms display lag
```

## 96. Coalwright — packet replay engine

```text
APP_DESCRIPTION: A CLI that replays captured pcap traffic onto a network interface at controlled rates, rewriting addresses and preserving inter-packet timing. It supports loop, speed scaling, and multi-interface splitting for testing.
TECH_STACK: C11 + libpcap + AF_PACKET TX + high-resolution timers + address rewriting, Make build
APP_TYPE: CLI
LANGUAGE: C
SCALE: replays at 10 Gbps line rate, nanosecond timing fidelity
```

## 97. Ravenmoor — distributed lock service

```text
APP_DESCRIPTION: A lightweight lock and coordination service exposing distributed locks, leader election, and ephemeral keys over a binary protocol. It replicates state via a Raft log across a small node quorum with leases.
TECH_STACK: C11 + custom Raft implementation + epoll + on-disk log + binary protocol, systemd, CMake build
APP_TYPE: API service
LANGUAGE: C
SCALE: 5-node quorum, ~30,000 lock ops/sec, failover under 2s
```

## 98. Glimmerfen — spectrogram analyzer desktop

```text
APP_DESCRIPTION: A desktop tool that visualizes audio spectrograms in real time from live input or files, with adjustable FFT windows, log/linear scaling, and marker measurement. It renders the waterfall on the GPU and exports images.
TECH_STACK: C11 + PortAudio + FFTW + OpenGL + GTK4 controls, CMake build
APP_TYPE: desktop
LANGUAGE: C
SCALE: 8192-point FFT at 60 fps waterfall, 96 kHz input
```

## 99. Cindervault — hardware key backup CLI

```text
APP_DESCRIPTION: A CLI for securely backing up and restoring cryptographic key material using Shamir secret sharing. It splits keys into shares, encrypts each, encodes them as printable mnemonics, and verifies reconstruction thresholds.
TECH_STACK: C17 + libsodium + Shamir secret sharing over GF(256) + mnemonic encoding, Make build, static binary
APP_TYPE: CLI
LANGUAGE: C
SCALE: single operator, 3-of-5 share schemes, offline air-gapped use
```

## 100. Stormglass — weather model data pipeline

```text
APP_DESCRIPTION: A scientific pipeline that ingests gridded numerical weather model output, regrids and interpolates to station points, computes derived variables, and writes compact per-location time-series for forecasting apps.
TECH_STACK: C11 + GRIB2/NetCDF readers + bilinear regridding + OpenMP + zstd output, CMake build
APP_TYPE: data pipeline
LANGUAGE: C
SCALE: processes 40 GB model runs 4x/day, ~1.5 GB/s regridding
```
