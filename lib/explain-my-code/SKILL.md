# Explain My Code

Analyze a complete code repository as a senior software architect and produce one self-contained, production-grade Markdown document that lets anyone new to the project fully understand the system with no handover meetings or outside help.

## When to Use

- User asks to document, explain, or map a codebase or repository
- User wants an onboarding document for people new to the project
- User wants a system/architecture overview with Mermaid diagrams
- User points at a repo and asks "what does this do / how does it work" AND wants it captured as a written document, not a one-line reply

Do NOT use for bug-finding code review, refactoring plans, or diagram-only output (see negative boundary in description).

## Co-Load Precedence

When co-loading with codebase-to-mermaid: that skill owns standalone diagram generation; this skill embeds diagrams inside the full document. When co-loading with refactoring-analyst: that skill owns refactor planning; this skill only describes the system (Section 13 suggests improvements at a high level, it does not plan the refactor). When co-loading with a code-review skill (e.g. wordpress-architect-review): review owns defect findings; this skill owns architecture explanation (Section 12 lists observations/risks but does not perform line-level review).

## Workflow

### Phase 1: SCOPE THE TARGET

1. Determine the repository root. Default to the current working directory. If the user named a path, use that.
2. If no code is present at the target, STOP and ask the user for the repo path (see Error Handling).
3. Map the top-level layout with `Glob` (`**/*`) and read manifest/config files first (package.json, pom.xml, go.mod, requirements.txt, Cargo.toml, *.csproj, Dockerfile, compose files, CI configs).

### Phase 2: IDENTIFY FOUNDATIONS

1. Identify tech stack: languages, frameworks, frontend/backend/infra split, package managers.
2. Classify architecture: monolith vs microservices vs modular.
3. Locate entry points (main files, server bootstrap, CLI roots) and config loading.

### Phase 3: TRAVERSE SYSTEMATICALLY

1. Walk folder-by-folder, service-by-service, module-by-module.
2. Infer design patterns (MVC, Clean, Hexagonal, Factory, Observer, etc.) - record where and why each is used.
3. Trace core business logic, dependency flow, and data flow (input → processing → storage).
4. For large repos, analyze in chunks; accumulate knowledge and refine earlier sections as understanding improves (see Error Handling: large repo).

### Phase 4: WRITE THE DOCUMENT

1. Produce ALL 13 sections in the order under Output Format. Do not skip any section.
2. Use real file names, classes, and functions from the repo - never generic placeholders.
3. Embed Mermaid diagrams (`graph TD`, `sequenceDiagram`) where they clarify architecture and flow.
4. Where behavior is undocumented, infer logically and explicitly state the assumption.

### Phase 5: VERIFY BEFORE DELIVERY

1. Confirm every one of the 13 sections is present and non-shallow.
2. Confirm cited file/class/function names actually exist in the repo (`Grep`-verifiable - no invented symbols).
3. Confirm Mermaid blocks are syntactically valid.
4. Write the result to `CODEBASE_DOCUMENTATION.md` at the repo root (or a user-specified path) with `Write`, then tell the user the path.

## Output Format

Single Markdown file, default name `CODEBASE_DOCUMENTATION.md`, containing these sections in order:

1. **Project Overview** - purpose, high-level functionality, key use cases
2. **System Architecture** - explanation, monolith/microservices/hybrid, Mermaid `graph TD` diagram
3. **Repository Structure** - folder hierarchy, role of each major directory, module responsibilities
4. **Tech Stack & Dependencies** - languages, frameworks, external libraries, package managers, dependency graph if possible
5. **Core Components / Services** - per component: responsibility, key classes/functions, interactions
6. **Application Flow** - 6.1 Startup flow (entry point, init sequence, config, DI); 6.2 Request/execution flow; 6.3 Auth flow if applicable; 6.4 Data flow; include Mermaid `sequenceDiagram`
7. **Key Design Patterns** - patterns used, where and why
8. **Database & Models** - schema overview, ORM usage, entity relationships
9. **External Integrations** - APIs, third-party services, queues, caches
10. **Configuration & Environment** - env vars, config files, build configs
11. **Build & Deployment** - build steps, scripts, CI/CD if present
12. **Observations & Risks** - code smells, tight coupling, scalability concerns, missing abstractions
13. **Suggestions for Improvement** - refactoring ideas, performance, architecture alternatives

Constraints (from source prompt, preserved):
- Be precise and technical; avoid generic explanations.
- Do NOT give shallow summaries or skip flows/architecture.
- Do NOT assume undocumented behavior without stating the reasoning.
- The deliverable is the document file; keep it complete, structured, and self-sufficient for onboarding.

## Error Handling

**No repository / empty target:** Ask the user for the repo path. Do not fabricate documentation for code that was not read.

**Large repo (cannot read fully in one pass):** Tell the user, then analyze in chunks - manifests and entry points first, then per-module. Accumulate findings and refine earlier sections. Note any directories sampled rather than fully read.

**Ambiguous path (multiple repos in directory):** Ask which repo to document before proceeding.

**Generated/vendored code (node_modules, vendor, build, dist):** Exclude from traversal; mention it was skipped.

**Section genuinely not applicable (e.g., no database):** Keep the heading, state "Not applicable - <reason>". Do not silently drop a section.

## Quality Gates

- [ ] All 13 sections present and substantive (no shallow summaries)
- [ ] Cited file/class/function names verified to exist in the repo (accuracy gate)
- [ ] At least one architecture diagram and one flow diagram in valid Mermaid syntax (format gate)
- [ ] Assumptions about undocumented behavior are explicitly labeled
- [ ] Output written to a `.md` file and its path reported to the user

## Examples

**Standard case:** User runs the skill in a Node/Express + React repo. The skill reads package.json files, identifies a modular monolith, walks `server/` and `client/`, and writes `CODEBASE_DOCUMENTATION.md` with all 13 sections, a `graph TD` of the request path, and a `sequenceDiagram` of an authenticated API call - citing real route files and controllers.

**Edge case:** User points at a directory containing two services and no top-level manifest. The skill detects ambiguity, asks which service to document (or confirms "both as one system"), excludes `node_modules`/`dist`, marks Section 8 "Not applicable - no database layer found", and states the assumption that inter-service calls are HTTP based on observed `fetch` usage.
