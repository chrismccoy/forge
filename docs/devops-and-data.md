# DevOps & Data

[← Back to the README](../README.md)

## `docker-compose-architect`

docker-compose stacks with secrets, health checks, and non-root containers from four inputs, in the voice of a DevOps engineer. Locked four-phase blueprint. Required-input validation and a silent output gate before sending.

```
/docker-compose-architect
```

Most "give me a docker-compose file" prompts return something that should never reach production: secrets hardcoded in plaintext, every service on one flat network, no volumes so data evaporates on restart, no healthchecks so `depends_on` races, and containers running as root. This plugin replaces that with what a senior DevOps engineer would do. Secrets are always `${VAR}` references resolved from a generated `.env` template - never literals. Tiers are isolated on separate bridge networks (frontend vs database). Every stateful service gets a named volume. Every service gets a healthcheck, or a one-line comment in the compose file stating why it cannot have one, and `depends_on` uses `condition: service_healthy`. Containers run non-root where the base image allows. Compose YAML is indented 2 spaces. Image names and tags are never invented - uncertain tags are flagged for confirmation.

The skill body runs the workflow. Step 1 validates inputs - a missing `TECH_STACK` or `DATABASE_REQUIREMENTS` gets one targeted question per field and stops only if still missing after asking, and conflicting constraints (e.g. "no persistence" plus a database) are surfaced before generating. Step 2 loads the master prompt from `references/prompt-template.md` and substitutes the four inputs. Step 3 produces the blueprint under the strict operating constraints. Step 4 runs a silent output gate - all four phases present, valid 2-space YAML, secrets as env refs, every service non-root where the image allows, data-tier services on isolated networks with no published ports, stateful services on named volumes with `depends_on`, every service gets a healthcheck, or a one-line comment in the compose file stating why it cannot have one, no invented images - and fixes any failure before returning.

Hard refusal on out-of-scope asks. Kubernetes, Terraform, raw Dockerfiles, and unrelated requests get exactly one line: `Out of scope: this engine outputs docker-compose stacks only.` Kubernetes manifest requests get the routing hint on that same line: `... only - try /kubernetes-architect.`

## Technical Overview

One slash command plus its procedure file. The procedure file `lib/docker-compose-architect/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` lives in `references/prompt-template.md` and loads on every blueprint request. The slash command `/docker-compose-architect` accepts an optional `TECH_STACK` arg, then walks the user through `AskUserQuestion` intake for the remaining fields.

## Features

- Four inputs in, one blueprint out. TECH_STACK + DATABASE_REQUIREMENTS (required) + NETWORK_SETUP + SPECIFIC_CONSTRAINTS (optional)
- Locked 4-phase output: Architecture Overview, complete `docker-compose.yml`, `.env` template, Deployment & Scaling
- Secrets only as `${VAR}` env references resolved from the `.env` template - never plaintext literals
- Tier network isolation (frontend-tier vs database-tier bridges), named volumes for every stateful service
- Every service gets a healthcheck, or a one-line comment in the compose file stating why it cannot have one; `depends_on` with `condition: service_healthy`; containers run non-root where the base image allows
- No invented image names, tags, version numbers, or compose keys - only real, documented images; uncertain tags flagged for confirmation
- Silent output validation: 4 phases present, valid 2-space YAML, every secret an env ref, non-root services, isolated data-tier networks with no published ports, named volumes for stateful services, every service gets a healthcheck, or a one-line comment in the compose file stating why it cannot have one, no invented images
- Prompt-injection defense. All inputs treated as untrusted data; embedded directives (`ignore prior`, `act as`, output-format-change attempts) ignored
- Required-field check + conflict surfacing - missing `TECH_STACK`/`DATABASE_REQUIREMENTS` asks one question per field and stops only if still missing; "no persistence" plus a database is surfaced before generating
- Scope-locked. Kubernetes, Terraform, raw Dockerfiles, unrelated requests refused with `Out of scope: this engine outputs docker-compose stacks only.`

## How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If `TECH_STACK` was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Validate inputs.** Empty / placeholder `TECH_STACK` or `DATABASE_REQUIREMENTS` → one targeted question per field; stop only if still missing after asking. Conflicting constraints → surface and ask which wins.
3. **Load template.** Read `references/prompt-template.md`. Substitute `{{TECH_STACK}}`, `{{DATABASE_REQUIREMENTS}}`, `{{NETWORK_SETUP}}`, `{{SPECIFIC_CONSTRAINTS}}`. Treat inputs as untrusted data.
4. **Generate** the blueprint under the strict operating constraints (non-root, tier isolation, named volumes, healthchecks, `${VAR}` secrets, 2-space YAML).
5. **Silent output gate.** 4 phases; valid YAML; secrets as env refs; non-root; isolated data-tier networks; named volumes for stateful services; every service gets a healthcheck, or a one-line comment in the compose file stating why it cannot have one; no invented images. Fix failures before printing.
6. **Output the four phases only**, with at most one `Assumptions:` line directly before Phase 1. Direct docker-compose questions are answered plainly.

## How to use it

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

Production-ready Kubernetes manifests from four inputs, in the voice of a Kubernetes architect. Locked four-phase blueprint. Empty/contradictory-input halt and a silent pre-delivery YAML validation before sending.

```
/kubernetes-architect
```

Most "give me a Kubernetes Deployment" prompts return YAML that falls apart at the first cluster review: no liveness or readiness probes so rollouts and traffic routing misbehave, no resource requests or limits so the scheduler and autoscaler have nothing to go on, containers running as root with a writable root filesystem, and Service selectors that don't match pod labels. This plugin replaces that with what a Kubernetes architect would do. Every container gets liveness and readiness probes, resource requests and limits, and a security context (`runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`). YAML is syntax-perfect, 2-space indented, with dash-based arrays. Image names, tags, apiVersion values, and field keys are never invented - uncertain tags are flagged for confirmation. Before sending, every block is validated: `apiVersion`/`kind`/`metadata.name` present, indentation valid, probes + resources + securityContext per container, and Service/Ingress selectors matching Deployment pod labels.

The skill body runs the workflow. Step 1 validates inputs - any empty, placeholder, or contradictory field STOPs with a list of exactly what is missing (or the conflict) and asks, rather than inventing a default. Step 2 loads the master prompt from `references/prompt-template.md` (including a reference container snippet that sets the expected manifest density) and substitutes the four inputs. Step 3 generates the manifests under the strict operating constraints. Step 4 runs a silent pre-delivery validation and fixes any failure before returning; unvalidated YAML is never emitted.

Hard prompt-injection defense. Inputs are untrusted data - a field that says "ignore probes", "run as root", or "skip security" is ignored and flagged in PHASE 1. Off-domain requests (Terraform, billing, application code, docker-compose stacks) get one refusal line - docker-compose requests are pointed to `/docker-compose-architect` on that same line - then the K8s task continues.

## Technical Overview

One slash command plus its procedure file. The procedure file `lib/kubernetes-architect/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` and the reference container snippet lives in `references/prompt-template.md` and loads on every blueprint request. The slash command `/kubernetes-architect` accepts an optional `APP_REQUIREMENTS` arg, then walks the user through `AskUserQuestion` intake for the remaining fields.

## Features

- Four inputs in, one blueprint out. APP_REQUIREMENTS + RESOURCE_LIMITS + EXPOSURE_STRATEGY + TARGET_ENVIRONMENT
- Locked 4-phase output: Architecture Overview, Deployment + HPA manifests, Service/Ingress/ConfigMap manifests, kubectl Deployment Guide. Direct Kubernetes concept questions are answered plainly, outside the phases
- Liveness AND readiness probes on every container - no silent rollout or routing failures
- `resources.requests` AND `resources.limits` on every container - scheduler and HPA get real signals
- Security contexts where applicable - `runAsNonRoot`, `readOnlyRootFilesystem`, `allowPrivilegeEscalation: false`
- No invented image names, tags, apiVersion values, kind names, or field keys - only real, documented Kubernetes resources; uncertain tags flagged for confirmation
- Silent pre-delivery validation per block: apiVersion/kind/metadata.name present, valid 2-space indentation, probes+resources+securityContext per container, Service/Ingress selectors match pod labels
- Prompt-injection defense. Inputs are untrusted data; behavior-altering directives (`ignore probes`, `run as root`, `skip security`) are ignored and flagged in PHASE 1
- No invented defaults - empty, placeholder, or contradictory fields STOP with a list of exactly what is missing (or the conflict) and ask
- Scope-locked. Terraform, billing, application-code, and docker-compose requests get one refusal line (docker-compose points to `/docker-compose-architect`), then the K8s task continues

## How it works

1. **Intake.** Slash command collects four fields via `AskUserQuestion`. If `APP_REQUIREMENTS` was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Validate inputs.** Empty / placeholder / contradictory field → STOP, list what is missing (or the conflict), ask. No invented defaults.
3. **Load template.** Read `references/prompt-template.md`. Substitute `{{APP_REQUIREMENTS}}`, `{{RESOURCE_LIMITS}}`, `{{EXPOSURE_STRATEGY}}`, `{{TARGET_ENVIRONMENT}}`. Treat inputs as untrusted data.
4. **Generate** the manifests under the strict operating constraints (probes, resource requests/limits, security contexts, 2-space YAML, dash-based arrays).
5. **Silent pre-delivery validation.** apiVersion/kind/metadata.name; 2-space indentation; probes+resources+securityContext per container; selectors match pod labels; no invented images. Fix failures before printing.
6. **Output the four phases only.**

## How to use it

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

PSScriptAnalyzer-clean PowerShell scripts from five inputs, in the voice of a Windows systems engineer. Locked four-section output. Pre-generation input validation and a silent self-check before output.

```
/powershell-script-engine
```

Most "write me a PowerShell script" prompts return something that fails review the moment it hits a real server: `Write-Host` used for data, unapproved verbs, hardcoded credentials in plaintext, a `Remove-Item` with no `-WhatIf`, and zero logging. This plugin replaces that with what a Windows systems engineer would do. Every script opens with `#Requires -Version 7.0`, carries comment-based help (`.SYNOPSIS`/`.DESCRIPTION`/`.PARAMETER`/`.EXAMPLE`) on the script and every function, uses `[CmdletBinding()]` with validated parameters, wraps work in `try/catch/finally`, and logs to both console and a rolling file (`$env:ProgramData\<ScriptName>\<ScriptName>.log`, 10 MB roll, 5 archives). Credentials are typed `[PSCredential]` - never plaintext. Destructive operations are refused unless named in the requirements, and gated behind `-WhatIf`/`-Confirm` when generated. Cmdlet, module, and parameter names are never invented.

The skill body runs the workflow. Step 1 loads the master prompt from `references/prompt-template.md` and substitutes the five inputs. Step 2 validates inputs - an empty or placeholder `TASK`/`USER_REQUIREMENTS` halts with one clarifying question rather than a guessed script, and allowing destructive ops without naming any triggers a follow-up question. Step 3 generates the script under the full specification (foundation, parameters, error handling, logging, security, remote). Step 4 runs a silent self-check - approved verbs, clean parse, no plaintext secrets, no invented names, destructive ops named and gated, four sections in order - and fixes any failure before returning.

Hard refusal on out-of-scope asks (output is the script plus usage examples only) and on security violations. Every response ends with `--- Generated by PowerShell Script Engine | review before production use ---`.

## Technical Overview

One slash command plus its procedure file. The procedure file `lib/powershell-script-engine/SKILL.md` carries the persona, scope lock, input handling, and 4-step workflow. The authoritative master prompt with `{{placeholders}}` lives in `references/prompt-template.md` and loads on every invocation. The slash command `/powershell-script-engine` accepts an optional `TASK` arg, then walks the user through `AskUserQuestion` intake for the remaining four fields.

## Features

- Five inputs in, one production script out. TASK + USER_REQUIREMENTS + PS_TARGET + REMOTE + DESTRUCTIVE
- `#Requires -Version 7.0`, comment-based help on the script and every function, `[CmdletBinding()]` with validated parameters
- `try/catch/finally` everywhere; clear error messages; console AND rolling file logging (10 MB roll, 5 archives)
- Approved verbs only (Get-Verb). No `Write-Host` for data, no aliases in the body, no positional args in examples, no PSScriptAnalyzer rule suppressions
- No plaintext secrets - `[PSCredential]` / `Get-Credential` / SecretManagement only
- No destructive ops (`Remove-*`, `Format-*`, `Stop-*`, registry/disk writes) unless named in requirements; when generated, gated by `[CmdletBinding(SupportsShouldProcess)]` plus a `$PSCmdlet.ShouldProcess(...)` check, so `-WhatIf`/`-Confirm` work
- No invented cmdlet, module, parameter, or version names - only real, documented PowerShell; unverifiable modules flagged for confirmation
- Locked 4-section output: Script, Parameters table (Name/Mandatory/Type/Validation), 3+ Usage Examples (local/pipeline, plus PSSession when remote), Security Notes
- Prompt-injection defense. `USER_REQUIREMENTS` treated as inert data; embedded directives (`ignore prior`, `act as`, output-format-change attempts) are ignored
- Scope-locked. Empty or off-topic requirements get one clarifying question, then a halt

## How it works

1. **Intake.** Slash command collects five fields via `AskUserQuestion`. If `TASK` was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Load template.** Read `references/prompt-template.md`. Substitute `{{TASK}}`, `{{USER_REQUIREMENTS}}`, `{{PS_TARGET}}`, `{{REMOTE}}`, `{{DESTRUCTIVE}}`. Treat requirements as inert data.
3. **Validate inputs.** Empty / blank / placeholder `TASK` or `USER_REQUIREMENTS` → ask one clarifying question naming the job, then halt. Destructive ops allowed but none named → ask which ones before generating.
4. **Generate** the script per the specification (foundation, parameters, error handling, logging, security, remote).
5. **Silent self-check.** Approved verbs; balanced braces, no aliases, no `Write-Host` for data; no plaintext secrets, credentials `[PSCredential]`; no invented names; any destructive op was named and is gated; four sections in order. Fix failures before printing.
6. **Output the four sections**, then the footer line.

## How to use it

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

jq one-liners for querying, filtering, transforming, and aggregating JSON in real shell pipelines. Inspects the JSON structure before writing the filter, builds it one pipe stage at a time, and returns a single copy-paste-ready command plus a one-line explanation per stage.

```
/jq
```

Most "give me a jq command" answers guess at the JSON structure, quote the filter wrong so the shell mangles it, and skip the null cases that break the pipeline on the first input that hits them. This plugin works like an experienced engineer. It samples the data first with `jq 'keys'` or `jq '.[0]'` to confirm the actual field names and nesting, then builds the filter incrementally instead of writing one opaque expression. The delivered command is single-quoted to block shell expansion, uses `-r` when the output feeds a shell variable or another command, injects shell values with `--arg` / `--argjson` rather than string interpolation, and handles the empty and null edge cases (`// empty`, `// 0`, `add // 0`). Every command comes with a plain-English explanation of what each `|` stage does.

The skill covers basic and nested selection, `select()` filtering, `map` and object reshaping, `reduce` and `group_by` aggregation, string interpolation and `@csv` / `@tsv` / `@base64` / `@uri` formatting, key and path manipulation, conditionals and `try` / `catch`, and shell integration with `curl`, `kubectl`, `aws`, `gh`, and `docker`. It is scope-locked to jq usage. JSON authoring, JSON Schema validation, jsonnet, and non-jq shell scripting are out of scope and get one refusal line.

## Technical Overview

One slash command plus its procedure file. The procedure file `lib/jq/SKILL.md` carries the 6-step workflow (identify source, inspect the structure, build incrementally, choose output mode, verify, deliver), a full cookbook of patterns, the output format, and the quality gates. The slash command `/jq` accepts an optional argument that seeds `JSON_SOURCE`, then walks the user through `AskUserQuestion` intake for the source, the goal, and the output mode.

## Features

- Three intake fields. JSON_SOURCE + GOAL + OUTPUT_MODE, or just paste JSON and ask
- Inspects the structure first (`jq 'keys'`, `jq '.[0]'`) - never guesses field names or nesting
- Builds filters one pipe stage at a time, verified against a sample
- Output mode aware - `-r` for shell consumption, `-c` for NDJSON, pretty for reading, `@csv` / `@tsv` for tables
- Safe shell injection via `--arg` / `--argjson`, never string interpolation; filters always single-quoted
- Null and empty edge cases handled (`// empty`, `// 0`, `add // 0`)
- One copy-paste-ready command, then a one-line explanation per filter stage
- Scope-locked. JSON authoring, JSON Schema, jsonnet, and non-jq shell scripting get one refusal line

## How it works

1. **Intake.** Slash command collects JSON_SOURCE, GOAL, and OUTPUT_MODE via `AskUserQuestion`. If a source was passed as `$ARGUMENTS`, confirm and skip that question.
2. **Inspect.** When the source is a paste or a file, check the structure with `jq 'keys'` / `jq '.[0]'` before writing anything.
3. **Build.** Compose the filter incrementally, adding one `|` stage at a time and verifying each against the sample.
4. **Apply output mode.** `-r`, `-c`, pretty, or `@csv` / `@tsv` per the chosen mode.
5. **Harden.** Single-quote the filter, inject variables with `--arg` / `--argjson`, cover null and empty cases.
6. **Deliver** one command in a bash block, then a one-line explanation per stage.

## How to use it

Two ways to invoke:

**Slash command:**

```
/jq 'curl -s https://api.github.com/repos/owner/repo/issues'   ← arg seeds JSON_SOURCE
/jq                                                            ← full intake
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"parse this JSON"*, *"extract X from this output"*, *"pull the field with jq"*, *"filter this API response"*, *"reshape this JSON"*, *"aggregate these records"*, *"turn this JSON into CSV"*, or paste raw JSON or CLI output and ask to filter, transform, or summarize it

The full procedure lives at [`lib/jq/SKILL.md`](../lib/jq/SKILL.md) and the slash command at [`commands/jq.md`](../commands/jq.md).

---

## `git-forge`

Safe, hands-on Git for every task from `git init` to a history rewrite, plus Git hosting, GitHub Actions, and GitHub security. Tell it the task in your own words; it loads the matching reference, does the work (or explains it), and never loses work along the way.

```
/git-forge
```

Most "help me with Git" answers paste a command and move on. They suggest `reset --hard` or `push --force` without saying what disappears, open an editor or a password prompt that hangs a non-interactive shell, and rewrite history before the leaked key has been rotated. This tool works like a careful senior engineer. Before any destructive operation it runs read-only checks, states exactly what will be lost, backs it up (a backup branch for commits, a `git clone --mirror` before `filter-repo`, a file copy before `git clean`, `git stash export` before dropping stashes), gives the recovery command, and waits for an explicit "yes" in the conversation. Every command it runs is in a non-interactive form (`commit -m`, `--no-edit`, `GIT_EDITOR=true git rebase --continue`, `GIT_SEQUENCE_EDITOR=:` for autosquash, `GIT_TERMINAL_PROMPT=0` for network commands); truly interactive work such as `git rebase -i` with manual edits, `git add -p`, `ssh-keygen`, and passphrase prompts is handed to you as an exact command.

The procedure covers everyday work (commit, branch, merge, conflicts, stash, tag, remotes), history editing (rebase with `--onto` and autosquash, squash, cherry-pick, revert, reset, amend), recovery (reflog, detached HEAD, rejected pushes, wrong-branch commits, corrupted repositories, undoing a force push), history rewriting and leaked-secret response, signing and credentials, hooks and conventional commits, submodules, worktrees, LFS, sparse-checkout, partial clone, reftable, Scalar, Git 2.48-2.53 and Git 3.0, CRLF and Git Bash path issues, PRs and MRs on GitHub, GitLab, Azure DevOps, and Bitbucket, and GitHub Actions, CodeQL, Dependabot, and secret scanning push protection (GH013). It is scope-locked to Git and Git hosting. Designing a full CI/CD pipeline is out of scope and gets one refusal line pointing at `/cicd-pipeline`.

## Technical Overview

One slash command plus its procedure folder. The procedure file `lib/git-forge/SKILL.md` carries the safety-first checklist, the commit preference check, the non-interactive execution rules, platform notes, a reference map, a quick command index, and the success criteria. Thirteen reference files under `lib/git-forge/references/` hold the command catalogs and procedures: basic operations, merging and rebasing, advanced commands, dangerous operations, troubleshooting and recovery, platform workflows, performance and large files, hooks and conventions, security, modern Git features, GitHub Actions, GitHub security, and cross-platform handling. Only the reference that matches the task is read. The slash command `/git-forge` takes the task as its argument and asks one plain question only when nothing is passed.

## Features

- One input. Describe the Git task in your own words, or pass it as the argument
- Commit preference asked once, as a menu, before the first change: commit for me, stage only, or guidance only. Never asked for read-only questions
- Five-step safety protocol for destructive operations: check, state the loss, back up, give the undo command, wait for "yes"
- Safer defaults: `--force-with-lease --force-if-includes` for force pushes, `git branch recovered <sha>` instead of `reset --hard` for recovery, credential rotation before any secret-removal rewrite
- Non-interactive commands only; interactive steps handed to you as exact commands
- 13 reference files, loaded only when the task needs them
- Hosting CLIs: `gh`, `glab`, `az repos`, and Bitbucket
- Current facts: Git 2.48-2.53, Git 3.0 changes, current GitHub Actions runners and action majors, push protection

## How it works

1. **Intake.** Take the task from `$ARGUMENTS`, or ask one plain question if empty.
2. **Load.** Read the reference that matches the task from the procedure's reference map.
3. **Check.** For a repository task, run read-only checks first: status, recent log, branch, and remote.
4. **Ask once.** Before the first repository change, ask the commit preference menu and keep that choice for the session.
5. **Act safely.** Run non-interactive commands. For a destructive step, follow the five-step safety protocol.
6. **Report.** Say what changed and how to undo it.

## How to use it

Two ways to invoke:

**Slash command:**

```
/git-forge squash my last 3 commits      ← task passed, starts at once
/git-forge my push was rejected          ← diagnoses fetch first vs. non-fast-forward
/git-forge                               ← asks what Git task to help with
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"I committed to the wrong branch"*, *"undo my last commit"*, *"I lost some work"*, *"resolve this merge conflict"*, *"I pushed a password"*, *"push blocked with GH013"*, *"set up commit signing"*, *"open a pull request"*, *"pin our Actions to SHAs"*

The full procedure lives at [`lib/git-forge/SKILL.md`](../lib/git-forge/SKILL.md) and the slash command at [`commands/git-forge.md`](../commands/git-forge.md).

---

## `bash-forge`

Bash scripting for Linux, macOS, WSL, Git Bash, and containers: write a new script, review or lint an existing one, find why it fails, make it faster, or scaffold a CLI, daemon, library, installer, or CI script. Tell it the task; it reads the matching guide first, then does the work.

```
/bash-forge
```

Most shell scripts that come back from a quick request work once, on the author's machine. They leave expansions unquoted, so a filename with a space splits in two. They call `exit` inside `$(...)` and expect the script to stop. They use `mapfile` or `${var,,}` and then fail on the Bash 3.2 that stock macOS still ships, or turn `C:\` paths into nonsense under Git Bash. This tool starts every script from a safety frame - shebang, `set -euo pipefail`, `readonly` constants, a `trap` cleanup, small single-purpose functions, and a `main` at the bottom - validates input by rejecting it instead of silently rewriting it, and gives cross-platform notes for the platforms you target.

Before it answers, it reads the guide that matches the request: Bash 5.3 features and version detection, arrays and `mapfile`, parameter expansion and `BASH_REMATCH`, pure-Bash text processing in place of `sed`/`awk`/`cut`, process substitution, FIFOs and coprocesses, `xargs -P`, GNU parallel and job pools, input validation and secrets, strict mode and trace debugging, ShellCheck in CI, CI/CD and cloud CLIs, platform differences, and Git Bash path conversion. Four requests have their own workflow: **analyze** (security, performance, portability, and style), **optimize** (speed, memory, or both, measured before and after), **template** (CLI, daemon, library, installer, or CI script), and **create** (a new script for a task). For large multi-file jobs - a full CI/CD script suite, a hang that only happens in CI, a performance project - it can hand parts to the bash-expert agent defined in the procedure.

## Technical Overview

One slash command plus its procedure folder. `lib/bash-forge/SKILL.md` carries the scope, the reference routing tables, the workflow table, the bash-expert agent instructions and quality checklist, the helper script index, and the core principles. Twenty-three reference files under `lib/bash-forge/references/` hold the depth: 13 topic guides, 6 core guides (patterns, the style guide, pitfalls, platforms, Git Bash paths, and resources), and the four workflow files. Only the file that matches the task is read. Three helper scripts sit under `lib/bash-forge/scripts/`. `/bash-forge` takes the task as its argument and asks one multiple-choice question only when nothing is passed.

## Features

- One input: the script, the folder, or the task in your own words, or a four-option menu when nothing is passed
- Reads the matching guide before answering, from 19 topic and core references
- Four workflows: analyze, optimize, template, and create
- Safety frame on every script: shebang, `set -euo pipefail`, quoted expansions, input validation, `trap` cleanup, `--help`
- Bash 5.3 (`${ cmd; }`, `${| cmd; }`, `GLOBSORT`, `BASH_TRAPSIG`) with version checks and shims for older Bash
- Parallel work with `xargs -P`, GNU parallel, `wait -n` job pools, and exit-code aggregation
- Security: injection prevention, `mktemp`, `PATH` hardening, and secrets handling
- Debugging with strict mode, `set -x`, `PS4`, and `trap DEBUG/ERR/EXIT`
- ShellCheck and BATS for linting and tests, with CI integration
- Portability notes for Linux, macOS, BSD, WSL, Git Bash, and containers
- bash-expert agent mode for large multi-file jobs
- `shellcheck-batch.sh`: ShellCheck over many files with a summary, JSON, gcc, or checkstyle output, and a CI mode
- `script-profiler.sh`: per-line timing of a script, as text, CSV, or JSON
- `parallel-runner.sh`: run commands in parallel with a job limit, timeouts, and retries

## How it works

1. **Intake.** Take the task from `$ARGUMENTS`, or ask what to do: write, review, fix or speed up, or scaffold.
2. **Route.** Read the reference that matches the task, and the workflow file if the request is one of the four.
3. **Work.** Write or change the script inside the safety frame, or analyze it with `shellcheck-batch.sh` and profile it with `script-profiler.sh`.
4. **Check.** Run the quality checklist: shebang, strict mode, quoting, error handling, validation, ShellCheck clean, cross-platform notes, and usage help.
5. **Report.** The complete script or the findings, the assumptions, test commands, and any warnings.

## How to use it

Two ways to invoke:

**Slash command:**

```
/bash-forge                                          ← asks what to do with Bash
/bash-forge lint ./deploy.sh                         ← analyze workflow on one script
/bash-forge back up /data to S3 with logging         ← create workflow
/bash-forge process.sh takes 5 minutes, speed it up  ← optimize workflow, timed before and after
```

**Requests it handles** (type the command to run it - it never auto-triggers):

> *"write a backup script"*, *"analyze deploy.sh for security problems"*, *"generate a daemon template with logging"*, *"why does this script hang in CI?"*, *"run these jobs in parallel"*, *"make this work in Git Bash"*

**Needs:** Bash. ShellCheck for the linting script; without it, the review is done by hand and says so.

For PowerShell use [`/powershell-script-engine`](#powershell-script-engine); for one jq filter use [`/jq`](#jq); for Git use [`/git-forge`](#git-forge); to refactor a script another program runs, with side-by-side proof that its output is unchanged, use [`/script-refactor`](code.md#script-refactor).

The full procedure lives at [`lib/bash-forge/SKILL.md`](../lib/bash-forge/SKILL.md), the reference files under [`lib/bash-forge/references/`](../lib/bash-forge/references/), the helper scripts under [`lib/bash-forge/scripts/`](../lib/bash-forge/scripts/), and the slash command at [`commands/bash-forge.md`](../commands/bash-forge.md).
