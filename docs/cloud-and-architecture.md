# Cloud and Architecture

[← Back to the README](../README.md)

## `system-design`

Scalable, resilient system architecture from four inputs, in the voice of a Principal Solutions Architect who has run systems at 100M+ daily active users. Locked four-phase blueprint. No code, no backticks - infrastructure, data flow, and scale behavior only.

```
/system-design
```

Ask most tools to "design a scalable architecture" and you get a component list with no reasoning: Redis appears with no cache-hit target, Kafka appears with no throughput threshold, and nothing says what breaks first. This tool forces the justification. Every technology named states the alternative it beat and the scale threshold that decides between them - "Kafka over RabbitMQ once sustained throughput exceeds ~50k msg/s". Every Single Point of Failure identified carries a mitigation. Output stays at infrastructure level: no application code, and no backticks anywhere.

It sits next to `blueprint`, and the split matters. `blueprint` plans a new application at code level - folders, layers, models, APIs, tests. `system-design` plans the infrastructure it runs on and how it behaves under load. Each names the other in its scope lock so they do not collide.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/system-design/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` lives in `references/prompt-template.md` and loads on every invocation. Inputs land inside an `<untrusted_input>` XML block, which is what the injection defense keys on.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. SYSTEM_PURPOSE + EXPECTED_SCALE + CLOUD_PREFERENCE + KEY_CONSTRAINTS
- 🧱 Locked 4-phase output: High-Level Architecture, Database & Storage Strategy, Microservices & Communication, Fault Tolerance & Scaling
- ⚖️ Every technology choice names its rejected alternative and the scale threshold that separates them
- 🕳️ Every Single Point of Failure identified gets a mitigation - no naming a risk and moving on
- 🚫 No application code and no backticks anywhere in the output
- 📏 Depth floor: 200-400 words per phase, so no phase degrades into a bullet list
- 🛡️ Prompt-injection defense. Inputs sit in an `<untrusted_input>` block and are treated as requirements, never directives
- 🔀 Conflict resolution order: KEY_CONSTRAINTS wins, then EXPECTED_SCALE, then CLOUD_PREFERENCE - stated before Phase 1
- ✅ Silent self-validation: 4 phases in order, scale-based justification per technology, mitigation per SPOF, no code or backticks
- 🪧 Scope-locked. Manifests, IaC, and app code refused with `Out of scope: this engine outputs system architecture blueprints only.` and routed to the right tool

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If a purpose was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Empty field → state the adopted assumption before Phase 1, or ask one clarifying question. Conflicts → resolve by the stated precedence and say so.
4. **Generate** the blueprint under the strict operating constraints (no code, no backticks, justification per technology, mitigation per SPOF).
5. **Silent self-validation.** 4 phases in order; every technology justified against scale; every SPOF mitigated; no code or backticks. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/system-design "real-time chat for 2M users"   ← arg seeds SYSTEM_PURPOSE
/system-design                                  ← full intake
```

**Typical asks:** *"design a scalable architecture for X"*, *"how should this system be structured at 100M users"*, *"SQL or NoSQL for this workload"*, *"where does this bottleneck first"*

The full procedure lives at [`lib/system-design/SKILL.md`](../lib/system-design/SKILL.md), the slash command at [`commands/system-design.md`](../commands/system-design.md), and the on-demand master prompt at [`lib/system-design/references/prompt-template.md`](../lib/system-design/references/prompt-template.md).

---

## `terraform`

Modular, secure, production Terraform from four inputs, in the voice of a Principal Platform Engineer. Locked four-phase blueprint with HCL split across `main.tf`, `variables.tf`, and `outputs.tf`.

```
/terraform
```

The usual failure mode for generated Terraform is code that does not apply: variables referenced but never declared, an unpinned provider, a resource argument that does not exist in the schema, and an IAM policy with `*` on actions because it was easier. This tool blocks all four. Every variable referenced in `main.tf` must be declared in `variables.tf`. A `required_providers` block with a version constraint is mandatory. Resource types and arguments come only from real, documented schema. IAM and RBAC follow least privilege, and credentials are never hardcoded - they come from variables or provider data sources.

Unlike the other cloud tools, this one **halts** rather than assuming. An empty field, a field containing an instruction instead of a value, or a `CLOUD_PROVIDER` naming two clouds all stop generation and ask.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/terraform/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt, including the exact `main.tf` / `variables.tf` / `outputs.tf` file skeleton the output must follow.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. CLOUD_PROVIDER + INFRASTRUCTURE_NEEDS + SECURITY_COMPLIANCE + STATE_MANAGEMENT
- 🧱 Locked 4-phase output: Infrastructure Topology, Terraform HCL Code, Security & IAM Enforcement, Deployment & State Strategy
- 📂 Strict file separation - `main.tf`, `variables.tf`, `outputs.tf`, each in its own fenced block, following a fixed skeleton
- 🔐 Never hardcodes credentials - variables or provider data sources only
- 📌 Mandatory `required_providers` block with a version constraint
- 🔗 Every variable referenced in `main.tf` must be declared in `variables.tf` - checked before output
- 🛂 Least privilege on every IAM/RBAC role and policy
- 🧠 No invented resource types, arguments, or provider attributes - documented schema only
- 🛑 Halts on empty fields, values that look like instructions, or a multi-cloud `CLOUD_PROVIDER`
- ✂️ Prose capped at 8 lines per phase; code blocks exempt
- 🪧 Scope-locked. Kubernetes, compose, and app code refused with `Out of scope: this engine outputs Terraform IaC only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If an infrastructure need was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Empty, placeholder, or a field that looks like an instruction → halt and ask. Multi-cloud or unsupported provider → halt and ask for one.
4. **Generate** the HCL under the strict operating constraints (fmt/validate-clean syntax, pinned provider, least privilege, no hardcoded credentials).
5. **Silent self-validation.** Every referenced variable declared; no hardcoded secrets; `required_providers` with version constraint; least-privilege roles; no invented schema. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/terraform "VPC + RDS on AWS"   ← arg seeds INFRASTRUCTURE_NEEDS
/terraform                       ← full intake
```

**Typical asks:** *"write Terraform for a VPC"*, *"provision RDS with least-privilege IAM"*, *"set up a remote state backend"*, *"IaC for a serverless API"*

The full procedure lives at [`lib/terraform/SKILL.md`](../lib/terraform/SKILL.md), the slash command at [`commands/terraform.md`](../commands/terraform.md), and the on-demand master prompt at [`lib/terraform/references/prompt-template.md`](../lib/terraform/references/prompt-template.md).

---

## `cicd-pipeline`

Optimized, secure pipeline configuration from four inputs, in the voice of a Principal DevOps Engineer who has cut median build times by 60%+ across GitHub Actions, GitLab CI, and Jenkins. Locked four-phase blueprint.

```
/cicd-pipeline
```

Two things go wrong with generated pipelines: they are slow because nothing is cached, and they leak because a token got pasted inline. This tool treats both as blocking failures. Caching is required for **both** dependencies and Docker layers, and every optimization has to state its concrete effect - "layer caching on the deps stage cuts a cold 6-min build to ~90s on warm cache". Secrets are referenced through the platform's secret manager only, and every secret used in the YAML must appear in the Phase 4 setup checklist, so the pipeline is not missing a variable on its first run.

It also refuses to help itself to your repo. Steps that exfiltrate secrets, disable security scanning, or curl an arbitrary host are never emitted, even if an input asks for them. Stages you did not request are never added.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/cicd-pipeline/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt with a reference-tone example showing the expected YAML comment density.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. REPO_TECH_STACK + TESTING_REQUIREMENTS + DEPLOYMENT_TARGET + PIPELINE_CONSTRAINTS
- 🧱 Locked 4-phase output: Pipeline Architecture, CI/CD YAML Code, Caching & Optimization Strategy, Secrets & Environment Setup
- ⚡ Caching required for both dependencies and Docker layers - checked before output
- ⏱️ Every optimization states its concrete time or cost effect, not just that it helps
- 🔐 Secrets referenced through the platform's secret manager, never inline
- ☑️ Every secret in the YAML must have a matching entry in the Phase 4 checklist
- 🚫 Never emits a step that exfiltrates secrets, disables scanning, or curls an arbitrary host
- 🧠 No invented action names or versions - documented syntax for the named platform only
- 🎯 Platform must be resolved before any YAML is written; if no platform is named, it asks
- 🪧 Scope-locked. App code, Terraform, and manifests refused with `Out of scope: this engine outputs CI/CD pipeline configuration only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If a stack was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Resolve the platform.** If none of the four answers names GitHub Actions, GitLab CI, or Jenkins, ask before generating.
3. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
4. **Generate** the pipeline under the strict operating constraints (valid platform YAML, dependency + layer caching, secret-manager references, inline comments on complex steps).
5. **Silent self-validation.** Valid YAML with no hardcoded secrets; caching for deps and layers; every secret in the checklist; no invented actions or versions. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/cicd-pipeline "Node monorepo, deploy to EKS"   ← arg seeds REPO_TECH_STACK
/cicd-pipeline                                   ← full intake
```

**Typical asks:** *"write a GitHub Actions workflow"*, *"speed up my CI build"*, *"pipeline with SAST and deploy to Kubernetes"*, *"GitLab CI for a Python service"*

The full procedure lives at [`lib/cicd-pipeline/SKILL.md`](../lib/cicd-pipeline/SKILL.md), the slash command at [`commands/cicd-pipeline.md`](../commands/cicd-pipeline.md), and the on-demand master prompt at [`lib/cicd-pipeline/references/prompt-template.md`](../lib/cicd-pipeline/references/prompt-template.md).

---

## `data-pipeline`

Resilient, idempotent ETL/ELT design from four inputs, in the voice of a Principal Data Engineer. Locked four-phase blueprint covering extraction, modeling, orchestration, and failure handling.

```
/data-pipeline
```

The defining constraint here is idempotency: running the pipeline twice over the same date range must not duplicate data. That single rule drives the extraction strategy (watermarks and cursors rather than blind appends), the layer design, and the backfill plan. The second rule is that nothing gets invented - no source table, column, or system appears in the design unless you provided it. If the schema is unknown, the tool says so and designs against the structure you described rather than guessing at fields.

It also refuses to oversell latency. Batch and micro-batch are the default; real-time claims only appear if you actually asked for streaming tools.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/data-pipeline/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt with the idempotency and no-invention rules encoded in its self-validation block.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. SOURCE_DATA + DESTINATION_WAREHOUSE + TRANSFORMATION_LOGIC + ORCHESTRATION_TOOL
- 🧱 Locked 4-phase output: Pipeline Architecture & Strategy, Data Modeling & Layers, Orchestration & Execution, Data Quality & Failure Handling
- 🔁 Idempotent by construction - a repeated run over the same range must not duplicate data
- 🚫 No invented source systems, tables, or fields beyond what you provided
- 🥉🥈🥇 Named modeling technique required in Phase 2 - Bronze/Silver/Gold, Star Schema, or SCD
- 🧪 2 or 3 concrete data quality tests defined, not "add some validation"
- ⏮️ Backfill strategy for historical corruption, not just the happy path
- 🐢 Batch/micro-batch default - no real-time latency claims unless streaming tools were requested
- 🛠️ Orchestrator-specific operators and features named for Airflow, dbt, Dagster, or Glue
- ✂️ Prose capped at 8 lines per phase
- 🪧 Scope-locked. Manifests and app code refused with `Out of scope: this engine outputs data pipeline blueprints only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If a source was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Any empty or unresolved field → halt and request it. Unknown schema → say so, design against the structure the user gave only.
4. **Generate** the blueprint under the strict operating constraints (idempotency, named modeling technique, batch default).
5. **Silent self-validation.** Idempotent for repeated same-range runs; nothing invented; 2-3 quality tests; named modeling technique; no unsupported latency claim. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/data-pipeline "Postgres to Snowflake, nightly"   ← arg seeds SOURCE_DATA
/data-pipeline                                     ← full intake
```

**Typical asks:** *"design an ETL pipeline"*, *"Postgres to BigQuery with dbt"*, *"incremental load with watermarks"*, *"how do I backfill this safely"*

The full procedure lives at [`lib/data-pipeline/SKILL.md`](../lib/data-pipeline/SKILL.md), the slash command at [`commands/data-pipeline.md`](../commands/data-pipeline.md), and the on-demand master prompt at [`lib/data-pipeline/references/prompt-template.md`](../lib/data-pipeline/references/prompt-template.md).

---

## `cloud-migration`

Enterprise data-center exit planning from four inputs, in the voice of a Principal Cloud Architect. Locked four-phase blueprint built on the 6 R's, with four fixed tables.

```
/cloud-migration
```

Migration advice usually arrives as a vague three-step plan that skips the part that actually sinks projects: the foundation. This tool requires a Landing Zone - networking, identity, security - to be established **before** any workload moves, and it maps every compliance requirement you named to a specific control in that zone. Each component gets one of the standard 6 R's (Rehost, Replatform, Refactor, Repurchase, Retire, Retain) with the driving factor stated, so the plan can be argued with rather than just accepted.

It will not promise zero downtime. Cutover is planned with practical methods - DNS switch, read-only windows - because the blind promise is the one that gets broken on migration night.

Output is table-heavy by design: four fixed tables with fixed columns, so the plan drops straight into a planning doc.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/cloud-migration/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt, including the exact column set required for each of the four tables.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. CURRENT_INFRASTRUCTURE + MIGRATION_GOAL + TARGET_CLOUD + COMPLIANCE_NEEDS
- 🧱 Locked 4-phase output: 6 R's Strategy, Landing Zone & Security, Phased Execution Roadmap, Risk Mitigation & TCO
- 🅁 Every component assigned one of the 6 R's with its driving factor stated
- 🛬 Landing Zone (networking, identity, security) established before any workload moves - enforced in validation
- 📊 Four fixed tables with fixed columns: component assignment, landing zone, migration waves, risk register
- 🔒 Every stated compliance requirement mapped to a specific control
- ⛔ No blind "zero downtime" promises - practical cutover methods only
- 🧰 Named cloud-native migration tooling (AWS SMS, Azure Migrate, and equivalents)
- 💸 Post-migration FinOps recommendations: tagging, rightsizing, commitment discounts, budget alerts
- 🛑 Halts if `TARGET_CLOUD` is unspecified rather than guessing
- 🪧 Scope-locked. Manifests and app code refused with `Out of scope: this engine outputs cloud migration blueprints only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If the current estate was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Empty field or unspecified `TARGET_CLOUD` → halt and ask. Conflicts → COMPLIANCE_NEEDS wins, then MIGRATION_GOAL, then TARGET_CLOUD, stated before Phase 1.
4. **Generate** the blueprint under the strict operating constraints (6 R's with rationale, Landing Zone first, compliance mapped, practical cutover).
5. **Silent self-validation.** 6 R's applied with rationale; Landing Zone precedes migration; no blind zero-downtime promise; every table present with its exact columns. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/cloud-migration "40 VMs and an Oracle DB, exiting DC in 9 months"
/cloud-migration                                                    ← full intake
```

**Typical asks:** *"plan our move to AWS"*, *"6 R's assessment for our estate"*, *"what does a landing zone need"*, *"migration waves for a data center exit"*

The full procedure lives at [`lib/cloud-migration/SKILL.md`](../lib/cloud-migration/SKILL.md), the slash command at [`commands/cloud-migration.md`](../commands/cloud-migration.md), and the on-demand master prompt at [`lib/cloud-migration/references/prompt-template.md`](../lib/cloud-migration/references/prompt-template.md).

---

## `sre-audit`

Full-stack observability and reliability design from four inputs, in the voice of a Principal SRE who has run telemetry for systems at millions of requests per minute. Locked four-phase blueprint.

```
/sre-audit
```

Most monitoring advice stops at "add alerts". This produces the opposite problem - alert fatigue - which is why every alerting rule here fires on error-budget burn rate or a user-visible symptom, never a static CPU threshold. Every SLO, alert, and retention rule carries a concrete number and the reasoning behind it: "99.9% availability over 28 days = 43 min error budget; page at 2% burn in 1h". An SLI without a matching SLO and error-budget note fails validation.

Tracing defaults to OpenTelemetry unless you are heavily invested in a proprietary vendor, and the span attributes recommended are chosen specifically to close the blind spots you named.

It does not claim to prevent outages. The goal stated up front is visibility, instrumentation accuracy, and lower MTTR.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/sre-audit/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt with a reference-tone example showing the expected burn-rate alert density.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. SYSTEM_ARCHITECTURE + CRITICAL_USER_JOURNEYS + CURRENT_BLIND_SPOTS + TELEMETRY_STACK
- 🧱 Locked 4-phase output: SLIs & SLOs, Distributed Tracing Strategy, Metrics & Alerting Rules, Structured Logging & Retention
- 🔢 Every SLO, alert, and retention rule carries a concrete number and its rationale
- 🔥 Burn-rate and symptom-based alerting only - static thresholds fail validation
- 🧵 OpenTelemetry-based tracing by default, with span attributes chosen to close your stated blind spots
- 📋 Every SLI paired with an SLO and an error-budget note
- 🗂️ A concrete JSON logging schema for your system, plus retention and sampling with storage cost in mind
- 🚫 No claim that outages will be prevented - visibility and MTTR only
- 📏 Depth floor: 200-400 words per phase
- 🪧 Scope-locked. Manifests and app code refused with `Out of scope: this engine outputs observability and SLO blueprints only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If a system description was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Empty field → state the adopted assumption before Phase 1 or ask. Conflicts → SYSTEM_ARCHITECTURE and CRITICAL_USER_JOURNEYS win over CURRENT_BLIND_SPOTS.
4. **Generate** the blueprint under the strict operating constraints (OTel default, burn-rate alerting, concrete numbers everywhere).
5. **Silent self-validation.** Every SLI has an SLO and budget note; alerts are burn-rate or symptom based; every target has a number; no outage-prevention claim. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/sre-audit "microservices on EKS, no tracing"   ← arg seeds SYSTEM_ARCHITECTURE
/sre-audit                                       ← full intake
```

**Typical asks:** *"define SLOs for our checkout flow"*, *"our alerts are too noisy"*, *"what should we trace"*, *"design our observability stack"*

The full procedure lives at [`lib/sre-audit/SKILL.md`](../lib/sre-audit/SKILL.md), the slash command at [`commands/sre-audit.md`](../commands/sre-audit.md), and the on-demand master prompt at [`lib/sre-audit/references/prompt-template.md`](../lib/sre-audit/references/prompt-template.md).

---

## `finops`

Cloud cost optimization from four inputs, in the voice of a Principal FinOps Architect who has cut 8-figure annual bills by 30%+. Locked four-phase blueprint separating quick wins from structural change.

```
/finops
```

Cost advice fails in two directions: it is either generic ("right-size your instances") or reckless ("delete the idle ones") without checking whether the idle thing is your failover capacity. This tool requires every recommendation to carry both a cost impact and a risk note, and it refuses to break the availability and performance requirements you stated. Commitment advice comes with its break-even: "a 3-year commit only pays off if the baseline is certain, else the exit penalty outweighs the extra 15% discount".

Cloud pricing changes constantly, so every savings figure is framed as approximate and pointed back at your own bill and the provider's current pricing page. Quick wins stay in Phase 1; architectural change stays in Phase 2, so nobody confuses "turn off the dev environment at night" with "move the batch tier to Spot".

## 📋 Technical Overview

One slash command plus its procedure file. `lib/finops/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt with a reference-tone example showing the expected commitment-analysis density.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. CLOUD_PROVIDER + CURRENT_ARCHITECTURE + MONTHLY_SPEND + PRIMARY_WASTE_SUSPECT
- 🧱 Locked 4-phase output: Audit & Quick Wins, Architectural Modernization, Discount & Commitment Strategy, Cost Governance & Alerts
- 💵 Every recommendation carries a cost impact **and** a risk note
- 🚦 Quick wins kept strictly separate from long-term architectural shifts
- 🛡️ Never sacrifices the availability or performance requirements you stated
- ⚖️ Commitment advice includes the break-even and lock-in risk, not just the headline discount
- 🏷️ Platform-specific pricing models named: Savings Plans, Sustained Use Discounts, Azure Hybrid Benefit, Spot
- 🌐 Non-big-three providers mapped to the nearest equivalent model, with the gap flagged
- ⚠️ Savings framed as approximate and verifiable against your own bill and the provider's current pricing
- 🏷️ Tagging strategy for cost allocation plus anomaly detection and billing alarm parameters
- 🪧 Scope-locked. Manifests and app code refused with `Out of scope: this engine outputs cloud cost optimization blueprints only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If a cost problem was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Empty field → state the adopted assumption before Phase 1 or ask. Non-big-three provider → map to the nearest model and flag the gap.
4. **Generate** the blueprint under the strict operating constraints (named pricing models, quick wins separated, availability preserved, break-even per commitment).
5. **Silent self-validation.** Cost impact and risk note per recommendation; quick wins separated; availability intact; savings framed as approximate. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/finops "AWS bill jumped 40% last quarter"   ← arg seeds PRIMARY_WASTE_SUSPECT
/finops                                       ← full intake
```

**Typical asks:** *"cut our AWS bill"*, *"should we buy Savings Plans or RIs"*, *"why is egress so expensive"*, *"set up cost governance"*

The full procedure lives at [`lib/finops/SKILL.md`](../lib/finops/SKILL.md), the slash command at [`commands/finops.md`](../commands/finops.md), and the on-demand master prompt at [`lib/finops/references/prompt-template.md`](../lib/finops/references/prompt-template.md).

---

## `incident-report`

Blameless root cause analysis from incident notes, in the voice of a Principal SRE and Incident Commander. Locked four-phase RCA with a 5 Whys chain that has to end at a systemic flaw.

```
/incident-report
```

Two things make a post-mortem useless: blaming a person, and inventing a timeline. This tool blocks both. Phrasing that names a person or role fails validation and is rewritten as the systemic gap - "the deployment pipeline lacked validation checks" rather than "someone pushed a bad config". Action items must assign a system or process to fix; "be more careful next time" is not an action item. The 5 Whys chain is checked to make sure it terminates at a structural flaw rather than stopping at a human.

The timeline is reconstructed only from your notes. Where a step is a reasonable inference it is marked `(inferred)` in the output, so nobody later reads a guess as a confirmed fact.

This writes up incidents **after** they are resolved. If yours is still burning, it says so and offers to write the RCA afterward.

## 📋 Technical Overview

One slash command plus its procedure file. `lib/incident-report/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. `references/prompt-template.md` holds the master prompt with the blameless-tone and no-invention rules encoded in its self-validation block.

## ✨ Features

- 🎯 Four inputs in, one RCA out. INCIDENT_SUMMARY + ROOT_CAUSE + BUSINESS_IMPACT + REMEDIATION_STEPS
- 🧱 Locked 4-phase output: Executive Summary & Impact, Incident Timeline, 5 Whys Root Cause, Preventative Action Items
- 🙅 Strictly blameless - no phrasing that blames a named person or role survives validation
- 🕵️ Timeline reconstructed only from your notes; reasonable inferences marked `(inferred)`
- 🚫 No invented timestamps, commands, or events presented as fact
- 🔧 Action items assign a system or process to fix - never "be more careful"
- ⛓️ The 5 Whys chain must terminate at a systemic flaw, not at a person
- 🎫 3 to 4 Jira-style action items categorized by type (Monitoring, CI/CD, Architecture)
- ✂️ Prose capped at 8 lines per phase
- 🕰️ After-the-fact only - an active incident gets a heads-up, not a rushed write-up
- 🪧 Scope-locked. Live triage and manifests refused with `Out of scope: this engine writes up incidents after the fact only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. The listed options are starting points - the "Other" field is the expected path for the real specifics.
2. **Load template.** Read `references/prompt-template.md`. Substitute the four values into the `<untrusted_input>` block.
3. **Validate inputs.** Any empty or unresolved field → halt and request it before drafting.
4. **Draft** the RCA under the strict operating constraints (blameless tone, systemic action items, inferences marked).
5. **Silent self-validation.** Blameless throughout; nothing stated as fact unless provided or marked `(inferred)`; every action item fixes a system; the 5 Whys chain ends at a systemic flaw. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

```
/incident-report "checkout down 43 min after a config push"
/incident-report                                             ← full intake
```

**Typical asks:** *"write up last night's outage"*, *"blameless post-mortem"*, *"RCA for the database incident"*, *"5 whys for this failure"*

The full procedure lives at [`lib/incident-report/SKILL.md`](../lib/incident-report/SKILL.md), the slash command at [`commands/incident-report.md`](../commands/incident-report.md), and the on-demand master prompt at [`lib/incident-report/references/prompt-template.md`](../lib/incident-report/references/prompt-template.md).
