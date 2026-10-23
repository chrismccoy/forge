## Erlang rules

### Files and tools

- In scope: `.erl`, `.hrl` and `.escript`. The checker reads them with its own lexer (`lexers.mjs`): no tree-sitter grammar ships as wasm. It splits the source into tokens (comments, strings, quoted atoms, `$c` character literals, numbers) and groups them into forms that end with `.`; comments between forms belong to the next form.
- Out of scope: `_build/`, `deps/`, `ebin/`, `.rebar3/`, `rebar.config` and `*.app.src` (Erlang terms, not code to document), `rebar.lock`, generated parsers (`*_lexer.erl` / `*_parser.erl` built from `.xrl` / `.yrl`, which the walker skips when they carry a generated marker).
- Syntax check and baseline (the main session, once per wave, in its work copy; agents rely on the checker parse): `rebar3 compile` (or `erlc` on the file) with warnings that must not grow; `rebar3 xref` and `rebar3 dialyzer` when the project runs them; `erlfmt --check` when it formats. Tests: `rebar3 eunit`, `rebar3 ct` (or the project's `make` targets, as emqx uses).

### Doc comment style

- EDoc comments: `%%` lines directly above the function (above its `-spec` when there is one), with `@doc` on the first line: `%% @doc Starts the listener on Port.` Module docs: `%%% @doc` (or `%% @doc`) lines just above `-module(…)`.
- OTP 27+ projects may use `-doc "…"` and `-moduledoc "…"` attributes instead. These are code: never add, edit or remove one. An existing one counts as documentation for coverage; a wrong one goes in the bug report. Where a function has neither, add an EDoc `%% @doc` comment.
- Content: summary sentence ending in a period, then details. Describe arguments by name and the return value only where the `-spec` doesn't say it, the error tuples or exits (`{error, timeout}`, `exit({noproc, …})`), the processes it sends to or links with, and ETS / Mnesia tables it reads and writes.
- Comment levels follow the Emacs convention: `%%%` for file and section headers, `%%` for comments on their own line, `%` at the end of a line.
- File header: a prose comment block above `-module(…)` (often under the license block), or a `-moduledoc` attribute. A `.hrl` gets one at the top; an `.escript` gets one after its `#!` line, its `%% -*- erlang -*-` mode line and its `%%!` emulator-flags line (the checker keeps `#!` on line 1 and `%%!` on its line).

### Coverage

- Every function (the first form of each name; a form right after one with the same name, a different arity delegating to it, is exempt), and every `-type`, `-opaque`, `-callback` and `-record`.
- Exempt in `*_SUITE.erl` / `*_tests.erl`: Common Test callbacks (`all/0`, `groups/0`, `suite/0`, `init_per_*`, `end_per_*`) and test functions (`t_*`, `prop_*`, `*_test`, `*_test_`).
- Checked by reading: `-define` macros, `fun` bodies passed to `gen_server` / `ets:foldl` / `lists:foreach`, `receive` clauses.

### Comments that are code

- Frozen whole comment: Emacs mode lines (`%% -*- … -*-`), `%% erlfmt-ignore`, `%% @format` / `%% @noformat`, plus the shared license, copyright, `@generated` and `cspell:` forms. emqx-style license banners between `%%---` rules are frozen whole.
- Last before its form: `%% erlfmt-ignore`.
- Frozen tag lines: `@private`, `@hidden`, `@deprecated`, `@equiv` (they change what EDoc publishes). Kept: `@see`, `@since`, `@author`, `@copyright`, `@version`, `@reference`.
- Attributes are code: `-spec`, `-export`, `-compile`, `-dialyzer`, `-ifdef` / `-endif`, `-include`, `-behaviour`, `-elvis`.

### OTP, Cowboy and emqx

- **Behaviours:** `gen_server`, `gen_statem` and `supervisor` callbacks implement the behaviour; document the module (its state, the messages it accepts, its registered name and restart strategy) and give each `handle_call` / `handle_cast` / `handle_info` clause a `%%` line naming the message.
- **Supervisors:** `init/1` says the strategy, intensity and each child spec.
- **Cowboy / Minirest handlers:** the dispatch table or `api_spec` forms the route map: method, path, auth, request and response bodies. emqx's `schema/1` / `fields/1` descriptions (`desc`) are strings, so they are code: never edit them. They are published in the management API docs; put a wrong one in the bug report, and document the function with a `%%` comment.
- **Hooks and messages:** emqx hook points (`emqx_hooks:add`) and `gproc` / `pg` groups follow the event map.
- **Environment:** `os:getenv`, `application:get_env` and HOCON config keys form the env map.

### Bug report additions

- `list_to_atom` / `binary_to_atom` on external input; unbounded `ets` growth.
- `gen_server:call` with the default 5 s timeout inside another `call`; missing `trap_exit` where `terminate/2` must run.
- `catch` that swallows errors without logging; `try … of` that hides crashes a supervisor should see.
