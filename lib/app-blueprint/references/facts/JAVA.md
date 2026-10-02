# JAVA facts
Covers: Spring Boot (MVC, WebFlux, Security, Data JPA/Hibernate, Batch, Kafka, Quartz), Java 17/21, GraalVM native image, Kafka consumers, from the TECH_STACK lines of support-files/JAVA.md
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Transactions

### JV-01 @Transactional/@Async ignored on self-invocation
- Trap: A service method calls its own `@Transactional` (or `@Async`) method and gets a new transaction or async execution.
- Reality: Proxy mode is the default. Only calls that come in through the proxy are intercepted, so `this.method()` runs with no transaction and no async hop. Since Spring 6.0, protected and package-private methods work with class-based proxies; interface-based proxies still need public interface methods.
- Detect: "calls its own transactional helper", "internal @Async method", one bean that orchestrates and also persists.
- Fix: Put the transactional or async method on a separate bean, or use AspectJ mode.
- Source: Using @Transactional - https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html

### JV-02 Checked exceptions commit by default
- Trap: Any exception thrown from a `@Transactional` method rolls back.
- Reality: Only `RuntimeException` and `Error` roll back. Checked exceptions commit. Spring 6.2+ can change this globally with `@EnableTransactionManagement(rollbackOn=ALL_EXCEPTIONS)`.
- Detect: Checked business exceptions (`InsufficientFundsException extends Exception`) described as "rolling back" the transaction.
- Fix: Declare `rollbackFor`, use unchecked exceptions, or set `rollbackOn=ALL_EXCEPTIONS` (6.2+).
- Source: Using @Transactional - https://docs.spring.io/spring-framework/reference/data-access/transaction/declarative/annotations.html

## Data access (JPA/Hibernate)

### JV-03 Open Session in View is on by default
- Trap: The persistence context closes when the service transaction ends, so lazy loading in controllers or views fails fast.
- Reality: In web apps, Spring Boot registers `OpenEntityManagerInViewInterceptor` by default. Lazy loads during rendering issue extra queries and hold a connection for the whole request.
- Detect: Lazy associations used in Thymeleaf/JSF views or JSON serialization with no mention of `spring.jpa.open-in-view`.
- Fix: Set `spring.jpa.open-in-view=false` and fetch what each view needs (fetch joins, entity graphs, DTO projections).
- Source: SQL Databases (Spring Boot) - https://docs.spring.io/spring-boot/reference/data/sql.html

### JV-04 To-one associations are EAGER; N+1 by default
- Trap: JPA associations load lazily unless stated otherwise.
- Reality: Under JPA, `@ManyToOne` and `@OneToOne` default to EAGER. Loading a list of entities can trigger one extra query per row (N+1). Hibernate recommends mapping associations `LAZY` and fetching explicitly per query.
- Detect: Entity diagrams with no fetch strategy, list or report screens over entities with to-one references.
- Fix: Map `fetch = LAZY`. Use fetch joins, entity graphs or batch fetching for each use case.
- Source: A Guide to Hibernate ORM (Introduction) - https://docs.hibernate.org/orm/current/introduction/html_single/Hibernate_Introduction.html

### JV-05 No schema creation on real databases; Boot 4 needs migration starters
- Trap: Hibernate creates or updates the PostgreSQL/Oracle schema, or adding `flyway-core` makes migrations run.
- Reality: `ddl-auto` defaults to `create-drop` only for embedded H2/HSQL/Derby and to `none` otherwise. Flyway and Liquibase run at startup when auto-configured. In Spring Boot 4, auto-configuration is modularized, so you need `spring-boot-starter-flyway` or `spring-boot-starter-liquibase`. Do not mix `schema.sql` with Flyway or Liquibase.
- Detect: "Hibernate generates the schema", `ddl-auto=update` in production, Boot 4 builds with a bare `flyway-core` dependency.
- Fix: Version the schema with Flyway or Liquibase through the Boot starter, and use `ddl-auto=validate` or `none` in production.
- Source: Database Initialization - https://docs.spring.io/spring-boot/how-to/data-initialization.html ; Spring Boot 4.0 Migration Guide - https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide

## Jobs and scheduling

### JV-06 @Scheduled and default Quartz are per-instance and in-memory
- Trap: A `@Scheduled` nightly job runs once per cluster, and Quartz jobs survive restarts.
- Reality: `@Scheduled` runs on an in-process `TaskScheduler` (one thread by default), and Spring has no cluster coordination, so every replica fires the job. Spring Boot's default Quartz `JobStore` is in memory. A persistent store needs `spring.quartz.job-store-type=jdbc`.
- Detect: `@Scheduled` billing, settlement or report jobs on multi-replica Kubernetes/EKS deployments. Quartz "deadline timers" with no JDBC store.
- Fix: Use a JDBC Quartz store with clustering, a distributed lock (for example ShedLock), or one external scheduler (Kubernetes CronJob, Control-M).
- Source: Task Execution and Scheduling - https://docs.spring.io/spring-boot/reference/features/task-execution-and-scheduling.html ; Quartz Scheduler - https://docs.spring.io/spring-boot/reference/io/quartz.html

### JV-07 Spring Batch 6 defaults to a non-persistent job repository
- Trap: Batch job metadata is stored in `BATCH_*` tables, so failed runs can be restarted.
- Reality: Spring Batch 6 (Boot 4) provides a `ResourcelessJobRepository` by default. It keeps no metadata, cannot restart, and is not thread-safe, so no partitioning or concurrent jobs. Boot 4 needs `spring-boot-starter-batch-jdbc` for a database-backed repository.
- Detect: "restartable from last checkpoint", partitioned steps or Control-M reruns on Boot 4 with no JDBC repository.
- Fix: Add `spring-boot-starter-batch-jdbc` or `@EnableJdbcJobRepository` and provision the metadata schema.
- Source: Configuring a JobRepository - https://docs.spring.io/spring-batch/reference/job/configuring-repository.html

## Platform versions

### JV-08 Boot 4 baseline changes; Boot 3.x OSS support has ended
- Trap: A blueprint targets "Spring Boot 3" as current, or ports Boot 3 code to Boot 4 unchanged.
- Reality: Boot 3.5 OSS support ended 2026-06-30. Boot 4.0 OSS runs to 2026-12-31 and 4.1 to 2027-07-31. Boot 4 requires Java 17+, Jakarta EE 11 and Servlet 6.1, drops Undertow, moves to Jackson 3 (`tools.jackson` packages), and replaces `@MockBean` with `@MockitoBean`. Boot 3+ already required `jakarta.*` instead of `javax.*`.
- Detect: `javax.persistence`/`javax.servlet` imports, Undertow, `@MockBean`, or "Spring Boot 3.x" with no upgrade plan.
- Fix: Target Boot 4.x on Java 17+ (21+ for virtual threads) and plan the Jackson 3 and starter changes.
- Source: System Requirements - https://docs.spring.io/spring-boot/system-requirements.html ; Spring Boot support - https://spring.io/projects/spring-boot#support ; Spring Boot 4.0 Migration Guide - https://github.com/spring-projects/spring-boot/wiki/Spring-Boot-4.0-Migration-Guide

## Security

### JV-09 Security auto-configuration defaults
- Trap: Adding Spring Security leaves endpoints open until rules are written, a custom `SecurityFilterChain` removes all defaults, or a JSON API does not need to handle CSRF.
- Reality: With Spring Security on the classpath, everything is secured, including actuator and `/error`, with a generated `user` password. A custom `SecurityFilterChain` bean does not remove the in-memory `UserDetailsService`. CSRF protection is on by default for POST, PUT and DELETE.
- Detect: API-only services with no CSRF decision, browser session auth next to `csrf.disable()`, a generated password in any non-dev environment.
- Fix: Define a `SecurityFilterChain` plus a real `UserDetailsService` or resource-server config. Disable CSRF only for stateless, non-browser clients.
- Source: Spring Security (Spring Boot) - https://docs.spring.io/spring-boot/reference/web/spring-security.html ; CSRF - https://docs.spring.io/spring-security/reference/servlet/exploits/csrf.html

## Concurrency

### JV-10 Virtual threads caveats
- Trap: `spring.threads.virtual.enabled=true` is a free throughput switch, and pool sizes still apply.
- Reality: Virtual threads need Java 21+. With them enabled, thread-pool properties have no effect. Virtual threads are daemon threads, so a scheduler-only app can exit unless `spring.main.keep-alive=true`. Before JDK 24, `synchronized` pins the carrier thread; native calls still pin. Never pool virtual threads; the JDBC connection pool is the real concurrency limit.
- Detect: Java 17 with virtual threads, tuning `spring.task.execution.pool.*` alongside virtual threads, "thousands of concurrent DB calls".
- Fix: Use Java 21+ (24+ preferred), size the connection pool deliberately, set keep-alive for worker apps, and use a Semaphore for other limits.
- Source: SpringApplication - Virtual threads - https://docs.spring.io/spring-boot/reference/features/spring-application.html ; Virtual Threads (JDK 24) - https://docs.oracle.com/en/java/javase/24/core/virtual-threads.html

### JV-11 WebFlux with JDBC/JPA
- Trap: WebFlux makes a JPA/JDBC service scale better.
- Reality: Spring's guidance is that apps with blocking persistence (JPA, JDBC) should use Spring MVC. Blocking calls on the event loop stall it.
- Detect: "Reactive WebFlux" combined with Spring Data JPA, JDBC or blocking vendor SDKs.
- Fix: Use MVC (optionally with virtual threads), or go fully non-blocking with R2DBC and reactive clients.
- Source: Spring WebFlux Overview - https://docs.spring.io/spring-framework/reference/web/webflux/new-framework.html

## Messaging (Spring for Apache Kafka)

### JV-12 Default listener error handling skips the record
- Trap: A failed Kafka message is retried until it succeeds, or lands in a dead-letter topic automatically.
- Reality: `DefaultErrorHandler` defaults to `FixedBackOff(0L, 9)`: 10 immediate attempts, after which the record is logged and skipped. Dead-lettering happens only if a `DeadLetterPublishingRecoverer` is configured.
- Detect: "at-least-once, never lost" claims with no recoverer, DLT or backoff configuration.
- Fix: Configure `DefaultErrorHandler` with a backoff and a `DeadLetterPublishingRecoverer`, and classify non-retryable exceptions.
- Source: Handling Exceptions - https://docs.spring.io/spring-kafka/reference/kafka/annotation-error-handling.html

### JV-13 Concurrency beyond partitions is idle
- Trap: Raising listener `concurrency` scales consumption linearly.
- Reality: Consumers beyond the assigned partitions sit idle. With several topics, the default `RangeAssignor` can leave most consumers idle, for example concurrency 15 over 3×5 partitions gives 5 active consumers.
- Detect: Concurrency or replica counts above topic partition counts, "scale consumers to N pods" with no partition plan.
- Fix: Size partitions to the maximum parallelism and consider `RoundRobinAssignor` for multi-topic listeners.
- Source: Message Listener Containers - https://docs.spring.io/spring-kafka/reference/kafka/receiving-messages/message-listener-container.html

## Native image

### JV-14 GraalVM native image fixes the app at build time
- Trap: A native image behaves like the JVM app, with profiles and `@ConditionalOnProperty` toggles at runtime.
- Reality: Closed-world assumption: the classpath and bean definitions are fixed at build time. `@Profile` and `@ConditionalOnProperty`/`.enabled` properties are evaluated at build time. Reflection, resources, proxies and JNI need reachability metadata, or the app fails at runtime.
- Detect: Picocli or Spring CLIs "compiled with GraalVM" that use reflection-heavy libraries (JDBC drivers, Bouncy Castle, SSH), or runtime feature flags that select beans.
- Fix: Run the tracing agent in tests, ship `reachability-metadata.json`, and move runtime switches out of bean conditions.
- Source: Introducing GraalVM Native Images - https://docs.spring.io/spring-boot/reference/packaging/native-image/introducing-graalvm-native-images.html ; Reachability Metadata - https://www.graalvm.org/latest/reference-manual/native-image/metadata/
