# Security-First Bash Scripting

## Overview

Missing input validation is one of the most common ways shell automation gets exploited. This reference provides mandatory security patterns.

## Contents

- [Critical Security Patterns](#critical-security-patterns)
- [Security Checklist](#security-checklist)
- [Automated Security Scanning](#automated-security-scanning)
- [Real-World Secure Script Template](#real-world-secure-script-template)
- [Compliance Standards](#compliance-standards)
- [Resources](#resources)

## Critical Security Patterns

### 1. Input Validation (Non-Negotiable)

**Every input MUST be validated before use:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# REQUIRED: Validate all inputs
validate_input() {
    local input="$1"
    local pattern="$2"
    local max_length="${3:-255}"

    # Check empty
    if [[ -z "$input" ]]; then
        echo "Error: Input required" >&2
        return 1
    fi

    # Check pattern
    if [[ ! "$input" =~ $pattern ]]; then
        echo "Error: Invalid format" >&2
        return 1
    fi

    # Check length
    if [[ ${#input} -gt $max_length ]]; then
        echo "Error: Input too long (max $max_length)" >&2
        return 1
    fi

    return 0
}

# Usage
read -r user_input
if validate_input "$user_input" '^[a-zA-Z0-9_-]+$' 50; then
    process "$user_input"
else
    exit 1
fi
```

### 2. Command Injection Prevention

**NEVER use eval or dynamic execution with user input:**

```bash
# DANGEROUS - Command injection vulnerability
user_input="$(cat user_file.txt)"
eval "$user_input"  # NEVER DO THIS

# DANGEROUS - Indirect command injection
grep "$user_pattern" file.txt  # If pattern is "-e /etc/passwd"

# SAFE - Pass the pattern with -e and end options with --
grep -e "$user_pattern" -- file.txt

# NOT ENOUGH - Arrays prevent word splitting, not option injection:
# a pattern like "-f/etc/shadow" is still parsed as an option here
grep_args=("$user_pattern" "file.txt")
grep "${grep_args[@]}"

# SAFE - Arrays plus -e/-- (build argument lists this way)
grep_args=(-e "$user_pattern" -- "file.txt")
grep "${grep_args[@]}"

# SAFE - Validate before use
if [[ "$user_pattern" =~ ^[a-zA-Z0-9]+$ ]]; then
    grep "$user_pattern" file.txt
fi
```

### 3. Path Traversal Prevention

**Sanitize and validate ALL file paths:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Reject (never strip) path traversal. Stripping "../" is bypassable:
# "....//" collapses to "../" after one pass, and a trailing ".." survives.
reject_traversal() {
    local path="$1"

    [[ -n "$path" ]] || return 1
    [[ "$path" != /* ]] || return 1            # absolute paths not allowed
    [[ "/$path/" != */../* ]] || return 1      # any ".." component
    [[ "$path" != *$'\n'* ]] || return 1       # no embedded newlines

    return 0
}

# Validate path is within allowed directory
is_safe_path() {
    local file_path="$1"
    local base_dir="$2"

    # Resolve to absolute paths
    local real_path real_base
    real_path=$(readlink -f "$file_path" 2>/dev/null) || return 1
    real_base=$(readlink -f "$base_dir" 2>/dev/null) || return 1

    # Check path starts with base
    [[ "$real_path" == "$real_base"/* ]]
}

# Usage: reject bad input, then confirm the resolved path stays inside the base
# (is_safe_path resolves symlinks, so it also catches symlink escapes)
if reject_traversal "$user_input" &&
   is_safe_path "/var/app/uploads/$user_input" "/var/app/uploads"; then
    cat -- "/var/app/uploads/$user_input"
else
    echo "Error: Access denied" >&2
    exit 1
fi
```

### 4. Secure Temporary Files

**Never use predictable temp file names:**

```bash
# DANGEROUS - Race condition vulnerability
temp_file="/tmp/myapp.tmp"
echo "data" > "$temp_file"  # Can be symlinked by attacker

# DANGEROUS - Predictable name
temp_file="/tmp/myapp-$$.tmp"  # PID can be guessed

# SAFE - Use mktemp
temp_file=$(mktemp)
chmod 600 "$temp_file"  # Owner-only permissions
echo "data" > "$temp_file"

# SAFE - Automatic cleanup: ONE cleanup function for every temp path,
# registered on EXIT. INT/TERM only exit (with the conventional status),
# which then triggers the EXIT trap. Putting rm directly on INT/TERM without
# exiting would delete the file and let the script keep running; and a
# second `trap ... EXIT` silently replaces the first.
TEMP_FILE=$(mktemp)                # mktemp creates files mode 600
TEMP_DIR=$(mktemp -d)              # and directories mode 700
readonly TEMP_FILE TEMP_DIR

cleanup() {
    rm -f -- "$TEMP_FILE"
    rm -rf -- "$TEMP_DIR"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
```

### 5. Secrets Management

**NEVER hardcode secrets or expose them:**

```bash
# DANGEROUS - Hardcoded secrets
DB_PASSWORD="supersecret123"

# DANGEROUS - Secrets in environment (visible in ps)
export DB_PASSWORD="supersecret123"

# SAFE - Read from secure file
# (Check permissions rather than chmod: secret mounts are often read-only,
# and a failing chmod would abort the script under set -e.)
if [[ -f /run/secrets/db_password ]]; then
    perms=$(stat -c '%a' /run/secrets/db_password)   # GNU stat; BSD/macOS: stat -f '%Lp'
    if [[ "$perms" != [0-7]00 ]]; then
        echo "Warning: secret file is group/world accessible ($perms)" >&2
    fi
    DB_PASSWORD=$(< /run/secrets/db_password)
else
    echo "Error: Secret not found" >&2
    exit 1
fi

# SAFE - Use cloud secret managers
get_secret() {
    local secret_name="$1"

    # AWS Secrets Manager
    aws secretsmanager get-secret-value \
        --secret-id "$secret_name" \
        --query SecretString \
        --output text
}

DB_PASSWORD=$(get_secret "production/database/password")

# SAFE - Prompt for sensitive data (no echo)
read -rsp "Enter password: " password
echo  # Newline after password
```

### 6. Privilege Management

**Follow least privilege principle:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Pick ONE policy for root at the top of the script.

# Option A: refuse to run as root
# if [[ $EUID -eq 0 ]]; then
#     echo "Error: Do not run as root" >&2
#     exit 1
# fi

# Option B: if started as root, re-exec as an unprivileged user.
# The script's own arguments must be passed in explicitly: inside a
# function, "$@" would be the function's arguments, not the script's.
drop_privileges() {
    local target_user="$1"
    shift

    if [[ $EUID -eq 0 ]]; then
        echo "Dropping privileges to $target_user" >&2
        exec sudo -u "$target_user" -- "$0" "$@"
    fi
}

drop_privileges "appuser" "$@"

# From here on the script runs as a non-root user.

# Run one specific command with elevated privileges, minimal scope
run_privileged() {
    sudo --non-interactive -- "$@"
}

# Usage
run_privileged /usr/bin/systemctl restart myapp.service
```

### 7. Environment Variable Sanitization

**Clean environment before executing:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Clean environment
clean_environment() {
    # Unset dangerous variables
    unset IFS
    unset CDPATH
    unset GLOBIGNORE

    # Set safe PATH (absolute paths only)
    export PATH="/usr/local/bin:/usr/bin:/bin"

    # Set safe IFS
    IFS=$'\n\t'
}

# Execute command in clean environment
exec_clean() {
    env -i \
        HOME="$HOME" \
        USER="$USER" \
        PATH="/usr/local/bin:/usr/bin:/bin" \
        "$@"
}

# Usage
clean_environment
exec_clean /usr/local/bin/myapp
```

### 8. Absolute Path Usage

**Use absolute paths or a known-safe PATH to prevent PATH hijacking:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# DANGEROUS - Resolved through the caller's (possibly attacker-controlled) PATH
curl https://example.com/data
jq '.items[]' data.json

# SAFE - Absolute paths
/usr/bin/curl https://example.com/data
/usr/bin/jq '.items[]' data.json

# SAFE - Reset PATH to trusted system directories FIRST, then resolve.
# (command -v alone searches the inherited PATH, so on its own it does
# not protect against hijacking.)
PATH=/usr/local/bin:/usr/bin:/bin
export PATH
CURL=$(command -v curl) || { echo "curl not found" >&2; exit 1; }
"$CURL" https://example.com/data
```

**Why This Matters:**
- Prevents malicious binaries in user PATH
- Standard practice in enterprise environments
- Required for security-sensitive scripts

### 9. Keeping Secrets Out of History, Process Lists, and Logs

Shell history only applies to **interactive** shells. In an interactive
session you can keep credential commands out of history:

```bash
# Interactive shell / ~/.bashrc only - no effect inside scripts
HISTIGNORE="*password*:*secret*:*token*"   # skip matching commands
HISTCONTROL=ignorespace                     # skip commands starting with a space
unset HISTFILE                              # don't save this session's history
```

Non-interactive scripts don't record history at all. Their leak paths are
**command-line arguments** (visible to every user via `ps` and
`/proc/<pid>/cmdline`), **exported environment variables** (readable via
`/proc/<pid>/environ` by the same user and root), **logs**, and **`set -x`
traces**:

```bash
#!/usr/bin/env bash
set -euo pipefail

read -rsp "Enter database password: " db_password
echo

# DANGEROUS - password visible in the process list
# /usr/bin/mysql -p"$db_password" -e "SELECT 1"

# SAFE - pass credentials through a private option file, not argv
# (MYSQL_PWD also works but is deprecated by MySQL and lands in the environment)
{ set +x; } 2>/dev/null                 # never trace while secrets are in use
cnf=$(mktemp)                           # created mode 600
trap 'rm -f -- "$cnf"' EXIT
printf '[client]\npassword=%s\n' "$db_password" > "$cnf"
/usr/bin/mysql --defaults-extra-file="$cnf" -e "SELECT 1"
rm -f -- "$cnf"

unset db_password
```

## Security Checklist

Every script MUST pass these checks:

### Input Validation
- [ ] All user inputs validated with regex patterns
- [ ] Maximum length enforced on all inputs
- [ ] Empty/null inputs rejected
- [ ] Special characters escaped or rejected

### Command Safety
- [ ] No eval with user input
- [ ] No dynamic variable names from user input
- [ ] All command arguments use -- separator
- [ ] Arrays used instead of string concatenation

### File Operations
- [ ] All paths validated against directory traversal
- [ ] Temp files created with mktemp
- [ ] File permissions set restrictively (600/700)
- [ ] Cleanup handlers registered (trap EXIT)

### Secrets
- [ ] No hardcoded passwords/keys/tokens
- [ ] Secrets read from secure storage
- [ ] Secrets never logged or printed
- [ ] Secrets cleared from memory when done

### Privileges
- [ ] Runs with minimum required privileges
- [ ] Root execution rejected unless necessary
- [ ] Privilege drops implemented where needed
- [ ] Sudo scope minimized

### Error Handling
- [ ] set -euo pipefail enabled
- [ ] All errors logged to stderr
- [ ] Sensitive data not exposed in errors
- [ ] Exit codes meaningful

## Automated Security Scanning

### ShellCheck Integration

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  shellcheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: ShellCheck
        run: |
          # Default severity (style and up). Don't use --severity=error:
          # it hides lower-severity findings such as SC2086 (unquoted expansion), which
          # are exactly the injection-relevant findings.
          find . -name "*.sh" -exec shellcheck \
            --enable=all \
            {} +
```

### Custom Security Linting

```bash
#!/usr/bin/env bash
# security-lint.sh - Check scripts for security issues

set -euo pipefail

lint_script() {
    local script="$1"
    local issues=0

    echo "Checking: $script"

    # Check for eval
    if grep -n "eval" "$script"; then
        echo "  FAIL: Found eval (command injection risk)"
        ((++issues))
    fi

    # Check for hardcoded secrets
    if grep -nE "(password|secret|token|key)\s*=\s*['\"][^'\"]+['\"]" "$script"; then
        echo "  FAIL: Found hardcoded secrets"
        ((++issues))
    fi

    # Check for predictable temp files
    if grep -n "/tmp/[a-zA-Z0-9_-]*\\.tmp" "$script"; then
        echo "  FAIL: Found predictable temp file"
        ((++issues))
    fi

    # Check for unquoted variables
    if grep -nE '\$[A-Z_]+[^"]' "$script"; then
        echo "  WARN: Found unquoted variables"
        ((++issues))
    fi

    if ((issues == 0)); then
        echo "  OK: No security issues found"
    fi

    return "$issues"
}

# Scan all scripts
total_issues=0
while IFS= read -r -d '' script; do
    lint_script "$script" || ((++total_issues))
done < <(find . -name "*.sh" -type f -print0)

if ((total_issues > 0)); then
    echo "FAIL: Found security issues in $total_issues scripts"
    exit 1
else
    echo "OK: All scripts passed security checks"
fi
```

## Real-World Secure Script Template

```bash
#!/usr/bin/env bash
#
# Secure Script Template
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC2034  # available to your logic below
readonly SCRIPT_DIR
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_NAME

# Security: Reject root execution
if [[ $EUID -eq 0 ]]; then
    echo "Error: Do not run as root" >&2
    exit 1
fi

# Security: Clean environment
export PATH="/usr/local/bin:/usr/bin:/bin"
unset CDPATH GLOBIGNORE

# Security: Secure temp file
TEMP_FILE=$(mktemp)                # created mode 600
readonly TEMP_FILE
cleanup() { rm -f -- "$TEMP_FILE"; }
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Validate input
validate_input() {
    local input="$1"

    if [[ -z "$input" ]]; then
        echo "Error: Input required" >&2
        return 1
    fi

    if [[ ! "$input" =~ ^[a-zA-Z0-9_/-]+$ ]]; then
        echo "Error: Invalid characters in input" >&2
        return 1
    fi

    if [[ ${#input} -gt 255 ]]; then
        echo "Error: Input too long" >&2
        return 1
    fi

    return 0
}

# Reject (never strip) path traversal - see "Path Traversal Prevention"
reject_traversal() {
    local path="$1"

    [[ -n "$path" ]] || return 1
    [[ "$path" != /* ]] || return 1            # absolute paths not allowed
    [[ "/$path/" != */../* ]] || return 1      # any ".." component
    [[ "$path" != *$'\n'* ]] || return 1       # no embedded newlines

    return 0
}

# Confirm the resolved path (symlinks followed) stays inside base_dir
is_safe_path() {
    local file_path="$1"
    local base_dir="$2"
    local real_path real_base

    real_path=$(readlink -f "$file_path" 2>/dev/null) || return 1
    real_base=$(readlink -f "$base_dir" 2>/dev/null) || return 1

    [[ "$real_path" == "$real_base"/* ]]
}

readonly BASE_DIR="/var/app/data"

# Main function
main() {
    local user_input="${1:-}"

    # Validate
    if ! validate_input "$user_input"; then
        exit 1
    fi

    # Reject traversal, then confirm the resolved path stays in BASE_DIR
    if ! reject_traversal "$user_input" ||
       ! is_safe_path "$BASE_DIR/$user_input" "$BASE_DIR"; then
        echo "$SCRIPT_NAME: Error: Access denied" >&2
        exit 1
    fi
    local safe_path="$BASE_DIR/$user_input"

    # Process safely
    echo "Processing: $safe_path"
    # ... your logic here ...
}

main "$@"
```

## Compliance Standards

### CIS Benchmarks
- Use ShellCheck for automated compliance
- Implement input validation on all user data
- Secure temporary file handling
- Least privilege execution

### NIST Guidelines
- Strong input validation (NIST SP 800-53)
- Secure coding practices
- Logging and monitoring
- Access control enforcement

### OWASP Top 10
- A03: Injection - Prevent command injection
- A01: Broken Access Control - Path validation
- A02: Cryptographic Failures - Secure secrets

## Resources

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [ShellCheck Security Rules](https://www.shellcheck.net/wiki/)
- [NIST SP 800-53](https://csrc.nist.gov/publications/detail/sp/800-53/rev-5/final)
