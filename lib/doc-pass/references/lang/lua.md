## Lua rules

### Files and tools

- In scope: `.lua` and `.rockspec`. The checker reads them with its own lexer (`lexers.mjs`): the bundled tree-sitter Lua grammar gave different trees for the same text from one parse to the next. The lexer handles `--` and `--[==[ … ]==]` comments, quoted strings (with `\z`), `[==[ … ]==]` long strings, numbers and names, and groups statements that start at column 0.
- Out of scope: `lua_modules/`, `.luarocks/`, `servroot/`, vendored libraries (`vendor/`, `deps/`), generated code (`*_pb.lua` from protobuf), and OpenResty `.t` files (Test::Nginx, Perl: see `perl.md`).
- Syntax check: `luac -p <file>` (or `luajit -bl <file> /dev/null`) before and after. Baseline: `luacheck <files>` (no new warnings) and `stylua --check` / `selene` when configured. Tests: `busted` (kong: `bin/busted`), Test::Nginx `prove`.

### Doc comment style

- LDoc: a comment block starting with `---` directly above the function, then `--` lines. First line: summary sentence ending in a period. Tags: `@tparam type name description` (type and name are kept) / `@param name description`, `@treturn type description` / `@return description`, `@raise` for errors raised with `error()`, `@usage` for examples, `@module` / `@classmod` in the file header. An existing block written only in `---` lines stays in that form when extended.
- LuaLS / EmmyLua annotations (`---@param name type`, `---@return type`, `---@class`, `---@field`, `---@type`, `---@alias`): used for type checking by the language server. Keep each line exactly; add a description as a separate `---` line above. Use whichever style the file already uses; do not mix them in one block.
- Lua's error convention: say whether the function raises (`error(...)`) or returns `nil, err`; for `nil, err` functions, describe both return shapes with LDoc numbered returns (`@treturn[1] table the credential`, `@treturn[2] nil`, `@treturn[2] string the error message`; in a LuaLS file, one `---@return` line per value instead).
- Say which OpenResty phase a function may run in (`init`, `init_worker`, `access`, `header_filter`, `body_filter`, `log`, timers) when it uses `ngx.*` APIs that are phase-restricted (cosockets are not available in `init` / `header_filter` / `body_filter` / `log`).
- File header: a `---` block at the top with a summary and `@module name` (LDoc), after any shebang.

### Coverage

- Every top-level function: `function M.f()`, `function M:f()`, `local function f()`, `M.f = function …`, `local f = function …`.
- The module or handler table (`local _M = {}`, `local Handler = {…}`) and files that only `return { … }` (`schema.lua`, `daos.lua`, migrations) are covered by the file header: say there what the table holds and who loads it. Coverage checks only that the file header exists, not what it says about the table; check that by reading.
- Checked by reading: functions nested inside other functions, functions in table constructors (`{ access = function(conf) … end }`), closures passed to `ngx.timer.at`, `pcall`, `table.sort`.
- Test files (`*_spec.lua`): `describe` / `it` / `before_each` callbacks need none.

### Comments that are code

- Frozen whole comment: `-- luacheck: …` (ignore, globals, push, pop, no unused), `-- stylua: ignore`, `-- selene: allow(…)`, `---@diagnostic disable…` / `enable`, plus the shared license, `@generated`, `cspell:` forms.
- Last before their code: `-- luacheck: ignore` (when on its own line), `-- stylua: ignore` (not `ignore start` / `end`), `---@diagnostic disable-next-line`.
- Frozen tag lines: `@deprecated`, `@private`, `@local` (LDoc hides the item). Kept: `@see`, `@since`, `@author`, `@module`, `@classmod`, `@usage`, `@phases`, LuaLS definitions whole, the first word of `@param` / `@return` / `@treturn` lines, and `@tparam type name`.

### Kong, OpenResty and LÖVE

- **Kong plugins:** `handler.lua` says the plugin's `PRIORITY` and `VERSION` meaning and, for each phase method (`access`, `header_filter`, `log` …), what it does to the request or response; `schema.lua` describes each config field once in a `--` comment above it, adding what the field's `description` leaves out (units, how the handler uses it, interactions with other fields); when `description` already says it all, one short line is enough. A field's `description` string is code (it is published in the Admin API docs): never edit it, and put a wrong one in the bug report.
- **Admin API and routes:** `kong/api/routes/*.lua` tables form the route map: method, path, auth (RBAC / workspaces), inputs, statuses. A plugin without an `api.lua` gets endpoints generated from `daos.lua` (`admin_api_name`, `admin_api_nested_name`, e.g. `/consumers/{consumer}/hmac-auth`): list those in the route map and in the DAO's file header.
- **DAO and migrations:** entity schemas name the table and fields; migrations say what `up` / `teardown` change for Postgres. A migration that only calls a Kong core helper (`operations.ws_migrate_plugin`) names the helper and its purpose; do not restate core's SQL.
- **Shared state:** `ngx.shared.DICT` names, `kong.cache` keys and their invalidation events follow the event map.
- **Environment:** `os.getenv`, `KONG_*` settings (`kong.conf` keys) form the env map.

### Bug report additions

- Globals created by assignment without `local`; `#t` on tables with holes.
- Cosocket use in phases that forbid it; blocking I/O (`io.open`, `os.execute`) in request phases.
- `pcall` that swallows errors; string building in loops with `..` instead of `table.concat`.
- Unescaped values in `ngx.re` patterns or SQL built with `string.format`.
