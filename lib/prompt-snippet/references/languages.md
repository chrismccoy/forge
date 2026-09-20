# Language rules

One section per language. Read **only** the section for the language that was asked for
and ignore every other section. Where a language section differs from the general rules
in `SKILL.md`, the language section wins. If no section matches, use *Any other language*
at the end.

Below is one section per language. Read only the section for the language you were asked for and ignore every other section. Where a language section differs from the general rules, the language section wins. If no section matches, use the "Any other language" section at the end.

### Bash

- **Code block label:** `bash`
- **Runs as:** a Bash 4.4+ script (`chmod +x`, then `./script.sh`). Bash 4.4+ is newer than the macOS system Bash (3.2), so name this in the header.
- **File start:** `#!/usr/bin/env bash`, then `set -Eeuo pipefail` on the next line.
- **Conventions:** Use `[[ ]]` for tests and `(( ))` for arithmetic. Quote every expansion. Declare variables inside functions with `local`, and constants with `readonly`. Put the logic in functions and finish the file with `main "$@"`.
- **Arguments and help:** Parse options with a `while (( $# ))` loop and `case`, or with `getopts` for short options only. Support `-h`/`--help` (print usage, exit 0). On an unknown option or a bad value, print usage to stderr and exit 2.
- **Errors and exit codes:** Print errors with `printf '%s\n' "..." >&2`. Add an `ERR` trap that reports the failing line (`$LINENO`). Exit 0 on success and non-zero on failure.
- **Cleanup:** Register a cleanup function with `trap cleanup EXIT` (and `INT TERM` if needed). Create temporary files with `mktemp`.
- **Running other programs:** Keep commands and their arguments in arrays and run them as `"${cmd[@]}"`. Put `--` before file-name arguments. Never use `eval` on input.
- **Dependencies:** Only use external commands you really need. Check each one with `command -v` at startup and stop with a clear message if one is missing.
- **Formatting:** `shfmt -i 2` style, and ShellCheck-clean.

### Clojure

- **Code block label:** `clojure`
- **Runs as:** a Babashka script, run with `bb script.clj`.
- **File start:** `#!/usr/bin/env bb`, then an `ns` form with the `:require` list.
- **Conventions:** Write pure functions and keep side effects at the edges. Define `-main` and call it only when the file is run directly: `(when (= *file* (System/getProperty "babashka.file")) (apply -main *command-line-args*))`.
- **Arguments and help:** Use `babashka.cli` with a spec. Support `--help` (print usage, exit 0), and exit 2 on bad arguments.
- **Errors and exit codes:** Throw `ex-info` with data and catch it with `try`/`catch` in `-main`. Print errors to `*err*` and exit with `(System/exit n)`.
- **Cleanup:** Use `try`/`finally` and `babashka.fs/with-temp-dir`.
- **Running other programs:** Use `babashka.process/process` or `shell` with each argument passed separately. Never build one command string from input.
- **Dependencies:** Prefer libraries bundled with Babashka. Add others with `babashka.deps/add-deps`.
- **Formatting:** cljfmt style (2 spaces).

### C#

- **Code block label:** `csharp`
- **Runs as:** a .NET 10 file-based app, run with `dotnet run app.cs`.
- **File start:** `#!/usr/bin/env dotnet`, then any `#:package Name@version` lines, then `#nullable enable`.
- **Conventions:** Use top-level statements, with helper methods and records below them. Use async/await throughout.
- **Arguments and help:** Parse `args` by hand, or with System.CommandLine added through `#:package` when the arguments are complex. Support `-h`/`--help` (print usage, return 0), and return 2 on bad arguments.
- **Errors and exit codes:** Catch exceptions at the top level, print them with `Console.Error.WriteLine`, and return a non-zero exit code from the top-level statements.
- **Cleanup:** Use `using`/`await using` and `try`/`finally`. Cancel a `CancellationTokenSource` from `Console.CancelKeyPress`.
- **Running other programs:** Use `ProcessStartInfo` with `ArgumentList`. Never pass a single `Arguments` string built from input, and never set `UseShellExecute = true` with input.
- **Dependencies:** Prefer the base library. Add NuGet packages only through `#:package` lines.
- **Formatting:** `dotnet format` style (4 spaces, braces on their own line).

### Elixir

- **Code block label:** `elixir`
- **Runs as:** an `.exs` script for Elixir 1.17+, run with `elixir script.exs`.
- **File start:** `#!/usr/bin/env elixir`, then `Mix.install/1` if libraries are needed, then `defmodule Script` with a `main/1` function. The last line is `Script.main(System.argv())`.
- **Conventions:** Use pattern matching, pipelines, and `with` for multi-step error flow. Return `{:ok, _}`/`{:error, _}` tuples.
- **Arguments and help:** Use `OptionParser.parse/2` with `strict:`. Support `--help` (print usage, `System.halt(0)`), and `System.halt(2)` on bad arguments.
- **Errors and exit codes:** Print errors with `IO.puts(:stderr, ...)` and exit with `System.halt/1`.
- **Cleanup:** Use `try`/`after`.
- **Running other programs:** Use `System.cmd/3` with the arguments as a list. Never use `System.shell/2` or `:os.cmd` with input.
- **Dependencies:** Add libraries only through `Mix.install/1`.
- **Formatting:** `mix format` style (2 spaces).

### Erlang

- **Code block label:** `erlang`
- **Runs as:** an escript for OTP 26+, run with `escript script.erl`.
- **File start:** `#!/usr/bin/env escript`, then `-module(...)`, then `-export([main/1]).`, then `main(Args)`.
- **Conventions:** Return `{ok, Value}` or `{error, Reason}` from functions and match on the result. Keep functions small and use guards.
- **Arguments and help:** Use the `argparse` module. Support `--help` (print usage, `halt(0)`), and `halt(2)` on bad arguments.
- **Errors and exit codes:** Use `try ... catch` at the top level. Print errors with `io:format(standard_error, ...)` and set the exit code with `halt(N)`.
- **Cleanup:** Use `try ... after`.
- **Running other programs:** Find the program's full path with `os:find_executable/1` (and stop with a clear message if it returns `false`), then run it with `open_port({spawn_executable, Path}, [{args, Args}, exit_status])`. Never pass input to `os:cmd`.
- **Dependencies:** Use OTP only.
- **Formatting:** erlfmt style.

### Go

- **Code block label:** `go`
- **Runs as:** a single `main.go` for Go 1.23+, run with `go run main.go`.
- **File start:** `package main`, with no shebang.
- **Conventions:** Keep `main` small: have it call `run(ctx, args) error`. Pass a `context.Context` through the code and use `log/slog` for logging.
- **Arguments and help:** Use the `flag` package. It prints usage for `-h`, and on a bad flag it exits with code 2.
- **Errors and exit codes:** Wrap errors with `fmt.Errorf("...: %w", err)` and return them up to `main`. Print them to stderr and call `os.Exit(1)` only from `main`.
- **Cleanup:** Use `defer`, and create the context with `signal.NotifyContext` so the program stops cleanly on interrupt. `defer` does not run after `os.Exit`, so exit only after `run` has returned.
- **Running other programs:** Use `exec.CommandContext` with separate arguments. Never run `sh -c` with input.
- **Dependencies:** Prefer the standard library. If a third-party module is needed, list the `go mod init` and `go get` commands in the header comment.
- **Formatting:** `gofmt` (tabs).

### Haskell

- **Code block label:** `haskell`
- **Runs as:** a cabal script, run with `cabal run script.hs` or `./script.hs`.
- **File start:** `#!/usr/bin/env cabal`, then a `{- cabal: build-depends: base, ... -}` block that lists every package used, then the `import` lines.
- **Conventions:** Give every top-level definition a type signature. Never use partial functions (`head`, `fromJust`, `read`); use `readMaybe` and pattern matching instead. Keep side effects in `IO` and the logic pure.
- **Arguments and help:** Use `optparse-applicative` for non-trivial arguments (it gives `--help`), or `getArgs` for simple ones.
- **Errors and exit codes:** Use `Either`/`ExceptT` for expected failures and `Control.Exception` for I/O errors. Print errors with `hPutStrLn stderr` and exit with `exitWith (ExitFailure n)`.
- **Cleanup:** Use `bracket` or `finally`.
- **Running other programs:** Use `proc` (not `shell`) from `System.Process`, with a list of arguments.
- **Dependencies:** List every package in the `{- cabal: -}` block.
- **Formatting:** Ormolu style.

### Java

- **Code block label:** `java`
- **Runs as:** Java 21+, as a single `Main.java` run with `java Main.java` (no compile step). If a library is needed, write a JBang script run with `jbang Main.java` instead.
- **File start:** the header comment, then `import` lines, then `public class Main`. For a JBang script, the first line is `///usr/bin/env jbang "$0" "$@" ; exit $?`, followed by `//DEPS group:artifact:version` lines.
- **Conventions:** Use records, `var`, switch expressions, pattern matching, text blocks, and `java.nio.file.Path`/`Files`. Put the logic in small static methods or nested classes.
- **Arguments and help:** Parse `args` by hand, or use picocli through JBang `//DEPS` when the arguments are complex. Support `-h`/`--help` (print usage, exit 0), and exit 2 on bad arguments.
- **Errors and exit codes:** Catch exceptions in `main`, print them with `System.err`, and call `System.exit` only from `main`.
- **Cleanup:** Use try-with-resources. If cleanup must run on Ctrl-C, register it with `Runtime.getRuntime().addShutdownHook`.
- **Running other programs:** Use `ProcessBuilder` with a list of arguments. Never run `sh -c` with input.
- **Dependencies:** Prefer the JDK. Add libraries only through JBang `//DEPS` lines.
- **Formatting:** google-java-format style.

### JavaScript

- **Code block label:** `javascript`
- **Runs as:** Node.js 22+ (unless the task says browser), run with `node script.mjs`. Give the `.mjs` file name in the header so ES modules work without a `package.json`.
- **File start:** `#!/usr/bin/env node`.
- **Conventions:** Use ES modules (`import`), `const`/`let`, arrow functions, async/await, template literals, and `node:`-prefixed built-ins. Put the logic in an async `main()` function.
- **Arguments and help:** Use `parseArgs` from `node:util` with `strict: true`. Support `-h`/`--help` (print usage, exit 0). On an unknown option or a bad value, print usage to stderr and exit 2.
- **Errors and exit codes:** Catch errors around `main()`, print them with `console.error`, and set `process.exitCode` to a non-zero value. Only call `process.exit()` when you must stop right away.
- **Cleanup:** Use `try`/`finally`, and handle `SIGINT` and `SIGTERM` with `process.on` to clean up. Create temporary directories with `fs.mkdtemp`.
- **Running other programs:** Use `execFile` or `spawn` from `node:child_process` with an array of arguments. Never use `exec`, `shell: true`, or `eval` with input.
- **Dependencies:** Prefer built-in modules. If an npm package is needed, give the `npm install` command in the header, load it with a dynamic `import()`, and stop with a clear message if it is missing.
- **Formatting:** Prettier style with 2-space indentation.

### Lua

- **Code block label:** `lua`
- **Runs as:** Lua 5.4, run with `lua script.lua`.
- **File start:** `#!/usr/bin/env lua`.
- **Conventions:** Declare every variable and function `local`. Put the logic in a `main(args)` function that returns an integer exit code, and end the file with `os.exit(main(arg))`.
- **Arguments and help:** Parse the global `arg` table by hand, or use the LuaRocks `argparse` module. Support `-h`/`--help` (print usage, exit 0), and exit 2 on bad arguments.
- **Errors and exit codes:** Raise errors with `error` and catch them with `pcall`. Write errors with `io.stderr:write` and exit with `os.exit(code)`.
- **Cleanup:** Use `<close>` variables.
- **Running other programs:** `os.execute` and `io.popen` always go through the shell. Wrap every argument in single quotes (escaping any `'` inside it) with a helper function before building the command.
- **Dependencies:** If a LuaRocks module is needed, give the `luarocks install` command in the header, load it with `pcall(require, ...)`, and stop with a clear message if it is missing.
- **Formatting:** StyLua style.

### Perl

- **Code block label:** `perl`
- **Runs as:** Perl 5.36+, run with `perl script.pl`.
- **File start:** `#!/usr/bin/env perl`, then `use v5.36;` (which turns on `strict`, `warnings`, signatures, and `say`), then `use autodie;`.
- **Conventions:** Use subroutines with signatures and lexical (`my`) variables only. Call `main(@ARGV)` at the end of the file and end the file with an embedded POD section for usage.
- **Arguments and help:** Use `Getopt::Long`. Show help with `pod2usage(-exitval => 0, -verbose => 1)` from `Pod::Usage`, and call `pod2usage(2)` on bad arguments.
- **Errors and exit codes:** Throw errors with `die` and catch them with `eval { ...; 1 } or do { ... }`. Print errors with `warn` or `say STDERR`, and exit with a non-zero code.
- **Cleanup:** Use `File::Temp` (which removes files automatically), `local $SIG{INT}`, and `END` blocks.
- **Running other programs:** Use the list form of `system` (`system { $prog } $prog, @args`) or `IPC::Open3`. Never pass a single command string built from input, and never use backticks with input.
- **Dependencies:** Prefer core modules. If a CPAN module is needed, give the `cpanm` command in the header, load it with `eval { require Module; 1 }`, and stop with a clear message if it is missing.
- **Formatting:** `perltidy` style (4 spaces).

### PHP

- **Code block label:** `php`
- **Runs as:** the PHP 8.2+ CLI, run with `php script.php`.
- **File start:** `#!/usr/bin/env php`, then `<?php`, then `declare(strict_types=1);`.
- **Conventions:** Use typed properties, parameters, and return types, plus `match`, enums, and `readonly` where they fit. Put the logic in functions or a class, and call a `main(array $argv): int` entry point with `exit(main($argv));`.
- **Arguments and help:** Use `getopt()` with its `$rest_index` argument, or parse `$argv` directly. `getopt()` silently ignores unknown options, so compare what it parsed against `$argv` and treat anything unexpected as a bad option. Support `-h`/`--help` (print usage, exit 0). On an unknown option or a bad value, print usage to STDERR and exit 2.
- **Errors and exit codes:** Throw and catch exceptions. Write errors with `fwrite(STDERR, ...)` and return a non-zero exit code.
- **Cleanup:** Use `try`/`finally`. If `pcntl` is available, handle `SIGINT` with `pcntl_signal`.
- **Running other programs:** Use `proc_open` with the command given as an array, which skips the shell. If a command string cannot be avoided, wrap every argument with `escapeshellarg`. Never use `eval` on input.
- **Dependencies:** Prefer built-in extensions. If Composer packages are needed, give the `composer require` command in the header, check that `vendor/autoload.php` exists, and stop with a clear message if it does not.
- **Formatting:** PSR-12 style with 4-space indentation.

### PowerShell

- **Code block label:** `powershell`
- **Runs as:** PowerShell 7.4+ (`pwsh`), run with `pwsh ./script.ps1`.
- **File start:** `#!/usr/bin/env pwsh`, then `#Requires -Version 7.4`, then comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`), then `[CmdletBinding(SupportsShouldProcess)]` and a `param()` block. After that, `Set-StrictMode -Version Latest` and `$ErrorActionPreference = 'Stop'`.
- **Conventions:** Name functions with approved `Verb-Noun` verbs. Report progress with `Write-Verbose` and results with `Write-Output`, never `Write-Host`. Build paths with `Join-Path` so the script works on every platform.
- **Arguments and help:** These replace the generic rules: validation attributes in the `param()` block replace manual argument checks, `Get-Help ./script.ps1` replaces `--help`, and `-WhatIf` replaces `--dry-run`. Wrap every change in `if ($PSCmdlet.ShouldProcess(...))`.
- **Errors and exit codes:** Use `try`/`catch`/`finally`. In the top-level `catch`, print the error with `[Console]::Error.WriteLine` and then `exit 1`. Do not use `Write-Error` there: with `$ErrorActionPreference = 'Stop'` it throws again and `exit 1` is never reached.
- **Cleanup:** Use `finally`, which also runs on Ctrl-C.
- **Running other programs:** Run programs with the call operator and an argument array (`& $exe @arguments`), then check `$LASTEXITCODE`. Never use `Invoke-Expression`.
- **Dependencies:** Declare required modules with `#Requires -Modules Name`. For state and config folders, use `[Environment]::GetFolderPath('ApplicationData')` on Windows and the XDG paths elsewhere.
- **Formatting:** PSScriptAnalyzer-clean, 4-space indentation.

### Python

- **Code block label:** `python`
- **Runs as:** Python 3.12+, run with `python3 script.py` or `uv run script.py`.
- **File start:** `#!/usr/bin/env python3`. If third-party packages are needed, follow it with an inline `# /// script` metadata block (PEP 723) that lists them.
- **Conventions:** Add type hints to every function. Use `pathlib` for paths, f-strings, and dataclasses where they fit. Define `main() -> int` and end with `if __name__ == "__main__": sys.exit(main())`.
- **Arguments and help:** Use `argparse`, which gives `-h`/`--help` (exit 0) and exits 2 on bad arguments.
- **Errors and exit codes:** Catch specific exceptions, not bare `except:`. Print errors to stderr and return a non-zero code from `main`. Use `logging` for log output.
- **Cleanup:** Use `with` blocks, the `tempfile` module, and `try`/`finally`. `KeyboardInterrupt` should exit cleanly with code 130.
- **Running other programs:** Use `subprocess.run([...], check=True)` with a list of arguments. Never use `shell=True` or `os.system` with input.
- **Dependencies:** Prefer the standard library. List any third-party packages in the PEP 723 block.
- **Formatting:** Ruff/Black style with 4-space indentation.

### Ruby

- **Code block label:** `ruby`
- **Runs as:** Ruby 3.3+, run with `ruby script.rb`.
- **File start:** `#!/usr/bin/env ruby`, then `# frozen_string_literal: true`.
- **Conventions:** Put the logic in a class or module. End the file with `exit(Main.new(ARGV).run) if $PROGRAM_NAME == __FILE__`.
- **Arguments and help:** Use `OptionParser`. Support `-h`/`--help` (print usage, exit 0). Rescue `OptionParser::ParseError`, print usage to stderr, and exit 2.
- **Errors and exit codes:** Use `begin`/`rescue` with specific error classes. Print errors with `warn` and exit with a non-zero code.
- **Cleanup:** Use `ensure`, `Tempfile`, and `trap("INT")`.
- **Running other programs:** Use `system(cmd, *args, exception: true)` or `Open3.capture3(cmd, *args)`, always with separate arguments. Never use backticks or a single command string with input.
- **Dependencies:** Prefer the standard library. If gems are needed, declare them inline with `require "bundler/inline"` and a `gemfile do ... end` block.
- **Formatting:** RuboCop style (2 spaces).

### Rust

- **Code block label:** `rust`
- **Runs as:** a single `src/main.rs` for the 2024 edition, run with `cargo run --`.
- **File start:** the header comment, with no shebang.
- **Conventions:** Use small functions and structs. Propagate errors with `?`. Never call `unwrap()` or `expect()` on input or I/O results.
- **Arguments and help:** Use `std::env::args` for simple arguments, or `clap` with derive when they are non-trivial (clap exits 2 on bad arguments). Support `-h`/`--help`.
- **Errors and exit codes:** Make `main` return `std::process::ExitCode` or `Result<(), Box<dyn std::error::Error>>`. Print errors with `eprintln!`.
- **Cleanup:** Clean up through `Drop` (RAII). If the script must react to Ctrl-C, use the `ctrlc` crate.
- **Running other programs:** Use `std::process::Command` with `.arg()`/`.args()`. Never run `sh -c` with input.
- **Dependencies:** Prefer the standard library. If crates are needed, put the `[dependencies]` section of `Cargo.toml` in the header comment.
- **Formatting:** `rustfmt` (4 spaces).

### Swift

- **Code block label:** `swift`
- **Runs as:** Swift 6, run with `swift script.swift`.
- **File start:** `#!/usr/bin/env swift`, then `import Foundation`.
- **Conventions:** Use structs, enums, and functions marked `throws`. Top-level code is the entry point, so keep it to a short call into `main()`.
- **Arguments and help:** Read `CommandLine.arguments` by hand, because Swift Argument Parser cannot be used from a single script file. Support `-h`/`--help` (print usage, exit 0), and exit 2 on bad arguments.
- **Errors and exit codes:** Define an `Error` enum and use `do`/`try`/`catch`. Write errors to `FileHandle.standardError` and exit with `exit(_:)`.
- **Cleanup:** Use `defer`.
- **Running other programs:** Use `Process`, setting `executableURL` and an `arguments` array. Never run `/bin/sh -c` with input.
- **Dependencies:** Use Foundation only.
- **Formatting:** swift-format style.

### TypeScript

- **Code block label:** `typescript`
- **Runs as:** Node.js 22.18+, which runs TypeScript directly by stripping the types. Run with `node script.mts`, and give the `.mts` file name in the header.
- **File start:** `#!/usr/bin/env node`.
- **Conventions:** Because the types are only stripped, use only syntax that can be erased: no `enum`, no `namespace`, and no constructor parameter properties. Use `import type` for type-only imports, and include the `.ts`/`.mts` extension in relative imports. Type everything explicitly and never use `any`. Use ES modules, `const`/`let`, async/await, and `node:`-prefixed built-ins, with an async `main()` function.
- **Arguments and help:** Use `parseArgs` from `node:util` with `strict: true`. Support `-h`/`--help` (print usage, exit 0). On an unknown option or a bad value, print usage to stderr and exit 2.
- **Errors and exit codes:** Catch errors around `main()` (treat the caught value as `unknown`), print them with `console.error`, and set `process.exitCode` to a non-zero value.
- **Cleanup:** Use `try`/`finally`, and handle `SIGINT` and `SIGTERM` with `process.on` to clean up.
- **Running other programs:** Use `execFile` or `spawn` from `node:child_process` with an array of arguments. Never use `exec`, `shell: true`, or `eval` with input.
- **Dependencies:** Prefer built-in modules. If an npm package is needed, give the `npm install` command in the header, load it with a dynamic `import()`, and stop with a clear message if it is missing.
- **Formatting:** Prettier style with 2-space indentation.

### zsh

- **Code block label:** `zsh`
- **Runs as:** an executable zsh script (`chmod +x`, then `./script.zsh`).
- **File start:** `#!/usr/bin/env zsh`, then `setopt err_exit no_unset pipe_fail` on the next line.
- **Conventions:** Use `[[ ]]` for tests and `(( ))` for arithmetic. Quote every expansion. Declare variables inside functions with `local`. Put the logic in functions and finish the file with `main "$@"`.
- **Arguments and help:** Parse options with `zparseopts -D -E -F`. Support `-h`/`--help` (print usage, exit 0). On an unknown option or a bad value, print usage to stderr and exit 2.
- **Errors and exit codes:** Print errors with `print -u2`. Exit 0 on success and non-zero on failure.
- **Cleanup:** Register a cleanup function with `trap cleanup EXIT INT TERM`. Create temporary files with `mktemp`.
- **Running other programs:** Keep commands and their arguments in arrays and run them as `"${cmd[@]}"`. Never use `eval` on input.
- **Dependencies:** Only use external commands you really need. Check each one with `command -v` at startup and stop with a clear message if one is missing.
- **Formatting:** shfmt-like style with 2-space indentation.

### Any other language

- **Code block label:** the language's standard identifier
- **Runs as:** the language's usual script or single-file runner.
- **File start:** a shebang if the language supports one, then the header comment.
- **Conventions:** Follow the language's current idiomatic conventions.
- **Arguments and help:** Support `-h`/`--help` (print usage, exit 0). On an unknown option or a bad value, print usage to stderr and exit 2.
- **Errors and exit codes:** Use the language's normal error handling. Print errors to stderr and exit with a non-zero code.
- **Cleanup:** Use the language's scoped-cleanup construct (`finally`, `defer`, or destructors).
- **Running other programs:** Pass arguments as a list. Never build a shell command string from input and never `eval` input.
- **Dependencies:** Prefer the standard library. Use the language's inline or single-file way of declaring dependencies if it has one; otherwise give the install command in the header.
- **Formatting:** The style of the language's standard formatter.
