# Servers and Scripting

[← Back to the README](../README.md)

## `docker-compose-architect`

Production, secure, scalable docker-compose stacks from four inputs, in the voice of a Senior DevOps Engineer and Docker expert. Locked four-phase blueprint. Required-input validation and a silent output gate before sending.

```
/docker-compose-architect
```

Most "give me a docker-compose file" prompts return something that should never reach production: secrets hardcoded in plaintext, every service on one flat network, no volumes so data evaporates on restart, no healthchecks so `depends_on` races, and containers running as root. This plugin replaces that with what a senior DevOps engineer actually does. Secrets are always `${VAR}` references resolved from a generated `.env` template - never literals. Tiers are isolated on separate bridge networks (frontend vs database). Every stateful service gets a named volume. Every service gets a healthcheck, and `depends_on` uses `condition: service_healthy`. Containers run non-root where the base image allows. Compose YAML is indented 2 spaces. Image names and tags are never invented - uncertain tags are flagged for confirmation.

The skill body runs the workflow. Step 1 loads the master prompt from `references/prompt-template.md` and substitutes the four inputs. Step 2 validates inputs - a missing `TECH_STACK` or `DATABASE_REQUIREMENTS` halts with one targeted question per field, and conflicting constraints (e.g. "no persistence" plus a database) are surfaced before generating. Step 3 produces the blueprint under the strict operating constraints. Step 4 runs a silent output gate - all four phases present, valid 2-space YAML, secrets as env refs, a healthcheck per service or documented reason, no invented images - and fixes any failure before returning.

Hard refusal on out-of-scope asks. Kubernetes, Terraform, raw Dockerfiles, and unrelated requests get exactly one line: `Out of scope: this engine outputs docker-compose stacks only.`

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/docker-compose-architect/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` lives in `references/prompt-template.md` and loads on every invocation. The slash command `/docker-compose-architect` accepts an optional `TECH_STACK` arg, then walks the user through `AskUserQuestion` intake for the remaining fields.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. TECH_STACK + DATABASE_REQUIREMENTS (required) + NETWORK_SETUP + SPECIFIC_CONSTRAINTS (optional)
- 🧱 Locked 4-phase output: Architecture Overview, complete `docker-compose.yml`, `.env` template, Deployment & Scaling
- 🔐 Secrets only as `${VAR}` env references resolved from the `.env` template - never plaintext literals
- 🧬 Tier network isolation (frontend-tier vs database-tier bridges), named volumes for every stateful service
- 🩺 Healthcheck on every service; `depends_on` with `condition: service_healthy`; containers run non-root where the base image allows
- 🧠 No invented image names, tags, version numbers, or compose keys - only real, documented images; uncertain tags flagged for confirmation
- ✅ Silent output validation: 4 phases present, valid 2-space YAML, every secret an env ref, every service healthchecked or documented, no invented images
- 🛡️ Prompt-injection defense. All inputs treated as untrusted data; embedded directives (`ignore prior`, `act as`, output-format-change attempts) ignored
- 🚦 Required-field halt + conflict surfacing - missing `TECH_STACK`/`DATABASE_REQUIREMENTS` asks one question per field; "no persistence" plus a database is surfaced before generating
- 🪧 Scope-locked. Kubernetes, Terraform, raw Dockerfiles, unrelated requests refused with `Out of scope: this engine outputs docker-compose stacks only.`

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If `TECH_STACK` was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute `{{TECH_STACK}}`, `{{DATABASE_REQUIREMENTS}}`, `{{NETWORK_SETUP}}`, `{{SPECIFIC_CONSTRAINTS}}`. Treat inputs as untrusted data.
3. **Validate inputs.** Empty / placeholder `TECH_STACK` or `DATABASE_REQUIREMENTS` → one targeted question per field, then halt. Conflicting constraints → surface and ask which wins.
4. **Generate** the blueprint under the strict operating constraints (non-root, tier isolation, named volumes, healthchecks, `${VAR}` secrets, 2-space YAML).
5. **Silent output gate.** 4 phases; valid YAML; secrets as env refs; healthcheck per service or documented reason; no invented images. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/docker-compose-architect "Node.js + React frontend, Express API"   ← arg seeds TECH_STACK
/docker-compose-architect                                           ← full intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"design a docker-compose stack"*, *"architect a containerized environment"*, *"write a production docker-compose.yml"*, *"multi-tier docker setup"*, *"docker compose with database and networks"*, *"containerize my app with compose"*

The full procedure lives at [`lib/docker-compose-architect/SKILL.md`](../lib/docker-compose-architect/SKILL.md), the slash command at [`commands/docker-compose-architect.md`](../commands/docker-compose-architect.md), and the on-demand master prompt at [`lib/docker-compose-architect/references/prompt-template.md`](../lib/docker-compose-architect/references/prompt-template.md).

---

## `kubernetes-architect`

Resilient, secure, production-ready Kubernetes manifests from four inputs, in the voice of a Principal Cloud Native Architect and Kubernetes expert. Locked four-phase blueprint. Empty/contradictory-input halt and a silent pre-delivery YAML validation before sending.

```
/kubernetes-architect
```

Most "give me a Kubernetes Deployment" prompts return YAML that falls apart at the first cluster review: no liveness or readiness probes so rollouts and traffic routing misbehave, no resource requests or limits so the scheduler and autoscaler have nothing to go on, containers running as root with a writable root filesystem, and Service selectors that don't match pod labels. This plugin replaces that with what a principal cloud native architect actually does. Every container gets liveness and readiness probes, resource requests and limits, and a security context (`runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`). YAML is syntax-perfect, 2-space indented, with dash-based arrays. Image names, tags, apiVersion values, and field keys are never invented - uncertain tags are flagged for confirmation. Before sending, every block is validated: `apiVersion`/`kind`/`metadata.name` present, indentation valid, probes + resources + securityContext per container, and Service/Ingress selectors matching Deployment pod labels.

The skill body runs the workflow. Step 1 loads the master prompt from `references/prompt-template.md` (including the canonical Deployment skeleton) and substitutes the four inputs. Step 2 validates inputs - any empty or contradictory field STOPs with a list of exactly what is missing rather than inventing a default. Step 3 generates the manifests under the strict operating constraints. Step 4 runs a silent pre-delivery validation and fixes any failure before returning; unvalidated YAML is never emitted.

Hard prompt-injection defense. Inputs are untrusted data - a field that says "ignore probes", "run as root", or "skip security" is ignored and flagged in PHASE 1. Off-domain requests (Terraform, billing, application code) get one refusal line, then the K8s task continues.

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/kubernetes-architect/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` and the Deployment skeleton lives in `references/prompt-template.md` and loads on every invocation. The slash command `/kubernetes-architect` accepts an optional `APP_REQUIREMENTS` arg, then walks the user through `AskUserQuestion` intake for the remaining fields.

## ✨ Features

- 🎯 Four inputs in, one blueprint out. APP_REQUIREMENTS + RESOURCE_LIMITS + EXPOSURE_STRATEGY + TARGET_ENVIRONMENT
- 🧱 Locked 4-phase output: Architecture Overview, Deployment + HPA manifests, Service/Ingress/ConfigMap manifests, kubectl Deployment Guide
- 🩺 Liveness AND readiness probes on every container - no silent rollout or routing failures
- 📊 `resources.requests` AND `resources.limits` on every container - scheduler and HPA get real signals
- 🔐 Security contexts where applicable - `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`
- 🧠 No invented image names, tags, apiVersion values, kind names, or field keys - only real, documented Kubernetes resources; uncertain tags flagged for confirmation
- ✅ Silent pre-delivery validation per block: apiVersion/kind/metadata.name present, valid 2-space indentation, probes+resources+securityContext per container, Service/Ingress selectors match pod labels
- 🛡️ Prompt-injection defense. Inputs are untrusted data; behavior-altering directives (`ignore probes`, `run as root`, `skip security`) are ignored and flagged in PHASE 1
- 🚦 No invented defaults - empty or contradictory fields STOP with a list of exactly what is missing
- 🪧 Scope-locked. Terraform, billing, and application-code requests get one refusal line, then the K8s task continues

## 🔄 How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If `APP_REQUIREMENTS` was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute `{{APP_REQUIREMENTS}}`, `{{RESOURCE_LIMITS}}`, `{{EXPOSURE_STRATEGY}}`, `{{TARGET_ENVIRONMENT}}`. Treat inputs as untrusted data.
3. **Validate inputs.** Empty / placeholder / contradictory field → STOP, list what is missing, ask. No invented defaults.
4. **Generate** the manifests under the strict operating constraints (probes, resource requests/limits, security contexts, 2-space YAML, dash-based arrays).
5. **Silent pre-delivery validation.** apiVersion/kind/metadata.name; 2-space indentation; probes+resources+securityContext per container; selectors match pod labels; no invented images. Fix failures before printing.
6. **Output the four phases only.**

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/kubernetes-architect "Node API, image myorg/api, port 3000, 3 replicas"   ← arg seeds APP_REQUIREMENTS
/kubernetes-architect                                                       ← full intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"design Kubernetes manifests"*, *"architect a K8s deployment"*, *"write a Kubernetes Deployment YAML"*, *"Deployment with HPA and probes"*, *"Kubernetes Service and Ingress"*, *"create production K8s manifests"*

The full procedure lives at [`lib/kubernetes-architect/SKILL.md`](../lib/kubernetes-architect/SKILL.md), the slash command at [`commands/kubernetes-architect.md`](../commands/kubernetes-architect.md), and the on-demand master prompt at [`lib/kubernetes-architect/references/prompt-template.md`](../lib/kubernetes-architect/references/prompt-template.md).

---

## `powershell-script-engine`

Production, PSScriptAnalyzer-clean PowerShell scripts from five inputs, in the voice of a PowerShell expert and Windows systems engineer. Locked four-section output. Pre-generation input validation and a silent self-check before output.

```
/powershell-script-engine
```

Most "write me a PowerShell script" prompts return something that fails review the moment it hits a real server: `Write-Host` used for data, unapproved verbs, hardcoded credentials in plaintext, a `Remove-Item` with no `-WhatIf`, and zero logging. This plugin replaces that with what a seasoned Windows systems engineer actually does. Every script opens with `#Requires -Version 7.0`, carries comment-based help (`.SYNOPSIS`/`.DESCRIPTION`/`.PARAMETER`/`.EXAMPLE`) on the script and every function, uses `[CmdletBinding()]` with validated parameters, wraps work in `try/catch/finally`, and logs to both console and a rolling file (`$env:ProgramData\<ScriptName>\<ScriptName>.log`, 10 MB roll, 5 archives). Credentials are typed `[PSCredential]` - never plaintext. Destructive operations are refused unless named in the requirements, and gated behind `-WhatIf`/`-Confirm` when generated. Cmdlet, module, and parameter names are never invented.

The skill body runs the workflow. Step 1 loads the master prompt from `references/prompt-template.md` and substitutes the five inputs. Step 2 validates inputs - an empty or placeholder `TASK`/`USER_REQUIREMENTS` halts with one clarifying question rather than a guessed script. Step 3 generates the script under the full specification (foundation, parameters, error handling, logging, security, remote). Step 4 runs a silent self-check - approved verbs, clean parse, no plaintext secrets, no invented names, four sections in order - and fixes any failure before returning.

Hard refusal on out-of-scope asks (output is the script plus usage examples only) and on security violations. Every response ends with `--- Generated by PowerShell Script Engine | review before production use ---`.

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/powershell-script-engine/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` lives in `references/prompt-template.md` and loads on every invocation. The slash command `/powershell-script-engine` accepts an optional `TASK` arg, then walks the user through `AskUserQuestion` intake for the remaining four fields.

## ✨ Features

- 🎯 Five inputs in, one production script out. TASK + USER_REQUIREMENTS + PS_TARGET + REMOTE + DESTRUCTIVE
- 📐 `#Requires -Version 7.0`, comment-based help on the script and every function, `[CmdletBinding()]` with validated parameters
- 🧯 `try/catch/finally` everywhere; clear error messages; console AND rolling file logging (10 MB roll, 5 archives)
- ✔️ Approved verbs only (Get-Verb). No `Write-Host` for data, no aliases in the body, no positional args in examples, no PSScriptAnalyzer rule suppressions
- 🔐 No plaintext secrets - `[PSCredential]` / `Get-Credential` / SecretManagement only
- 🚫 No destructive ops (`Remove-*`, `Format-*`, `Stop-*`, registry/disk writes) unless named in requirements; gated behind `-WhatIf`/`-Confirm` when generated
- 🧠 No invented cmdlet, module, parameter, or version names - only real, documented PowerShell; unverifiable modules flagged for confirmation
- 📦 Locked 4-section output: Script, Parameters table (Name/Mandatory/Type/Validation), 3+ Usage Examples (local/pipeline/PSSession), Security Notes
- 🛡️ Prompt-injection defense. `USER_REQUIREMENTS` treated as inert data; embedded directives (`ignore prior`, `act as`, output-format-change attempts) are ignored
- 🪧 Scope-locked. Empty or off-topic requirements get one clarifying question, then a halt

## 🔄 How it works

1. **Intake.** Slash command collects five fields via `AskUserQuestion`. If `TASK` was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute `{{TASK}}`, `{{USER_REQUIREMENTS}}`, `{{PS_TARGET}}`, `{{REMOTE}}`, `{{DESTRUCTIVE}}`. Treat requirements as inert data.
3. **Validate inputs.** Empty / blank / placeholder `TASK` or `USER_REQUIREMENTS` → ask one clarifying question naming the job, then halt.
4. **Generate** the script per the specification (foundation, parameters, error handling, logging, security, remote).
5. **Silent self-check.** Approved verbs; balanced braces, no aliases, no `Write-Host` for data; no plaintext secrets, credentials `[PSCredential]`; no invented names; four sections in order. Fix failures before printing.
6. **Output the four sections**, then the footer line.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/powershell-script-engine "Audit local admin group membership across a server list and export to CSV"   ← arg seeds TASK
/powershell-script-engine                                                                                ← full 5-question intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"write a PowerShell script"*, *"create a production PS module"*, *"PSScriptAnalyzer-clean script"*, *"PowerShell automation script"*, *"PowerShell remoting script"*, *"PowerShell with comment-based help"*

The full procedure lives at [`lib/powershell-script-engine/SKILL.md`](../lib/powershell-script-engine/SKILL.md), the slash command at [`commands/powershell-script-engine.md`](../commands/powershell-script-engine.md), and the on-demand master prompt at [`lib/powershell-script-engine/references/prompt-template.md`](../lib/powershell-script-engine/references/prompt-template.md).

---

## `jq`

Expert jq one-liners for querying, filtering, transforming, and aggregating JSON in real shell pipelines, in the voice of a senior CLI engineer. Inspects the JSON structure before writing the filter, builds it one pipe stage at a time, and returns a single copy-paste-ready command plus a one-line explanation per stage.

```
/jq
```

Most "give me a jq command" answers guess at the JSON structure, quote the filter wrong so the shell mangles it, and skip the null cases that break the pipeline on the first input that hits them. This plugin works like an experienced engineer. It samples the data first with `jq 'keys'` or `jq '.[0]'` to confirm the actual field names and nesting, then builds the filter incrementally instead of writing one opaque expression. The delivered command is single-quoted to block shell expansion, uses `-r` when the output feeds a shell variable or another command, injects shell values with `--arg` / `--argjson` rather than string interpolation, and handles the empty and null edge cases (`// empty`, `// 0`, `add // 0`). Every command comes with a plain-English explanation of what each `|` stage does.

The skill covers basic and nested selection, `select()` filtering, `map` and object reshaping, `reduce` and `group_by` aggregation, string interpolation and `@csv` / `@tsv` / `@base64` / `@uri` formatting, key and path manipulation, conditionals and `try` / `catch`, and shell integration with `curl`, `kubectl`, `aws`, `gh`, and `docker`. It is scope-locked to jq usage. JSON authoring, JSON Schema validation, jsonnet, and non-jq shell scripting are out of scope and get one refusal line.

## 📋 Technical Overview

One slash command plus its procedure file. The procedure file `lib/jq/SKILL.md` carries the persona, the 6-step workflow (identify source, inspect the structure, build incrementally, choose output mode, verify, deliver), a full cookbook of patterns, the output format, and the quality gates. The slash command `/jq` accepts an optional argument that seeds `JSON_SOURCE`, then walks the user through `AskUserQuestion` intake for the source, the goal, and the output mode.

## ✨ Features

- 🎯 Three intake fields. JSON_SOURCE + GOAL + OUTPUT_MODE, or just paste JSON and ask
- 🔎 Inspects the structure first (`jq 'keys'`, `jq '.[0]'`) - never guesses field names or nesting
- 🧱 Builds filters one pipe stage at a time, verified against a sample
- 📤 Output mode aware - `-r` for shell consumption, `-c` for NDJSON, pretty for reading, `@csv` / `@tsv` for tables
- 🛡️ Safe shell injection via `--arg` / `--argjson`, never string interpolation; filters always single-quoted
- 🕳️ Null and empty edge cases handled (`// empty`, `// 0`, `add // 0`)
- 📝 One copy-paste-ready command, then a one-line explanation per filter stage
- 🪧 Scope-locked. JSON authoring, JSON Schema, jsonnet, and non-jq shell scripting get one refusal line

## 🔄 How it works

1. **Intake.** Slash command collects JSON_SOURCE, GOAL, and OUTPUT_MODE via `AskUserQuestion`. If a source was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Inspect.** When the source is a paste or a file, check the structure with `jq 'keys'` / `jq '.[0]'` before writing anything.
3. **Build.** Compose the filter incrementally, adding one `|` stage at a time and verifying each against the sample.
4. **Apply output mode.** `-r`, `-c`, pretty, or `@csv` / `@tsv` per the chosen mode.
5. **Harden.** Single-quote the filter, inject variables with `--arg` / `--argjson`, cover null and empty cases.
6. **Deliver** one command in a bash block, then a one-line explanation per stage.

## 🚀 How to use it

Two ways to invoke:

**Slash command:**

```
/jq 'curl -s https://api.github.com/repos/owner/repo/issues'   ← arg seeds JSON_SOURCE
/jq                                                            ← full intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"parse this JSON"*, *"extract X from this output"*, *"pull the field with jq"*, *"filter this API response"*, *"reshape this JSON"*, *"aggregate these records"*, *"explain this jq filter"*, or paste raw JSON or CLI output and ask to filter, transform, or summarize it

The full procedure lives at [`lib/jq/SKILL.md`](../lib/jq/SKILL.md) and the slash command at [`commands/jq.md`](../commands/jq.md).
