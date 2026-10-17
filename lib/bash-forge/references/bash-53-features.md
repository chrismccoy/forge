# Bash 5.3 Features

## Overview

Bash 5.3 (released July 2025) adds in-shell command substitution, new options for several builtins, configurable glob sorting, and a floating-point loadable builtin. Everything below was checked against Bash 5.3; run `bash --version` to see what you have.

## Contents

- [Key New Features](#key-new-features)
  - [1. In-Shell Command Substitution `${ cmd; }`](#1-in-shell-command-substitution--cmd-)
  - [2. REPLY Substitution `${| cmd; }`](#2-reply-substitution--cmd-)
  - [3. `read -E`](#3-enhanced-read-builtin)
  - [4. `source -p`](#4-enhanced-source-builtin)
  - [5. `compgen -V`](#5-enhanced-compgen-builtin)
  - [6. GLOBSORT](#6-globsort-variable)
  - [7. BASH_TRAPSIG](#7-bash_trapsig-variable)
  - [8. `fltexpr` (loadable)](#8-floating-point-arithmetic-fltexpr-loadable-builtin)
- [Performance Notes](#performance-notes)
- [Migration Guide](#migration-guide)
- [Best Practices](#best-practices)
- [Compatibility Notes](#compatibility-notes)
- [Real-World Examples](#real-world-examples)
- [Resources](#resources)

## Key New Features

### 1. In-Shell Command Substitution `${ cmd; }`

**New: `${ command; }` syntax** - Runs the command list in the *current* shell (no subshell fork) and substitutes its standard output:

```bash
# OLD way - the command list runs in a forked subshell
output=$(some_function)

# NEW way (Bash 5.3+) - runs in the current shell
output=${ some_function; }
```

Note the required space after `${` and the terminating `;` (or newline) before `}`.

**What it does and does not save:**
- It saves the *subshell* fork only. An external program inside it (`grep`, `wc`, `sed`, ...) is still forked and exec'd as usual.
- The biggest win is when the body is shell builtins/functions, e.g. calling a shell function that `echo`es a result.
- Side effects persist: variable assignments, `cd`, etc. inside `${ ...; }` affect the current shell.

```bash
counter=0
next_id() { counter=$((counter + 1)); echo "id-$counter"; }

a=$(next_id)     # runs in a subshell: counter stays 0 in the parent
b=${ next_id; }  # runs in current shell: counter becomes 1
echo "$a $b counter=$counter"   # id-1 id-1 counter=1
```

**Example:**
```bash
#!/usr/bin/env bash

count=0
for file in *.txt; do
    # wc is an external command: it is still forked either way.
    # ${ } only removes the extra subshell around it.
    lines=${ wc -l < "$file"; }
    count=$((count + lines))
done
echo "$count"
```

### 2. REPLY Substitution `${| cmd; }`

**New: `${| command; }` syntax** - Runs the command list in the current shell with a *local* `REPLY` variable. The value of the expansion is whatever `REPLY` holds when the list finishes. The command's standard output is **not** captured; it passes through to the terminal as normal.

```bash
# The body must ASSIGN REPLY; the expansion's value is REPLY's final value
v=${| REPLY=$((42 * 2)); }
echo "$v"            # 84

# stdout is NOT captured - it goes straight through
w=${| echo "this prints to the terminal"; REPLY="value"; }
echo "$w"            # value

# REPLY is local to the construct: the caller's REPLY is untouched
REPLY="outer"
x=${| REPLY="inner"; }
echo "$x $REPLY"     # inner outer
```

Functions that set `REPLY` (a common "return a string without forking" convention) pair naturally with it:

```bash
to_upper() { REPLY=${1^^}; }
name=${| to_upper "hello"; }
echo "$name"         # HELLO
```

**Pitfall:** like any expansion, a bare `${| ...; }` used as a statement is expanded and the *result is executed as a command*:

```bash
${| REPLY=$((1 + 1)); }   # tries to run a command named "2": command not found
```

Always assign it (`var=${| ...; }`) or use it as an argument.

**Use Cases:**
- Getting a string result from a function without a fork and without capturing its stdout
- Avoiding clobbering a global `REPLY`

### 3. Enhanced `read` Builtin

**New: -E option** - Uses Readline to read the line (like `-e`), but with bash's default completion, including programmable completion, instead of Readline's default (filename) completion:

```bash
# Interactive input with tab completion
read -E -p "Enter filename: " filename

# Full readline features (editing, completion)
read -E -p "Select environment: " env
```

`-E` only has an effect when standard input is a terminal.

**Benefits:**
- Better UX for interactive scripts
- Built-in path completion

### 4. Enhanced `source` Builtin

**New: -p PATH option** - Searches the colon-separated PATH argument for the file instead of `$PATH`:

```bash
# OLD way
source /opt/myapp/lib/helpers.sh

# NEW way - search a custom path
source -p /opt/myapp/lib:/usr/local/lib helpers.sh

LIB_PATH=/app/modules:/shared/lib
source -p "$LIB_PATH" database.sh
```

`source` reads exactly **one** file. Any further words become that file's positional parameters (`source -p "$LIB_PATH" database.sh logging.sh` sources only `database.sh`, with `$1=logging.sh`). Source multiple libraries with multiple commands or a loop:

```bash
for lib in database.sh logging.sh; do
    source -p "$LIB_PATH" "$lib"
done
```

**Benefits:**
- Modular library organization
- Avoid hard-coded paths
- Environment-specific sourcing

### 5. Enhanced `compgen` Builtin

**New: `-V varname` option** - Stores the completions in an indexed array instead of printing them:

```bash
# OLD way - capture stdout (subshell, word-splitting concerns)
mapfile -t completions < <(compgen -f)

# NEW way - results go straight into an indexed array
compgen -V completions -f
printf '%s\n' "${completions[@]}"

compgen -V words -W "start stop status" -- st
declare -p words   # declare -a words=([0]="start" [1]="stop" [2]="status")
```

**Benefits:**
- No subshell or output parsing
- Filenames with spaces/newlines stay intact as array elements

### 6. GLOBSORT Variable

**New: Control pathname-expansion sort order**:

```bash
# Unset or empty: historical behavior (by name, per LC_COLLATE)
echo *.txt

# Newest first
GLOBSORT="-mtime"
echo *.txt

# Smallest first
GLOBSORT="size"
echo *.txt

# Reverse alphabetical
GLOBSORT="-name"
echo *.txt
```

**Valid values:** an optional `+` (ignored, ascending) or `-` (descending) prefix followed by one specifier:
- `name` - by name (ascending is the default)
- `numeric` - all-digit names sorted by numeric value (`2` before `10`); others follow, by name
- `size` - by file size
- `mtime` / `atime` / `ctime` - by modification / access / inode change time
- `blocks` - by number of blocks
- `nosort` - no sorting; filesystem order

Ties on non-name keys fall back to sorting by name. An invalid value such as `reverse` is not an error; it silently falls back to name order.

### 7. BASH_TRAPSIG Variable

**New: Signal number variable in traps**:

```bash
#!/usr/bin/env bash
set -euo pipefail

# BASH_TRAPSIG contains the number of the signal being handled
handle_signal() {
    echo "Caught signal: $BASH_TRAPSIG" >&2
    case "$BASH_TRAPSIG" in
        15) echo "SIGTERM (15) received, shutting down gracefully" ;;
        2)  echo "SIGINT (2) received, cleaning up" ;;
        *)  echo "Signal $BASH_TRAPSIG received" ;;
    esac
}

trap handle_signal SIGTERM SIGINT SIGHUP
```

**Benefits:**
- Reusable signal handlers
- Dynamic signal-specific behavior
- Better logging and debugging

### 8. Floating-Point Arithmetic: `fltexpr` (Loadable Builtin)

`fltexpr` is **not** built into bash. It is one of the example *loadable builtins* shipped with the bash 5.3 sources, and must be loaded with `enable -f` before use. Whether it is available depends on how bash was packaged:

- Debian/Ubuntu: install the `bash-builtins` package, which provides `/usr/lib/bash/fltexpr`.
- Other builds: look in the directories listed in `$BASH_LOADABLES_PATH` (defaults include `/usr/local/lib/bash` and `/usr/lib/bash`).

```bash
# Load it (a bare name is searched for in $BASH_LOADABLES_PATH)
enable -f fltexpr fltexpr || { echo "fltexpr loadable not available" >&2; exit 1; }

# Quote the expression: unquoted, `*` is subject to globbing
fltexpr 'result = 42.5 * 1.5'
echo "$result"         # 63.75

fltexpr 'circle_area = pi * 5 * 5'   # pi is a predefined constant
echo "Area: $circle_area"            # Area: 78.53981633974483

# -p also prints the value to stdout
fltexpr -p '10 / 4'    # 2.5
```

Note: `fltexpr` returns status 1 when the expression evaluates to 0 (like `(( ))`), so guard it under `set -e`. Avoid variable names beginning with a predefined constant name such as `pi` (`pi_area` is a syntax error).

**Use Cases:**
- Simple scientific or financial calculations
- Avoiding external tools (`bc`, `awk`) where the loadable is known to be installed

## Performance Notes

### `${ }` Removes the Subshell, Not External Commands

```bash
# Forks a subshell AND runs an external bc every iteration
for i in {1..1000}; do
    result=$(echo "$i * 2" | bc)
    process "$result"
done

# Integer math needs no substitution at all - fastest
for i in {1..1000}; do
    result=$((i * 2))
    process "$result"
done

# ${ } helps when the body is shell code (functions, builtins)
double() { echo $(( $1 * 2 )); }
for i in {1..1000}; do
    result=${ double "$i"; }   # no subshell fork
    process "$result"
done
```

How much `${ }` saves depends entirely on whether the body runs external programs. Benchmark your own loop rather than relying on a single percentage.

### Efficient File Processing

Pattern matching against a line does not need any command at all:

```bash
#!/usr/bin/env bash
set -euo pipefail

process_log() {
    local line_count=0
    local error_count=0
    local line

    while IFS= read -r line; do
        line_count=$((line_count + 1))

        # Pure bash pattern match: no fork, no subshell
        if [[ "$line" == *ERROR* ]]; then
            error_count=$((error_count + 1))
        fi
    done < "$1"

    echo "Processed $line_count lines, found $error_count errors"
}

process_log /var/log/app.log
```

## Migration Guide

### Check Bash Version

```bash
#!/usr/bin/env bash

# Require Bash 5.3+
if ((BASH_VERSINFO[0] < 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] < 3))); then
    echo "Error: Bash 5.3+ required (found $BASH_VERSION)" >&2
    exit 1
fi
```

### Feature Detection

```bash
# Test for 5.3 features
has_bash_53_features() {
    # Older bash fails to parse ${ ...; } inside eval
    eval '_probe=${ echo "yes"; }' 2>/dev/null
}

if has_bash_53_features; then
    echo "Bash 5.3 features available"
else
    echo "Using legacy mode"
fi
```

Older bash versions cannot even *parse* `${ ...; }` or `${| ...; }`, so a script that uses them directly fails at parse time regardless of any runtime version check. Keep 5.3-only syntax inside `eval`, or in a separate file that is sourced only after the version check.

### Gradual Adoption

```bash
#!/usr/bin/env bash
set -euo pipefail

# Support both old and new bash
if ((BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3))); then
    # Bash 5.3+ path (in eval so older bash can still parse the file)
    eval 'result=${ compute_value; }'
else
    # Legacy path
    result=$(compute_value)
fi
```

## Best Practices

1. **Use `${ }` for shell-function calls in hot loops**
   ```bash
   for item in "${large_array[@]}"; do
       processed=${ transform "$item"; }
   done
   ```

2. **Use `${| }` with functions that set REPLY**
   ```bash
   file_hash() { REPLY=${ sha256sum < "$1"; }; REPLY=${REPLY%% *}; }

   hash=${| file_hash "$file"; }
   if [[ "$hash" == "$expected_hash" ]]; then
       echo "Valid"
   fi
   ```

3. **Enable readline for interactive scripts**
   ```bash
   read -E -p "Config file: " config
   ```

4. **Use `source -p` for modular libraries (one file per call)**
   ```bash
   source -p "$LIB_PATH" database.sh
   source -p "$LIB_PATH" logging.sh
   ```

5. **Use safe increments under `set -e`**: `x=$((x + 1))` or `((++x))`, not `((x++))`.

6. **Document version requirements**
   ```bash
   # Requires: Bash 5.3+ for ${ } / ${| } command substitution
   ```

## Compatibility Notes

### Bash 5.3 Availability

Bash 5.3 was released in July 2025; check the GNU bash page for the current release. Availability of 5.3 depends on your platform, so always check `bash --version` on the target system:

- **macOS**: system `/bin/bash` is 3.2; install a current bash with Homebrew (`brew install bash`)
- **Linux**: rolling distributions (e.g. Arch) and newer distribution releases ship 5.3; many current LTS releases still ship 5.2.x
- **Containers**: the official `bash` image on Docker Hub is tagged by version (e.g. `bash:5.3`)

### Fallback Pattern

```bash
#!/usr/bin/env bash
set -euo pipefail

# Detect bash version
readonly BASH_53_PLUS=$((BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 3)))

process_items() {
    local item result
    for item in "$@"; do
        if ((BASH_53_PLUS)); then
            eval 'result=${ transform "$item"; }'  # Fast path (eval: parseable by old bash)
        else
            result=$(transform "$item")            # Compatible path
        fi
        echo "$result"
    done
}
```

## Real-World Examples

### Fast Log Parser

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse log file without forking per line
parse_log() {
    local file="$1"
    local stats_errors=0
    local stats_warnings=0
    local stats_lines=0
    local line

    while IFS= read -r line; do
        stats_lines=$((stats_lines + 1))

        # Pattern matching in bash itself: no grep, no subshell
        case "$line" in
            *ERROR*) stats_errors=$((stats_errors + 1)) ;;
            *WARN*)  stats_warnings=$((stats_warnings + 1)) ;;
        esac
    done < "$file"

    echo "Lines: $stats_lines, Errors: $stats_errors, Warnings: $stats_warnings"
}

parse_log /var/log/application.log
```

### Interactive Configuration

```bash
#!/usr/bin/env bash
set -euo pipefail

# Returns its verdict in REPLY instead of on stdout
check_dir() {
    if [[ -d "$1" ]]; then REPLY="valid"; else REPLY="invalid"; fi
}

# Interactive setup with readline
setup_config() {
    echo "Configuration Setup"
    echo "==================="

    # Tab completion for paths
    read -E -p "Data directory: " data_dir
    read -E -p "Config file: " config_file

    # Validate (no fork; stdout is not captured)
    local status
    status=${| check_dir "$data_dir"; }

    if [[ "$status" == "valid" ]]; then
        echo "DATA_DIR=$data_dir" > config.env
        echo "CONFIG_FILE=$config_file" >> config.env
        echo "Configuration saved"
    else
        echo "Error: invalid directory: $data_dir" >&2
        return 1
    fi
}

setup_config
```

## Resources

- [Bash 5.3 Release Announcement](https://lists.gnu.org/archive/html/bash-announce/2025-07/msg00000.html)
- [Bash Manual - Command Substitution](https://www.gnu.org/software/bash/manual/html_node/Command-Substitution.html)
- [ShellCheck Releases](https://github.com/koalaman/shellcheck/releases)
