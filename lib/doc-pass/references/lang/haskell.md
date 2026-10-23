## Haskell rules

### Files and tools

- In scope: `.hs` and `.hsc`. The checker reads them with its own lexer (`lexers.mjs`): no tree-sitter grammar ships as wasm. It splits the source into tokens (nested `{- -}` comments, `--` comments but not operators like `-->`, strings with gaps, character literals but not `'Promoted` or TH `'name` quotes, CPP lines) and groups them into declarations that start at column 0.
- Out of scope: `dist-newstyle/`, `.stack-work/`, `dist/`, literate Haskell (`.lhs`), Happy / Alex sources (`.y`, `.x`) and their generated `.hs`, `*.cabal` and `stack.yaml`.
- Syntax check and baseline (the main session, once per wave, in its work copy; agents rely on the checker parse): `cabal build` (or `stack build`) with warnings that must not grow; `hlint` when the project uses it; `ormolu` / `fourmolu --mode check` or `stylish-haskell` when it formats. Tests: `cabal test` / `stack test`. Haddock: `cabal haddock` should not gain warnings.

### Doc comment style

- Haddock: `-- |` before a declaration, `-- ^` after a field, constructor or argument, `{- | … -}` for longer blocks. Plain `--` is not documentation.
- First sentence is the summary, ending in a period. Markup: `'identifier'` and `"Module.Name"` links (only to names in scope), `@code@`, `/emphasis/`, `__bold__`, bird tracks (`> code`) or `@ … @` blocks for code.
- Document arguments with `-- ^` on each argument line of the type signature only where the project already does; otherwise describe them in prose. Say what the type cannot: preconditions, which exceptions it throws (`throwIO`, `error`), laziness and strictness, `IO` effects (files, network, `MVar`s), complexity for data-structure code.
- Section headings (`-- * Section`, `-- ** Sub`) and named chunks (`-- $name`) in export lists shape the generated page: keep them and their order (checked by reading).
- File header: the module Haddock before `module` (`{- | Module : … Copyright : … License : … -}` blocks are frozen whole because they hold the copyright: add nothing to them), or a `-- |` description. A file without one gets `-- |` lines directly above `module`.

### Coverage

- Every top-level type signature (one comment covers `a, b :: T`), and every `data`, `newtype`, `type` and `class` declaration. `type family` / `data instance` / `instance` declarations are exempt.
- Exempt in test files (`test/`, `*Spec.hs`): `main`, `spec`, `tests`.
- Checked by reading: class methods, record fields and constructors (`-- ^`), local `where` bindings that are not obvious, top-level bindings without a signature.

### Comments that are code

- Frozen whole comment: every `{-# … #-}` pragma (`LANGUAGE`, `OPTIONS_GHC`, `INLINE`, `SPECIALIZE`, `ANN`, `COMPLETE`, `RULES`), LiquidHaskell `{-@ … @-}` annotations, `HLINT` comments, `ORMOLU_DISABLE` / `FOURMOLU_DISABLE` / `_ENABLE`, plus the shared license, copyright, `@generated` and `cspell:` forms.
- Doctests: `-- >>> expr` and `-- prop> …` lines and the expected output after them, up to a blank comment line, run under doctest / cabal-docspec. Frozen: never edit, add or remove one.
- Kept: `@since 1.2` lines (Haddock prints them).
- CPP lines (`#if MIN_VERSION_base(4,8,0)`, `#include`) are code. Inside `#if` blocks, document the declaration in each branch.

### Servant, Yesod, pandoc and effects

- **Servant:** the API type forms the route map: each `:<|>` alternative's method, path (`"users" :> Capture "id" Int`), auth combinators, request body and response type. Handlers say which errors they throw (`throwError err404`).
- **Yesod / Scotty / Warp:** the routes file or `get` / `post` calls form the route map.
- **Effects:** say which monad stack or effect constraints a function needs (`MonadIO m`, `PandocMonad m`, `Members '[Error E] r`) and what each effect is used for; `unsafePerformIO` and `unsafeCoerce` get a why comment.
- **Concurrency:** `forkIO`, `async`, `MVar`, `STM` and `IORef` use: say who writes, who reads and what ordering guarantees hold.
- **Environment:** `getEnv`, `lookupEnv` and `optparse-applicative` options form the env and CLI maps.

### Bug report additions

- Partial functions on user input (`head`, `fromJust`, `read`, `!!`); `error` in library code.
- Lazy IO (`readFile` then closing the handle) and space leaks from lazy accumulators (`foldl`, `modifyIORef`).
- `String` concatenation in hot paths; orphan instances.
