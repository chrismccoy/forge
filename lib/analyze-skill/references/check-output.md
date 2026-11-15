# Check output reference

What `run_checks.py` returns and how to read it. Use this when interpreting the JSON in Step 2,
or when a field name in the output is unclear.

## Contents

1. Commands, paging, exit codes
2. `inventory`
3. `lint`
4. `security`
5. Plugin context
6. `requirements`
7. `build_appendix.py` report validation

Fallbacks for pasted text, no Python, or no file-writing tool are in `fallbacks.md`.

## 1. Commands, paging, exit codes

Run the commands exactly as `SKILL.md` Step 2 writes them, with `${CLAUDE_PLUGIN_ROOT}` as
Claude Code substitutes it.

- `--only inventory|lint|security|requirements|siblings` returns one key (`siblings` runs only
  when asked: names and descriptions of the other skills in the target's collection, paged). `--limit N --offset N` pages that
  check's main list (`files` for inventory, plus `plugin.files`; `findings` for lint, security,
  and requirements), and adds `"page": {"offset", "limit", "total"}`. Repeat with
  `offset + limit` until it reaches `total`.
- Unpaged fields (`tree`, `suppressed`, `not_covered`, `declared`, `frontmatter`, the requirements
  output's own `siblings` name list (the `--only siblings` check is paged like any list),
  and plugin `hook_commands`, `mcp_commands`, `other_commands`, `components`, `missing`) appear on the first page
  only (inventory's `grep_exclude` too).
- A check that crashed has no `page` key: do not page it; cover it by hand.
- Every page re-runs the check. When the security scan hit its time budget (`SEC-BIG-5`), pages can
  come from different runs: if `total` changes between pages, page again from offset 0, and treat
  any file the `SEC-BIG-5` finding names as not scanned.
- `grep_exclude` (inventory): the exact Grep-tool glob that leaves out credential files for this
  target (Grep does not follow symlinks). It names each credential file by base name under `**/`,
  including files inside `node_modules/` and other folders the inventory skips, so it holds from any
  subfolder; a same-named file elsewhere is left out of searches too. `grep_exclude_misses` lists credential files whose names
  cannot sit in a glob (a comma, brace, or star in the name): when it is not empty, Grep named
  files only.
- Silent caps: requirements lists keep 40 items per axis, and the requirements output's own
  `siblings` name list keeps 100; `--only siblings` lists up to 300 entries, each description cut
  at 1,000 characters.
- `--brief` shrinks the output for large skills: no `tree`, no item `detail`, one source per
  requirements item, 20 `suppressed` locations per rule. Use it when a first page is cut off.
- `--heading-level N` sets the Markdown heading level of the title (default 2); each check is one
  level deeper. `build_appendix.py` uses level 4 for Appendix A.
- `--` ends the options, so a target path that begins with `-` cannot be read as a flag.
- If the output is cut off or does not parse as JSON, re-run with a smaller `--limit`.

| Exit code | Meaning | Action |
|---|---|---|
| 0 | Success | Use the output |
| 1 | A check crashed; its key holds `{"error": ..., "trace": ...}` | Report it; cover that check by hand with Glob/Grep |
| 2 | Target refused (no root `SKILL.md`, home, system, or credential folder, leading `-`), or bad arguments (argparse prints `usage:`; `--offset` without `--limit`) | Read stderr; fix the arguments or tell the user why the target was refused |
| 126 / 127 | `python3` missing or not executable | Use the "No Python" fallback in `fallbacks.md` |
| 139 | The interpreter crashed on a pathological file (a folder tree ~1,000 levels deep, or an extremely nested expression on Python 3.10 or older); a `RecursionError` inside one check is caught and exits 1 instead | Report it as a finding; cover that check by hand with Glob/Grep |
| Timeout | The tool's time limit was hit. Every page re-runs the whole check, so a smaller `--limit` does not help | Cover that check by hand with Glob/Grep and say so in the report |
| Output cut off or empty | The output was too long for the tool | Re-run with a smaller `--limit`, then add `--brief`, or read the file where the harness saved the full output |

## 2. `inventory`

- `skill_dir`, `tree` (an indented tree), `totals` (counts, bytes, words, `by_category`, and
  `code_referenced_words` for the context budget).
- `files`: one entry per path. Every entry has `path`, `kind`, and `category`.
  - `kind`: `file`, `symlink`, `dir-symlink`, `special` (FIFO, device, socket), `unreadable`,
    or `unreadable-dir`.
  - `category`: `skill`, `references`, `scripts`, `assets`, `examples`, `templates`, `meta`
    (README, LICENSE), `root-other`, `other-dir`, or `plugin`.
- Regular files add:

  | Field | Meaning |
  |---|---|
  | `bytes` | size on disk |
  | `lines`, `words` | text files only |
  | `encoding` | `utf-8`, `nul-text` (UTF-8 with a few NUL bytes), `utf-16`, `binary`, or `not read (total budget reached)`; credential files are read by the scripts for counts and the secret scan, but never quoted or opened by Claude |
  | `binary` | true when the content cannot be read as text |
  | `executable`, `shebang` | permission bit and first line |
  | `code` | code suffix (`.py`, `.sh`, `.js`, ...), any file under `scripts/` except docs and data (`.md`, `.txt`, `.json`, `.csv`, `.yaml`, `.yml`), or executable with a shebang |
  | `referenced` | named by `SKILL.md` (path, glob, or file name) |
  | `generated` | lockfile, minified bundle, source map, or `.pyc` |
  | `large` | over 100 KB |
  | `truncated` | over the 5 MB read limit |
  | `hardlinked` | more than one hard link: read and quoted like any file (`SEC-LINK-2`, medium, notes it: check the quote before sharing) |
  | `credential` | a credential-type name that is not a code file (a file with a code suffix such as `credentials.py` is read, quoted, and flagged `SEC-PATH-4` high; `scripts/.env` has no code suffix, so it stays a credential file and is not marked `code`) (`.env*`, `.envrc`, `*.env`, `*.pem`, `*.key`, `id_rsa`/`id_dsa`/`id_ecdsa`/`id_ed25519` (and `.pub`), `.credentials.json`, `credentials*` except docs, `secrets.json/yaml/toml/txt/ini/cfg/conf/properties`, `passwords.*`, `env.*`, `client_secret*.json`, `token.json`, `.htpasswd`, `*.p8`, `.netrc`, ...): never Read it; the Appendix omits it |
  | `quote_fence` | fence string that quotes the file verbatim without breaking |

- Links add `symlink_target` and `points_outside`. Unreadable entries add `error`.
- `skipped_dirs`: vendored or cache folders (`node_modules`, `.venv`, `.git`, ...) with
  `file_count`. Inventory and lint do not walk them; the security scan does, except `.git`.
- `plugin`: see section 5.

## 3. `lint`

- `frontmatter`: the parsed frontmatter, with secrets redacted and invisible characters escaped.
- `metrics`: `parser` (`pyyaml` or `minimal`), `frontmatter_status` (`ok`, `missing`, `unclosed`, or
  `parse-error` when FM000 fired), `name`, `directory`,
  description and `when_to_use` lengths, quoted trigger phrase count, body words and lines,
  `body_words_target`, `file_lines`, second-person line count, `references_in_skill_md`, `files`,
  and `sections` (each `SKILL.md` heading with its line and word count, first 80).
- `findings`: `id`, `severity` (error, warn, info), `message`, `file`, `line`.

| ID family | Covers |
|---|---|
| `STRUCT001-007` | `SKILL.md` missing, not UTF-8 (`STRUCT002` also for UTF-16), BOM, CRLF, NUL bytes, over the 2 MB read limit (only its start was linted); `STRUCT007` the lint read budget (100 MB) was reached, so reference checks are incomplete |
| `FM000` | frontmatter parse error (Claude Code would drop all metadata) |
| `FM001-031` | frontmatter: presence, name rules, description quality and length, unknown fields, field combinations, `allowed-tools` breadth (`FM024`, including `mcp__server__*` wildcards), hooks (`FM030`), parser notes (`FM031`), a key given twice (`FM033`, warn). After `FM000`, findings that only follow from the empty frontmatter drop to info and say so |
| `BODY001-010` | `001` body over the error size, `002` over the warn size, `003` too many lines, `004` empty body, `005` unclosed fence, `006` placeholder marker, `007` backslash path, `008` load-time (`!`) command, `009` sampling setting, `010` a bundled file run by relative path or by bare name (`helper.mjs x`) |
| `STYLE001` | second-person prose lines |
| `ARG001-002` | argument hint and `$ARGUMENTS` mismatches |
| `DUP001` | repeated sentences |
| `BODY011` | `$0`-`$9` inside a command in `SKILL.md`: Claude Code substitutes it with a skill argument |
| `REF008` | a file named in a "- `scripts/`: ..." list that does not ship |
| `REF001-004` | missing reference (error; warn for a glob that matches no file; info for a mentioned folder the skill does not ship; placeholders like `references/FILE.md` skipped), only-reachable-via-reference, orphan file (info for tests and dotfiles), link outside the skill |
| `REF005-007` | `${CLAUDE_PLUGIN_ROOT}` problems, plugin-level dependencies, plugin hooks |
| `FM032` | an `allowed-tools` `Bash(cmd ...)` whose command no file in the skill uses (info; harmless commands such as `mkdir`, `ls`, `wc` are skipped) |
| `BODY012` | an angle-bracket placeholder (`<workspace>`) used 3+ times in `SKILL.md` and never defined (info) |
| `REF009` | a reference file uses `${CLAUDE_SKILL_DIR}`, which is substituted only in `SKILL.md` (not raised when `SKILL.md` uses it too, so Claude sees the real path) |
| `SCR001-008` | code files: binary content, shebang, executable bit, third-party imports, usage text, Python version, parse errors, unreadable |

## 4. `security`

- `findings`: `rule`, `severity` (high, medium, low), `category`, `file`, `line`,
  `description`, and `excerpt` (redacted, invisible characters escaped). Plugin-level files
  show as `<plugin>/path`.
- `counts`: totals per severity across every hit, listed or not.
- Context adjusts severity (at most one level per hit), and the description says why. Every match
  on a line is judged and the most severe reading wins, so a harmless decoy earlier on the line
  cannot lower a real hit.
  - **Reference docs** (Markdown under `references/`, or plugin skill Markdown): destructive,
    file-delete, file-write, exec, deserialization, network, privilege, persistence, sensitive-path,
    and supply-chain hits drop one level
    (`[reference doc]`), except in reference files that `SKILL.md` tells Claude to run or follow:
    named on a line with a run-type verb (run, execute, call, invoke, type, paste, use, start,
    launch, install, read, see, load, open, consult, check, follow, apply, before, first,
    "according to", "as described in"). The list is broad on purpose: a reference Claude reads
    before acting is treated as instructions.
  - **Commands named in backticks, or in a Markdown table row, in prose** (outside code blocks;
    not `SKILL.md`, not a followed reference) drop one level. Injection phrases never do.
  - **A bare command name in backticks** ("never use `Invoke-Expression`") drops one level in any
    category except secrets, hidden text, and prompt injection, outside `SKILL.md` and followed
    references. A pattern with arguments or pipes does not.
  - **Injection phrases** inside a tight pair of quotes (within 60 characters; apostrophes in
    words such as "don't" do not count) drop to low only in reference-doc prose that visibly
    discusses attacks (cues such as "for example", "injection", "attack"), never in code,
    `SKILL.md`, or a reference `SKILL.md` tells Claude to follow.
  - **`rm -rf "$VAR"`** (a quoted variable, the temp-dir cleanup idiom) is medium, except for
    `HOME`, `PWD`, `USER`, `TMPDIR`, and similar, and except in `SKILL.md`.
  - **Generic credential shapes in reference docs** (`password = "..."`, `Authorization: Bearer`,
    `user:pass@host` URLs, `--token=` flags) are medium: usually example values. Provider-format
    keys (`sk-ant-`, `ghp_`, AWS, Google, Stripe, Slack, JWT, private keys, webhooks, AWS credentials-file entries
    (`-9`), command-line credentials (`-19`), passphrases (`-20`), markup elements (`-21`), and GitLab / Vault /
    SendGrid tokens (`-22`)) stay high.
  - **Zero-width characters inside a code string** (every one of them inside a quoted string or a
    regex literal, not in a comment) are medium; zero-width joiners inside emoji are low.
    Variation selectors: 3 or more on a line are high; a supplementary selector (U+E0100-E01EF,
    never needed for emoji) is medium; a lone U+FE00-FE0F not after an emoji is low.
  - **Never downgraded by context** (apart from the bare-name and list-item rules): remote execution and
    exfiltration; and secrets and hidden text except the specific cases above (generic credential
    shapes in reference docs, zero-width characters in code strings, emoji joiners). Bidi
    controls (Trojan Source) and tag characters stay high anywhere. In `SKILL.md`, no downgrade
    ever applies.
  - **List items** outside `SKILL.md` that name a pattern in backticks ("- `iwr | iex` without a
    checksum") drop one level, unless the line also says run, execute, paste, type, then, first, or
    next (words that make it a step). In a
    followed reference this applies only to a list of bad patterns (cue words such as without,
    on input, from input, unvalidated, untrusted, unsafe, avoid, report, vulnerable); a list item
    that is a step keeps its level. Never for secrets or hidden text.
  - **Followed references** are named on a `SKILL.md` line with a run-type verb, by path, file
    name, or pattern (`references/lang/<language>.md`, `references/*.md`); a verb line ending in
    `:` also covers the table or list right below it.
  - **Credential files:** findings keep rule and line, but the excerpt is withheld; report such a
    hit as `unconfirmed (file not opened)`. Base64 blobs (`SEC-OBF-1`) are shown cut to 12
    characters, after any secret on the line is redacted.
  - **Decoys:** every match of a rule on a line is judged, the most severe wins, and the excerpt
    starts at that match; only real download-then-run separators count toward the 400 cap, so
    padding anywhere around a hit cannot lower it or hide it.
  - **Excerpts** start just before the match, so the matched text shows even on long lines; the
    cut never splits a secret, so it is still redacted. Secret hits give one finding per rule and
    line, with a hit count. Joined (backslash-continued) lines and multi-line comment bodies are
    redacted line by line before they are joined, so line-anchored secret rules still apply.
  - **Very long lines** are scanned in overlapping windows, so a secret past column 20,000 is
    still found and redacted; pattern rules beyond that column report `SEC-BIG-3`.
- `suppressed`: `{rule: {"count": n, "locations": ["file:line (severity)", ...]}}`. `count` is
  the true total of hits not listed. Findings are sorted by severity first, then at most 10 are
  listed per rule and file, and at most 50 per rule across all files (so paging always ends); the rest are counted here with their first 20 locations (200 for
  exfiltration, prompt-injection, permissions, remote-exec, secret, and hidden-text rules), highs
  first. Past 200 medium or low hits per rule and file in other categories, hits are only counted
  (`"file: +N more hits not located"`); high hits are kept, up to 2,000 per rule and file (past that
  they are counted, not located). The six categories above stop
  locating hits past 2,000 per rule and file (they are still counted). When `counts` exceed the
  listed findings, open the `suppressed` locations for high and medium rules.
- `not_covered`: the scan's known blind spots. Check them by hand.

| Category | Rules |
|---|---|
| hidden-text | `SEC-HID-1` (control, zero-width, bidi, tag characters, and the blank Braille character U+2800; no-break and other Unicode spaces read as plain spaces for every pattern rule, so a phrase split by them is still matched), `-2` (HTML and link-reference comments), `-3` (variation selectors), `-4` (CSS-hidden content), `-5` (NUL bytes in text), `-6` (lone carriage return) |
| secret | `SEC-KEY-1` to `-22` (`-7` any key name containing password, passphrase, secret, token, api key, credentials, a `_salt`, or an upper-case `*_KEY` such as `ENCRYPTION_KEY`, or named `pass` or `pw`, ..., also as a subscript (`cfg['password'] = ...`) or with `=>` or `:=`; `-8` Authorization headers, also as a JSON or dict entry; `-14` credentials in URLs; `-15` `--token=` style flags; `-16` webhook URLs; `-17` short or spaced quoted passwords under a password/secret key name; `-18` short unquoted values under a key ending in PASSWORD, PASSWD, PWD, SECRET, or TOKEN, such as `PGPASSWORD=postgres`, or `password = <word>` ending a line; descriptive words, permission words (`id-token: write`), variables (`s3_credentials`), paths, and calls are skipped, and `-7` skips lowercase snake_case variables too; `-19` a credential on a command line: `curl`/`wget -u user:pass`, `mysql -p<value>`, `sshpass -p <value>`, netrc `machine h login u password p`, or the password in `auth=("user", "pw")` and `HTTPBasicAuth("user", "pw")`; `-20` an unquoted passphrase of several lowercase words under a YAML-style password key; `-21` a credential in a markup element such as `<password>...</password>`; `-22` GitLab `glpat-`, Vault `hvs.`, and SendGrid `SG.` tokens) |
| network (page) | `SEC-NET-5` (a `<script src>` that loads remote code into a page) |
| remote-exec | `SEC-RCE-1` to `-5` (`-1` and `-4` allow up to 3 filters, such as gunzip or base64, between the download and the shell or interpreter; `-5`: `eval "$(curl ...)"`, `python3 -c "$(curl ...)"`, interpreter fed by `<(curl ...)`, download then execute on the same line, or a download saved with `-o`/`-O`/`>` that a line within the next 20 runs) |
| destructive, file-delete, file-write | `SEC-DEL-*` (`-2` includes JS `rmSync(..., {recursive: true})` and removing untracked files; `-3` includes `git restore` and `git checkout -- <files>`, which discard changes), `SEC-FS-*` |
| code-exec | `SEC-EXEC-1` to `-8` (`-5`: `bash`/`sh`/`python`/`pwsh -c` and `node`/`perl`/`ruby`/`php -e` or `-r`; `ruby -c` and `perl -c` only check syntax and are not flagged; `-8`: PHP request input, dynamic include, `/e` eval), `SEC-HOOK-1` (frontmatter hooks), `SEC-HOOK-2` (plugin hooks), `SEC-MCP-1` (plugin MCP server commands, and other plugin-declared commands such as `lspServers`, labelled with their JSON path) |
| sensitive-path, file-write, secret (extra) | `SEC-PATH-3` (`~/Downloads/` read or moved, medium), `SEC-FS-3` (`chmod -R`), `SEC-FS-4` (copies a `.env` file) |
| network (plugin) | `SEC-MCP-2` (a remote MCP server: a `url` with no `command`; tool calls and data go to that host) |
| deserialization | `SEC-DESER-1` |
| network, exfiltration | `SEC-NET-1` to `-4` |
| privilege, persistence, sensitive-path, portability, supply-chain | `SEC-PRIV-1`, `SEC-PERS-*`, `SEC-PATH-*` (`-3` `~/Downloads`, medium; `-4` a code file with a credential-type name: high for key names such as `id_rsa.py` or `x.pem.js`, medium for others such as `env.py`), `SEC-PKG-1` (pip, `npm i/install/ci`, `pnpm`/`yarn install/add`, `composer`/`bundle install`, `npx` except `--no-install`, gem, brew, go, cargo; low: confirm it runs and is not only shown) |
| prompt-injection | `SEC-INJ-1` to `-4` |
| permissions | `SEC-TOOL-1` (broad `allowed-tools`: any shell, an interpreter or run-wrapper with free arguments (`python3:*`, `npx`, `command`, `env`, `xargs`, `nice`, `timeout`, `sqlite3`, `psql`), code-capable commands (`git`, `gh api`, `find`, `curl`, ...), file-mutating or file-reading commands (`cat`, `grep`, `rg`, ...), a bare `mcp__server`, and a relative `Bash(./scripts/...)`), `-2` (network - web tools or a browser MCP - plus shell; high when wildcarded). Both cite the `allowed-tools` line |
| obfuscation | `SEC-OBF-1` (long base64 runs) |
| symlink, special-file, opaque-binary | `SEC-LINK-1` (symlinks), `-2` (hard links), `SEC-SPEC-1`, `SEC-BIN-1` |
| coverage, vcs | `SEC-READ-1` (unreadable, or the listing cap of 20,000 entries was reached), `SEC-BIG-1` (truncated read), `-2` (vendored cap), `-3` (line over 20,000 chars), `-4` (100 MB total scan budget reached; the rest is listed for hand review), `-5` (high: the 60-second scan time budget was reached, checked between files, every 50 lines in the hidden-character and secret pass, and on every logical line in the pattern pass; or one file ran past its hard 20-second limit and was stopped, which names that file; each unscanned file, or the line a file stopped at, is listed, so cover them by hand), `SEC-ENC-1` (UTF-16), `SEC-GIT-1` |

## 5. Plugin context

`inventory.plugin` is `null` unless either of these is true:

- the skill sits at `<root>/skills/<name>/` and `<root>/.claude-plugin/plugin.json` exists;
- `SKILL.md` or a code file names a path as `${CLAUDE_PLUGIN_ROOT}/...` or
  `$CLAUDE_PLUGIN_ROOT/...` (a mention in a reference document alone does not count).

When present:

| Field | Meaning |
|---|---|
| `root`, `name` | plugin root path (null if it could not be found) and name from `plugin.json` |
| `files` | plugin-level files the skill depends on, described like skill files, plus `reason` |
| `missing` | `${CLAUDE_PLUGIN_ROOT}/...` paths that do not exist |
| `hook_commands`, `mcp_commands` | full command lines from `hooks/hooks.json`, `plugin.json`, `.mcp.json`; a remote MCP server appears as `REMOTE <url>` |
| `other_commands` | other plugin-declared commands (`lspServers` and similar), each with its JSON path |
| `components` | the plugin's other skills, agents, and commands (names only) |
| `uses_plugin_root`, `truncated` | whether the skill uses `${CLAUDE_PLUGIN_ROOT}`; whether the 300-file cap was hit |

`files` always includes `plugin.json`, `hooks/hooks.json`, and `.mcp.json` when they exist: plugin
hooks and MCP servers run whenever the plugin is enabled, so they belong in any vetting of one of
its skills. It also includes every file a skill file names with `${CLAUDE_PLUGIN_ROOT}/...`
(files, folders, and globs), every hooks or MCP file that `plugin.json` declares at a custom path
(parsed for commands too), and every script a hook or MCP command runs (named through
`${CLAUDE_PLUGIN_ROOT}`, quoted or not, or by a relative or absolute path inside the plugin; a script
or declared hooks file outside the plugin goes in `missing`, marked not read). Links are listed, never
followed.

A missing path in documentation-style skills (one that teaches how to write hooks, for example)
is often only an example. Confirm before calling it broken.

## 6. `requirements`

What the skill needs to run, from the skill's files and the plugin files it uses (`<plugin>/path`).
README, CHANGELOG, and LICENSE are skipped: they describe the skill, they do not define its needs.

- `declared`: the `compatibility` frontmatter value (redacted) and the parsed `allowed-tools`.
- Lists, each item `{item, confidence, hits, sources (first 3 file:line), detail}`:

  | Key | Detected from | Confidence |
  |---|---|---|
  | `runtime` | shebangs, `package.json` engines, `requires-python`, `composer.json` `require.php`, `.nvmrc` / `.python-version` (verified); PHP floors (match, `?->`, `str_contains` 8.0; enum, readonly 8.1; arrow functions 7.4) (inferred); Python syntax floors via `ast` (match 3.10, except* 3.11, walrus 3.8, `type` 3.12, tomllib 3.11, removeprefix 3.9, ...) and Node floors (`fetch` 18, `node:` 16, `structuredClone` 17, `fs.cp`/`cpSync` 16.7) (inferred) | mixed |
  | `packages` | third-party Python imports (via `ast`; `(optional)` when guarded), JS imports (Node built-ins excluded), `package.json`, `requirements.txt`, `pyproject.toml`, `composer.json` dependencies and PHP extensions, `vendor/autoload.php`, install commands (`install: ...`) | verified |
  | `binaries` | external programs in shell code blocks, shell scripts, `subprocess`/`spawn` calls, PHP `shell_exec`/`exec`/`system`, and inline commands in `SKILL.md` and `references/` (also after `cd ... &&`, `(`, `<(`, or `VAR=` prefixes; an install argument such as `chromium` is not a binary). A bash-only `<(...)` adds a runtime item | verified |
  | `network` | domains on lines that run a command or make a network call, tagged `(install)` or `(runtime)` | verified |
  | `tools` | Claude capabilities the `SKILL.md` instructions rely on (shell, file read, file write, file delivery, image viewing, web access, subagents, MCP connector, artifacts, memory, uploads, asking the user mid-task, display) plus `allowed-tools` and `context: fork`; a named `MCP connector: <server>` replaces the generic one | inferred from prose, verified from frontmatter |
  | `companions` | installed, sibling (in a skills collection), or same-plugin skill names in backticks or routing lines; single-word names count only when the line also says "skill" | verified |

- `docs_links`: count of URLs that no command or call uses (documentation, schema ids, examples).
- `findings` (pageable):

  | ID | Severity | Meaning |
  |---|---|---|
  | `REQ001` | info | no `compatibility` field, but requirements were detected |
  | `REQ002` | warn | the `compatibility` field omits image viewing, shell, an MCP connector, or subagents when the instructions rely on it (only these four, matched as whole words; a field naming `node`, `npm`, `git`, `python`, or a terminal counts as shell; subagents are skipped when the skill states a no-agents fallback) |
  | `REQ003` | warn | the `compatibility` value contains `: ` |
  | `REQ004` | warn | the `compatibility` value is over 500 characters |
  | `REQ005` | warn | a package is imported but there is no install command for it and no manifest of that ecosystem at all (a `requirements.txt` that lacks the package is not flagged: compare by hand) |
  | `REQ006` | info | runtime network access to a domain (blocked where domains are allowlisted) |
  | `REQ007` | info | the highest inferred runtime floor, per runtime |
  | `REQ008` | warn | the `compatibility` value is not a string (a mapping, list, or boolean) |
  | `REQ009` | warn | the frontmatter YAML is broken: declared values were recovered for audit, but Claude Code would ignore them (`declared.unparsed: true`) |
  | `REQ010` | warn | `npm ci` is used but no `package-lock.json` ships |
  | `REQ011` | info | Python package detection skipped: the checker runs on Python older than 3.10 and cannot tell standard-library imports from third-party ones; check imports by hand |
  | `REQ012` | warn | the 100 MB total read budget was reached; the files past it were not checked |

- `in_collection`: true when the target sits in a collection of skills (run `--only siblings`
  for collision checks; descriptions are cut at 1,000 characters).
- `siblings`: names of other skills in the same collection (a `skills` folder, or a folder holding
  several skills). For their descriptions, run `--only siblings` (paged). Use them for collision
  checks in section 2.
- Browser-side JavaScript (DOM access, no Node modules) does not raise a Node version floor.
- requirements is small enough that it needs no `--limit`; its `findings` can still be paged.

## 7. `build_appendix.py` report validation

The append run first prints `appendix written to <path>: Q files quoted + O omitted = N of N
entries; K sanitize notes`. A sanitize note marks a quoted file where secrets were redacted or
invisible characters escaped; the note sits above that file in the Appendix and needs no action
beyond reporting the underlying finding. Secrets are redacted before any cut. The Appendix quotes at most 5 MB of file text in total (later files
are listed as omitted). Quoted files over
40 KB and over 450 lines (except `SKILL.md`) show their first 300 and last 100 lines, with the
omitted span marked. An untrusted-data banner sits above Appendix A and above Appendix B.

Pass `--mode <mode>` (default `full`); it sets the file prefix, title line, and required
sections (`report-sections.md` section 0). Run it with `--check-only` before appending (it writes
nothing); the append run checks the report again, so it is the final run. Modes without an appendix (`compat`, `beginner`) run with
`--check-only` only (without it they exit 2). Both runs print `ERROR:` / `WARN:` lines, `REPORT CHECK: PASS` or `FAIL`,
and the File Map check (modes with section 5), and exit 1 on any ERROR or must-fix WARN (in write mode the
Appendix is still written). The report must be named `<prefix>*.md`, start with the mode's
title line, name the target's absolute path (anywhere in the report; the header is the place), and sit outside the target, its plugin, this skill,
and `.claude/`.

Both modes exit 2 with an `error:` line on stderr, and write nothing, when a guard fails or the
Appendix cannot be built: wrong file name or title line, a path inside the target, its plugin, this skill, or
`.claude/`, a report that does not name the target, or not exactly one `## 16. Appendix` line
outside fences (found 0 usually means an unclosed code fence above it), or a numbered section
heading below 16 sits after the Appendix line (write mode refuses rather than drop it), or the
report is not valid UTF-8 (rewriting it would replace the bad bytes). `--stdout` exits 2 unless `ANALYZE_SKILL_STDOUT=1` is set (it is for the user to
run). Fix the report or path and re-run.

- **ERROR** - the section headings are not exactly the mode's sections, in order.
- **WARN** - a section title differs from the standard title (ERROR in beginner mode).
- **WARN** - a table row has a `|` inside a code span (`` `a | b` ``): it splits the cell when
  rendered. Write `\|` inside the span.
- **ERROR** - a line contains invisible or control characters (a ⚠️ mark's U+FE0F after a symbol
  is fine). Write them as `<U+XXXX>` text.
- **INFO** - the prose word count and the mode's band for the target's size. Prose words exclude
  tables, code fences, and the header before section 1.
- **WARN** (advisory, `length:`) - the count is outside the band. One pass to cut padding and
  repetition, then continue; never drop required content.
- Every WARN except `length:` must be fixed before appending; `length:` is advisory.
- **beginner mode** - ERROR for long dashes, curly quotes, or any heading besides the title and
  the 8 numbered ones; WARN for each banned filler word, a table, a `file:line` citation, or a
  confidence label.
- **ERROR** (`security`) - section 1 has no `Verdict:` line.
- **WARN** (every mode but `beginner`) - the header has no `> Runs on:` line.
- **ERROR** - section 13 starts with `N/A -` (it never applies), has no `| Surfaces |` row, a
  surface has no mark (works / partial / blocked), a surface (Claude Code, Cowork, claude.ai,
  Chrome, API) is missing, or a ⚠️/❌ surface has no blocker named. Accepted format: the
  Requirement cell of the Surfaces row, surfaces separated by `·` or `;` (or a `,` directly before
  a surface name; never `/`), each
  starting with its name ("Claude in Chrome" counts as Chrome), then its mark, then a blocker of
  at least 4 characters after any ⚠️ or ❌ (or `n/a`).
- **ERROR** - a section 13 table row states a version (`3.10+`, `18+`) with no `file:line`,
  `SKILL.md:frontmatter`, `(unverified)`, or declaration keyword (`engines`, `requires-python`,
  `python_requires`). A shebang is cited by its line (`scripts/run.mjs:1`); an extensionless file
  counts when its path has a `/` or it is a known name (`Dockerfile:3`, `scripts/run:4`).
- **ERROR** - the suggested `compatibility:` line (the last one inside a `yaml` block in section
  13) contains `: ` or is over 500 characters. A quoted declared value elsewhere is not checked.
- **ERROR** - a line of sections 1-15 contains a secret (any `SEC-KEY-*` pattern). Cite the rule
  and `path:line` instead.
- **WARN** - a template placeholder (`<...>`, `<n>`, or several words in angle brackets; not HTML
  tags, `<plugin>/` paths, or anything inside a code span or code block, so a quoted `agent-<n>` is
  fine; inside code blocks only the template's own `<description>` and `<suggested one-line value>`
  are caught) was left anywhere in the prose body, or in the header: a `<...>` line, a line opening with
  `<` and a capital, a long `<...>` instruction inside a line (a space and 20 or more characters
  inside the brackets, outside code spans), a `<- only when` note, or a `/3` score cell. Fill it
  or delete it.
- **Verdict line:** `REPORT CHECK: PASS` only when there is no ERROR and no WARN except `length:`;
  otherwise a line starting `REPORT CHECK: FAIL (n error(s), m warning(s) to fix` and exit 1.
- **WARN** - a header placeholder (`<n>`, `<today's date...>`) was left; the header's `Runs on`
  line marks a surface differently from section 13's Surfaces row; beginner mode lacks a Target,
  Analyzed, or Report mode header line. (A second `# ` title in beginner mode is an ERROR.)
- **WARN** (content) - a scorecard cell is not a bare digit 0-3 (`N/A` is accepted on Resources &
  scripts only); the scorecard (`full`, `improve`) misses a row, its total does not add up
  (max 3 per scored row), or the total's rubric band is not named; `security` scores a row other
  than Safety, its `Verdict:` line uses none of the four verdicts, or the verdict does not match
  the Safety score (3 as is, 2 after the listed fixes, 1 not safe until, 0 do not install); section 2 has fewer
  should-trigger or near-miss prompts than the minimum; section 14 has fewer questions than the
  minimum (`full`, `interview`).
- **WARN** (every mode but `beginner`) - the report has no confidence label at all (Verified,
  Inferred, or `(unverified)`). An advisory INFO also lists (up to 20) sentences of 8 or more words
  with no citation and no label; it skips template label lines ("What it does: ..."), captions
  ending in ':', instructions ("Add ...", "Verify ..."), "**Term** - definition" lines, lines that
  already cite or label anything, quoted phrases, sentences about the report itself, and judgement
  words ("well", "should", "consider"). The bare word "unverified" and "Verified (by reading)" count as labels; "Not applicable" and "None"
  lines (negative findings that name what was checked) are skipped. It is a
  heuristic that never blocks PASS: label or cite only the listed sentences that state a fact, and
  you need not clear it.
- **WARN** - hedging words outside code fences, `>` blockquote lines, code spans, and text in
  double or curly double quotes (single quotes are not skipped). The full list: "should
  work", "should be fine", "probably", "may work", "might work", "in most cases", "generally
  works", "we think", "presumably", "seems to work", "may not work", "might not work", "may or may
  not".

The File Map check prints a `WARNING:` line listing inventory paths not named in sections 1-15
(matched as whole paths, so `a.py` is not satisfied by `data.py`), or `File Map check: every
inventory path is named in the report.` A WARNING does not fail the check; Done still requires
the paths. In check output, `SKILL.md:frontmatter` means the frontmatter block; cite its line
range in the report.
