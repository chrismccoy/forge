# PYTHON facts
Covers: Django, DRF, FastAPI, Flask, pydantic, SQLAlchemy, Celery/Redis, HTMX, pandas, Python
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Jobs (Celery)

### PY-01 Celery acks before the task runs
- Trap: A queued task survives a worker crash and is retried.
- Reality: Default acks just before execution, so a crash mid-task loses it. `acks_late=True` acks after (a killed child is still acked unless `task_reject_on_worker_lost`); redelivery can run tasks twice.
- Detect: "exactly once"; payment/SMS tasks with no idempotency.
- Fix: Idempotent tasks, then `acks_late`.
- Source: Tasks - https://docs.celeryq.dev/en/stable/userguide/tasks.html

### PY-02 Tasks enqueued in a transaction run before commit
- Trap: `task.delay(obj.id)` after `save()` sees the new row.
- Reality: The worker can run before commit and miss the row; model objects passed as args go stale.
- Detect: `.delay()` inside `atomic()` or under ATOMIC_REQUESTS.
- Fix: `transaction.on_commit(...)` or Celery 5.4+ `delay_on_commit()`; pass PKs.
- Source: First steps with Django - https://docs.celeryq.dev/en/stable/django/first-steps-with-django.html

### PY-03 Redis visibility timeout redelivers long ETA tasks
- Trap: `countdown`/`eta` reminders days ahead fire once.
- Reality: Redis broker visibility timeout defaults to 1 hour; ETA/countdown/retry tasks past it are redelivered, repeatedly.
- Detect: Long `eta=`/`countdown=` on Redis.
- Fix: Store due times in the DB and dispatch via Beat, or raise `visibility_timeout`.
- Source: Using Redis - https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/redis.html

### PY-04 Celery Beat must be exactly one instance
- Trap: Beat runs in every worker (`-B`) or scaled container.
- Reality: Multiple schedulers duplicate tasks; `-B` is not recommended for production.
- Detect: `worker -B`; beat with replicas > 1.
- Fix: One dedicated beat service; idempotent periodic tasks.
- Source: Periodic Tasks - https://docs.celeryq.dev/en/stable/userguide/periodic-tasks.html

### PY-05 Celery defaults: results kept, no time limits, prefetch 4
- Trap: Defaults suit long jobs; results clean themselves up.
- Reality: Results are stored by default; `result_expires` (1 day) runs via `celery.backend_cleanup`, which needs Beat. No time limits, so a hung task holds a slot forever. Prefetch multiplier 4 starves long tasks.
- Detect: Long tasks with no limits.
- Fix: `ignore_result=True` unless read; set soft/hard time limits; long tasks use prefetch 1 + `acks_late`.
- Source: Configuration - https://docs.celeryq.dev/en/stable/userguide/configuration.html

## Transactions and data model (Django)

### PY-06 Autocommit by default; ATOMIC_REQUESTS is off
- Trap: Each request is one transaction that rolls back on error.
- Reality: Each query commits immediately; `ATOMIC_REQUESTS` defaults to False.
- Detect: Multi-step writes with no `atomic()`.
- Fix: `transaction.atomic()` around multi-write operations, or enable ATOMIC_REQUESTS.
- Source: Database transactions - https://docs.djangoproject.com/en/stable/topics/db/transactions/

### PY-07 select_for_update needs an open transaction
- Trap: `select_for_update()` alone locks rows.
- Reality: In autocommit it raises `TransactionManagementError`. `TestCase` wraps tests in a transaction, hiding this; on SQLite it is a silent no-op.
- Detect: select_for_update outside `atomic()`.
- Fix: Use inside `atomic()`; test with `TransactionTestCase` on the production engine.
- Source: QuerySet API - https://docs.djangoproject.com/en/stable/ref/models/querysets/

### PY-08 Signals skip bulk writes and fire before commit
- Trap: `post_save` reliably audits or notifies every change.
- Reality: `bulk_create`, `bulk_update`, `QuerySet.update()` send no save signals. Signals run inside the caller's transaction, so side effects fire even on rollback. `on_commit()` with no open transaction runs immediately.
- Detect: Audit, indexing or email on `post_save`; bulk imports.
- Fix: Side effects in service code via `on_commit()`.
- Source: QuerySet API - https://docs.djangoproject.com/en/stable/ref/models/querysets/ ; Database transactions - https://docs.djangoproject.com/en/stable/topics/db/transactions/

### PY-09 Migrations on large tables
- Trap: `migrate` is instant, including backfills.
- Reality: On PostgreSQL/SQLite each migration is one transaction, so a backfill holds locks throughout. `AddIndexConcurrently` needs `atomic = False`. A new unique non-null field needs add-nullable, backfill, alter.
- Detect: RunPython backfills; new unique/indexed columns on big tables.
- Fix: `atomic = False` with batched `atomic()` chunks; concurrent index ops.
- Source: Writing migrations - https://docs.djangoproject.com/en/stable/howto/writing-migrations/

### PY-10 Timezone-aware datetimes
- Trap: `datetime.now()`/`utcnow()` for stored and reminder times.
- Reality: Django 5.0+ defaults `USE_TZ=True` (UTC storage; naive values warn). `utcnow()` is deprecated in 3.12 and returns naive. Naive vs aware comparison raises `TypeError`.
- Detect: `datetime.now()`, `utcnow()`, reminders with no user timezone.
- Fix: `timezone.now()` / `datetime.now(UTC)`; store UTC plus the user's IANA zone.
- Source: Time zones - https://docs.djangoproject.com/en/stable/topics/i18n/timezones/ ; datetime - https://docs.python.org/3/library/datetime.html

## Async and concurrency

### PY-11 FastAPI: blocking calls in async def stall the server
- Trap: `async def` everywhere makes endpoints faster.
- Reality: `def` endpoints/dependencies run in a threadpool; `async def` runs on the event loop, so sync DB drivers, `requests` or CPU work there block every request.
- Detect: `async def` calling psycopg2, requests, pandas, OCR.
- Fix: `def` for sync libraries; CPU work to workers.
- Source: Concurrency and async/await - https://fastapi.tiangolo.com/async/

### PY-12 FastAPI BackgroundTasks are not a job queue
- Trap: BackgroundTasks deliver webhooks/emails durably.
- Reality: Same process, after the response: lost on restart, no retries; must open their own DB session.
- Detect: BackgroundTasks for webhooks, payments, OCR, retries.
- Fix: Celery or another broker-backed queue.
- Source: Background Tasks - https://fastapi.tiangolo.com/tutorial/background-tasks/

### PY-13 Yield-dependency exit timing changed
- Trap: Cleanup after `yield` runs before the response.
- Reality: 0.106.0 moved exit before the response; 0.118.0 moved it back after; 0.121.0 added `Depends(..., scope="function")` for before. Default `scope="request"` exits after.
- Detect: Commit in a yield dependency the response relies on.
- Fix: Commit in the endpoint/service, or `scope="function"` on 0.121+.
- Source: Advanced Dependencies - https://fastapi.tiangolo.com/advanced/advanced-dependencies/

### PY-14 Django async mode has no transactions
- Trap: Async views use `atomic()` and the sync ORM directly.
- Reality: `a`-prefixed ORM methods exist, but transactions do not work in async mode; sync ORM calls there raise `SynchronousOnlyOperation`.
- Detect: `async def` views using `atomic` or the sync ORM.
- Fix: Put transactional code in a sync function called via `sync_to_async`.
- Source: Asynchronous support - https://docs.djangoproject.com/en/stable/topics/async/

## Library APIs

### PY-15 SQLAlchemy 2.0 removed 1.x idioms
- Trap: `engine.execute()`, raw SQL strings, autocommit.
- Reality: 2.0 removes `Engine.execute()` and autocommit, requires `text()` for string SQL, and makes `Query` legacy (use `select()` + `Session.execute()`).
- Detect: 1.x snippets.
- Fix: `with Session(engine) as s, s.begin(): s.execute(select(...))`.
- Source: Migrating to 2.0 - https://docs.sqlalchemy.org/en/20/changelog/migration_20.html

### PY-16 SQLAlchemy session scope and async lazy loads
- Trap: One global Session shared across requests or tasks.
- Reality: A Session is unsafe across concurrent threads or asyncio tasks. With AsyncSession, lazy loads and attributes expired by commit (`expire_on_commit=True` default) do implicit IO and fail.
- Detect: Module-level session; relationships read after commit.
- Fix: Session per request/task; async: `selectinload()`, `expire_on_commit=False`.
- Source: Asyncio - https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html

### PY-17 Pydantic v2 API and semantics
- Trap: v1 names: `.dict()`, `parse_obj`, `class Config`, `orm_mode`, `@validator`, `pydantic.BaseSettings`.
- Reality: v2: `model_dump`, `model_validate`, `model_config`, `from_attributes`, `field_validator`; `pydantic-settings`. `Optional[T]` is required unless given a default. FastAPI 0.100+ uses v2.
- Detect: Any v1 name; Optional assumed to default to None.
- Fix: v2 APIs; write `= None` explicitly.
- Source: Migration Guide - https://pydantic.dev/docs/validation/latest/get-started/migration/

### PY-18 pandas 3.0 Copy-on-Write
- Trap: Chained assignment updates the DataFrame.
- Reality: pandas 3.0 makes CoW the only mode: chained assignment never updates, `df["c"].replace(..., inplace=True)` leaves `df` unchanged, `to_numpy()` can be read-only.
- Detect: `df["a"][mask] = x`; column-level `inplace=True`.
- Fix: `df.loc[mask, "a"] = x`; reassign columns.
- Source: Copy-on-Write - https://pandas.pydata.org/docs/user_guide/copy_on_write.html

## Security

### PY-19 CSRF for HTMX, AJAX and DRF
- Trap: HTMX/fetch POSTs need no CSRF plan.
- Reality: Unsafe methods need the token, e.g. `X-CSRFToken` header. DRF SessionAuthentication checks CSRF only for authenticated requests, so login views must enforce it. `CSRF_TRUSTED_ORIGINS` entries need a scheme.
- Detect: HTMX POSTs with no token; `csrf_exempt` on session views.
- Fix: Send the header globally; keep CSRF for cookie auth.
- Source: CSRF how-to - https://docs.djangoproject.com/en/stable/howto/csrf/ ; DRF Authentication - https://www.django-rest-framework.org/api-guide/authentication/

### PY-20 Password hashers and SECRET_KEY rotation
- Trap: Argon2/bcrypt is the default; changing SECRET_KEY is harmless.
- Reality: Default is PBKDF2-SHA256; Argon2 needs `django[argon2]` and listing it first. Never remove hashers (old hashes upgrade on login). A new SECRET_KEY invalidates sessions, reset tokens and signatures unless the old key is in `SECRET_KEY_FALLBACKS`.
- Detect: "argon2" claims with no setting; key rotation.
- Fix: Set PASSWORD_HASHERS; rotate via SECRET_KEY_FALLBACKS, then drop the old key.
- Source: Password management - https://docs.djangoproject.com/en/stable/topics/auth/passwords/ ; Settings - https://docs.djangoproject.com/en/stable/ref/settings/

## Deploy

### PY-21 Django with DEBUG=False
- Trap: DEBUG=False is the whole production config.
- Reality: Empty `ALLOWED_HOSTS` gives 400 on every request. Django does not serve static files: run `collectstatic` and serve via web server, CDN/S3 or WhiteNoise. Behind a TLS proxy (ALB) `is_secure()` is False unless `SECURE_PROXY_SSL_HEADER` is set (safe only if the proxy sets it).
- Detect: No hosts/static/proxy plan.
- Fix: Plan all three.
- Source: Settings; Static files - https://docs.djangoproject.com/en/stable/howto/static-files/deployment/

### PY-22 Default cache and dev server are single-process
- Trap: Default cache for rate limits; `flask run` in prod.
- Reality: With no CACHES, Django uses LocMemCache, private per process. Flask's dev server is not for production.
- Detect: Rate limits with no CACHES; `flask run` in containers.
- Fix: Redis/Memcached; Gunicorn behind a proxy.
- Source: Cache framework - https://docs.djangoproject.com/en/stable/topics/cache/ ; Flask Deploying - https://flask.palletsprojects.com/en/stable/deploying/

### PY-23 Python and Django versions
- Trap: New projects on Python 3.9/3.10 or Django 4.2/5.0.
- Reality: Python 3.9 EOL 2025-10; 3.10 EOL 2026-10. Django 5.2 LTS runs to April 2028; 6.0/6.1 need Python 3.12+; 4.2 is unsupported.
- Detect: Old pins; Django 6 on Python 3.11.
- Fix: Python 3.13/3.14 with Django 5.2 LTS or 6.x.
- Source: Python versions - https://devguide.python.org/versions/ ; Django download - https://www.djangoproject.com/download/
