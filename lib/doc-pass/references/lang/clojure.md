## Clojure rules

### Files and tools

- In scope: `.clj`, `.cljs`, `.cljc`, `.cljd`, and Babashka scripts (`.bb`). The checker reads them with its own Clojure reader (`clojure.mjs`): there is no maintained tree-sitter grammar, and the reader covers the full reader syntax (reader conditionals, tagged literals, regexes, character literals, metadata, `#_` discards).
- Out of scope: `.edn` data files (`deps.edn`, `shadow-cljs.edn`, `bb.edn`), `target/`, `.cpcache/`, `.shadow-cljs/`, `node_modules/`, compiled JS output.
- Syntax check and baseline: `clj-kondo --lint <files>` before and after: no new findings (`clj-kondo` reads docstrings: `:missing-docstring` should go down). cljfmt (`cljfmt check`) or zprint in check mode when the project formats. Tests: `clojure -X:test`, `lein test`, or the project's shadow-cljs / Kaocha task.

### Doc comment style

- Documentation is the **docstring**: a string literal right after the name in `defn`, `defn-`, `defmacro`, `defmulti`, `defprotocol` (and after each method's argument vectors), `ns`, and project macros built on them (`rum/defc`, `rum/defcs`, `s/defn`). In `def` and `defonce` a docstring goes after the name only when a value follows it: `(def timeout "Request timeout in ms." 5000)`.
- The checker treats these docstrings as documentation, not code: adding, rewording or removing one passes, any other string change fails.
- Layout: when the name and the argument vector are on separate lines, the docstring takes its own line between them, indented two spaces. When they share a line (`(defn f [x]`), put the docstring inline (`(defn f "Does x." [x]`): moving `[x]` to a new line changes the layout and fails.
- Content: first line a summary sentence ending in a period. Continuation lines are indented two spaces (as `clojure.repl/doc` prints them). Name arguments in backticks or plain words; describe each argument, the return value, side effects (atoms swapped, DB writes, re-frame events dispatched) and what is thrown (`ex-info` data keys).
- `defrecord`, `deftype` and `definterface` take no docstring: a `;;` comment block above them describes the type and each field.
- `;;` for comments on their own line, `;` for trailing comments. Never edit inside a `(comment …)` rich-comment form or a `#_` discarded form: both are code.
- File header: the `ns` docstring. A file without `ns` (a script) gets `;;` lines at the top, after any shebang.

### Coverage

- Every top-level `defn`, `defn-`, `defmacro`, `defmulti`, `defprotocol`, `defrecord`, `deftype`, `definterface`, and project definers (`rum/defc*`), including those inside a top-level reader conditional. `def` / `defonce` values are optional: document the ones whose purpose the name does not say.
- Exempt: `deftest`, `defmethod` (it implements a documented `defmulti`), protocol implementations inside `extend-type` / `extend-protocol` / `reify`.
- Checked by reading: anonymous functions passed to `swap!`, `reg-event-fx`, `reg-sub`, `add-watch`, `go` blocks.

### Comments that are code

- Frozen whole comment: Emacs mode lines (`;; -*- … -*-`), shebangs (`#!/usr/bin/env bb`), zprint directives (`;!zprint {…}`, also last before their form), plus the shared license, `@generated`, `cspell:` forms.
- clj-kondo and cljfmt directives are code, not comments: `#_:clj-kondo/ignore`, `#_{:clj-kondo/ignore [:rule]}`, `^:cljfmt/ignore`. Never add, move or edit them.
- Metadata maps (`^{:doc "…"}`, `^:private`, `^:export`) are code. A `:doc` in metadata counts as documentation for coverage, but its string is code too: never edit it, and put a wrong one in the bug report. Only a docstring in its usual place in a `def` form (after the name) may be edited.

### re-frame, Reagent, Ring and Datascript

- **re-frame:** document each `reg-event-db` / `reg-event-fx` handler with the event vector shape, what it changes in `app-db` and which effects it returns; each `reg-sub` with what it derives and its inputs; each `reg-fx` with its effect map. One description per event, at the registration; dispatchers get one line.
- **Reagent / Rum components:** what the component renders, its arguments and which atoms or subscriptions it reads. Mixins (`rum/reactive`, `rum/local`) get a word on why.
- **Ring / Reitit:** route data forms the route map: method, path, middleware (auth, coercion), parameters, responses.
- **State:** each top-level `atom`, `defonce` atom or Integrant / Mount component says what it holds and who writes it.
- **Environment:** `System/getenv`, `(environ/env …)` and `goog-define` reads form the env map.

### Bug report additions

- Blocking calls inside `go` blocks; `put!` without back-pressure.
- `swap!` functions with side effects (they can be retried).
- Lazy sequences realized outside their `with-open` or binding scope.
- `read-string` / `eval` on untrusted input (use `clojure.edn/read-string`).
