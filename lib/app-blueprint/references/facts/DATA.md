# Data stores facts
Covers: PostgreSQL, PgBouncer, Redis, Kafka, SQLite, MySQL, TimescaleDB, ClickHouse, RabbitMQ, Elasticsearch/OpenSearch
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Concurrency and constraints

### DATA-01 Read-then-write races under default isolation
- Trap: A transaction makes "SELECT balance, then UPDATE" or "check exists, then INSERT" safe.
- Reality: PostgreSQL defaults to READ COMMITTED; InnoDB to REPEATABLE READ, where plain SELECTs read a snapshot. Both let two sessions act on one stale read. PG REPEATABLE READ/SERIALIZABLE fail with SQLSTATE 40001; retry the whole transaction.
- Detect: counters, stock, balances, "if not exists then create".
- Fix: Atomic `UPDATE ... WHERE n > 0 RETURNING`, `SELECT ... FOR UPDATE`, a unique constraint, or SERIALIZABLE with retry.
- Source: Transaction Isolation - https://www.postgresql.org/docs/current/transaction-iso.html

### DATA-02 Upsert needs a unique arbiter
- Trap: `ON CONFLICT` works on any column; `DO NOTHING RETURNING` always returns a row.
- Reality: `ON CONFLICT DO UPDATE` needs a conflict target backed by a unique index or constraint; it is then atomic under concurrency. `DO NOTHING` returns no row for conflicts.
- Detect: upsert without a unique index; ids expected from DO NOTHING.
- Fix: Add the unique index; use `DO UPDATE SET col = EXCLUDED.col`, or re-SELECT when nothing returns.
- Source: INSERT - https://www.postgresql.org/docs/current/sql-insert.html

### DATA-03 NULLs do not collide in UNIQUE
- Trap: `UNIQUE (tenant_id, external_id)` blocks duplicates when a column is NULL.
- Reality: NULLs are distinct by default, so many rows may share them. PG15+ offers `NULLS NOT DISTINCT`.
- Detect: uniqueness invariants over nullable columns; `deleted_at` inside a unique key.
- Fix: Make the columns NOT NULL, use NULLS NOT DISTINCT (PG15+), or a partial unique index.
- Source: Constraints - https://www.postgresql.org/docs/current/ddl-constraints.html

## Schema migrations

### DATA-04 ALTER TABLE locks and rewrites
- Trap: Any ALTER on a live table is instant.
- Reality: PG ALTER TABLE takes ACCESS EXCLUSIVE unless noted. A volatile default (`clock_timestamp()`), stored generated or identity column, or most type changes rewrite the table; a non-volatile default is metadata-only. `SET NOT NULL` scans the table unless a valid CHECK proves no NULLs. MySQL 8.4 changes column types only with ALGORITHM=COPY, blocking DML.
- Detect: big-table migrations with volatile defaults, NOT NULL or type changes.
- Fix: Add nullable, backfill in batches, `ADD CONSTRAINT ... CHECK (c IS NOT NULL) NOT VALID`, `VALIDATE CONSTRAINT`, then SET NOT NULL; set `lock_timeout`.
- Source: ALTER TABLE - https://www.postgresql.org/docs/current/sql-altertable.html ; Online DDL - https://dev.mysql.com/doc/refman/8.4/en/innodb-online-ddl-operations.html

### DATA-05 Index builds block writes
- Trap: `CREATE INDEX` is safe on a busy table, and CONCURRENTLY fits in a normal migration.
- Reality: Plain CREATE INDEX locks out writes. CONCURRENTLY cannot run inside a transaction block; a failed build leaves an INVALID index.
- Detect: index builds in transactional migrations.
- Fix: CONCURRENTLY outside a transaction; on failure drop and rebuild.
- Source: CREATE INDEX - https://www.postgresql.org/docs/current/sql-createindex.html

## Connections

### DATA-06 Connection limits and pooler modes
- Trap: Each serverless call or worker can open its own connections.
- Reality: `max_connections` defaults to 100. PgBouncer defaults to session mode; transaction mode never supports SET, LISTEN, SQL PREPARE, WITH HOLD cursors or session advisory locks. Protocol-level prepared statements work from 1.21 (`max_prepared_statements`; on by default since 1.24).
- Detect: autoscaled app, no pooler; LISTEN, SET or `pg_advisory_lock` via a transaction pooler.
- Fix: Size pools to max_connections; in transaction mode use `pg_advisory_xact_lock`, SET LOCAL.
- Source: Connections - https://www.postgresql.org/docs/current/runtime-config-connection.html ; PgBouncer features - https://www.pgbouncer.org/features.html

## Queues and messaging

### DATA-07 At-least-once delivery needs idempotent handlers
- Trap: Each message is processed exactly once.
- Reality: Kafka is at-least-once by default. RabbitMQ requeues unacked deliveries when a channel closes. Unacked Redis Stream entries get reclaimed.
- Detect: consumer side effects (charges, emails) with no dedup key.
- Fix: Dedup on a message id in the same transaction as the effect.
- Source: Kafka Design - https://kafka.apache.org/43/design/design/ ; Consumer Acknowledgements - https://www.rabbitmq.com/docs/confirms

### DATA-08 Kafka ordering and exactly-once limits
- Trap: A topic is ordered, and exactly-once covers the DB write too.
- Reality: Order holds per partition only. Keys hash to partitions; adding partitions remaps keys and partitions cannot be reduced. Transactions give exactly-once for Kafka-to-Kafka with `isolation.level=read_committed` (default `read_uncommitted`); external outputs must store offsets with the output.
- Detect: "in order" with no key; "exactly-once" into a DB.
- Fix: Key by entity id, fix partition count up front, store offsets with output or dedup.
- Source: Kafka Design - https://kafka.apache.org/43/design/design/ ; Operations - https://kafka.apache.org/43/operations/basic-kafka-operations/

### DATA-09 Kafka consumer defaults lose or replay data
- Trap: Offsets commit after processing, and a new group reads from the start.
- Reality: `enable.auto.commit=true` commits in the background every 5 s. `auto.offset.reset=latest` skips existing data. Exceeding `max.poll.interval.ms` (5 min) triggers a rebalance.
- Detect: slow work in the poll loop; no commit strategy.
- Fix: Commit manually after processing; set the reset policy explicitly; bound work per poll.
- Source: Consumer Configs - https://kafka.apache.org/43/configuration/consumer-configs/

### DATA-10 RabbitMQ acks, prefetch and timeouts
- Trap: Delivered means handled; published means stored.
- Reality: Automatic ack is unsafe fire-and-forget. Default prefetch is unlimited. Broker-side safety needs publisher confirms. Unacked past `consumer_timeout` (30 min): channel closed, requeued.
- Detect: auto-ack, no prefetch, long jobs per message.
- Fix: Manual ack after work, prefetch ~100-300, publisher confirms, split long jobs.
- Source: Acknowledgements - https://www.rabbitmq.com/docs/confirms ; Consumers - https://www.rabbitmq.com/docs/consumers

### DATA-11 Pub/Sub is not a queue
- Trap: Redis Pub/Sub or Postgres LISTEN/NOTIFY can carry jobs or events.
- Reality: Redis Pub/Sub is at-most-once; a disconnected subscriber loses messages. NOTIFY reaches only sessions listening at the time. Neither persists.
- Detect: jobs or cache sync over PUBLISH/NOTIFY.
- Fix: Redis Streams consumer groups (XACK, XAUTOCLAIM), a table queue with `FOR UPDATE SKIP LOCKED`, or a broker.
- Source: Redis Pub/Sub - https://redis.io/docs/latest/develop/pubsub/ ; NOTIFY - https://www.postgresql.org/docs/current/sql-notify.html

## Redis

### DATA-12 Redis is not durable by default
- Trap: Data written to Redis survives a crash.
- Reality: Stock redis.conf has `appendonly no`; RDB snapshots can lose minutes. AOF with default `everysec` can lose ~1 s. Replication is async; Cluster can lose acknowledged writes.
- Detect: sessions, ledgers or queues only in Redis.
- Fix: Keep Redis data rebuildable, or enable AOF.
- Source: Persistence - https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/

### DATA-13 Memory limits and eviction
- Trap: Redis evicts old cache entries automatically.
- Reality: `maxmemory` 0 (unlimited) on 64-bit; default policy `noeviction` errors on writes at the limit. `volatile-*` acts like noeviction when no key has a TTL.
- Detect: no maxmemory/policy; cache and durable keys in one instance.
- Fix: Set maxmemory with `allkeys-lru`/`allkeys-lfu`; use a separate instance for durable keys.
- Source: Key eviction - https://redis.io/docs/latest/develop/reference/eviction/

### DATA-14 Redis locks
- Trap: `SETNX` + `DEL`, or Redlock, gives strict mutual exclusion.
- Reality: Acquire with `SET key rand NX PX ttl`; release only if the value matches (DELEX 8.4+ or Lua). Failover to an async replica can grant a lock twice. Docs advise fencing tokens; TTLs use a non-monotonic clock.
- Detect: locks guarding payments; plain DEL release.
- Fix: Fencing token checked by the resource, or a DB row lock or constraint.
- Source: Distributed Locks - https://redis.io/docs/latest/develop/clients/patterns/distributed-locks/

## SQLite

### DATA-15 One writer, SQLITE_BUSY, FKs off
- Trap: WAL allows many writers, servers can share the file, REFERENCES is enforced.
- Reality: One writer at a time, even in WAL. With no busy handler, locked calls return SQLITE_BUSY at once; a DEFERRED transaction may fail to upgrade to write. WAL fails on network filesystems. FKs are off until each connection runs `PRAGMA foreign_keys = ON`.
- Detect: many instances on one file; NFS/EFS; FK cascades.
- Fix: One writer process; busy_timeout; `BEGIN IMMEDIATE` for writes; pragma per connection.
- Source: WAL - https://www.sqlite.org/wal.html ; Transactions - https://www.sqlite.org/lang_transaction.html ; Foreign keys - https://www.sqlite.org/foreignkeys.html

## MySQL

### DATA-16 utf8, MyISAM and gap locks
- Trap: `utf8` stores all Unicode; every engine is transactional.
- Reality: `utf8` is a deprecated alias for utf8mb3 (no emoji). MyISAM has no transactions and locks whole tables. InnoDB REPEATABLE READ takes gap/next-key locks on range locking reads.
- Detect: `CHARSET=utf8`, `ENGINE=MyISAM`, range `FOR UPDATE` on hot tables.
- Fix: utf8mb4 and InnoDB; lock via unique-key lookups.
- Source: utf8mb3 - https://dev.mysql.com/doc/refman/8.4/en/charset-unicode-utf8.html ; Isolation - https://dev.mysql.com/doc/refman/8.4/en/innodb-transaction-isolation-levels.html

## Analytics and search

### DATA-17 TimescaleDB licensing
- Trap: All TimescaleDB features are Apache-2.0 everywhere.
- Reality: Columnstore/compression, continuous aggregates, retention and job policies are Community edition (Timescale License) only, which cannot be sold as a service.
- Detect: caggs or compression on a managed Postgres.
- Fix: Confirm the edition on the host, or self-host Community edition.
- Source: Editions - https://www.tigerdata.com/docs/about/latest/timescaledb-editions

### DATA-18 Continuous aggregates lag
- Trap: A continuous aggregate shows the latest data.
- Reality: v2.13+: real-time aggregation is off, so queries see only materialized data. With no refresh policy nothing refreshes; backfill before `start_offset` is not refreshed; retention inside the window deletes aggregates.
- Detect: live dashboards on caggs; late-arriving data.
- Fix: Add a policy; `materialized_only = false` if needed; refresh backfills manually.
- Source: Real-time aggregates - https://www.tigerdata.com/docs/learn/continuous-aggregates/real-time-aggregates ; Refresh - https://www.tigerdata.com/docs/build/continuous-aggregates/refresh-policies

### DATA-19 ClickHouse updates and dedup are eventual
- Trap: ClickHouse updates and upserts behave like OLTP.
- Reality: `ALTER TABLE UPDATE` is a heavy async mutation. ReplacingMergeTree dedups only in background merges, not guaranteed.
- Detect: row-level updates; "latest state" reads without FINAL.
- Fix: Append-only design; FINAL or argMax at query time.
- Source: ReplacingMergeTree - https://clickhouse.com/docs/engines/table-engines/mergetree-family/replacingmergetree

### DATA-20 Search is near-real-time
- Trap: A document is searchable once indexed.
- Reality: Elasticsearch refreshes every 1 s, and only on indices searched in the last 30 s.
- Detect: write-then-search flows; search as system of record.
- Fix: Read-after-write from the primary DB; `?refresh=wait_for` only where needed.
- Source: Near real-time search - https://www.elastic.co/docs/manage-data/data-store/near-real-time-search
