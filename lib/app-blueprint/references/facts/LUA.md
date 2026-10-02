# Lua facts
Covers: OpenResty (lua-nginx-module, lua-resty-*), LuaJIT and FFI, LÖVE, Lapis
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## OpenResty request phases

### LUA-01 Cosockets are not available in every phase
- Trap: The design calls Redis, Kafka or HTTP from `log_by_lua*`, `header_filter_by_lua*`, `body_filter_by_lua*`, `set_by_lua*` or `init_by_lua*`/`init_worker_by_lua*`.
- Reality: The cosocket API is disabled in set, log, header_filter and body_filter, and currently also in init and init_worker. `ngx.socket.tcp` works in rewrite, access, content, `ngx.timer.*` and some ssl_* phases. This affects lua-resty-redis, lua-resty-kafka and lua-resty-http.
- Detect: "in the log phase we push to Kafka/ClickHouse", "on startup load config from Redis/Consul".
- Fix: Buffer the data and send it from `ngx.timer.at(0, ...)` or a batching timer. Load startup state inside a timer created in init_worker.
- Source: lua-nginx-module README, "Cosockets Not Available Everywhere" - https://github.com/openresty/lua-nginx-module#cosockets-not-available-everywhere

### LUA-02 A cosocket belongs to its request
- Trap: One Redis or upstream connection object is kept in a module-level variable and shared across requests or passed into timers.
- Reality: A cosocket lives exactly as long as the handler that created it and must not be shared between requests or handed to a timer ("bad request" error). Reuse goes through the per-worker pool with `setkeepalive`.
- Detect: "global connection", "singleton Redis client" in OpenResty.
- Fix: Connect per request or per timer and call `setkeepalive()` to return the connection to the pool.
- Source: ngx.socket.tcp and ngx.timer.at - https://github.com/openresty/lua-nginx-module#ngxsockettcp

### LUA-03 Blocking I/O stalls the whole worker
- Trap: LuaSocket, `io.popen`, `os.execute`, large `io.*` file reads or a blocking C library over FFI inside request handlers.
- Reality: Network I/O must go through the Nginx Lua APIs. Otherwise the event loop is blocked for every request on that worker. Huge file reads should be avoided too.
- Detect: `require "socket"`, luasql, a synchronous FFI client, "shell out".
- Fix: Use cosocket-based lua-resty-* libraries. Move blocking work to another service.
- Source: lua-nginx-module README, Nginx API for Lua - https://github.com/openresty/lua-nginx-module#nginx-api-for-lua

## OpenResty state

### LUA-04 Lua module state is per worker
- Trap: A module-level table is used as a global cache, counter, rate limiter or session store.
- Reality: Each Nginx worker has its own Lua VM, so module data is per-worker and does not cross process boundaries. `ngx.shared.DICT` (`lua_shared_dict`) is shared by all workers of the instance, but not across hosts or pods.
- Detect: "in-memory counter", "local cache" plus rate limits or quotas; `worker_processes auto`.
- Fix: Use lua_shared_dict for node-wide state, lua-resty-lrucache for per-worker caches, and Redis or Tarantool for cluster-wide state.
- Source: Data Sharing within an Nginx Worker - https://github.com/openresty/lua-nginx-module#data-sharing-within-an-nginx-worker

### LUA-05 shared dict stores scalars only and evicts under pressure
- Trap: Tables are stored in lua_shared_dict, or it is treated as a durable store.
- Reality: Values may be only booleans, numbers, strings or nil. When full, `set` evicts least-recently-used items even if they are unexpired, and may fail with "no memory". Contents are lost on restart.
- Detect: "store the rule set/session table in shared dict", dedup or quotas relying on it being complete.
- Fix: Serialize with cjson. Size the zones, check `forcible`/`err`, and keep authoritative state in Redis or Tarantool.
- Source: ngx.shared.DICT.set - https://github.com/openresty/lua-nginx-module#ngxshareddictset

### LUA-06 init_worker timers run in every worker
- Trap: A "background job" (health check, config poll, flush) is started in `init_worker_by_lua*`, expecting it to run once.
- Reality: init_worker runs once per worker process, so the timer runs N times. `ngx.worker.id()` returns 0..N-1.
- Detect: periodic jobs in init_worker with side effects (writes, purges, external calls).
- Fix: Guard with `if ngx.worker.id() == 0`, or coordinate through a shared-dict lock. Clusters also need cross-node leader election.
- Source: init_worker_by_lua_block and ngx.worker.id - https://github.com/openresty/lua-nginx-module#ngxworkerid

## LuaJIT

### LUA-07 LuaJIT is Lua 5.1 plus selected extensions
- Trap: The code uses Lua 5.3/5.4 features: `_ENV`, integer subtype semantics, `//`, or the `utf8` library.
- Reality: LuaJIT is API- and ABI-compatible with Lua 5.1, so `_ENV` cannot be supported. It backports only the listed 5.2/5.3 extensions (goto, table.move and others). Bit operations use the `bit` module, and 64-bit integers use FFI cdata.
- Detect: "Lua 5.4" plus OpenResty, LÖVE or LuaJIT, or 5.4 syntax in snippets.
- Fix: Target Lua 5.1 semantics with the LuaJIT extensions, and use `bit.*` and FFI `int64_t` where needed.
- Source: LuaJIT extensions - https://luajit.org/extensions.html

### LUA-08 FFI memory is GC-owned
- Trap: A pointer from `ffi.new`/`ffi.cast` is passed to C (libvips, a TLS lib) that keeps it, while no Lua reference is kept.
- Reality: cdata is garbage collected once the last Lua reference is gone. The caller must keep references alive while C uses the memory. C-to-Lua callbacks are slow.
- Detect: FFI bindings with async or retained buffers, "zero-copy".
- Fix: Anchor cdata in a table for the C side's lifetime, use `ffi.gc` for C-allocated memory, and avoid callback-heavy APIs.
- Source: FFI semantics - https://luajit.org/ext_ffi_semantics.html

### LUA-09 LuaJIT has rolling releases; no JIT on iOS
- Trap: The blueprint pins "LuaJIT 2.1.0 tarball" or plans JIT performance on iOS or consoles.
- Reality: LuaJIT publishes no release tarballs. The v2.1 branch is the production branch, and versions are $major.$minor.$commit-timestamp. The JIT compiler is disabled on iOS and consoles (interpreter only).
- Detect: version pins such as "2.1.0-beta3", iOS or console targets with JIT-dependent budgets.
- Fix: Pin a v2.1 commit, or use OpenResty's bundled build. Budget for interpreter speed on iOS.
- Source: LuaJIT status - https://luajit.org/status.html ; Installation - https://luajit.org/install.html

## LÖVE and Lapis

### LUA-10 LÖVE: 11.5 is current, 12.0 unreleased; colors are 0-1
- Trap: The blueprint uses LÖVE 12 APIs (newTextBatch, setStencilMode, love.sensor) as released, or 0-255 colors from older tutorials.
- Reality: The latest release is 11.5 (2023-12-03), and 12.0 is still marked unreleased in the changelog and renames or deprecates many APIs. Since 11.0, all color values range 0-1.
- Detect: 12.0 function names, `setColor(255, ...)`.
- Fix: Target 11.5, set `t.version = "11.5"` in conf.lua, and use 0-1 colors.
- Source: LÖVE changelog - https://github.com/love2d/love/blob/main/changes.txt ; releases - https://github.com/love2d/love/releases

### LUA-11 Lapis with SQLite blocks the worker
- Trap: Lapis on OpenResty with SQLite is expected to stay non-blocking.
- Reality: PostgreSQL (pgmoon) and MySQL (lua-resty-mysql) queries yield on cosockets and are pooled. SQLite queries block, with no pooling. Queries need a cosocket-capable phase (see LUA-01).
- Detect: "Lapis + SQLite" for a concurrent service, DB calls in log or init phases.
- Fix: Use PostgreSQL or MySQL under load, or confine SQLite to low-traffic admin paths.
- Source: Lapis database reference - https://leafo.net/lapis/reference/database.html
