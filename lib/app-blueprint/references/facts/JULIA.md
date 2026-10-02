# Julia facts
Covers: Julia 1.x, Pkg, PackageCompiler.jl, threads and Distributed.jl, Oxygen.jl, DataFrames.jl, Rasters.jl
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Latency and deployment

### JL-01 First calls compile: plan for TTFX
- Trap: The blueprint expects a Julia CLI, container or HTTP service to answer its first request fast after a cold start, or sets short health-check or autoscaling timeouts.
- Reality: The first call of each method compiles it. PrecompileTools workloads cache native code in package images and reduce time to first execution, but code not covered is still compiled on first use.
- Detect: scale-to-zero, "fast startup", tight readiness probes, per-call `julia script.jl`.
- Fix: Add PrecompileTools workloads or a PackageCompiler sysimage/app built from a representative trace. Warm up before reporting ready, and use long-lived processes.
- Source: Performance tips, execution latency - https://docs.julialang.org/en/v1/manual/performance-tips/

### JL-02 A PackageCompiler app is a bundle, not a small static binary
- Trap: "single self-contained binary", cross-built for other OSes, or built with hard-coded paths.
- Reality: `create_app` produces a directory (bin plus Julia and dependency libraries) for machines where the same Julia can run. Libraries move only to the same architecture. Methods missed by the trace are still compiled at runtime. Packages that embed absolute paths (build.jl, `find_library`) are not relocatable.
- Detect: "single binary", "cross-compile for Windows/macOS", `@__FILE__`-relative data, deps/build.jl.
- Fix: Ship the whole bundle and build it on each target OS and architecture. Use artifacts, `pkgdir`/RelocatableFolders, and a `precompile_execution_file`.
- Source: PackageCompiler apps - https://julialang.github.io/PackageCompiler.jl/stable/apps.html ; Overview - https://julialang.github.io/PackageCompiler.jl/stable/

### JL-03 A sysimage freezes package versions
- Trap: A custom sysimage speeds startup while the Manifest keeps changing.
- Reality: Packages compiled into a sysimage (with their dependencies) take precedence over the versions in the project, which can silently run old versions. Sysimages generally work only on the machine that built them.
- Detect: "custom sysimage in Docker/dev", no rebuild step on dependency updates.
- Fix: Rebuild the sysimage in CI whenever the Manifest changes, on the target base image.
- Source: Sysimages - https://julialang.github.io/PackageCompiler.jl/stable/sysimages.html ; Overview - https://julialang.github.io/PackageCompiler.jl/stable/

### JL-04 Reproducibility needs the Manifest
- Trap: Only Project.toml is committed, or one Manifest is shared across Julia versions.
- Reality: Project.toml plus Manifest.toml reproduces the exact environment. The Manifest records `julia_version`, and since 1.10.8 version-specific `Manifest-v{major}.{minor}.toml` files are supported. `[compat]` bounds dependencies and Julia.
- Detect: an app or service with no committed Manifest, `Pkg.update()` in a Dockerfile.
- Fix: Commit the Manifest for applications, run `Pkg.instantiate()` in builds, pin Julia's minor version, and set `[compat]`.
- Source: Project and Manifest - https://pkgdocs.julialang.org/v1/toml-files/

## Performance model

### JL-05 Untyped globals and type instability are slow
- Trap: Config, models or connection pools live in untyped globals used by hot code, or structs have abstract fields such as `Vector{Any}`/`Real`.
- Reality: An untyped global may change type, so the compiler cannot optimize code that uses it. Performance-critical code belongs in functions with type-stable returns. Abstract fields and containers defeat specialization.
- Detect: top-level scripts doing heavy work, `global model = ...`, abstract struct fields.
- Fix: Use `const` or typed globals (`x::T = ...`), pass state as arguments, use concrete or parametric fields, and check with `@code_warntype`.
- Source: Performance tips - https://docs.julialang.org/en/v1/manual/performance-tips/

## Concurrency

### JL-06 Threads are fixed at startup
- Trap: The app "scales threads at runtime", or `@threads` code runs in a container started with plain `julia`.
- Reality: Threads are set with `-t`/`--threads` or `JULIA_NUM_THREADS` before start. Since 1.12 the default is 1 worker plus 1 interactive thread, and `-t1` gives no interactive thread. `-t` propagates to `-p` workers.
- Detect: Docker CMD or ENTRYPOINT with no `-t`, "parallel" claims.
- Fix: Set `--threads=auto` or an explicit count in the entrypoint, sized to the container CPU limit.
- Source: Multi-Threading - https://docs.julialang.org/en/v1/manual/multi-threading/

### JL-07 Do not index buffers by threadid(); lock Base collections
- Trap: `bufs[Threads.threadid()]` is used for scratch space, or a shared Dict or Vector is updated with `push!` from tasks.
- Reality: Since 1.7, tasks can migrate between threads when they yield, so threadid() is not stable. `@threads` defaults to `:dynamic`. Base collections need manual locking when any thread mutates them.
- Detect: `nthreads()`-sized buffer arrays, shared caches in handlers.
- Fix: Allocate per task (chunk the work, then spawn), and use locks, Channels or atomics for shared state.
- Source: Multi-Threading, Task Migration and Caveats - https://docs.julialang.org/en/v1/manual/multi-threading/

### JL-08 Distributed workers need code loaded everywhere
- Trap: `using MyPkg` on the master, then `pmap` or `remotecall` using its functions on workers.
- Reality: `using`/`import` loads a module only on the calling process. Code must be available on every process that runs it.
- Detect: Distributed.jl or addprocs with no `@everywhere`.
- Fix: `@everywhere using MyPkg` after addprocs, with the same project and environment on each worker (`--project`).
- Source: Distributed computing - https://docs.julialang.org/en/v1/manual/distributed-computing/

## Libraries

### JL-09 Oxygen.jl: threads, shared context and cron are the app's job
- Trap: `serve()` is expected to use all cores, the shared context is assumed to be thread-safe, or in-app cron jobs are assumed to run once per cluster.
- Reality: Multithreaded serving needs `serveparallel()` and Julia started with more than one thread. The application context has no built-in data-race protection. Registered cron and repeat jobs start in every process that calls serve/serveparallel.
- Detect: ECS, EKS or K8s replicas plus Oxygen `@cron`; mutable pools or caches in context.
- Fix: Use serveparallel with `-t`, guard shared state with locks or Channels, and run scheduled jobs in a single dedicated worker or scheduler.
- Source: Oxygen.jl README - https://github.com/OxygenFramework/Oxygen.jl

### JL-10 DataFrames: `!` aliases, `:` copies
- Trap: `v = df.col` (or `df[!, :col]`) is mutated as if it were a copy, or `df[:, :col] = v` is expected to replace the column type.
- Reality: `df[!, col]` and `df.col` return the stored vector without copying. `df[:, col]` returns a copy. `df[!, col] = v` replaces the column without copying, and `df[:, col] = v` writes in place into the existing vector.
- Detect: in-place updates on extracted columns, type-changing column assignments.
- Fix: Use `copy`/`df[:, col]` for independent data, and `df[!, col] = v` or `transform!` to replace or retype a column.
- Source: DataFrames indexing - https://dataframes.juliadata.org/stable/lib/indexing/

### JL-11 Rasters.jl needs backends loaded and reads eagerly
- Trap: `using Rasters` then `Raster("x.tif")` in a service, with large GeoTIFF, NetCDF or Zarr files assumed to stream.
- Reality: File backends are package extensions: ArchGDAL (GDAL), NCDatasets, GRIBDatasets, ZarrDatasets and others must be installed and loaded. `lazy` is `false` by default, so data is read into memory.
- Detect: large rasters, tiles or zarr on S3, memory limits on ECS or Fargate tasks.
- Fix: Add and `using` the backend package, pass `lazy=true`, and read windows or views.
- Source: Rasters.jl README - https://github.com/rafaqz/Rasters.jl ; API - https://rafaqz.github.io/Rasters.jl/stable/api
