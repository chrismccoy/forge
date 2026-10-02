# C facts
Covers: C11/C17, Make/CMake, epoll, pthreads, mmap/O_DIRECT/fsync storage, OpenSSL, systemd services, static and embedded builds
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Event loops and signals

### C-01 epoll edge-triggered needs a drain loop
- Trap: EPOLLET with one read() per event, or with blocking fds.
- Reality: epoll(7) says to use EPOLLET only with nonblocking fds, and to wait again only after read/write returns EAGAIN. Stopping earlier leaves data that gets no new event, so the connection stalls. EPOLLONESHOT fds must be re-armed with EPOLL_CTL_MOD.
- Detect: "EPOLLET", "edge-triggered" with no O_NONBLOCK or EAGAIN loop.
- Fix: Set O_NONBLOCK and loop read/accept/write until EAGAIN, or use level-triggered mode.
- Source: epoll(7) - https://man7.org/linux/man-pages/man7/epoll.7.html

### C-02 Signal handlers may call only async-signal-safe functions
- Trap: The SIGTERM/SIGHUP handler logs with printf, calls malloc/free, or flushes and closes state.
- Reality: Only functions in the signal-safety(7) list are safe. stdio and malloc are not. A handler that changes errno must save and restore it.
- Detect: "signal handler flushes/logs/reloads config", "graceful shutdown in handler".
- Fix: Set a `volatile sig_atomic_t` flag or write to a self-pipe, or use signalfd, and do the work in the main loop.
- Source: signal-safety(7) - https://man7.org/linux/man-pages/man7/signal-safety.7.html

### C-03 fork() in a threaded program
- Trap: A worker pool is started first and then fork() is used for children or helpers that keep running normal code.
- Reality: The child has only the calling thread. Until execve it may call only async-signal-safe functions, because mutexes held by other threads stay locked in the child.
- Detect: pthreads plus "fork a worker/child" with no immediate exec.
- Fix: Fork before creating threads, or exec right away (posix_spawn).
- Source: fork(2) - https://man7.org/linux/man-pages/man2/fork.2.html

## Threads and undefined behavior

### C-04 Condition waits wake spuriously
- Trap: `pthread_cond_wait` is called once under `if (!ready)`.
- Reality: POSIX allows spurious wakeups, and the predicate must be re-checked after every return.
- Detect: a job queue or thread pool design that uses signal/wait with no loop.
- Fix: Use `while (!pred) pthread_cond_wait(...)`.
- Source: pthread_cond_wait (POSIX) - https://pubs.opengroup.org/onlinepubs/9799919799/functions/pthread_cond_wait.html

### C-05 Signed overflow and oversized shifts are UB
- Trap: A hash, checksum, rate limiter or counter relies on `int` wrapping, or shifts by the full width.
- Reality: Signed overflow is undefined, and the compiler may delete the overflow check. Unsigned arithmetic wraps modulo 2^n. A shift by a negative count or by at least the bit width is UB.
- Detect: hashing, CRC, rolling hash or sequence numbers on `int`/`long`; "wraps around".
- Fix: Use `uint32_t`/`uint64_t` for wrapping math, and `__builtin_*_overflow` or explicit checks elsewhere.
- Source: Arithmetic operators - https://en.cppreference.com/w/c/language/operator_arithmetic

## Storage durability

### C-06 fsync(file) does not persist the rename or create
- Trap: "write temp, fsync, rename = durable", or a WAL segment that is created and fsynced only as a file.
- Reality: fsync does not ensure that the directory entry reached disk. The directory needs an explicit fsync too.
- Detect: WAL, checkpoint files, lease/state files, "atomic rename".
- Fix: After create or rename, fsync the parent directory fd.
- Source: fsync(2) - https://man7.org/linux/man-pages/man2/fsync.2.html

### C-07 mmap access past EOF raises SIGBUS
- Trap: The design mmaps files that other processes may truncate or that are still growing, and treats a bad read as an error code.
- Reality: Touching a mapped page beyond the end of the file delivers SIGBUS, which kills the process by default.
- Detect: mmap of logs, indexes or user files; "remap on growth".
- Fix: Map only up to the current size, ftruncate before extending the mapping, or handle SIGBUS deliberately.
- Source: mmap(2) - https://man7.org/linux/man-pages/man2/mmap.2.html

### C-08 O_DIRECT has alignment rules
- Trap: O_DIRECT is used with ordinary malloc buffers and arbitrary offsets and lengths.
- Reality: Buffer address, length and file offset may need alignment (historically the logical block size, typically 512 or 4096 bytes), or EINVAL results. Since Linux 6.1 the rules can be queried with statx STATX_DIOALIGN.
- Detect: "O_DIRECT", "bypass page cache".
- Fix: Use posix_memalign buffers and aligned offsets and lengths, and query STATX_DIOALIGN where available.
- Source: open(2) - https://man7.org/linux/man-pages/man2/open.2.html

## Dependencies and build

### C-09 OpenSSL 1.1.1 and 3.0 are EOL; low-level APIs are deprecated
- Trap: The blueprint targets OpenSSL 1.1.1, or uses `AES_*`, `SHA256_Init`, `HMAC_*`, `RSA_*` or ENGINEs.
- Reality: 1.1.1 reached EOL on 2023-09-11. 3.0 is also out of public support, and 3.5 is the current LTS (to 2030-04-08). 3.x deprecates the low-level algorithm APIs in favor of EVP and ENGINEs in favor of providers. Legacy algorithms such as DES and MD4 need the legacy provider.
- Detect: "OpenSSL 1.1", direct AES/HMAC/SHA calls, ENGINE.
- Fix: Target OpenSSL 3.5 LTS or later and use the EVP APIs (EVP_Cipher*, EVP_MAC, EVP_Digest*).
- Source: OpenSSL release strategy - https://openssl-library.org/policies/releasestrat/index.html ; 1.1.1 EOL - https://openssl-library.org/post/2023-09-11-eol-111/ ; Migration guide - https://docs.openssl.org/3.0/man7/migration_guide/

### C-10 Old cmake_minimum_required breaks on CMake 4
- Trap: `cmake_minimum_required(VERSION 2.8)` or `3.0` is copied from an old template.
- Reality: CMake 4.0 and later fail with an error if the policy version is below 3.5, and CMake 3.31 and later warn below 3.10. The version also switches policies to NEW behavior.
- Detect: minimum versions below 3.10 in the build section.
- Fix: Declare a real floor with an upper bound, e.g. `cmake_minimum_required(VERSION 3.16...3.31)`.
- Source: cmake_minimum_required - https://cmake.org/cmake/help/latest/command/cmake_minimum_required.html

### C-11 systemd Type=simple is "started" at fork
- Trap: Dependent units start "after the daemon is ready" while `Type=simple` is used, or `Type=notify`/WatchdogSec is used without sending notifications.
- Reality: simple is started right after fork(), and exec after the binary is executed. notify waits for `READY=1` via sd_notify. WatchdogSec requires periodic `WATCHDOG=1`. forking suits only a daemon that actually forks.
- Detect: "systemd unit", "After=", "watchdog", daemonizing code.
- Fix: Use Type=notify and send READY=1 after sockets are bound and state is loaded. Send WATCHDOG=1 more often than WatchdogSec. Do not self-daemonize.
- Source: systemd.service(5) - https://man7.org/linux/man-pages/man5/systemd.service.5.html
