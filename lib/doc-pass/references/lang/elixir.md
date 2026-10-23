## Elixir rules

### Files and tools

- In scope: `.ex` and `.exs` (including `mix.exs`, `config/*.exs`, `test/**/*_test.exs`, `priv/repo/migrations/*.exs`).
- Out of scope: `deps/`, `_build/`, `.elixir_ls/`, `cover/`, `priv/static/`, `assets/node_modules/`; `.heex` / `.eex` / `.leex` templates (markup).
- Syntax check and baseline (the main session, once per wave, in its work copy; agents rely on the checker parse): `mix compile --warnings-as-errors` (warnings must not grow), `mix format --check-formatted` when the project formats (it re-indents heredocs, so doc heredocs must match the code's indentation), `mix credo` when configured (`Credo.Check.Readability.ModuleDoc` should go down). Tests: `mix test`, which also runs the doctests.

### Doc comment style

- Documentation is module attributes, not comments: `@moduledoc` for modules, `@doc` for public functions and macros, `@typedoc` for public types. The checker treats an attribute whose value is a string, a `"""` heredoc or a `~S"""` / `~s"""` sigil as documentation: adding, rewording or removing it passes. `@doc false` and `@moduledoc false` are code (they hide a definition from the docs): never add, remove or change one.
- Use a heredoc (`@doc """`), indented like the `def` below it, with the closing `"""` on its own line. Use `~S"""` when the text contains `#{` or backslashes that must not be interpolated.
- Markdown body: summary sentence ending in a period, a blank line, then details. Elixir style has no `@param` tags: describe arguments in prose or a `## Options` list for keyword options (`` * `:timeout` - … ``), and a `## Examples` section.
- A new `@doc` between two one-line definitions (`defdelegate`, `def … do:`) that were on consecutive lines needs a blank line above it: `mix format` puts one before every attribute that follows a definition, and `--check-formatted` fails without it.
- **Doctests:** lines starting with `iex>` and `...>`, and the expected output after them up to a blank line, run under `doctest MyModule`. They are frozen: never edit, add or remove one. Add new examples as prose, not `iex>` lines.
- Private functions (`defp`, `defmacrop`, `defguardp`): `@doc` on them is discarded with a warning, so describe them with `#` comments directly above the first clause.
- File header: the `@moduledoc` of the file's module (one module per file is the convention). A script without a module (`config/*.exs`, `test_helper.exs`, `.formatter.exs`) gets `#` lines at the top.

### Coverage

- Every `defmodule` and `defprotocol` (`@moduledoc` as the first thing in the body), every public `def`, `defmacro`, `defguard`, `defdelegate` (`@doc`), every `@type` / `@opaque` (`@typedoc`), every `@callback` / `@macrocallback` (`@doc` before it), and every `defp` / `defmacrop` / `defguardp` (`#` comment).
- Only the first clause of a multi-clause function needs documentation; `@doc` and `@spec` go above it.
- Exempt: definitions marked `@impl true` / `@impl SomeBehaviour` (the behaviour documents them), `defimpl` bodies, and `test` / `describe` blocks.
- The order above a definition is: `@doc`, then `@spec`, then the `def`.

### Comments that are code

- Frozen whole comment: `# credo:disable-for-this-file`, `# credo:disable-for-next-line`, `# credo:disable-for-lines:N`, `# coveralls-ignore-start` / `-stop` / `-next-line`, `# sobelow_skip […]`, plus the shared license, `@generated`, `cspell:` forms.
- Last before their code: `# credo:disable-for-next-line`, `# coveralls-ignore-next-line`, `# sobelow_skip`.
- Other attributes (`@spec`, `@impl`, `@behaviour`, `@derive`, `@deprecated`, `@dialyzer`, `@compile`, `@external_resource`) are code.

### Phoenix, Ecto and OTP

- **Router:** `scope`, `pipe_through` and each `get` / `post` / `live` / `resources` line form the route map: full path with scope prefixes, pipeline (auth, CSRF), controller action or LiveView. Controller actions then document params, assigns and responses.
- **LiveView:** `mount/3`, `handle_params/3`, `handle_event/3` and `handle_info/2` are `@impl` callbacks (exempt) but each clause gets a `#` comment naming the event or message it handles and the assigns it changes. Components (`attr` / `slot` declarations) say what they render.
- **Ecto:** schemas name the table and each field's meaning; changesets say which fields they cast and validate; context functions say which `Repo` calls they make and in which transaction (`Ecto.Multi`).
- **OTP:** GenServers say what state they hold, the messages they accept (`call` / `cast` / `info` shapes) and their restart strategy; supervisors list children and strategy. Oban / Broadway workers: queue, arguments, retries and uniqueness.
- **PubSub and Telemetry:** topics and `:telemetry` event names follow the event map: full description once at the broadcaster, one line at each subscriber.
- **Environment:** `System.get_env`, `System.fetch_env!` and `config/runtime.exs` reads form the env map.

### Bug report additions

- `String.to_atom` on user input (atom table exhaustion); `Code.eval_string` on input.
- GenServer calls that can time out inside other GenServers (deadlocks); unbounded mailboxes.
- Ecto queries built with string interpolation in `fragment`; missing `Repo.transaction` around multi-step writes.
- `raw/1` or `Phoenix.HTML.raw` on user content.
