## Go rules

### Files and tools

- **In scope:** `.go` files, `_test.go` included.
- **Out of scope:** `vendor/`, files whose first lines carry `// Code generated ... DO NOT EDIT.` (protoc `*.pb.go`, counterfeiter and mockgen fakes, sqlc, stringer output), and templates (`.tmpl`, `.gohtml`, embedded assets). Read them for facts only.
- **Checks after each file** (agents): `gofmt -l <file>` prints nothing. gofmt reformats doc comments (list indentation, code block indentation, blank `//` lines), so write them in the form gofmt leaves alone.
- **Once per wave** (the main session, in its work copy): `go build ./...` passes; `go vet ./...`, plus `staticcheck ./...` and `golangci-lint run` when the project uses them, with no new findings (a new `ST1020`–`ST1022` or `revive` `exported` finding means a comment is wrong, and goes back to its file).
- **Final verification only** (the main session): `go test ./...` passes with the same counts.

### Doc comment style

- Follow go.dev/doc/comment. A doc comment is the `//` block directly above the declaration, with no blank line between.
- **First sentence starts with the name** and ends in a period: `// NewServer returns a Server that ...`, `// ErrNotFound is returned when ...`. For a method, use the method name, not the receiver.
- **Package doc:** one comment starting `// Package server ...` directly above `package server`, in exactly one file per directory (`doc.go` when it exists, otherwise the file named after the package or its main file). A license block separated by a blank line does not count. In `package main`, start with `// Command name ...` or the binary's name.
- **File header in every other file:** a `//` block above `package`, after any license block, with a blank line between it and `package` so godoc does not read it as a second package doc. Never put it between `package` and `import`.
- **Build constraints:** `//go:build` (and old `// +build`) lines stay where they are, before everything else except a license block, followed by a blank line. Put the file header or package doc after that blank line, as usual.
- **Struct fields and gofmt:** a comment line between aligned struct fields restarts gofmt's column alignment, so `gofmt -l` then fails, and realigning would change code whitespace. Document such fields as a list in the type's doc comment (or reword an existing trailing comment on the field's own line) instead of adding comment lines between them.
- **Doc comments with directives:** `//go:embed`, `//go:generate`, `//go:noinline`, `//nolint` and the like stay directly above the declaration, as the last comment before its code. Put the doc text above them, then a lone `//` line (gofmt requires it before a directive), then the directive. Never put doc text between a directive and its code.
- **Deprecated:** a paragraph starting `Deprecated:` is the authors' claim. Never add, edit or remove one.
- **Doc links:** `[Name]`, `[pkg.Name]`, `[*bytes.Buffer]`, `[Server.Start]`. Link only identifiers that resolve: a package-qualified link resolves only for packages the file imports; otherwise write the name as plain text.
- **Go 1.19+ syntax:** a list item is `//   - item` or `//  1. item` (indented); a code block is a line indented one tab or more spaces after `//`; a heading is `// # Heading` on its own paragraph. Blank `//` lines separate paragraphs.
- **Inline comments:** `//` full sentences ending in a period.
- **godot with `capital: true`** (in `.golangci.yml` / `.golangci.yaml`): every sentence must start with a capital letter; only the first word of a doc comment is exempt, since it is the declaration's name. So a later sentence or paragraph never starts with a lowercase identifier. Write `The ctx argument is ...`, not `ctx is ...`. Adding a summary above an existing comment turns its lowercase first line into a later paragraph, which godot then flags: reword that line too (`It locks the queue itself.`).

### Coverage

- **Required:** every top-level `func` and method, exported or not, and every top-level `type`, `const` and `var` declaration (a grouped `const ( ... )` needs a comment on the group).
- **Exempt:** `main`, `init`, and in `_test.go` files `Test*`, `Benchmark*`, `Fuzz*`, `Example*`. Test helpers are not exempt.
- **Package doc:** at least one non-test file per directory has a comment directly before `package`.
- **By reading:** a directive is not documentation; a declaration with only `//go:embed` above it still needs a doc comment above the directive. Document each exported spec inside a group, each exported struct field and each interface method that is not plain from its name. Closures passed to `r.Get`, `go func()` and `errgroup.Go` get a `//` comment when the body is not trivial.

### Comments that are code

- **Frozen whole comment** (the checker matches the comment's text after `//`, so `// go:` counts too):
  - Compiler and build directives: `//go:build`, `//go:embed`, `//go:generate`, `//go:linkname`, `//go:noinline` and every other `go:` word; `// +build`.
  - Linter suppressions: `//nolint`, `//nolint:errcheck`; staticcheck `//lint:ignore` and `//lint:file-ignore`.
  - cgo: `//export Name`, `//extern`, `// #cgo` lines, and the whole cgo preamble directly above `import "C"` (it is C source).
  - `//line file.go:12` position directives.
  - Example output: `// Output:` and `// Unordered output:` blocks, and every comment inside an `Example*` function body (`go test` compares them with stdout).
  - swaggo / swag annotations: every line that starts with `@word` (`// @Summary`, `// @Description`, `// @Param`, `// @Success`, `// @Failure`, `// @Router`, `// @Security`, `// @tags`, and the `// @title` / `// @host` / `// @securityDefinitions…` lines on `main`). `swag init` turns them into the published OpenAPI spec. Write the godoc prose above them; never add, edit or reorder an annotation line.
  - Shared: license and copyright text, `@generated`, `cspell:`, `noinspection`, `NOSONAR`, `language=`.
- **Frozen line:** a line starting `Deprecated:`. Treat the rest of that paragraph as frozen too; the checker only pins the first line.
- **Next-line directives:** `//go:...`, `//nolint`, `//lint:ignore` stay the last comment before their code.
- **Frozen whole, linters:** gosec `// #nosec` and `//nosec`, `//revive:disable` / `//revive:enable`, `//exhaustive:ignore`, staticcheck `//lint:ignore` / `//lint:file-ignore`.
- **Trigger words:** never start a new comment line with `go:`, `+build`, `nolint`, `lint:`, `export` followed by one word, `extern`, `line` followed by `file:N`, `#cgo`, `Output:`, `output:`, `Unordered output:`, `Deprecated:`, `@` followed by a word, or license words. Reword (`The returned output is ...`).
- **Struct tags are code:** `json:"id"`, `db:"created_at"`, `env:"PORT" envDefault:"9000"`, `validate:"required"`. Describe the field's meaning; never restate or edit the tag.

### Web services

- **Route map:** the file that builds the router (`chi.NewRouter()`, `gin.New()`, `echo.New()`, `http.NewServeMux()`) gets the full list in its doc comment: method, path, mounted prefix (`r.Route("/api", ...)`, `r.Mount`, `e.Group`), handler name. Handlers defined elsewhere reference it.
- **Middleware order is behavior:** before each `r.Use(...)` group, a `//` comment says why it sits there (logger and `middleware.Recoverer` first, `httprate` before auth, CORS before routes). A setup function meant to run in a fixed order says so in its doc comment.
- **Handlers** (`func(w http.ResponseWriter, r *http.Request)`, `gin.HandlerFunc`, `echo.HandlerFunc`): method and path, auth (Basic Auth, session cookie, token middleware), inputs (`chi.URLParam`, query, JSON body, form) and their validation (ozzo-validation rules, `validator` tags), each status and body written, and what is logged.
- **Context values:** the middleware that calls `context.WithValue` documents the key type and value once; readers reference it.
- **Queries** (`database/sql`, sqlx, pgx, lib/pq, GORM): table, columns read and written, transaction and locking, what is returned on `sql.ErrNoRows`, and placeholder dialect when the code supports several drivers. SQL strings are code.
- **Env config:** the config struct loaded by caarlos0/env (`env.Parse`) is the env map. Each field's doc comment gives meaning, unit, default (as the tag states it), and whether it is required or a secret. Tags stay as they are.

### Concurrency

- **Goroutine ownership:** every `go` statement gets a `//` comment saying what stops it (context cancel, channel close, `WaitGroup`) and who waits for it.
- **Channels:** document direction and buffering on the declaration or parameter, who sends, who closes, and what a receiver does on close.
- **Mutexes:** the doc comment of a struct with a `sync.Mutex` or `RWMutex` names the fields it guards; a method says whether the caller must hold the lock.
- **Context:** a function taking `ctx` says what it does on cancellation (returns `ctx.Err()`, rolls back, leaves work running).
- **`sync.Once`, atomics, `errgroup`:** what runs once, what is read without locks, how the first error cancels the rest.

### Bug report additions

- Handlers that ignore an error from `Write`, `Encode` or `Close` where it matters, and `defer rows.Close()` before the error check.
- Goroutines with no stop path, sends on channels nobody reads, a mutex copied by value.
- SQL built with `fmt.Sprintf` from input.
- A `go vet`, `staticcheck` or `golangci-lint` finding that existed before the pass (not caused by it).
