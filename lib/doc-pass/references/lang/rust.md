## Rust rules

### Files and tools

- **In scope:** `.rs` files, including `build.rs`, `tests/`, `benches/` and `examples/`.
- **Out of scope:** `target/`, code that `build.rs` writes to `OUT_DIR` and pulls in with `include!`, generated bindings (bindgen, cbindgen output, prost and tonic code, files marked `@generated` or `DO NOT EDIT`). Read them for facts only.
- **Checks after each file** (agents): `rustfmt --check <file>` (or `cargo fmt --check`) reports nothing. With `wrap_comments` or `normalize_comments` in `rustfmt.toml`, write comments in the form rustfmt leaves alone.
- **Once per wave** (the main session, in its work copy, so `target/` is never written in the project):
  - `cargo clippy --all-targets` with the project's lints. Check `missing_docs`, `clippy::missing_docs_in_private_items`, `clippy::undocumented_unsafe_blocks`, `clippy::doc_markdown` (identifiers in backticks) and `clippy::missing_errors_doc` / `missing_panics_doc` / `missing_safety_doc` one by one when the crate enables them.
  - `cargo check --all-targets` and `cargo doc --no-deps` with no new warnings (broken intra-doc links, unclosed HTML tags such as `Vec<T>` outside backticks).
- **Final verification only** (the main session, in its work copy): `cargo test`, doctests included; the doctest count must not move.

### Doc comment style

- **Outer docs:** `///` above the item, after nothing but other `///` lines and attributes. Never move an attribute.
- **Inner docs:** `//!` at the top of `lib.rs` or `main.rs` for the crate, and at the top of each module file for the module.
- **Summary line:** one third-person sentence ending in a period (`Returns the merge base of two commits.`), then a blank `///` line and detail.
- **Sections** (`# Heading` inside the doc): `# Errors` for every `Result`-returning public function (which variants and when), `# Panics` for every reachable panic, `# Safety` on every `unsafe fn` and `unsafe trait` (the caller's obligations). Use `# Examples` only where the item already has one.
- **Intra-doc links:** `` [`Repository`] ``, `` [`Self::open`] ``, `` [`crate::error::Error`] ``. Link only paths in scope. A public item's docs never link a private item (`rustdoc::private_intra_doc_links` warns even with `--document-private-items`, and CI often adds `-D warnings`): write the private path in backticks without brackets.
- **Never add a fenced or 4-space-indented block.** Every ```` ``` ```` block (and every 4-space indented block) in a doc comment is a doctest that compiles and runs, and the checker freezes every line of one, ```` ```text ```` included, so a new block fails as `added`. Describe usage, diagrams and output in prose.
- **`// SAFETY:` comments:** every `unsafe { }` block gets one directly above, saying why each invariant holds. Keep an existing `SAFETY:` line exactly as it is (the checker compares it byte for byte); add new facts on new `//` lines after it.
- **Inline comments:** `//` full sentences ending in a period.

### Coverage

- **Required** (private items too): every `fn` (free, inherent method, trait method declaration, nested fn), `struct`, `enum`, `union`, `trait`, `type` alias, `const`, `static`, inline `mod { }`, `macro_rules!`, every named struct field and every enum variant.
- **File header:** every `.rs` file starts with a `//!` comment (or `#![doc = ...]`), including `main.rs`, `mod.rs`, `build.rs` and integration test files.
- **Exempt:** `#[test]`, `#[bench]`, `#[tokio::test]` and other `…::test` functions; the whole `#[cfg(test)] mod`; `mod name;` declarations (document the module in its file); methods inside `impl Trait for Type` (they inherit the trait's docs). An item with `#[doc = "..."]` counts as documented.
- **By reading:** tuple struct fields with a meaning not plain from the type, closures passed to `tokio::spawn`, `thread::spawn` and iterator chains with multi-line bodies, and items declared inside macro invocations, which the scan cannot see.

### Comments that are code

- **Frozen whole comment:**
  - Every line of a fenced block inside a doc comment, fences included: doctests, hidden `# ` lines, `text`, `ignore`, `no_run`, `compile_fail` and `should_panic` blocks.
  - compiletest annotations: comments starting `~` (`//~ ERROR`, `//~^ WARN`).
  - rustfmt test config comments starting `rustfmt-`.
  - Shared: license and copyright text, `@generated`, `cspell:`, `noinspection`, `NOSONAR`, `language=`.
- Also frozen: 4-space indented code blocks in doc comments (doctests), fences anywhere inside a `/** */` block, and `cbindgen:` annotations.
- **Kept line:** `SAFETY:` lines stay; text may be added around them.
- **Trigger words:** never start a new comment with `~`, `rustfmt-`, or license words. Never write ```` ``` ```` in a new comment.
- **Attributes are code:** `#[derive]`, `#[cfg]`, `#[allow]` / `#[expect]` / `#[deny]` lint attributes, `#[must_use = "..."]`, `#[deprecated(note = "...")]` (the authors' claim), `#[rustfmt::skip]`, `#[doc(hidden)]`, `#[error("...")]`, `#[serde(...)]`, `#[arg(...)]`.
- **Locked regions:** the grammar fails on `str!(...)` and `str![...]` (snapbox expected-output macros). The region around them is compared byte for byte, as **Locked regions** in the universal rules describes. Never add or edit a comment inside it; the item's own doc comment above its signature may still be written.

### Async, errors and ownership

- **Tasks:** each `tokio::spawn`, `spawn_blocking` or `JoinSet` gets a `//` comment: what the task owns (moved values), what stops it, who awaits or aborts the `JoinHandle`, and what happens to a panic.
- **Send and Sync:** say when a type is shared across tasks or threads (`Arc<Mutex<_>>`, `Arc<RwLock<_>>`) and what the lock guards; say why an `unsafe impl Send` holds in a `// SAFETY:` comment.
- **Cancellation:** an `async fn` says what is left done or undone if its future is dropped at an `.await` (partial writes, temp files, open transactions)
- **Error enums** (`thiserror`): the enum says when it is returned; each variant says when it happens. `#[error("...")]` strings and `#[from]` are code.
- **`anyhow`:** the `# Errors` section names the failure cases in words; `.context("...")` strings are code.
- **Lifetimes and borrows:** explain in prose what a lifetime ties together (`The iterator borrows the repository, so it must not outlive it.`). Never change a lifetime name.

### Tauri and CLI crates

- **Tauri commands are the route map.** The `tauri::generate_handler![...]` list in `main.rs` is the list of IPC endpoints. Each `#[tauri::command]` (or project wrapper such as `#[but_api]`) gets: the command name the frontend invokes, each argument and its JSON shape, the return value, the error type sent to the frontend, and the state it reads (`State<'_, T>`, `AppHandle`, windows). Events emitted with `emit` follow the event map.
- **clap derive:** doc comments on `#[derive(Parser)]`, `#[derive(Subcommand)]` and `#[derive(Args)]` types, their fields and variants become `--help` text. Write for the CLI user: no internal notes, no file paths. The first line is the short help; later paragraphs are `--help` long text. Never edit `#[command(about = ...)]` or `#[arg(help = ...)]`.
- **Other doc readers:** `schemars` (JSON Schema `description`), `ts-rs` and `specta` (generated TypeScript), `napi-rs` (`.d.ts`), `utoipa` (OpenAPI). Write for the reader of the output.
- **serde attributes are code:** `rename`, `rename_all`, `tag`, `default`, `skip_serializing_if`, `flatten`. Describe the wire format in the type's doc (field names as serialized) without editing them.

### Bug report additions

- `unsafe` blocks whose invariant could not be stated, and `unwrap()` / `expect()` reachable from user input or IPC.
- Blocking calls on the async runtime, tasks with no owner or stop path, locks held across `.await`.
- Public items whose `# Errors` or `# Panics` could not be stated because behavior is unclear.
