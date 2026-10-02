# C++ Blueprint Types — Copy-Paste Input Sets

Copy a fenced block into the prompt as-is, or swap individual fields.

## 1. TickForge — low-latency market data gateway

```text
APP_DESCRIPTION: A low-latency market data gateway for a proprietary trading desk. It decodes exchange multicast feeds (ITCH/OUCH), rebuilds full order books per instrument, and republishes normalized top-of-book and depth snapshots to internal strategy engines over shared memory with microsecond budgets.
TECH_STACK: C++20 + Boost.Asio + kernel-bypass NIC (DPDK) + lock-free ring buffers + shared-memory IPC, deployed on colocated bare-metal Linux
APP_TYPE: API service
LANGUAGE: C++
SCALE: ~6M messages/sec peak, <5 µs decode-to-publish, 40 instruments
```

## 2. Lumberyard — voxel game engine runtime

```text
APP_DESCRIPTION: A voxel-based game engine runtime for open-world sandbox titles. It streams chunked terrain, runs a job-based entity component system, and drives a Vulkan renderer with greedy meshing and frustum culling to keep large destructible worlds interactive on mid-range GPUs.
TECH_STACK: C++23 + Vulkan + EnTT ECS + custom job scheduler + FastNoise2, built with CMake for Windows and Linux
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 60 FPS at 1080p, ~200k active entities, 16 km view distance
```

## 3. Reverb — real-time convolution audio plugin

```text
APP_DESCRIPTION: A real-time convolution reverb plugin for music production DAWs. It loads impulse-response files, partitions them for zero-latency block convolution, and offers early-reflection shaping and stereo width controls with fully automatable parameters inside the host.
TECH_STACK: C++17 + JUCE + FFTW + SIMD-optimized DSP, packaged as VST3/AU for macOS and Windows
APP_TYPE: desktop
LANGUAGE: C++
SCALE: <3 ms added latency at 48 kHz, 64 partitions, 32 concurrent instances
```

## 4. Sightline — factory defect vision inspector

```text
APP_DESCRIPTION: A machine-vision inspection service for a manufacturing line. It captures frames from GigE industrial cameras, runs classical and deep defect-detection pipelines, and signals PLCs to reject faulty parts while logging annotated images for quality audits.
TECH_STACK: C++20 + OpenCV + TensorRT + Pylon SDK + gRPC control channel, deployed on an edge industrial PC with NVIDIA GPU
APP_TYPE: API service
LANGUAGE: C++
SCALE: 120 parts/min, 4 cameras at 20 MP, <40 ms per inspection
```

## 5. Kelpie — autonomous rover navigation stack

```text
APP_DESCRIPTION: A navigation stack for an autonomous warehouse rover. It fuses wheel odometry, IMU, and 2D LiDAR to localize on a prebuilt map, plans collision-free paths, and issues velocity commands to the motor controllers under a real-time control loop.
TECH_STACK: C++17 + ROS 2 + Eigen + PCL + Nav2, running on an NVIDIA Jetson under Ubuntu
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 50 Hz control loop, 30 rovers per site, 8-hour shifts
```

## 6. Chisel — parametric CAD kernel service

```text
APP_DESCRIPTION: A parametric CAD modeling backend for a browser-based mechanical design tool. It maintains boundary-representation solids, replays feature histories (extrude, fillet, boolean), and returns tessellated meshes and mass properties to the front end.
TECH_STACK: C++20 + OpenCASCADE + Drogon HTTP server + PostgreSQL for document metadata, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: ~800 concurrent model sessions, avg 1,500 features per part
```

## 7. Fissure — computational fluid dynamics solver

```text
APP_DESCRIPTION: A finite-volume CFD solver for aerospace cooling simulations. It partitions unstructured meshes across MPI ranks, solves compressible Navier-Stokes with implicit time stepping, and writes field snapshots for post-processing.
TECH_STACK: C++20 + MPI + PETSc + Eigen + HDF5 output, run on an HPC cluster via SLURM
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 512 MPI ranks, 80M-cell meshes, 12-hour runs
```

## 8. Millstone — embedded LSM key-value store

```text
APP_DESCRIPTION: An embeddable log-structured key-value storage engine for high-write telemetry apps. It provides ordered iteration, snapshots, and column families with configurable compaction, exposing a C++ API and a thin C ABI for bindings.
TECH_STACK: C++17 + RocksDB internals + jemalloc + io_uring async I/O, distributed as a static library via CMake/vcpkg
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 500k writes/sec, 2 TB datasets, <1 ms p99 point reads
```

## 9. Prism — GPU video transcoding farm

```text
APP_DESCRIPTION: A hardware-accelerated video transcoding service for a streaming platform. It ingests source masters, generates adaptive bitrate ladders, and packages HLS/DASH segments while offloading decode and encode to GPU codecs.
TECH_STACK: C++20 + FFmpeg libav + NVENC/NVDEC + ZeroMQ job queue + S3 storage, deployed on GPU nodes in Kubernetes
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 3,000 concurrent transcodes, 8 renditions per title, 20 PB library
```

## 10. Cinder — RTOS sensor firmware framework

```text
APP_DESCRIPTION: A firmware framework for a battery-powered environmental sensor node. It schedules periodic ADC sampling, applies calibration, buffers readings, and transmits compressed batches over BLE while aggressively managing sleep states for multi-year battery life.
TECH_STACK: C++17 (embedded, no exceptions/RTTI) + FreeRTOS + CMSIS + nanopb, cross-compiled for ARM Cortex-M4
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 32 KB RAM, 1 Hz sampling, 3-year battery target
```

## 11. Tessellate — real-time terrain LOD editor

```text
APP_DESCRIPTION: A desktop terrain authoring tool for game studios. It streams heightmap tiles, applies sculpting and erosion brushes on the GPU, and previews continuous level-of-detail meshing with material splatting in an interactive viewport.
TECH_STACK: C++20 + OpenGL 4.6 + Dear ImGui + compute shaders + GDAL for geodata import, built with CMake for Windows
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 16k×16k heightmaps, 120 FPS editing, 4 GB tile cache
```

## 12. Quench — options pricing analytics engine

```text
APP_DESCRIPTION: A command-line derivatives pricing tool for quantitative analysts. It reads a portfolio file, prices vanilla and exotic options via analytic and Monte Carlo methods, computes Greeks, and writes risk reports to CSV and Parquet.
TECH_STACK: C++20 + Intel TBB + QuantLib + Boost.Multiprecision + Apache Arrow, distributed as a static binary via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 400k-position portfolios, 2M revaluations/sec, <30 s full run
```

## 13. Halyard — MQTT industrial message broker

```text
APP_DESCRIPTION: A high-throughput MQTT broker tuned for factory-floor IoT. It handles massive fan-out of sensor topics, enforces per-tenant ACLs, persists retained messages, and bridges selected topics to an upstream time-series database.
TECH_STACK: C++20 + Boost.Asio + ProtoBuf + RocksDB persistence + libpqxx bridge, deployed as a container on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 1M concurrent connections, 300k msgs/sec, 50k topics
```

## 14. Obsidian — offline map rendering mobile app

```text
APP_DESCRIPTION: A cross-platform mobile app for offline outdoor navigation. It renders vector map tiles on-device, computes routing on cached graphs, and tracks GPS breadcrumbs for hikes with no network dependency in the backcountry.
TECH_STACK: C++17 core + Qt6/QML UI + Mapbox GL Native + SQLite tile store, cross-compiled for iOS and Android
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 2 GB offline region, 60 FPS pan/zoom, 200k routing nodes
```

## 15. Bedrock — columnar analytics query engine

```text
APP_DESCRIPTION: A vectorized columnar query engine for interactive analytics on event data. It scans compressed columnar segments, executes SIMD-accelerated filters and aggregations, and returns sub-second results over billions of rows.
TECH_STACK: C++20 + Apache Arrow + abseil + LLVM ORC JIT for expression codegen, deployed on AWS with S3-backed storage
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 20B rows scanned/sec cluster-wide, 8 TB compressed, <500 ms p95
```

## 16. Halcyon — spatial audio game middleware

```text
APP_DESCRIPTION: An audio middleware runtime for console and PC games. It mixes hundreds of positional voices, applies HRTF binaural spatialization and occlusion, and streams compressed banks with sample-accurate event scheduling.
TECH_STACK: C++17 + custom DSP graph + Opus decoding + SIMD mixing, integrated via CMake for consoles, Windows, and Linux
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 512 simultaneous voices, <10 ms mix latency, 30 MB voice pool
```

## 17. Cairn — point cloud registration pipeline

```text
APP_DESCRIPTION: A batch pipeline for surveying firms that aligns terrestrial LiDAR scans into a unified point cloud. It detects features, runs coarse-to-fine ICP registration, removes outliers, and exports georeferenced tiles for downstream modeling.
TECH_STACK: C++20 + PCL + Eigen + Ceres Solver + LASlib I/O, run as batch jobs on a compute cluster
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 400 scans, 12B points, ~90-minute alignment jobs
```

## 18. Talon — kernel-bypass packet firewall

```text
APP_DESCRIPTION: A stateful network firewall appliance for data-center edges. It inspects packets at line rate, enforces connection-tracking rules and rate limits, and mirrors flow metadata to a telemetry sink for security analytics.
TECH_STACK: C++20 + DPDK + eBPF hooks + hash-based flow tables + ZeroMQ export, on bare-metal Linux appliances
APP_TYPE: API service
LANGUAGE: C++
SCALE: 100 Gbps line rate, 8M concurrent flows, <2 µs per-packet
```

## 19. Emberline — thermal simulation desktop suite

```text
APP_DESCRIPTION: A command-line thermal analysis tool for electronics engineers. It reads PCB geometry, meshes components, solves transient heat conduction, and writes temperature fields and hotspot reports for downstream review.
TECH_STACK: C++20 + Eigen sparse solvers + OpenMP + VTK output, distributed as a static binary via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 5M mesh elements, 10k time steps, ~15-minute solves
```

## 20. Warden — embedded ANPR camera app

```text
APP_DESCRIPTION: An on-camera license plate recognition application for parking enforcement. It detects and rectifies plates in the video stream, runs an OCR model, and posts matched events with cropped evidence over a cellular uplink.
TECH_STACK: C++17 + OpenCV + NCNN inference + GStreamer capture, cross-compiled for an ARM SoC camera under embedded Linux
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 30 FPS at 4K, <150 ms plate-to-event, 512 MB RAM
```

## 21. Slipstream — HFT order execution router

```text
APP_DESCRIPTION: A smart order router for a high-frequency trading firm. It receives strategy intents, splits orders across venues by predicted fill probability, manages risk limits, and handles acknowledgments and cancels with deterministic latency.
TECH_STACK: C++20 + Boost.Asio + FIX/SBE encoding + lock-free queues + huge-page memory, on colocated bare metal
APP_TYPE: API service
LANGUAGE: C++
SCALE: 500k orders/sec, <8 µs decision latency, 14 venues
```

## 22. Foundry — asset build data pipeline

```text
APP_DESCRIPTION: A command-line content build tool for a AAA game studio. It cooks textures, meshes, and audio into platform-optimized formats, resolves asset dependencies, and produces incremental patches for shipping builds.
TECH_STACK: C++20 + custom DAG scheduler + Basis Universal + meshoptimizer + RocksDB build cache, run on Windows build agents
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 1.2M assets, 40-minute incremental cook, 8 target platforms
```

## 23. Vellum — collaborative code editor core

```text
APP_DESCRIPTION: The document and editing core for a native desktop code editor. It manages a piece-table text buffer, incremental syntax highlighting, and CRDT-based collaborative editing synchronized between peers.
TECH_STACK: C++20 + tree-sitter + Automerge-style CRDT + Qt6 UI + WebSocket sync, built with CMake for all desktop platforms
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 10 MB files, <5 ms keystroke latency, 20 concurrent collaborators
```

## 24. Pulsar — real-time ad bidding service

```text
APP_DESCRIPTION: A real-time bidding service for a programmatic advertising exchange. It scores incoming bid requests against campaign models, applies budget pacing and frequency caps, and returns a bid within the auction timeout.
TECH_STACK: C++20 + Pistache HTTP + abseil + Redis + gradient-boosted model inference, deployed on AWS EC2 fleets
APP_TYPE: API service
LANGUAGE: C++
SCALE: 1.5M bid requests/sec, <20 ms budget, 30k active campaigns
```

## 25. Anvil — physics engine for robotics sim

```text
APP_DESCRIPTION: A rigid-body physics engine for robotics simulation environments. It integrates constrained multibody dynamics, resolves contacts with friction, and exposes deterministic stepping for reinforcement-learning rollouts.
TECH_STACK: C++20 + Eigen + custom LCP solver + SIMD + Python bindings via pybind11, built with CMake
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 1,000 parallel envs, 240 Hz stepping, 500-body scenes
```

## 26. Meridian — GNSS RTK positioning engine

```text
APP_DESCRIPTION: A precise positioning engine for agricultural autosteer systems. It processes raw GNSS observations with RTK corrections, resolves carrier-phase ambiguities, and outputs centimeter-accurate position and heading to the vehicle controller.
TECH_STACK: C++17 + Eigen + RTKLIB core + serial/NTRIP I/O, running on an embedded Linux compute module
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 10 Hz fixes, <2 cm accuracy, 3 constellations
```

## 27. Kilnworks — 3D print slicer engine

```text
APP_DESCRIPTION: A command-line slicing tool for desktop FDM 3D printers. It repairs input meshes, generates layered toolpaths with adaptive infill and supports, and emits optimized G-code with configurable speed and cooling profiles.
TECH_STACK: C++20 + CGAL + Clipper2, distributed as a static binary via CMake for Windows, macOS, and Linux
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 5M-triangle models, 20k layers, <30 s slice time
```

## 28. Backdraft — distributed in-memory cache

```text
APP_DESCRIPTION: A distributed in-memory cache service backing a large web platform. It shards keys with consistent hashing, replicates hot entries, supports TTL eviction and LRU, and serves get/set over a binary protocol with pipelining.
TECH_STACK: C++20 + Boost.Asio + folly data structures + jemalloc + gossip membership, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 5M ops/sec/node, 256 GB per node, 64-node cluster
```

## 29. Cascade — HDR photo processing app

```text
APP_DESCRIPTION: A desktop RAW photo editor with HDR merging. It decodes camera RAW files, aligns and merges bracketed exposures, applies tone mapping and local adjustments on the GPU, and exports color-managed outputs.
TECH_STACK: C++20 + LibRaw + OpenGL compute + Little CMS + Qt6, built with CMake for macOS and Windows
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 100 MP RAW files, 9-frame brackets, <2 s preview render
```

## 30. Signalman — SDR spectrum monitoring tool

```text
APP_DESCRIPTION: A software-defined radio spectrum monitoring application. It streams IQ samples from an SDR, computes rolling FFT waterfalls, detects and classifies signal bursts, and logs occupancy statistics for RF surveys.
TECH_STACK: C++17 + liquid-dsp + FFTW + SoapySDR + Dear ImGui, built with CMake for Linux and Windows
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 40 MHz bandwidth, 8k-bin FFT at 60 Hz, 24-hour captures
```

## 31. Loamstone — genomic variant calling pipeline

```text
APP_DESCRIPTION: A batch pipeline for a genomics lab that calls variants from sequencing reads. It aligns reads to a reference, marks duplicates, applies local realignment, and emits a filtered variant set with quality annotations.
TECH_STACK: C++20 + htslib + SIMD alignment kernels + OpenMP, run as containerized batch jobs on an HPC cluster
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 30x whole genomes, 4M variants/sample, ~2-hour runtimes
```

## 32. Ratchet — deterministic build cache server

```text
APP_DESCRIPTION: A remote build cache and execution service for large C++ monorepos. It stores content-addressed action outputs, deduplicates artifacts, and serves cache hits to distributed compilers to cut incremental build times.
TECH_STACK: C++20 + gRPC (Remote Execution API) + RocksDB + content-addressed blob store, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 50k cache lookups/sec, 40 TB blob store, 92% hit rate
```

## 33. Nimbus — weather nowcasting compute engine

```text
APP_DESCRIPTION: A short-term precipitation nowcasting engine for a weather service. It ingests radar reflectivity grids, advects fields with optical-flow motion estimation, and produces gridded rainfall forecasts refreshed every few minutes.
TECH_STACK: C++20 + CUDA + Eigen + NetCDF I/O + gRPC serving, deployed on GPU cloud instances
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 4k×4k radar grids, 5-minute refresh, 90-minute lead time
```

## 34. Palisade — TLS-terminating reverse proxy

```text
APP_DESCRIPTION: A high-performance reverse proxy and load balancer for microservice fleets. It terminates TLS, routes by host and path, applies retries and circuit breaking, and exports rich latency metrics per upstream.
TECH_STACK: C++20 + Boost.Asio + BoringSSL + HTTP/2 + Prometheus exposition, deployed as a sidecar on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 200k req/sec/instance, 10k upstreams, <1 ms added latency
```

## 35. Driftwood — ocean simulation renderer

```text
APP_DESCRIPTION: A real-time ocean rendering component for maritime training simulators. It synthesizes wave spectra with FFT-based displacement, renders foam and subsurface scattering, and couples buoyancy forces back to floating vessels.
TECH_STACK: C++20 + Vulkan + cuFFT + Eigen, built with CMake for Windows training rigs
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 512×512 FFT ocean, 90 FPS at 4K, 12 dynamic vessels
```

## 36. Gantry — container image build daemon

```text
APP_DESCRIPTION: A daemon that builds OCI container images from build definitions. It resolves layers, executes build steps in isolated namespaces, deduplicates content, and pushes signed images to a registry.
TECH_STACK: C++20 + libcurl + Protobuf + OverlayFS + content-addressed store, running on Linux CI hosts
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 5k builds/day, 200-layer images, 3 TB layer cache
```

## 37. Solstice — astronomy plate solving CLI

```text
APP_DESCRIPTION: A command-line tool for astrophotographers that solves the sky coordinates of an image. It extracts star centroids, matches geometric hashes against a catalog, and outputs a WCS solution plus annotated object overlays.
TECH_STACK: C++17 + CFITSIO + Eigen + kd-tree matching, distributed as a static binary via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 24 MP frames, <3 s solve, 100M-star index
```

## 38. Ironclad — automotive CAN diagnostics tool

```text
APP_DESCRIPTION: A desktop diagnostics tool for automotive technicians. It connects to a vehicle's CAN buses, decodes DBC-defined signals, runs UDS diagnostic sessions, and plots live parameters with fault-code reading and clearing.
TECH_STACK: C++20 + SocketCAN + Qt6 + Boost.Signals2, built with CMake for Linux and Windows
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 4 CAN buses at 1 Mbps, 2k signals, 100 Hz plotting
```

## 39. Beacon — mesh networking router firmware

```text
APP_DESCRIPTION: Firmware for a self-healing wireless mesh router. It maintains routing tables via a distance-vector protocol, forwards packets across radio links, and rebalances traffic as nodes join or fail, all within tight memory limits.
TECH_STACK: C++17 (embedded) + lwIP + FreeRTOS + nanopb config, cross-compiled for a MIPS SoC
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 64-node mesh, 200 KB heap, sub-second reconvergence
```

## 40. Wavelength — DSP synthesizer instrument

```text
APP_DESCRIPTION: A mobile software synthesizer app for musicians. It offers wavetable and FM oscillators, a modulation matrix, and a resonant filter with polyphonic voice allocation, playable via on-screen keyboard or MIDI over USB and Bluetooth.
TECH_STACK: C++17 + JUCE + SIMD oscillator kernels, cross-compiled for iOS and Android
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 64-voice polyphony, <8 ms latency, 300 wavetables
```

## 41. Quarry — full-text search index engine

```text
APP_DESCRIPTION: A command-line full-text indexing tool for local document collections. It builds inverted indexes with positional postings, runs boolean and phrase queries with BM25 ranking, and updates indexes incrementally as files change.
TECH_STACK: C++20 + abseil + memory-mapped segments + SIMD posting decode, distributed as a static binary via CMake/vcpkg
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 50M documents, <15 ms query p95, 120 GB index
```

## 42. Redshift — distributed ray tracer

```text
APP_DESCRIPTION: A distributed path-tracing renderer for architectural visualization. It builds BVH acceleration structures, traces physically based light transport across worker nodes, and streams progressively refined tiles to the artist.
TECH_STACK: C++20 + Embree + OpenImageDenoise + ZeroMQ tile distribution, deployed on a render farm
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 4K frames, 4,096 samples/pixel, 40-node farm
```

## 43. Sentry — real-time fraud scoring service

```text
APP_DESCRIPTION: A real-time fraud scoring service for a payments processor. It enriches each transaction with velocity features, evaluates gradient-boosted and rule-based models, and returns an approve/decline decision within the authorization window.
TECH_STACK: C++20 + Drogon + abseil + Redis feature store + XGBoost inference, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 80k transactions/sec, <25 ms budget, 900 features
```

## 44. Loomframe — video compositing engine

```text
APP_DESCRIPTION: A node-based video compositing engine for post-production. It evaluates a graph of image operations, caches intermediate frames, and renders effects with GPU acceleration and color-managed pipelines for final delivery.
TECH_STACK: C++20 + OpenGL + OpenColorIO + OpenEXR + Qt6, built with CMake for Linux and Windows workstations
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 8K plates, 300-node graphs, real-time 1080p playback
```

## 45. Ledgerstone — append-only event store

```text
APP_DESCRIPTION: An append-only event store for event-sourced systems. It writes immutable event streams with per-stream ordering, supports snapshotting and subscriptions, and serves catch-up reads to projection builders.
TECH_STACK: C++20 + io_uring + Protobuf + memory-mapped segments + gRPC subscriptions, deployed on Linux
APP_TYPE: API service
LANGUAGE: C++
SCALE: 1M events/sec append, 500k streams, 5 TB retained
```

## 46. Kestrel — drone flight controller stack

```text
APP_DESCRIPTION: A flight control stack for an autonomous quadrotor. It runs attitude and position estimators, executes a cascaded PID/geometric controller, and manages mission waypoints and failsafes within a hard real-time loop.
TECH_STACK: C++17 (embedded) + Eigen + MAVLink + NuttX RTOS, cross-compiled for an STM32H7 flight controller
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 1 kHz control loop, <200 g compute board, 6 failsafe modes
```

## 47. Cobblestone — build system CLI

```text
APP_DESCRIPTION: A fast, correct build tool for polyglot repositories. It parses build graphs, hashes inputs for incremental rebuilds, schedules jobs across cores with dependency ordering, and caches outputs for reproducibility.
TECH_STACK: C++20 + abseil + Ninja-style graph + content hashing + thread pool, distributed as a single binary via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 200k build nodes, 32-core scheduling, <2 s null build
```

## 48. Verdigris — image similarity search API

```text
APP_DESCRIPTION: A command-line visual similarity tool for image libraries. It computes deep embeddings for a folder of images, builds an approximate nearest-neighbor index on disk, and returns visually similar matches for a query image.
TECH_STACK: C++20 + FAISS + ONNX Runtime + libjpeg-turbo, distributed as a CLI via CMake (CUDA optional)
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 200M image vectors, <30 ms query, 512-dim embeddings
```

## 49. Grindstone — matrix computation library

```text
APP_DESCRIPTION: A high-performance dense and sparse linear algebra library for scientific applications. It provides blocked factorizations, iterative solvers, and eigenvalue routines with multi-threaded and SIMD-optimized kernels.
TECH_STACK: C++23 + templates/concepts + OpenMP + BLAS/LAPACK backends + SIMD intrinsics, packaged via CMake/vcpkg
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 50k×50k dense solves, 90% peak FLOPS, 64-thread scaling
```

## 50. Stormglass — market backtesting engine

```text
APP_DESCRIPTION: An event-driven backtesting engine for quantitative researchers. It replays historical tick and bar data through strategy callbacks, simulates order fills with slippage models, and reports performance and risk statistics.
TECH_STACK: C++20 + Boost + Apache Arrow data loading + Python bindings via pybind11, run on research workstations
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 10 years tick data, 5B events, <5-minute full backtest
```

## 51. Cauldron — molecular dynamics simulator

```text
APP_DESCRIPTION: A molecular dynamics engine for computational chemistry research. It computes bonded and non-bonded forces with neighbor lists, integrates Verlet dynamics, and applies thermostats while writing trajectory frames for analysis.
TECH_STACK: C++20 + CUDA + Eigen + HDF5 trajectories + MPI domain decomposition, run on GPU clusters via SLURM
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 2M atoms, 2 fs timestep, 100 ns simulations
```

## 52. Portcullis — API gateway rate limiter

```text
APP_DESCRIPTION: An API gateway edge service handling authentication and rate limiting. It validates tokens, enforces sliding-window quotas per client, routes to backends, and emits structured access logs for billing and abuse detection.
TECH_STACK: C++20 + Boost.Beast + JWT validation + Redis counters + Protobuf logs, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 300k req/sec, 100k API keys, <1 ms auth overhead
```

## 53. Anthracite — log ingestion pipeline

```text
APP_DESCRIPTION: A high-volume log ingestion and enrichment pipeline for a security operations team. It parses varied log formats, normalizes fields, enriches with GeoIP and threat feeds, and writes to a search backend with backpressure handling.
TECH_STACK: C++20 + RE2 parsing + ZeroMQ + abseil + Elasticsearch bulk sink, deployed on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 2M events/sec, 40 log formats, 15 TB/day
```

## 54. Bastion — encrypted backup engine CLI

```text
APP_DESCRIPTION: A deduplicating encrypted backup tool for servers and workstations. It chunks files with content-defined boundaries, deduplicates and compresses blocks, encrypts them, and uploads to object storage with verifiable restore.
TECH_STACK: C++20 + libsodium + zstd + rolling-hash chunking + libcurl to S3, distributed as a static binary via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 10 TB repositories, 4 MB avg chunk, 60% dedup ratio
```

## 55. Overtone — guitar amp modeling plugin

```text
APP_DESCRIPTION: A guitar amplifier and cabinet modeling plugin for players and producers. It emulates nonlinear tube stages with oversampled waveshaping, applies impulse-response cabinets, and offers a tuner and noise gate in a DAW.
TECH_STACK: C++17 + JUCE + oversampled DSP + SIMD convolution, packaged as VST3/AU/AAX for macOS and Windows
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 8x oversampling, <5 ms latency, 40 amp models
```

## 56. Tideline — real-time analytics stream processor

```text
APP_DESCRIPTION: A streaming analytics processor for a product telemetry platform. It consumes event streams, maintains windowed aggregations and sketches, and serves live dashboards with approximate distinct counts and percentiles.
TECH_STACK: C++20 + Kafka consumer + folly + HyperLogLog/t-digest sketches + gRPC serving, deployed on Kubernetes
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 3M events/sec, 1-second windows, 50k dashboard queries/min
```

## 57. Graphite — scene graph 3D viewer

```text
APP_DESCRIPTION: A mobile 3D model viewer app for engineering review on the go. It loads glTF assemblies, organizes them in a scene graph with instancing, and renders PBR materials with section and measurement tools driven by touch gestures.
TECH_STACK: C++20 + Vulkan/Metal + Assimp + Dear ImGui, cross-compiled for iOS and Android
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 20M-triangle assemblies, 60 FPS, 50k scene nodes
```

## 58. Basalt — time-series database engine

```text
APP_DESCRIPTION: A purpose-built time-series database for infrastructure metrics. It ingests labeled samples, compresses them with delta-of-delta and XOR encoding, and answers range and aggregation queries over long retention windows.
TECH_STACK: C++20 + memory-mapped blocks + Gorilla compression + gRPC + RocksDB index, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 5M samples/sec ingest, 2B active series, 13-month retention
```

## 59. Hollowpoint — game networking netcode library

```text
APP_DESCRIPTION: A client-server networking library for competitive multiplayer games. It handles snapshot interpolation, client-side prediction and reconciliation, delta compression, and lag compensation over an unreliable UDP transport.
TECH_STACK: C++17 + custom UDP protocol + bitpacking serialization + GameNetworkingSockets, integrated via CMake
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 64 players/match, 64 Hz tick, <100 ms compensated lag
```

## 60. Cindergrid — power grid state estimator

```text
APP_DESCRIPTION: A state estimation service for an electric utility control center. It ingests SCADA measurements, solves a weighted-least-squares network estimate, detects bad data, and publishes bus voltages and line flows to operators.
TECH_STACK: C++20 + Eigen sparse + SuiteSparse + Boost + PostgreSQL/libpqxx, deployed on redundant on-prem servers
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 20k buses, 4-second cycle, 60k measurements
```

## 61. Quill — structured PDF generation library

```text
APP_DESCRIPTION: A command-line PDF generation tool for reporting workflows. It lays out text, tables, and vector graphics with pagination from template and data files, embeds fonts and images, and produces tagged, searchable documents.
TECH_STACK: C++20 + FreeType + HarfBuzz + zlib + custom layout engine, distributed as a static binary via CMake/vcpkg
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 50k pages/sec, 200-page reports, 40 embedded fonts
```

## 62. Riftvalley — seismic imaging processor

```text
APP_DESCRIPTION: A seismic data processing pipeline for oil and gas exploration. It reads shot gathers, applies velocity analysis and migration, and produces subsurface reflectivity images for interpretation.
TECH_STACK: C++20 + CUDA + FFTW + MPI + SEG-Y I/O, run on GPU HPC clusters via SLURM
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 10 TB surveys, 200M traces, 6-hour migration jobs
```

## 63. Steadfast — embedded HMI dashboard app

```text
APP_DESCRIPTION: A touchscreen HMI application for industrial machinery. It renders a fluid control dashboard, reads live PLC tags over industrial protocols, drives alarms and setpoints, and logs operator actions to local storage.
TECH_STACK: C++17 + Qt6/QML + Modbus/OPC UA + SQLite, cross-compiled for an ARM industrial panel under embedded Linux
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 800×480 panel, 500 live tags, 60 FPS UI
```

## 64. Voltaic — battery management system firmware

```text
APP_DESCRIPTION: Firmware for an electric vehicle battery management system. It measures cell voltages and temperatures, estimates state of charge and health, balances cells, and enforces safety limits with fault isolation.
TECH_STACK: C++17 (embedded, MISRA-aligned) + CMSIS + CAN + fixed-point math, cross-compiled for an automotive-grade MCU
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 108 cells, 10 ms measurement cycle, <1% SoC error
```

## 65. Thornfield — vector tile map server

```text
APP_DESCRIPTION: A vector tile server for a web mapping platform. It queries geospatial features, clips and simplifies geometry per zoom level, encodes Mapbox Vector Tiles, and serves them with caching to browser and mobile clients.
TECH_STACK: C++20 + Boost.Geometry + PostGIS/libpqxx + Crow HTTP + Redis cache, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 60k tiles/sec, 15 zoom levels, 500M features
```

## 66. Emberflux — GPU particle VFX editor

```text
APP_DESCRIPTION: A real-time particle effects authoring tool for games and film. It simulates millions of GPU particles with force fields and collisions, previews shading, and exports effect definitions for runtime playback.
TECH_STACK: C++20 + DirectX 12 + compute shaders + Dear ImGui, built with CMake for Windows
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 5M particles, 120 FPS, 200 emitters
```

## 67. Almanac — high-throughput scheduler service

```text
APP_DESCRIPTION: A distributed job scheduler for batch compute platforms. It matches queued tasks to worker resources under fairness and priority constraints, tracks execution state, and reschedules on failure with backoff.
TECH_STACK: C++20 + gRPC + abseil + etcd coordination + RocksDB state, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 100k pending tasks, 20k workers, <50 ms scheduling decision
```

## 68. Marlinspike — network protocol fuzzer CLI

```text
APP_DESCRIPTION: A coverage-guided protocol fuzzer for security testing network services. It mutates structured message inputs, drives a target over a socket, tracks coverage feedback, and minimizes crashing test cases for triage.
TECH_STACK: C++20 + LLVM sanitizer coverage + libFuzzer integration + Boost.Asio, distributed as a binary via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 40k execs/sec, 12 protocol grammars, corpus of 200k inputs
```

## 69. Slateworks — spreadsheet calculation engine

```text
APP_DESCRIPTION: A dependency-tracking calculation engine for a spreadsheet application. It builds a formula dependency graph, evaluates cells in topological order, recalculates minimally on edits, and supports array and cross-sheet references.
TECH_STACK: C++20 + custom expression VM + abseil + topological scheduler, embedded via CMake in a Qt6 desktop app
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 5M cells, <50 ms incremental recalc, 300 functions
```

## 70. Firewatch — thermal camera analytics unit

```text
APP_DESCRIPTION: An edge analytics unit for wildfire early detection. It processes thermal and RGB camera streams, detects heat anomalies and smoke plumes, geolocates events, and dispatches alerts over a low-bandwidth link.
TECH_STACK: C++17 + OpenCV + TensorRT + GStreamer, deployed on an NVIDIA Jetson at remote tower sites
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 15 FPS dual-stream, <2 s detection, 25 W power budget
```

## 71. Copperhead — DEX matching engine

```text
APP_DESCRIPTION: A central limit order book matching engine for a digital asset exchange. It maintains price-time-priority books, matches incoming orders deterministically, publishes fills and market data, and journals every event for replay.
TECH_STACK: C++20 + lock-free order book + SBE encoding + aeron messaging + RocksDB journal, on colocated bare metal
APP_TYPE: API service
LANGUAGE: C++
SCALE: 1M orders/sec, <10 µs match latency, 500 trading pairs
```

## 72. Millpond — ETL data transformation engine

```text
APP_DESCRIPTION: A high-throughput ETL engine for a data warehouse team. It reads source files and databases, applies typed transformation graphs with schema validation, and writes partitioned columnar output to the lake.
TECH_STACK: C++20 + Apache Arrow + Parquet + abseil + thread-pool executor, deployed on cloud batch compute
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 2 TB/hour throughput, 400 transformation steps, 50 sources
```

## 73. Hoarfrost — climate model post-processor

```text
APP_DESCRIPTION: A post-processing pipeline for climate model ensembles. It reads gridded NetCDF outputs, regrids and computes statistical diagnostics across ensemble members, and emits derived indices for researchers.
TECH_STACK: C++20 + NetCDF + Eigen + OpenMP + HDF5, run as batch jobs on an HPC cluster
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 100-member ensembles, 1 km grids, 5 TB per experiment
```

## 74. Ironwood — CAD constraint solver library

```text
APP_DESCRIPTION: A command-line geometric constraint solving tool for CAD build pipelines. It reads 2D sketch definitions, resolves coincidence, distance, and angle constraints into consistent geometry, and reports over- and under-constrained systems.
TECH_STACK: C++20 + Eigen + custom Newton solver + graph decomposition, distributed as a CLI via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 5k entities, 8k constraints, <50 ms per solve
```

## 75. Nightjar — RTSP video surveillance NVR

```text
APP_DESCRIPTION: A mobile app for monitoring security camera fleets. It connects to on-site NVRs, plays live and recorded RTSP streams with hardware decoding, scrubs motion-triggered events, and pushes alerts for detected objects.
TECH_STACK: C++20 + FFmpeg + Qt6/QML + SQLite metadata, cross-compiled for iOS and Android
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 128 cameras at 1080p, 30-day archive, 8 AI channels
```

## 76. Petrichor — ROS perception pipeline

```text
APP_DESCRIPTION: A perception pipeline for an autonomous delivery robot. It fuses camera and LiDAR data, segments the drivable surface, detects and tracks pedestrians and obstacles, and publishes an occupancy grid to the planner.
TECH_STACK: C++17 + ROS 2 + PCL + OpenCV + TensorRT, running on an NVIDIA Orin under Ubuntu
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 20 Hz fused output, 3 cameras + 1 LiDAR, <80 ms latency
```

## 77. Sablewing — flight simulator avionics engine

```text
APP_DESCRIPTION: An avionics simulation engine for a desktop flight simulator. It models aircraft systems, drives glass-cockpit instruments and autopilot logic, and integrates with the flight dynamics loop for realistic procedures training.
TECH_STACK: C++20 + custom systems modeling + OpenGL instrument rendering + Lua scripting, built with CMake for Windows
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 30 aircraft systems, 60 FPS, 1,200 simulated failures
```

## 78. Coalface — distributed graph processing engine

```text
APP_DESCRIPTION: A distributed graph analytics engine for social and network data. It partitions large graphs across workers, runs vertex-centric algorithms like PageRank and connected components, and returns results with checkpointed fault tolerance.
TECH_STACK: C++20 + MPI + abseil + memory-mapped adjacency + Protobuf messaging, deployed on a compute cluster
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 10B edges, 200M vertices, 32-node processing
```

## 79. Zephyrus — real-time wind simulation service

```text
APP_DESCRIPTION: A microscale wind flow simulation service for urban planning and drone routing. It solves airflow around building geometry on a GPU, exposes queryable wind fields, and streams gust forecasts to client applications.
TECH_STACK: C++20 + CUDA + lattice-Boltzmann solver + gRPC serving + Redis cache, deployed on GPU cloud
APP_TYPE: API service
LANGUAGE: C++
SCALE: 1024³ lattice, 10 Hz field updates, 5 km² domains
```

## 80. Tallowmere — roguelike game engine

```text
APP_DESCRIPTION: A 2D game engine for procedurally generated roguelike titles. It runs a data-driven ECS, generates dungeon layouts, drives sprite-batched rendering and tile physics, and hot-reloads content for rapid iteration.
TECH_STACK: C++20 + SDL2 + EnTT + Lua scripting + spdlog, built with CMake for desktop platforms
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 144 FPS, 50k tiles per level, 2k active entities
```

## 81. Bracken — embedded ML inference runtime

```text
APP_DESCRIPTION: A lightweight neural network inference runtime for microcontrollers. It loads quantized models, executes fused operator kernels with static memory arenas, and runs keyword spotting and gesture recognition on-device.
TECH_STACK: C++17 (embedded) + CMSIS-NN + int8 quantization + static memory planner, cross-compiled for ARM Cortex-M55
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 256 KB model, <10 ms inference, 128 KB RAM budget
```

## 82. Wolfsbane — malware sandbox analysis engine

```text
APP_DESCRIPTION: A dynamic malware analysis engine for a threat research team. It executes suspicious binaries in an instrumented sandbox, traces API calls and network behavior, and produces structured behavior reports and IOCs.
TECH_STACK: C++20 + Intel Pin instrumentation + Boost + Protobuf reports + RocksDB, run on isolated Linux analysis hosts
APP_TYPE: data pipeline
LANGUAGE: C++
SCALE: 20k samples/day, 90 s per detonation, 4 GB trace per sample
```

## 83. Saltmarsh — oceanographic data ingest API

```text
APP_DESCRIPTION: An ingestion and query API for oceanographic sensor buoys. It receives batched measurements over satellite, validates and quality-flags readings, stores time-series and profiles, and serves them to research dashboards.
TECH_STACK: C++20 + Drogon + TimescaleDB/libpqxx + Protobuf + Redis, deployed on cloud VMs
APP_TYPE: API service
LANGUAGE: C++
SCALE: 2k buoys, 5-minute cadence, 200 parameters each
```

## 84. Emberkiln — GPU accelerated OLAP cube

```text
APP_DESCRIPTION: A GPU-accelerated OLAP engine for interactive business intelligence. It loads fact tables into GPU memory, executes group-by aggregations and joins on the device, and returns sub-second slices for pivot dashboards.
TECH_STACK: C++20 + CUDA + Thrust + Apache Arrow + gRPC, deployed on GPU cloud instances
APP_TYPE: API service
LANGUAGE: C++
SCALE: 5B-row fact tables, <300 ms queries, 80 GB GPU memory
```

## 85. Coldforge — deterministic replay debugger

```text
APP_DESCRIPTION: A record-and-replay debugging tool for native applications. It captures nondeterministic inputs during execution, replays them deterministically, and lets developers step backward through program state to find root causes.
TECH_STACK: C++20 + ptrace + hardware performance counters + LLVM symbolization, distributed as a CLI via CMake for Linux
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 30-minute recordings, <2x runtime overhead, 8 GB traces
```

## 86. Nettlewick — real-time collaboration server

```text
APP_DESCRIPTION: A real-time collaboration backend for a whiteboarding product. It maintains shared document state, resolves concurrent edits with operational transforms, broadcasts updates over WebSockets, and persists snapshots.
TECH_STACK: C++20 + uWebSockets + OT engine + Redis pub/sub + PostgreSQL/libpqxx, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 50k concurrent rooms, 500k connections, <30 ms sync
```

## 87. Grimoire — shader compiler toolchain

```text
APP_DESCRIPTION: A cross-platform shader compilation toolchain for a game engine. It parses a shading language, performs optimization passes, and emits SPIR-V, DXIL, and Metal targets with reflection metadata for the runtime.
TECH_STACK: C++20 + custom AST + SPIRV-Tools + LLVM passes, distributed as a CLI and library via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 12k shader variants, <1 s per compile, 3 backend targets
```

## 88. Hearthstone — smart home hub daemon

```text
APP_DESCRIPTION: A cross-platform mobile app for controlling a local smart home. It discovers devices across Zigbee, Z-Wave, and Matter bridges on the LAN, presents room dashboards, and runs automations with no cloud dependency.
TECH_STACK: C++17 core + Qt6/QML UI + Matter SDK + SQLite + rules VM, cross-compiled for iOS and Android
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 300 devices, 500 automation rules, <100 ms local response
```

## 89. Cragmoor — heightfield physics vehicle sim

```text
APP_DESCRIPTION: A vehicle physics simulation for an off-road racing game. It models suspension, tire friction, and drivetrain over a heightfield terrain, integrates at a fixed timestep, and feeds telemetry to the rendering and audio systems.
TECH_STACK: C++20 + Jolt Physics + Eigen + custom tire model, integrated via CMake for consoles and PC
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 24 vehicles, 240 Hz physics, 16 km² terrain
```

## 90. Saltpan — distributed object storage node

```text
APP_DESCRIPTION: A storage node daemon for a distributed object store. It stores erasure-coded shards, verifies integrity with checksums, participates in rebalancing and repair, and serves S3-compatible get/put requests.
TECH_STACK: C++20 + Boost.Beast + Reed-Solomon coding + io_uring + RocksDB metadata, deployed on bare-metal storage servers
APP_TYPE: API service
LANGUAGE: C++
SCALE: 500 TB/node, 20k req/sec, 12+4 erasure coding
```

## 91. Foxglove — biosignal processing SDK

```text
APP_DESCRIPTION: A real-time biosignal processing SDK for medical wearables. It filters ECG and PPG streams, detects heartbeats and arrhythmias, estimates heart-rate variability, and exposes results to a companion mobile app.
TECH_STACK: C++17 + Eigen + SIMD DSP filters + JNI/Objective-C++ bridges, cross-compiled for iOS and Android
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 512 Hz sampling, <20 ms beat detection, 24-hour recording
```

## 92. Wickerstone — game AI pathfinding library

```text
APP_DESCRIPTION: A command-line navigation mesh baking and pathfinding tool for game build pipelines. It generates navigation meshes from level geometry, validates connectivity, and benchmarks hierarchical A* queries with crowd steering for automation.
TECH_STACK: C++20 + Recast/Detour + custom hierarchical planner + SIMD steering, distributed as a CLI via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 500 agents, <2 ms per path query, 10 km² navmesh
```

## 93. Brightwater — real-time bidenergy trading gateway

```text
APP_DESCRIPTION: A market gateway for an energy trading operation. It connects to power exchange APIs, normalizes order and quote messages, manages position and risk limits, and routes bids for intraday electricity markets.
TECH_STACK: C++20 + Boost.Asio + FIX engine + PostgreSQL/libpqxx + Redis, deployed on low-latency on-prem servers
APP_TYPE: API service
LANGUAGE: C++
SCALE: 50k messages/sec, <50 µs processing, 40 market connections
```

## 94. Cindertrack — race car telemetry desktop suite

```text
APP_DESCRIPTION: A telemetry analysis desktop application for motorsport engineers. It imports logged CAN and GPS channels, time-aligns laps, computes derived channels and sector deltas, and overlays runs on interactive multi-axis charts.
TECH_STACK: C++20 + Qt6 + Qt Charts + Apache Arrow + Eigen, built with CMake for Windows and Linux
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 600 channels at 1 kHz, 50-lap sessions, 4 GB logs
```

## 95. Nightshade — DNS resolver appliance

```text
APP_DESCRIPTION: A high-performance recursive DNS resolver appliance with filtering. It serves recursive queries with an in-memory cache, enforces blocklists and DNSSEC validation, and exports query telemetry for network operators.
TECH_STACK: C++20 + Boost.Asio + concurrent hash cache + DNSSEC crypto + Prometheus metrics, on bare-metal Linux
APP_TYPE: API service
LANGUAGE: C++
SCALE: 800k queries/sec, 10M cache entries, <1 ms cached response
```

## 96. Emberly — mobile AR measurement app

```text
APP_DESCRIPTION: An augmented reality measurement app for contractors. It tracks device pose from camera and IMU, detects planes and edges, and lets users measure distances, areas, and volumes with on-screen annotations saved to projects.
TECH_STACK: C++17 core + ARKit/ARCore bridges + OpenCV + Eigen + Metal/OpenGL ES rendering, cross-compiled for iOS and Android
APP_TYPE: mobile
LANGUAGE: C++
SCALE: 60 FPS tracking, <1% measurement error, 200 saved scenes
```

## 97. Stonecrop — bioinformatics alignment CLI

```text
APP_DESCRIPTION: A command-line sequence alignment tool for research pipelines. It indexes reference genomes with an FM-index, aligns short reads with seed-and-extend using SIMD, and outputs sorted alignments for downstream analysis.
TECH_STACK: C++20 + SIMD Smith-Waterman + htslib + OpenMP, distributed as a static binary via CMake/conda
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 400M reads/hour, 3 GB reference index, 32-thread scaling
```

## 98. Wraithkeep — memory profiler CLI

```text
APP_DESCRIPTION: A heap and allocation profiler for native applications. It intercepts allocations, samples call stacks, tracks lifetimes and fragmentation, and produces flame graphs and leak reports for performance engineers.
TECH_STACK: C++20 + malloc interposition + libunwind + LLVM symbolization + Protobuf output, distributed as a CLI via CMake
APP_TYPE: CLI
LANGUAGE: C++
SCALE: 10M allocations/sec traced, <15% overhead, 5 GB heaps
```

## 99. Duskfall — cinematic real-time renderer

```text
APP_DESCRIPTION: A real-time renderer for virtual production and previsualization. It drives a clustered forward+ pipeline with real-time global illumination, volumetric fog, and depth-of-field, feeding LED wall and preview outputs.
TECH_STACK: C++20 + Vulkan + ray-traced GI + OpenColorIO + Dear ImGui, built with CMake for Windows workstations
APP_TYPE: desktop
LANGUAGE: C++
SCALE: 4K at 60 FPS, 2M-triangle scenes, 500 dynamic lights
```

## 100. Cinderhaven — MMO world simulation server

```text
APP_DESCRIPTION: An authoritative world simulation server for a large multiplayer game. It partitions the game world across shards, simulates entities and combat, replicates relevant state to clients with interest management, and persists progress.
TECH_STACK: C++20 + Boost.Asio + EnTT + Protobuf replication + ScyllaDB/RocksDB persistence, deployed on Kubernetes
APP_TYPE: API service
LANGUAGE: C++
SCALE: 10k players per shard, 20 Hz simulation, 1M persistent entities
```
