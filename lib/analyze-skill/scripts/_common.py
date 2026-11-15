"""Shared helpers for the analyze-skill checks. Not a CLI.

Every check imports this module from its own directory (never from the target
skill), so walking, reading, frontmatter parsing, redaction, and escaping
behave identically across inventory, lint, scan, and appendix generation.
All functions are static: nothing here executes or imports target content.
"""
import os
import bisect
import re
import stat
import sys

SKILL_ROOT = os.path.realpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

# Vendored/cache dirs: listed with file counts, not walked by inventory/lint.
# scan_security walks them anyway (except .git internals) so payloads cannot hide there.
SKIP_DIRS = {".git", "__pycache__", "node_modules", ".venv", "venv", ".mypy_cache", ".pytest_cache", ".tox"}
MAX_READ = 2_000_000          # bytes read per ordinary file
MAX_READ_CODE = 5_000_000     # bytes read for scripts and referenced files
LARGE_FILE = 100_000          # bytes; large non-code files are omitted from the verbatim Appendix
MAX_FRONTMATTER = 16_000      # bytes; larger frontmatter is rejected before YAML parsing
MAX_QUOTE = 500_000           # bytes; larger files are listed, not quoted, even when code
QUOTE_FULL_MAX = 40_000       # bytes; larger quoted files show their first 300 and last 100 lines
MAX_VENDORED_FILES = 2_000    # files scanned per vendored dir before giving up
GENERATED_NAMES = {"package-lock.json", "yarn.lock", "pnpm-lock.yaml", "poetry.lock", "Pipfile.lock",
                   "uv.lock", "Cargo.lock", "composer.lock", "Gemfile.lock", "go.sum"}
GENERATED_SUFFIXES = (".min.js", ".min.css", ".map", ".pyc")
CODE_SUFFIXES = (".py", ".sh", ".bash", ".zsh", ".js", ".mjs", ".cjs", ".ts", ".rb", ".pl", ".php", ".ps1", ".lua")


def _char_class(ranges):
    """Build a regex character class from code-point ranges (no literal escapes in source)."""
    return "[" + "".join(re.escape(chr(a)) + ("-" + re.escape(chr(b)) if b != a else "") for a, b in ranges) + "]"


# Characters that render invisibly, reorder text, or drive terminals.
_INVISIBLE = [(0x00, 0x08), (0x0B, 0x0C), (0x0E, 0x1F), (0x7F, 0x9F), (0xAD, 0xAD), (0x034F, 0x034F),
              (0x061C, 0x061C), (0x115F, 0x1160), (0x17B4, 0x17B5), (0x180B, 0x180F), (0x200B, 0x200F),
              (0x2028, 0x202E),
              (0x2060, 0x2064), (0x2066, 0x206F), (0x3164, 0x3164), (0xFE00, 0xFE0F), (0xFEFF, 0xFEFF),
              (0x2800, 0x2800),  # Braille blank: renders as empty space but is not whitespace
              (0x0600, 0x0605), (0x06DD, 0x06DD), (0x070F, 0x070F), (0x110BD, 0x110BD), (0x13430, 0x1343F),
              (0x1BCA0, 0x1BCA3),  # other invisible format (Cf) characters
              (0xFFA0, 0xFFA0), (0xFFF9, 0xFFFB), (0x1D173, 0x1D17A), (0xE0000, 0xE007F), (0xE0100, 0xE01EF)]
INVISIBLE_RE = re.compile(_char_class(_INVISIBLE))
HIDDEN_CLASSES = {
    # Form feed (0x0C) is common in source files; it is escaped in output but not flagged.
    "control": re.compile(_char_class([(0x00, 0x08), (0x0B, 0x0B), (0x0E, 0x1F), (0x7F, 0x9F)])),
    "zero-width / filler": re.compile(_char_class([(0xAD, 0xAD), (0x034F, 0x034F), (0x115F, 0x1160),
                                                    (0x17B4, 0x17B5), (0x180B, 0x180F), (0x200B, 0x200D),
                                                    (0x2060, 0x2064),
                                                    (0x2800, 0x2800), (0x0600, 0x0605), (0x06DD, 0x06DD),
                                                    (0x070F, 0x070F), (0x110BD, 0x110BD), (0x13430, 0x1343F),
                                                    (0x1BCA0, 0x1BCA3),
                                                    (0x3164, 0x3164), (0xFEFF, 0xFEFF), (0xFFA0, 0xFFA0),
                                                    (0xFFF9, 0xFFFB), (0x1D173, 0x1D17A)])),
    "bidi / line-separator": re.compile(_char_class([(0x061C, 0x061C), (0x200E, 0x200F), (0x2028, 0x202E),
                                                      (0x2066, 0x206F)])),
    "unicode-tag": re.compile(_char_class([(0xE0000, 0xE007F)])),
}
VARIATION_RE = re.compile(_char_class([(0xFE00, 0xFE0F), (0xE0100, 0xE01EF)]))
EMOJI_RE = re.compile(_char_class([(0x2600, 0x27BF), (0x1F000, 0x1FAFF)]))
EMOJI_FE0F_RE = re.compile("(?<=" + _char_class([(0x2190, 0x2BFF), (0x1F000, 0x1FAFF), (0x00A9, 0x00AE), (0x23, 0x23), (0x2A, 0x2A), (0x30, 0x39)]) + ")[\ufe0e\ufe0f]")

_KEYWORDS = r"(?:password|passwd|passphrase|(?<=[_-])pass|(?<![A-Za-z0-9])pass(?![A-Za-z])|(?-i:(?<![A-Za-z0-9])pw(?![A-Za-z]))|(?<=[_-])pw(?![A-Za-z])|pwd|secret|client_secret|api[_-]?key|apikey|access[_-]?key|" \
            r"auth[_-]?token|access[_-]?token|refresh[_-]?token|token|private[_-]?key|credentials?|(?<=[_-])salt|(?<=\x22)auth(?=\x22)|" \
            r"(?-i:(?<=[A-Z0-9]_)KEY(?![a-z])))"  # ENCRYPTION_KEY, SIGNING_KEY (upper case only: not primary_key)
# A short unquoted value: not a word that describes a field, not a variable, path, call, or index.
_SHORT_VAL = (r"(?!(?:required|optional|none|null|nil|true|false|yes|no|string|str|int|text|secret|password|"
              r"token|your\w*|example\w*|changeme|placeholder|xxx+|n/a|tbd|todo|redacted|see|use|set|the|a|an|read|write|"
              r"await|new|this|self)\b)"
              r"(?!(?-i:[a-z]{1,20}\d{0,2}(?:_[a-z]{1,20}\d{0,2})+)\b(?![-.@/:]))"  # a lowercase snake_case variable (s3_credentials) is code
              r"(?![A-Za-z_]\w{0,60}\.\w)(?!\w{1,60}=)(?![$%{<(\[*'\"`#/~.])[^\s'\"`()\[\]{}]{4,200}")
SECRET_RULES = [
    ("SEC-KEY-1", re.compile(r"\b(AKIA|ASIA)[0-9A-Z]{16}\b"), "AWS access key id"),
    ("SEC-KEY-2", re.compile(r"\bgh[pousr]_[A-Za-z0-9]{30,}|\bgithub_pat_[A-Za-z0-9_]{22,}"), "GitHub token"),
    ("SEC-KEY-3", re.compile(r"\bsk-ant-[A-Za-z0-9_-]{20,}"), "Anthropic API key"),
    ("SEC-KEY-4", re.compile(r"\bsk-(?!ant-)[A-Za-z0-9_-]{32,}"), "OpenAI-style secret key"),
    ("SEC-KEY-5", re.compile(r"\bxox[abprs]-[A-Za-z0-9-]{10,}"), "Slack token"),
    ("SEC-KEY-6", re.compile(r"-----BEGIN [A-Z0-9 ]{0,40}PRIVATE KEY( BLOCK)?-----.{0,20000}?(?:-----END [A-Z0-9 ]{0,40}PRIVATE KEY"
                             r"(?: BLOCK)?-----|$)"), "private key block"),
    # key = "value", key: 'value', "key": "value", KEY=value - keyword anywhere in the key name (client_secret,
    # OPENAI_API_KEY). Values that are variables, placeholders, or obvious examples are skipped.
    ("SEC-KEY-7", re.compile(r"(?<![A-Za-z0-9])[A-Za-z0-9_.-]{0,1000}" + _KEYWORDS + r"[A-Za-z0-9_.-]{0,80}['\"]?\]?[ \t]{0,40}(?:=>|:=|[:=])[ \t]{0,40}"
                             r"(?:['\"](?![$%{<]|https?://|\*+['\"]|/[\w.-]{1,60}/[\w.-])(?!(?:your|example|changeme|placeholder|xxx|dummy|redacted)[^'\"\n]{0,40}['\"])"
                             r"(?!(?:my|test|none|null)(?:[-_]?(?:key|token|secret|password|pass|value))?['\"])"
                             r"(?!(?:same-origin|include|omit)['\"])"  # fetch()'s credentials option
                             r"[^'\"\s]{8,4000}['\"]|(?![$%{<(\[]|os\.|process\.|getenv|env\[|None|null|true|false)"
                             r"(?!https?://)(?![A-Z]{2,8}(?:-[A-Z]{1,8}){0,2}-\d{1,3}\b)"  # a rule ID (SEC-KEY-7) is a citation
                             r"(?!(?-i:[a-z]{1,20}\d{0,2}(?:_[a-z]{1,20}\d{0,2})+)(?:[\s,;)'\"]|$))"  # a snake_case variable is code
                             r"(?:[A-Za-z0-9+/=_.:@~-]{12,4000}(?=\s*(?:#.*)?$)|"
                             # mid-line (KEY=v && cmd, -H "X-Api-Key: v"): only a value mixing letters and digits
                             r"(?=[^\s'\"()\[\]{}]{0,199}\d)(?=[^\s'\"()\[\]{}]{0,199}[A-Za-z])(?![A-Za-z_]\w{0,60}\.\w)"
                             r"(?![^\s'\"()\[\]{}]{0,60}[:,][A-Za-z_]\w{0,30}=)"  # an option list (pass=1:stats=x.log) is not a value"
                             r"[^\s'\"$%{<(\[\])}][^\s'\"()\[\]{}]{7,199}"
                             r"(?=[\s\"';&|)\\]|$)))", re.I), "hardcoded credential"),
    # Short or spaced passwords in quotes (password = "<short>", "<several words>"); key names that
    # say password/passwd/secret/pwd only. Placeholders are skipped.
    ("SEC-KEY-17", re.compile(r"(?<![A-Za-z0-9])[A-Za-z0-9_.-]{0,1000}(?:password|passwd|secret|pwd)[A-Za-z0-9_.-]{0,80}"
                              r"['\"]?\]?[ \t]{0,40}(?:=>|:=|[:=])[ \t]{0,40}['\"](?![$%{<]|https?://|\*+['\"]|\.\.\.)"
                              r"(?!(?:your|my|the|a|an|example|changeme|placeholder|xxx|dummy|test|redacted|none|null|"
                              r"secret|password)\b)[^'\"\n]{6,4000}['\"]", re.I), "hardcoded password"),
    # Short or letters-only unquoted values under a key named ...PASSWORD/PASSWD/PWD/SECRET/TOKEN
    # (PGPASSWORD=<word>, password: <word>, ini-style password = <word>). Words that describe a field are
    # skipped. Shell style (no space before '=') takes no space after it: "pwd= text" is prose.
    ("SEC-KEY-18", re.compile(r"(?<![A-Za-z0-9])[A-Za-z0-9_.-]{0,1000}(?:password|passwd|pwd|secret|token)"
                              r"(?:=(?P<v1>" + _SHORT_VAL + r")(?=[\s;&|)]|$)"
                              # ini style (password = <word>): the value ends the line, so code (x = f(y)) is skipped
                              r"|[ \t]{1,40}:?=[ \t]{0,40}(?P<v3>" + _SHORT_VAL + r")(?=[ \t]*(?:#.*)?$)"
                              r"|[ \t]{0,40}:[ \t]{0,40}(?P<v2>" + _SHORT_VAL + r")(?=[ \t]*(?:#.*)?$))", re.I), "short password"),
    # A credential given on a command line: curl/wget -u user:pass, mysql -p<value>, sshpass -p <value>, or the
    # netrc "machine h login u password p" form. Variables ($PASS, ${X}, <placeholder>) are skipped.
    ("SEC-KEY-19", re.compile(r"(?:^|[\s'\"(])(?:-u|--user)[ =]['\"]?[A-Za-z0-9_.@+-]{2,64}:(?![$%{<*\\/])"
                              r"(?!(?:pass(?:word)?|passwd|pwd|secret|token|changeme|xxx+|\.\.\.)(?![\w.@+/-]))"
                              r"(?=[^\s'\"]{0,200}[A-Za-z])[^\s'\"]{4,200}"
                              r"|\b(?:mysql|mysqldump|mariadb|mysqladmin)\b[^\n]{0,200}?\s-p(?![$%{<\s'\"])[^\s'\"]{4,200}"
                              r"|\bsshpass\s+-p\s*['\"]?(?![$%{<])[^\s'\"]{4,200}"
                              r"|\bmachine\s+\S{1,200}\s+login\s+\S{1,200}\s+password\s+(?![$%{<])\S{4,200}"
                              # auth=("user", "pw") and HTTPBasicAuth("user", "pw"): the second string is the password
                              r"|(?:\bauth\s{0,3}=\s{0,3}\(|\b(?:HTTPBasicAuth|HTTPDigestAuth|BasicAuth)\s{0,3}\()\s{0,3}['\"][^'\"\n]{1,100}['\"]"
                              r"\s{0,3},\s{0,3}['\"](?![$%{<])(?!(?:pass(?:word)?|secret|changeme|xxx+|\.\.\.)['\"])[^'\"\n]{4,200}['\"]"),
     "credential on a command line"),
    # An unquoted passphrase of several lowercase words under a YAML-style password key ("password: correct horse
    # battery staple"). Words that make it prose ("enter your password") are skipped.
    ("SEC-KEY-20", re.compile(r"^\s*[A-Za-z0-9_.-]{0,60}(?:password|passwd|passphrase)\s*:\s+"
                              r"(?![^\n]{0,80}\b(?:your|the|enter|is|are|be|of|to|for|from|and|or|with|this|that|it|"
                              r"here|below|above|same|as|see|use|set|required|optional|user|users|account|field|value|"
                              r"string|none|null|true|false|password|secret|token)\b)"
                              r"[a-z]{3,12}(?: [a-z]{3,12}){1,5}[ \t]*$", re.I), "unquoted passphrase"),
    # <password>value</password>, <apiKey>value</apiKey> (XML config, Maven settings.xml)
    ("SEC-KEY-21", re.compile(r"<([A-Za-z0-9_.-]{0,60}" + _KEYWORDS + r"[A-Za-z0-9_.-]{0,40})>(?![$%{<])(?!(?:your|example|changeme|placeholder|xxx|value|secret|password|token)\w*<)"
                              r"[^<\s]{4,200}</\1>", re.I), "credential in a markup element"),
    ("SEC-KEY-8", re.compile(r"\b(Authorization|Proxy-Authorization)['\"]?\s{0,3}:\s{0,3}['\"]?(Bearer|Basic|Token)\s+[A-Za-z0-9._~+/=-]{12,4000}", re.I),
     "authorization header"),
    ("SEC-KEY-9", re.compile(r"\baws_(secret_access_key|session_token)[ \t]{0,40}=[ \t]{0,40}\S{16,}", re.I), "AWS credentials file entry"),
    ("SEC-KEY-10", re.compile(r"\bAIza[0-9A-Za-z_-]{35}\b"), "Google API key"),
    ("SEC-KEY-11", re.compile(r"\b[rs]k_live_[0-9A-Za-z]{20,}"), "Stripe live key"),
    ("SEC-KEY-12", re.compile(r"\bhf_[A-Za-z0-9]{30,}|\bnpm_[A-Za-z0-9]{36}\b"), "Hugging Face / npm token"),
    ("SEC-KEY-22", re.compile(r"\bglpat-[A-Za-z0-9_-]{20,}|\bhvs\.[A-Za-z0-9_-]{24,}|\bSG\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}"),
     "GitLab / Vault / SendGrid token"),
    ("SEC-KEY-13", re.compile(r"\beyJ[A-Za-z0-9_-]{10,1400}\.eyJ[A-Za-z0-9_-]{10,1400}\.[A-Za-z0-9_-]{10,1400}"), "JSON Web Token"),
    ("SEC-KEY-14", re.compile(r"\b[a-z][a-z0-9+.-]{1,20}://[^\s/:@'\"]{0,64}:[^\s/@'\"]{4,1000}@"), "credentials in a URL"),
    ("SEC-KEY-15", re.compile(r"--(?:token|api[-_]?key|password|secret|auth)(?:=|\s+)['\"]?(?![$<{])[A-Za-z0-9._~+/=:-]{8,4000}", re.I),
     "credential passed as a command-line flag"),
    ("SEC-KEY-16", re.compile(r"https://(?:hooks\.slack\.com/services|discord(?:app)?\.com/api/webhooks)/[A-Za-z0-9/_-]{10,}"),
     "webhook URL"),
]
MAX_SECRET_LINE = 20_000  # window size for the secret scan (long lines use overlapping windows)
MAX_TOTAL_SCAN = 100 * 1024 * 1024  # bytes the security scan reads across all files before it stops
CREDENTIAL_FILE_RE = re.compile(r"(^|/)(\.env([.\-_][\w.-]*)?|\.envrc|[^/]+\.env|\.htpasswd|token\.json|"
                                r"secrets?\.(json|ya?ml|toml|txt|ini|cfg|conf|properties)|passwords?\.\w+|env\.(?!md$|txt$)\w+|"
                                r"client_secret[^/]*\.json|"
                                r"[^/]*\.(pem|key|p8|p12|pfx|keystore|jks|ppk|kdbx|tfvars|tfstate)|"
                                r"\.?credentials(?![^/]*\.(?:md|markdown|txt)$)[^/]*|[^/]*service[-_]?account[^/]*\.json|kubeconfig[^/]*|"
                                r"id_(rsa|dsa|ecdsa|ed25519)(_sk)?(\.pub)?|\.netrc|\.npmrc|\.pypirc|\.pgpass|\.git-credentials|\.vault-token|\.s3cfg|"
                                r"\.dockercfg|\.terraformrc|\.docker/config\.json)$",
                                re.I)
PEM_BEGIN_RE = re.compile(r"-----BEGIN [A-Z0-9 ]{0,40}PRIVATE KEY( BLOCK)?-----")
PEM_END_RE = re.compile(r"-----END [A-Z0-9 ]{0,40}PRIVATE KEY( BLOCK)?-----")
# The line after an open BEGIN that starts a key body: base64 (bare, or 40+ characters behind a quote,
# comment, or concatenation prefix) or a PEM header.
PEM_BODY_RE = re.compile(r"^\s*(?:[A-Za-z0-9+/=]{16,}|Proc-Type:|DEK-Info:|Comment:)"
                         r"|^[\s\"'#/*>;,+(\[-]{0,12}(?:[A-Za-z0-9+/=]{40,}|Proc-Type:|DEK-Info:)")
JWT_HEAD_RE = re.compile(r"\beyJ[A-Za-z0-9_-]{10,1400}\.eyJ")
B64URL_RUN_RE = re.compile(r"[A-Za-z0-9_-]*")
PEM_MAX_BODY = 1000  # body lines hidden after a BEGIN with no END (a 16384-bit RSA key is ~200)
KEYWORD_RE = re.compile(_KEYWORDS, re.I)
KEYCHARS = frozenset("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_.-")
KEY_START = frozenset("\"',;&?{([|")  # characters that end one value and start the next key name
NONSPACE_RUN_RE = re.compile(r"\S{0,4200}")
KEY_SEP_RE = re.compile(r"[A-Za-z0-9_.-]{0,80}['\"]?\]?[ \t]{0,40}(?:=>|:=|[:=])[ \t]{0,40}(['\"])?")
QUOTE_RE = re.compile(r"['\"\n]")
LONG_VALUE_RE = re.compile(r"[^\s'\"`]*")
UNTERMINATED_RE = re.compile(r"((?<![A-Za-z0-9])[A-Za-z0-9_.-]{0,80}" + _KEYWORDS +
                             r"[A-Za-z0-9_.-]{0,80}['\"]?[ \t]{0,40}[:=][ \t]{0,40}['\"])[^'\"\[\n]{8,}$", re.I)

INTERPRETERS = (r"((?:/[\w.+-]{1,64}){1,12}/)?(python[0-9.]*|node|deno|bun|bash|sh|zsh|fish|ruby|perl|php|pwsh|powershell|uv run|uvx|"
                r"npx|bunx|pipx run|poetry run|pdm run|deno run|pytest|ipython|osascript|lua|Rscript|tsx|ts-node|"
                r"go run|cargo run|java|eval|source|exec|xargs)")
# Commands that can run arbitrary code or reach arbitrary data when given free arguments.
CODE_CAPABLE = r"((?:/[\w.+-]{1,64}){1,12}/)?(git|gh|npm|pnpm|yarn|make|cmake|find|env|xargs|docker|podman|kubectl|ssh|scp|" \
               r"curl|wget|awk|gawk|sed|tar|pip[0-9.]*|sudo|su|nohup|timeout|watch|open|xdg-open|rsync)"
MUTATING = r"((?:/[\w.+-]{1,64}){1,12}/)?(rm|rmdir|mv|cp|tee|chmod|chown|ln|truncate|dd|install)"
READING = r"((?:/[\w.+-]{1,64}){1,12}/)?(cat|head|tail|less|more|strings|xxd|od|base64|grep|egrep|fgrep|rg|ag|ack)"
_ARGS_WILDCARD = r"(\s+-\S+)*\s*[: ]\s*\*\s*\)$"
INTERP_WILDCARD_RE = re.compile(r"^Bash\(\s*" + INTERPRETERS + _ARGS_WILDCARD)
# Free arguments right after the command (or after a code-running subcommand) are what make it broad;
# "Bash(git status:*)" stays narrow.
CODE_WILDCARD_RE = re.compile(r"^Bash\(\s*" + CODE_CAPABLE + r"(\s+-\S+)*(\s+(run|exec|dlx|x|-c|-e|--exec|api))?\s*[: ]\s*\*\s*\)$")
MUTATING_WILDCARD_RE = re.compile(r"^Bash\(\s*" + MUTATING + r"\b.*\*\s*\)$")
WRAPPER_WILDCARD_RE = re.compile(r"^Bash\(\s*((?:/[\w.+-]{1,64}){1,12}/)?(uv run|uvx|poetry run|pdm run|pipx run|deno run|npx|bunx|"
                                 r"hatch run|rye run|conda run|command|builtin|env|xargs|nice|nohup|timeout|time|stdbuf|"
                                 r"ionice|chrt|setsid|doas|watch|sqlite3|psql|mysql|mongosh|redis-cli)(?![\w-]).*\*\s*\)$")
# (command/nice/timeout/... run any program; sqlite3 .shell, psql \!, mysql \! run shell commands.)
READING_WILDCARD_RE = re.compile(r"^Bash\(\s*" + READING + r"(?![\w-]).*\*\s*\)$")
RELATIVE_ENTRY_RE = re.compile(r"^Bash\(\s*" + INTERPRETERS + r"(\s+-\S+)*\s+[\"']?(\./)?(scripts|references|assets)/")
FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
SYSTEM_DIRS = ("/etc", "/private/etc", "/proc", "/sys", "/dev", "/usr", "/bin", "/sbin", "/boot", "/var/root", "/private/var/root",
               "/System", "/Library/Keychains")
SENSITIVE_DIRS = (".ssh", ".aws", ".gnupg", ".kube", ".docker", ".config/gcloud", ".password-store", "Library/Keychains",
                  ".config/gh", ".config/op", ".local/share/keyrings", ".azure", ".netrc")


# ---------------------------------------------------------------- targets

def resolve_target(path):
    """Accept a skill directory or a SKILL.md path. Return (skill_dir, skill_md_path)."""
    path = os.path.abspath(os.path.expanduser(path))  # a quoted '~/...' reaches us unexpanded
    if os.path.basename(path) == "SKILL.md" and not os.path.isdir(path):
        return os.path.dirname(path), path
    return path, os.path.join(path, "SKILL.md")


def folder_refusal(path):
    """Why a folder must not be read by the pre-approved scripts (home, system, or credential folder), or None."""
    real = os.path.realpath(path)
    home = os.path.realpath(os.path.expanduser("~"))
    if sys.platform in ("darwin", "win32"):  # case-insensitive file systems: ~/.SSH is ~/.ssh
        real, home = os.path.normcase(real).lower(), os.path.normcase(home).lower()
    homes = os.path.dirname(home)  # /home, /Users: another user's home is refused the same way as yours
    if homes == "/":  # HOME=/root (containers): / is not a folder of homes, so /skill stays allowed
        homes = None
    if real in ("/", home, "/root", "/var/root", "/private/var/root") or (homes and (real == homes or os.path.dirname(real) == homes)):
        return "refusing to analyze a home or root directory: " + real
    owner = real.split(os.sep)[len(homes.split(os.sep))] if homes and real.startswith(homes + os.sep) else None
    for base in {home, os.path.join(homes, owner) if owner else home}:
        for d in SENSITIVE_DIRS:
            sens = os.path.realpath(os.path.join(base, d))
            if sys.platform in ("darwin", "win32"):
                sens = os.path.normcase(sens).lower()
            if real == sens or real.startswith(sens + os.sep):
                return "refusing to analyze a sensitive directory: " + real
            if sens.startswith(real + os.sep):  # ~/.config holds ~/.config/gh: its files would be scanned and quoted
                return "refusing to analyze a folder that contains a credential folder ({}): {}".format(d, real)
    if any(real == d or real.startswith(d + os.sep) for d in
           (SYSTEM_DIRS if sys.platform not in ("darwin", "win32") else [x.lower() for x in SYSTEM_DIRS])):
        return "refusing to analyze a system directory: " + real
    return None


def validate_target(path):
    """Return an error string if path must not be analyzed by a pre-approved entry script, else None."""
    skill_dir, skill_md = resolve_target(path)
    if not os.path.isdir(skill_dir):
        return "not a skill directory or SKILL.md: " + path
    why = folder_refusal(skill_dir)
    if why:
        return why
    if path.startswith("-") or os.path.basename(path.rstrip(os.sep)).startswith("-"):
        return "refusing a path that starts with '-'"
    skill_md = os.path.join(skill_dir, "SKILL.md")
    if os.path.islink(skill_md) or not os.path.isfile(skill_md):
        return "no regular SKILL.md at the skill root: " + skill_dir
    return None


def inside(path, root):
    path, root = os.path.realpath(path), os.path.realpath(root)
    if sys.platform in ("darwin", "win32"):  # case-insensitive file systems
        path, root = os.path.normcase(path).lower(), os.path.normcase(root).lower()
    return path == root or path.startswith(root + os.sep)


# ---------------------------------------------------------------- walking

MAX_WALK_ENTRIES = 20_000


def cap_path(rel):
    """The folder a cap entry names: the root (".") is "./", any other folder keeps its own name."""
    return "./" if rel in (".", "") else rel + "/"


def walk(skill_dir, include_skipped=False):
    """Return sorted entries for everything under skill_dir without following links.

    kinds: file, symlink, dir-symlink, special (fifo/device/socket), unreadable,
    unreadable-dir, skipped-dir (vendored/cache dir, with 'file_count').
    """
    skill_dir = os.path.abspath(skill_dir)
    real_root = os.path.realpath(skill_dir)
    entries = []

    def onerror(exc):
        rel = _rel(getattr(exc, "filename", "") or skill_dir, skill_dir)
        entries.append({"path": rel + "/", "kind": "unreadable-dir", "error": str(exc.strerror or exc)})

    dirs_seen = 0
    for root, dirs, names in os.walk(skill_dir, followlinks=False, onerror=onerror):
        dirs_seen += 1
        if dirs_seen > MAX_WALK_ENTRIES:  # empty folders count too: a million nested empty folders is not walked
            entries.append({"path": cap_path(_rel(root, skill_dir)), "kind": "unreadable-dir",
                            "error": "listing capped at {} folders; later folders were not listed".format(MAX_WALK_ENTRIES)})
            break
        keep = []
        for d in sorted(dirs):
            if len(entries) >= MAX_WALK_ENTRIES:  # folder links count toward the cap too
                break
            full = os.path.join(root, d)
            rel = _rel(full, skill_dir)
            if os.path.islink(full):
                try:
                    entries.append(_link_entry(full, rel, real_root, "dir-symlink"))
                except OSError as exc:  # removed while walking
                    entries.append({"path": rel + "/", "kind": "unreadable", "error": str(exc.strerror or exc)})
            elif d == ".git" or (d in SKIP_DIRS and not include_skipped):
                entries.append({"path": rel + "/", "kind": "skipped-dir", "file_count": _count_files(full)})
            else:
                keep.append(d)
        dirs[:] = keep
        for n in sorted(names):
            full = os.path.join(root, n)
            rel = _rel(full, skill_dir)
            try:
                if os.path.islink(full):
                    entries.append(_link_entry(full, rel, real_root, "symlink"))
                    continue
                mode = os.lstat(full).st_mode
            except OSError as exc:
                entries.append({"path": rel, "kind": "unreadable", "error": str(exc.strerror or exc)})
                continue
            entries.append({"path": rel, "kind": "file" if stat.S_ISREG(mode) else "special"})
            if len(entries) >= MAX_WALK_ENTRIES:  # bound every check's per-file work on a huge tree
                break
        if len(entries) >= MAX_WALK_ENTRIES:
            entries.append({"path": cap_path(_rel(root, skill_dir)), "kind": "unreadable-dir",
                            "error": "listing capped at {} entries; later files were not listed or "
                                     "checked".format(MAX_WALK_ENTRIES)})
            break
    entries.sort(key=lambda e: e["path"])
    return entries


def _rel(full, root):
    return os.path.relpath(full, root).replace(os.sep, "/")


def _link_entry(full, rel, real_root, kind):
    resolved = os.path.realpath(full)
    inside_root = resolved == real_root or resolved.startswith(real_root + os.sep)
    return {"path": rel, "kind": kind, "symlink_target": excerpt(os.readlink(full), 300),
            "points_outside": not inside_root}


def _count_files(path, cap=100_000):
    n = 0
    for _, _, names in os.walk(path, followlinks=False):
        n += len(names)
        if n >= cap:
            break
    return n


def in_skipped_dir(rel):
    return any(part in SKIP_DIRS for part in rel.split("/")[:-1])


# ---------------------------------------------------------------- reading

def read_bytes(full, limit=MAX_READ):
    """Read at most limit bytes of a regular file without following links or blocking.

    Return (data, truncated). Raises OSError for non-regular files and links.
    """
    st = os.lstat(full)
    if not stat.S_ISREG(st.st_mode):
        raise OSError("not a regular file: " + full)
    flags = os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0) | getattr(os, "O_NONBLOCK", 0)
    fd = os.open(full, flags)
    fst = os.fstat(fd)  # the file opened must be the regular file checked above (no swap in between)
    if not stat.S_ISREG(fst.st_mode) or (fst.st_ino, fst.st_dev) != (st.st_ino, st.st_dev):
        os.close(fd)
        raise OSError("file changed while opening: " + full)
    with os.fdopen(fd, "rb") as fh:
        data = fh.read(limit + 1)
    return data[:limit], len(data) > limit


def to_text(data, truncated=False):
    """Classify bytes. Return (encoding, text): encoding is utf-8, nul-text, utf-16, or binary (text None).

    nul-text is valid UTF-8 containing NUL bytes: kept as text so the NULs get flagged and escaped
    instead of hiding the whole file as "binary".
    """
    if data[:2] in (b"\xff\xfe", b"\xfe\xff"):
        try:
            return "utf-16", data.decode("utf-16")
        except UnicodeDecodeError:
            pass
    for cut in ((0, 1, 2, 3) if truncated else (0,)):  # a cut at the read limit can split a multibyte char
        try:
            text = (data[:-cut] if cut else data).decode("utf-8")
            break
        except UnicodeDecodeError:
            text = None
    if text is None:
        return "binary", None
    # Valid UTF-8 is text even with NUL bytes: real binaries almost never decode cleanly,
    # and treating NUL-salted text as binary would hide it from every check.
    return ("nul-text" if "\x00" in text else "utf-8"), text


def is_credential_path(rel):
    """A credential-type file name that is not real code. Only a code suffix counts as code here, never the
    scripts/ location: scripts/.env is a credential file, scripts/id_sync.sh is a script."""
    return bool(CREDENTIAL_FILE_RE.search(rel)) and not rel.endswith(CODE_SUFFIXES)


def is_binary(data):
    return to_text(data, len(data) >= MAX_READ)[0] == "binary"  # a cut read may end mid-character


def decode(data):
    enc, text = to_text(data, len(data) >= MAX_READ)
    return text if text is not None else data.decode("utf-8", errors="replace")


def is_generated(rel):
    base = rel.rsplit("/", 1)[-1]
    return base in GENERATED_NAMES or base.endswith(GENERATED_SUFFIXES)


def is_code(rel):
    if rel.endswith(CODE_SUFFIXES):
        return True
    return rel.startswith("scripts/") and not rel.endswith((".md", ".txt", ".json", ".csv", ".yaml", ".yml"))


def quote_fence(text):
    """A backtick fence longer than any fence run inside text (CommonMark-safe)."""
    longest = 0
    for line in text.splitlines():
        m = FENCE_RE.match(line)
        if m and m.group(1)[0] == "`":
            longest = max(longest, len(m.group(1)))
    return "`" * max(3, longest + 1)


FENCE_OPEN_RE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")


def fenced_flags(lines):
    """Return (flags, unclosed): flags[i] is True where line i is inside, opens, or closes a fence.

    CommonMark rules: at most 3 spaces of indent, and a backtick fence's info string may not
    contain a backtick (```x``` on one line is inline code, not a fence).
    """
    flags, fence = [], None
    for line in lines:
        m = FENCE_OPEN_RE.match(line)
        if m and fence is None and m.group(1)[0] == "`" and "`" in m.group(2):
            m = None
        if m:
            run = m.group(1)
            if fence is None:
                fence = run
                flags.append(True)
                continue
            if run[0] == fence[0] and len(run) >= len(fence) and line.strip() == run:
                fence = None
                flags.append(True)
                continue
        flags.append(fence is not None)
    return flags, fence is not None


# ---------------------------------------------------------------- escaping and redaction

SURROGATE_RE = re.compile("[\ud800-\udfff]")  # a file name that is not valid UTF-8 (os.walk's surrogateescape)


def escape_invisible(s):
    s = SURROGATE_RE.sub(lambda m: "<U+%04X>" % ord(m.group(0)), s)  # never printable as UTF-8
    return INVISIBLE_RE.sub(lambda m: "<U+%04X>" % ord(m.group(0)), s)


def safe_cut(text, n):
    """text cut to n characters with every secret redacted first, so a cut never leaves a partial secret that no
    rule recognizes (a margin wider than any secret rule's match is redacted before the cut)."""
    head = text[:n + 4400]
    head = redact_text(head) if "\n" in head else redact(head, find_secrets(head))
    return head[:n]


def safe_stdout():
    """Entry scripts: a stray undecodable name must print escaped, never crash the output."""
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(errors="backslashreplace")
        except (AttributeError, ValueError):
            pass


def safe_name(s):
    """A path or name made safe for Markdown tables, code spans, and fences."""
    s = escape_invisible(s).replace("\n", "<LF>").replace("\r", "<CR>").replace("\t", "<TAB>")
    return s.replace("`", "'").replace("|", "\\|")


def md_cell(s):
    """Text made safe for a Markdown table cell: names escaped, HTML neutralized."""
    return safe_name(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


def find_secrets(line):
    """Return [(start, end, rule, description)] for secret matches anywhere in line.

    Long lines are scanned in overlapping 20,000-character windows, so cost stays linear and a
    secret past any single window is still found.
    """
    hits, seen = [], set()

    def keep(s, e, rule, desc):
        if (s, e, rule) not in seen:
            seen.add((s, e, rule))
            hits.append((s, e, rule, desc))

    # PEM keys: whole-line search, BEGIN to END (or to the end of the line), so no window cuts a key.
    if "-----BEGIN" in line:
        ends = [(e.start(), e.end()) for e in PEM_END_RE.finditer(line)]
        for m in PEM_BEGIN_RE.finditer(line):  # one pass over ENDs, bisected per BEGIN: linear
            k = bisect.bisect_left(ends, (m.end(), -1))
            keep(m.start(), ends[k][1] if k < len(ends) else len(line), "SEC-KEY-6", "private key block")
            if k >= len(ends):
                break  # no END after this BEGIN: one span to the end of the line covers the rest
    # JSON Web Tokens of any length: a bounded head (header + ".eyJ") found per start, then the payload and
    # signature runs extended by hand, each scanned once. A payload cut off at the end of the text (a cut
    # excerpt) still counts.
    if "eyJ" in line:
        for m in JWT_HEAD_RE.finditer(line):
            p = B64URL_RUN_RE.match(line, m.end()).end()
            if p == len(line) and p - m.start() >= 40:
                keep(m.start(), p, "SEC-KEY-13", "JSON Web Token")
            elif p - m.end() >= 7 and line[p:p + 1] == ".":
                q = B64URL_RUN_RE.match(line, p + 1).end()
                if q - p - 1 >= 10 or q == len(line):
                    keep(m.start(), q, "SEC-KEY-13", "JSON Web Token")
    step, overlap = MAX_SECRET_LINE, 4400  # every other rule matches at most ~4,300 chars
    for base in range(0, max(1, len(line)), step):
        off = max(0, base - overlap)
        window = line[off:base + step]
        for rule, rx, desc in SECRET_RULES:
            if rule == "SEC-KEY-6":
                continue
            if rule in ("SEC-KEY-7", "SEC-KEY-17", "SEC-KEY-18"):
                # No literal anchor: one anchored attempt at the start of each key name that holds a keyword,
                # skipping keywords inside a match already found, and keywords with no ':' or '=' close after them
                # (so a run of decoy keywords costs one cheap check each, never a match attempt).
                # After a failed attempt, later keywords in the same run of non-space text are tried only when
                # they start a new key (after a quote, comma, '&', ...), never when they sit inside a value: a
                # run of key=key=key= decoys costs one attempt, while {"token":"","password":"..."} and
                # grant_type=password&password=... still reach the real key.
                tried, last_end, fail_end = set(), -1, -1
                for k in KEYWORD_RE.finditer(window):
                    if k.start() < last_end:
                        continue
                    lo = k.start()
                    tail = window[k.end():k.end() + 130]
                    if ":" not in tail and "=" not in tail:
                        continue
                    # ASCII key characters only, as the rules match them: a non-ASCII prefix (contrase\u00f1a_db_password)
                    # ends the key name instead of defeating the match.
                    while lo > 0 and k.start() - lo < 1000 and window[lo - 1] in KEYCHARS:
                        lo -= 1
                    if lo < fail_end and lo > 0 and window[lo - 1] not in KEY_START:
                        continue
                    if lo in tried:
                        continue
                    tried.add(lo)
                    # Cheap gate: every rule here needs key, optional quote, ':' or '=', then a value; a quoted
                    # value needs 6+ characters before its closing quote (a run of "key":"" decoys stops here).
                    g = KEY_SEP_RE.match(window, k.end())
                    if not g or (g.group(1) and QUOTE_RE.search(window, g.end(), g.end() + 6)):
                        continue
                    m = rx.match(window, lo, min(len(window), k.end() + 4200))
                    if m:
                        keep(off + m.start(), off + m.end(), rule, desc)
                        last_end = m.end()
                    else:
                        fail_end = max(fail_end, NONSPACE_RUN_RE.match(window, k.end()).end())
                continue
            for m in rx.finditer(window):
                keep(off + m.start(), off + m.end(), rule, desc)
    # Values past the rules' length caps (a 4,001-char key, a 250-char token mid-line): a keyword key whose value
    # run is longer than any rule matches is hidden to the end of the run. One pass, each run measured once.
    if "=" in line or ":" in line:
        covered = sorted((s_, e_) for s_, e_, _r, _d in hits)
        skip_to = -1
        for k in KEYWORD_RE.finditer(line):
            if k.start() < skip_to:
                continue
            g = KEY_SEP_RE.match(line, k.end())
            if not g:
                continue
            v0 = g.end()
            if g.group(1):
                close = QUOTE_RE.search(line, v0)
                v1 = close.start() if close else len(line)
                long_run = v1 - v0 > 3990
            else:
                v1 = LONG_VALUE_RE.match(line, v0).end()
                long_run = v1 - v0 > 195
            skip_to = v1
            if long_run and not any(a <= k.start() < b and b >= v1 for a, b in covered):
                lo = k.start()
                while lo > 0 and k.start() - lo < 1000 and line[lo - 1] in KEYCHARS:
                    lo -= 1
                keep(lo, v1, "SEC-KEY-7", "hardcoded credential (value longer than the pattern limit)")
    return hits


# A key whose value starts on the next line: "export DB_PASSWORD=\", "db_password: |", "PASSWORD = (", or a bare
# "password:" with the value indented below it.
DANGLING_KEY_RE = re.compile(r"(?<![A-Za-z0-9])[A-Za-z0-9_.-]{0,80}" + _KEYWORDS + r"[A-Za-z0-9_.-]{0,80}['\"]?\]?[ \t]{0,40}"
                             r"(?:=>|:=|[:=])[ \t]{0,40}(?:\\|[|>][-+]?\d?|\(|['\"]\\)?[ \t]*$", re.I)
# The value line: one token (optionally quoted, with a trailing comma, ')' or '\'), mixing letters and digits, that is
# not itself a key (min_length: 8) or a variable ($X, ${X}, <x>).
SPLIT_VALUE_RE = re.compile(r"^[ \t]*['\"]?(?![$%{<])(?!\w{1,60}[ \t]*[:=](?:[ \t]|$))(?=[^\s'\"]{0,400}\d)"
                            r"(?=[^\s'\"]{0,400}[A-Za-z])([^\s'\",)\\]{8,400})['\"]?[ \t]*[,)]?[ \t]*\\?[ \t]*$")


def split_secrets(lines):
    """Return {line_index: [(start, end, rule, desc)]} for credential values that start on the line after their key.

    A block scalar ("key: |") hides each following value line, up to 20, while they keep the shape.
    """
    out = {}
    for i, line in enumerate(lines):
        # A value cut by a backslash right after it (KEY=Zx81\ + newline + rest): bash joins the two halves with no
        # space, so judge the joined text and hide the part of each following line that continues the secret.
        k = i
        while k + 1 < len(lines) and k - i < 5 and re.search(r"\S\\[ \t]*$", lines[k][-200:]):
            head = "".join(re.sub(r"\\[ \t]*$", "", x.rstrip()) if j < k - i + 1 else x
                           for j, x in enumerate(lines[i:k + 1]))
            nxt = lines[k + 1]
            lead = len(nxt) - len(nxt.lstrip())
            cut = len(head)
            joined = head + nxt[lead:lead + 4400]
            if not KEYWORD_RE.search(joined[max(0, cut - 400):cut]) and not re.search(r"[A-Za-z0-9]{8}$", head):
                break
            spans = [(a, b, r, d) for a, b, r, d in find_secrets(joined) if a < cut < b]
            if not spans:
                break
            end = max(b for _a, b, _r, _d in spans) - cut
            out.setdefault(k + 1, []).append((lead, lead + end, "SEC-KEY-7", "hardcoded credential (value continued "
                                                                            "on the line after its key)"))
            k += 1
        tail = line[-200:].rstrip()
        if not tail or tail[-1] not in "\\|>(:=-+0123456789" or not KEYWORD_RE.search(line[-400:]):
            continue
        if not DANGLING_KEY_RE.search(line[-400:]):
            continue
        block = tail[-1] in "|>-+0123456789"
        j = i + 1
        while j < len(lines) and not lines[j].strip() and j - i < 3:
            j += 1
        for k in range(j, min(len(lines), j + (2000 if block else 1))):  # a whole key block (an SSH key) hides
            m = SPLIT_VALUE_RE.match(lines[k][:500])
            if not m:
                break
            out.setdefault(k, []).append((m.start(1), m.end(1), "SEC-KEY-7", "hardcoded credential (value on the "
                                                                              "line after its key)"))
    return out


def redact_text(text):
    """Redact secrets in multi-line text, line by line, including whole PEM key bodies."""
    return "\n".join(sanitize_lines(text.split("\n"))[0])


def redact(line, hits, keep=4):
    """Redact merged secret spans. Overlapping spans are merged before replacing."""
    merged = []
    # A value on the line after its key starts with secret text, not a key name: show none of it.
    bare = {s for s, e, r, d in hits if "the line after its key" in d}
    for s, e, r in sorted((s, e, r) for s, e, r, _ in hits):
        if merged and s <= merged[-1][1]:
            ps, pe, pr = merged[-1]
            merged[-1] = (ps, max(pe, e), pr if r in pr.split("+") else pr + "+" + r)
        else:
            merged.append((s, e, r))
    for s, e, r in reversed(merged):
        k = 0 if s in bare else min(keep, e - s)
        line = line[:s + k] + "[REDACTED:" + r + "]" + line[e:]
    return line


def sanitize_lines(lines):
    """Redact secrets (including whole PEM key bodies) and escape invisible chars.

    Return (new_lines, redacted_line_numbers_with_rules, escaped_line_numbers).
    """
    out, redacted, escaped, in_pem, pem_lines = [], [], [], False, 0
    split = split_secrets(lines)
    for ln, line in enumerate(lines, 1):
        nxt = lines[ln] if ln < len(lines) else ""
        if in_pem:
            end = PEM_END_RE.search(line)
            pem_lines += 1
            if not end and pem_lines > PEM_MAX_BODY:  # no END in PEM_MAX_BODY lines: stop hiding text
                in_pem = False
                out.append("[REDACTED:SEC-KEY-6 private key body; no END line within {} lines, "
                           "later lines shown]".format(PEM_MAX_BODY))
                redacted.append((ln, "SEC-KEY-6"))
                continue
            if not end:
                out.append("[REDACTED:SEC-KEY-6 private key body]")
                redacted.append((ln, "SEC-KEY-6"))
                continue
            else:  # END on this line
                # Body text before END is key material; the rest of the line is checked like any other.
                line = "[REDACTED:SEC-KEY-6 private key body]" + line[end.start():]
                redacted.append((ln, "SEC-KEY-6"))
        begins = [m.end() for m in PEM_BEGIN_RE.finditer(line)]
        ends = [m.end() for m in PEM_END_RE.finditer(line)]
        # A key stays open past this line when its last BEGIN has no END after it, whatever precedes the
        # marker (KEY = """, export X=", # ). A prose mention is told apart by what follows: key material
        # (base64, or a Proc-Type header) on the next line, bare or behind a prefix that quotes, comments,
        # or concatenates it ("...\n" +, # , // , > , * ).
        if bool(begins) and (not ends or begins[-1] > ends[-1]) and PEM_BODY_RE.match(nxt[:400]):
            in_pem, pem_lines = True, 0
        else:
            in_pem = False
        hits = find_secrets(line) + split.get(ln - 1, [])
        if hits:
            line = redact(line, hits)
            redacted.append((ln, "+".join(sorted({h[2] for h in hits}))))
        if INVISIBLE_RE.search(line.replace("\t", "")):
            line = escape_invisible(line)
            escaped.append(ln)
        out.append(line)
    return out, redacted, escaped


_CHUNK_RE = re.compile(r"\S{1,4096}")


def _collapse_head(line, n):
    """Return " ".join(line.split())[:n] while reading only as much of line as that needs."""
    out, size, last = [], 0, -1
    for m in _CHUNK_RE.finditer(line):
        if out:
            if m.start() > last:  # whitespace between chunks
                out.append(" ")
                size += 1
        out.append(m.group())
        size += len(m.group())
        last = m.end()
        if size >= n:
            break
    return "".join(out)[:n]


def excerpt(line, limit=140):
    """One-line, invisible-escaped, secret-redacted excerpt safe for a report table.

    Only the head that can reach the output (plus a margin wider than any secret pattern) is
    whitespace-collapsed and scanned: the cost is bounded by that head, not by the line's length.
    """
    # Redact before cutting: a secret that starts inside the shown part is matched whole (any secret rule
    # matches at most ~4,300 characters), so a cut never turns it into an unrecognizable tail.
    if "\n" in line:  # any later line could be joined into view by the whitespace collapse: redact per line
        # Multi-line text (a comment body, joined lines): redact each line first, while line-anchored rules
        # (a value that ends its line, a "password:" line start) can still see their anchors. Whole lines are
        # kept (blank ones skipped, since they collapse away), so no cut lands inside a secret however many
        # blank lines come before it.
        keep, size, pos, budget = [], 0, 0, limit + 4400
        for _ in range(20000):
            end = line.find("\n", pos)
            piece = line[pos:] if end < 0 else line[pos:end]
            if piece.strip():
                piece = _collapse_head(piece, budget)  # collapse before cutting: no run of spaces can pull a cut
                keep.append(piece)                     # secret into view
                size += len(piece)
            if end < 0 or size >= budget:
                break
            pos = end + 1
        line = redact_text("\n".join(keep))
    line = _collapse_head(line, limit + 4400)
    hits = find_secrets(line)
    if hits:
        line = redact(line, hits)
    line = " ".join(escape_invisible(line).split())
    out = line if len(line) <= limit else line[: limit - 3] + "..."
    # A key name with an unterminated quoted value ("API_TOKEN="Zx81...): hide the value to the end.
    return UNTERMINATED_RE.sub(lambda m: m.group(1) + "[REDACTED:unterminated value]", out)


def scrub(obj, depth=0, budget=None):
    """Recursively redact and escape strings in parsed data (e.g. frontmatter) for output.

    A shared node budget bounds the walk, so a structure that reuses nodes cannot blow up the output.
    """
    budget = budget if budget is not None else [10000]
    budget[0] -= 1
    if depth > 20 or budget[0] < 0:
        return "<nested too deep>" if depth > 20 else "<too many nodes>"
    if isinstance(obj, str):
        obj = obj[:20000]
        if "\n" in obj:  # a block scalar: redact line by line so line-anchored rules still see their anchors
            return escape_invisible(redact_text(obj))
        hits = find_secrets(obj)
        return escape_invisible(redact(obj, hits) if hits else obj)
    if isinstance(obj, dict):
        return {scrub(k if isinstance(k, str) else repr(type(k)), depth + 1, budget): scrub(v, depth + 1, budget)
                for k, v in list(obj.items())[:200]}
    if hasattr(obj, "isoformat"):  # YAML dates and times read as date objects: show the value, not the class
        return obj.isoformat()
    if isinstance(obj, (list, tuple)):
        return [scrub(v, depth + 1, budget) for v in list(obj)[:200]]
    return obj if isinstance(obj, (int, float, bool, type(None))) else repr(type(obj))


# ---------------------------------------------------------------- frontmatter

def normalize_newlines(text):
    return text.replace("\r\n", "\n").replace("\r", "\n")


def split_frontmatter(text):
    """Return (status, fm_text, body, body_start_line). status: ok | missing | unclosed."""
    text = normalize_newlines(text.lstrip("\ufeff"))
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return "missing", None, text, 1
    for i in range(1, len(lines)):
        if lines[i].rstrip() == "---":  # column 0 only: an indented --- is text inside a block scalar
            return "ok", "\n".join(lines[1:i]), "\n".join(lines[i + 1:]), i + 2
    return "unclosed", None, text, 1


def _scalar(v, depth=0):
    v = v.strip()
    if depth > 20:  # hostile nesting ([[[[...]]]]): keep the raw text, never recurse further
        return v[:200]
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        return v[1:-1]
    low = v.lower()
    if low in ("true", "yes"):
        return True
    if low in ("false", "no"):
        return False
    if v.startswith("[") and v.endswith("]"):
        return [_scalar(x, depth + 1) for x in v[1:-1].split(",")[:200] if x.strip()]
    return v


def parse_yaml_minimal(fm):
    """Strict-ish YAML subset: top-level scalars, block scalars, lists, nested maps (as raw text).

    Flags the breaks PyYAML would reject that real skills hit most: an unquoted
    ': ' or ' #' inside a plain scalar, unclosed quotes, unclosed flow collections.
    """
    data, errors = {}, []
    lines = fm.split("\n")
    anchors = set(re.findall(r"(?:^|[\s:\[{,-])&([^\s,\[\]{}]+)", fm))
    i = 0
    while i < len(lines):
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        if line[0] in " \t":
            errors.append("unexpected indentation at frontmatter line {}".format(i + 2))
            i += 1
            continue
        m = re.match(r"^([A-Za-z0-9_-]+)\s*:(?:\s+(.*)|\s*)$", line)
        if not m:
            errors.append("unparseable frontmatter line {}: {!r}".format(i + 2, line[:60]))
            i += 1
            continue
        key, rest, key_line = m.group(1), (m.group(2) or "").rstrip(), i + 2
        i += 1
        block = []
        while i < len(lines) and (lines[i].startswith((" ", "\t")) or not lines[i].strip()):
            block.append(lines[i])
            i += 1
        while block and not block[-1].strip():
            block.pop()
        if rest in ("|", ">", "|-", ">-", "|+", ">+"):
            parts = [b.strip() for b in block]
            data[key] = ("\n" if rest.startswith("|") else " ").join(parts).strip()
        elif rest == "" and block and block[0].strip().startswith("- "):
            data[key] = [_scalar(b.strip()[2:]) for b in block if b.strip().startswith("- ")]
        elif rest == "" and block and not any(re.match(r"^\s+[A-Za-z0-9_-]+\s*:(\s|$)", b) for b in block):
            data[key] = _scalar(" ".join(b.strip() for b in block))  # multi-line plain scalar
        elif rest == "" and block:
            data[key] = {"__raw__": "\n".join(block)}
        else:
            value = " ".join([rest] + [b.strip() for b in block]) if block else rest
            v = value.strip()
            if v[:1] in ("\"", "'"):
                close = _quote_end(v)
                if close is None:
                    errors.append("unclosed quote in '{}' at frontmatter line {}".format(key, key_line))
                elif v[close + 1:].strip() and not re.match(r"^\s+#", v[close + 1:]):
                    errors.append("text after the closing quote in '{}' at frontmatter line {} (quote the whole "
                                  "value, or escape the inner quote)".format(key, key_line))
            elif v[:1] == "*" and (re.match(r"^\*([^\s,\[\]{}]+)", v) or [None, None])[1] not in anchors:
                errors.append("the value of '{}' at frontmatter line {} starts with '*', a YAML alias to an anchor that "
                              "is not defined (quote the value)".format(key, key_line))
            elif v[:1] in ("`", "@", "%") or re.match(r"^[?-](?:\s|$)", v) or re.match(r"^[|>][-+0-9]*\s+\S", v):
                errors.append("the value of '{}' at frontmatter line {} starts with '{}', which YAML reserves "
                              "(quote the value)".format(key, key_line, v[:1]))
            elif v[:1] in ("[", "{"):
                if v[-1:] not in ("]", "}"):
                    errors.append("unclosed flow collection in '{}' at frontmatter line {}".format(key, key_line))
            elif ": " in v or v.endswith(":"):
                errors.append("unquoted ': ' inside the value of '{}' at frontmatter line {} "
                              "(YAML reads it as a nested mapping; quote the value)".format(key, key_line))
            elif " #" in v:
                errors.append("NOTE: ' #' inside the value of '{}' at frontmatter line {} starts a YAML comment; "
                              "the text after it is dropped".format(key, key_line))
            data[key] = _scalar(value)
    return data, errors


def _quote_end(v):
    """Index of the quote that closes the scalar opened at v[0], or None. '' escapes in single quotes, \\ in double."""
    q, i = v[0], 1
    while i < len(v):
        c = v[i]
        if q == '"' and c == "\\":
            i += 2
            continue
        if c == q:
            if q == "'" and v[i + 1:i + 2] == "'":
                i += 2
                continue
            return i
        i += 1
    return None


ANCHOR_ALIAS_RE = re.compile(r"(:[ \t]+|^[ \t]*-[ \t]+|[\[{,][ \t]*)[&*][A-Za-z0-9_-]+", re.M)


def _parse_frontmatter(fm):
    """Return (data, errors, parser). Uses PyYAML safe_load when importable and safe."""
    if len(fm.encode("utf-8", "replace")) > MAX_FRONTMATTER:
        data, errors = parse_yaml_minimal(fm[:MAX_FRONTMATTER])
        return data, ["NOTE: frontmatter over {} bytes; not YAML-parsed (checked with the built-in parser; it may "
                      "still be valid YAML)".format(MAX_FRONTMATTER)] + errors, "minimal"
    unquoted = re.sub(r"\"[^\"\n]*\"|'[^'\n]*'", "", fm)
    if ANCHOR_ALIAS_RE.search(unquoted):
        data, errors = parse_yaml_minimal(fm)
        return data, ["NOTE: YAML anchors/aliases present; not expanded (alias bombs can hang parsers), "
                      "checked with the built-in parser instead"] + _compose_errors(fm) + errors, "minimal"
    try:
        import yaml
    except ImportError:
        data, errors = parse_yaml_minimal(fm)
        return data, errors, "minimal"
    try:  # the regex above is a fast pre-filter; the event stream catches tagged or commented aliases
        has_alias = any(isinstance(ev, yaml.AliasEvent) for ev in yaml.parse(fm))
    except Exception:
        has_alias = False  # a parse error surfaces below
    if has_alias:
        data, errors = parse_yaml_minimal(fm)
        return data, ["NOTE: YAML aliases present; not expanded (alias bombs can hang parsers), "
                      "checked with the built-in parser instead"] + _compose_errors(fm) + errors, "minimal"
    try:
        data = yaml.safe_load(fm)
    except ValueError as exc:  # valid YAML that Python refuses (an integer over 4,300 digits): not a YAML error
        data, errors = parse_yaml_minimal(fm)
        return data, ["NOTE: PyYAML could not convert a value ({}); checked with the built-in parser".format(
            str(exc).splitlines()[0][:80])] + errors, "minimal"
    except Exception as exc:  # yaml.YAMLError and subclasses
        return {}, ["YAML error: {}{}".format(str(exc).splitlines()[0], _mark_line(exc))], "pyyaml"
    if data is None:
        return {}, [], "pyyaml"
    if not isinstance(data, dict):
        return {}, ["frontmatter is not a mapping"], "pyyaml"
    # PyYAML drops a plain value's text after ' #' silently; report it the same way the built-in parser does.
    return data, [e for e in parse_yaml_minimal(fm)[1] if e.startswith("NOTE: ' #'")], "pyyaml"


def _compose_errors(fm):
    """YAML errors (an undefined alias) found by composing the node graph: aliases are shared, never expanded,
    so an alias bomb costs nothing. Empty when PyYAML is absent; the built-in parser then checks aliases."""
    try:
        import yaml
    except ImportError:
        return []
    try:
        yaml.compose(fm, Loader=yaml.SafeLoader)
    except Exception as exc:
        return ["YAML error: {}{}".format(str(exc).splitlines()[0], _mark_line(exc))]
    return []


def _mark_line(exc):
    """' at frontmatter line N' from a PyYAML error's position (N is the SKILL.md line), or ''."""
    mark = getattr(exc, "context_mark", None) or getattr(exc, "problem_mark", None)  # where the bad node starts
    return " at frontmatter line {}".format(mark.line + 2) if mark is not None else ""


def parse_frontmatter(fm):
    """Return (data, errors, parser). Never raises on hostile nesting."""
    try:
        return _parse_frontmatter(fm)
    except (RecursionError, MemoryError):
        return {}, ["frontmatter nests too deeply to parse (hostile or broken)"], "minimal"
    except Exception as exc:  # a parser bug on hostile input is reported, never raised
        return {}, ["frontmatter could not be parsed ({})".format(type(exc).__name__)], "minimal"


def parse_tools(value):
    if value is None:
        return []
    if isinstance(value, list):
        return [str(t).strip() for t in value if str(t).strip()]
    # Tool names, each with its (...) argument kept whole even when it holds nested parentheses
    # (Bash(env FOO=$(pwd) python3 *)): a scan that counts depth, linear in the value.
    text, out, i = str(value)[:20000], [], 0
    name_re = re.compile(r"[A-Za-z_][\w:.*-]*")
    while i < len(text):
        m = name_re.match(text, i)
        if not m:
            i += 1
            continue
        j = m.end()
        if j < len(text) and text[j] == "(":
            depth, k = 0, j
            while k < len(text):
                depth += {"(": 1, ")": -1}.get(text[k], 0)
                if depth == 0:
                    break
                k += 1
            j = min(k + 1, len(text))
        out.append(text[m.start():j].strip())
        i = j
    return out


def risky_tools(tools):
    """Return [(tool, severity, reason)] for overly broad allowed-tools entries."""
    out = []
    for t in tools:
        if t == "Bash" or re.match(r"^Bash\(\s*\*?\s*\)$", t):
            out.append((t, "high", "pre-approves any shell command"))
        elif INTERP_WILDCARD_RE.match(t):
            out.append((t, "high", "pre-approves an interpreter with any arguments: arbitrary code "
                                   "(inline code via -c or -e, or a script inside the target)"))
        elif WRAPPER_WILDCARD_RE.match(t):
            out.append((t, "high", "pre-approves a run-wrapper with free arguments: arbitrary code"))
        elif CODE_WILDCARD_RE.match(t):
            out.append((t, "high", "pre-approves a command that can run code or reach arbitrary data with free "
                                   "arguments (git -c, npm run, find -exec, env, xargs, curl, ...)"))
        elif MUTATING_WILDCARD_RE.match(t):
            out.append((t, "medium", "pre-approves a file-mutating command with free arguments"))
        elif READING_WILDCARD_RE.match(t):
            out.append((t, "medium", "pre-approves reading arbitrary files (credentials included) with no prompt"))
        elif RELATIVE_ENTRY_RE.match(t):
            out.append((t, "medium", "relative script path: matches whatever scripts/ is in the working "
                                     "directory, including a target's. Use ${CLAUDE_SKILL_DIR}"))
        elif re.match(r"^Bash\(.*/\*\s*\)$", t) or re.match(r"^Bash\(.*/\*[\"']?\s", t) or \
                re.match(r"^Bash\([^)]*?/[^\s\"')]*\*", t):
            out.append((t, "medium", "directory wildcard; '../' in the path can reach scripts outside it. "
                                     "List each script explicitly"))
        elif re.match(r"^Bash\(\s*\.{0,2}/?(?:scripts|references|assets)/", t):
            out.append((t, "medium", "relative script path in allowed-tools: it matches whatever that path is in the "
                                     "working directory, including a target's. Use ${CLAUDE_SKILL_DIR}"))
        elif re.match(r"^mcp__[\w-]*\*|^mcp__[\w-]+__\*$|^mcp__\*$|^mcp__[\w-]+$", t):  # a bare server name too
            risky_server = re.search(r"chrome|browser|playwright|puppeteer|computer|desktop|filesystem|shell|terminal|exec",
                                     t, re.I)
            out.append((t, "high" if risky_server else "medium",
                        "pre-approves every tool of an MCP server{} for the invoking turn".format(
                            " that controls a browser, desktop, files, or a shell" if risky_server else "")))
        elif re.match(r"^(Write|Edit|MultiEdit|NotebookEdit)(\(.*\))?$", t):
            out.append((t, "low" if "(" in t else "medium",
                        "pre-approves file writes{} for the invoking turn".format("" if "(" in t else " anywhere, with no prompt")))
        elif re.match(r"^(WebFetch|WebSearch)(\(.*\))?$", t):
            out.append((t, "low", "pre-approves network access for the invoking turn"))
    return out


def hook_commands(hooks):
    """Return every 'command' string found anywhere in a hooks structure."""
    found = []

    def visit(x, depth=0):
        if depth > 10:
            return
        if isinstance(x, dict):
            for k, v in x.items():
                if k == "command" and isinstance(v, str):
                    found.append(v)
                elif k == "__raw__" and isinstance(v, str):
                    found.extend(m.group(1).strip() for m in re.finditer(r"command\s*:\s*(.+)", v))
                else:
                    visit(v, depth + 1)
        elif isinstance(x, list):
            for v in x:
                visit(v, depth + 1)

    visit(hooks)
    return found


def frontmatter_for_audit(text):
    """(status, fm_dict) for security auditing: falls back to the minimal parser on broken YAML."""
    status, fm_text, _, _ = split_frontmatter(text)
    if status != "ok":
        return status, {}
    try:
        fm, errors, _ = parse_frontmatter(fm_text)
        if errors and not fm:
            fm = parse_yaml_minimal(fm_text[:MAX_FRONTMATTER])[0]
    except Exception:  # hostile frontmatter must never cost the caller its whole result
        fm = {}
    return status, fm


def frontmatter_line(skill_md_text, key):
    """1-based line of a top-level frontmatter key in SKILL.md, or None."""
    lines = normalize_newlines(skill_md_text.lstrip("\ufeff")).split("\n")
    if not lines or lines[0].strip() != "---":
        return None
    for i, ln in enumerate(lines[1:], 2):
        if ln.rstrip() == "---":  # column 0 only, as split_frontmatter
            return None
        if re.match(r"^" + re.escape(key) + r"\s*:", ln):
            return i
    return None


def heading(level, text):
    return "#" * max(1, min(6, level)) + " " + text


# ---------------------------------------------------------------- plugin context

PLUGIN_REF_RE = re.compile(r"\$\{?CLAUDE_PLUGIN_ROOT\}?[\"']?/([A-Za-z0-9_.*?/-]+)")  # also with the variable quoted
# A script path a hook or MCP command runs (python3 hooks/x.py, bash /abs/plugin/run.sh)
CMD_SCRIPT_RE = re.compile(r"(?:^|[\s'\"=])((?:\.{1,2}/|/)?[\w.-]{1,100}(?:/[\w.-]{1,100}){0,12}\."
                           r"(?:sh|bash|zsh|py|js|mjs|cjs|ts|rb|pl|php|ps1))(?=$|[\s'\";&|)])")
PLUGIN_CONTEXT_FILES = (".claude-plugin/plugin.json", "hooks/hooks.json", ".mcp.json")
MAX_PLUGIN_FILES = 300


def plugin_root(skill_dir):
    """Return the plugin root holding this skill (<root>/skills/<name>/), or None."""
    real = os.path.realpath(skill_dir)
    parent = os.path.dirname(real)
    if os.path.basename(parent) != "skills":
        return None
    root = os.path.dirname(parent)
    manifest = os.path.join(root, ".claude-plugin", "plugin.json")
    # Neither the manifest nor its folder may be a link (O_NOFOLLOW covers only the last component).
    if os.path.isfile(manifest) and not os.path.islink(manifest) and not os.path.islink(os.path.dirname(manifest)):
        return root
    return None


def _plugin_refs_in(text):
    out = []
    for m in PLUGIN_REF_RE.finditer(text):
        ref = m.group(1).rstrip(".,;:)'\"")
        if ref and "..." not in ref and not set(ref) <= set("./*?"):  # skip prose like ${CLAUDE_PLUGIN_ROOT}/...
            out.append(ref)
    return out


def _read_text_safe(full, limit=MAX_READ):
    try:
        data, _ = read_bytes(full, limit)
    except OSError:
        return None
    return None if is_binary(data) else normalize_newlines(decode(data))


_PLUGIN_CACHE = {}


def plugin_context(skill_dir, entries=None):
    """Cached wrapper: the context is computed once per skill directory per process."""
    key = os.path.realpath(skill_dir)
    if key not in _PLUGIN_CACHE:
        try:
            _PLUGIN_CACHE[key] = _plugin_context(skill_dir, entries)
        except Exception as exc:  # a hostile plugin layout costs the plugin part only, never the caller's findings
            _PLUGIN_CACHE[key] = {"root": None, "name": None, "files": [], "hook_commands": [], "mcp_commands": [],
                                  "other_commands": [], "components": {}, "uses_plugin_root": False, "truncated": False,
                                  "missing": ["plugin context not read ({}): review the plugin by hand".format(
                                      type(exc).__name__)]}
    import copy
    return copy.deepcopy(_PLUGIN_CACHE[key])


def _plugin_context(skill_dir, entries=None):
    """Describe plugin-level files this skill depends on. Static; follows no links.

    Returns None when the skill does not use ${CLAUDE_PLUGIN_ROOT} and is not inside a plugin.
    Otherwise: {"root", "name", "files": [{"path", "reason", "kind"}], "missing": [ref],
    "hook_commands": [...], "mcp_commands": [...], "components": {...}, "uses_plugin_root": bool,
    "truncated": bool}. Paths in "files" are relative to the plugin root.
    """
    skill_dir = os.path.abspath(skill_dir)
    entries = entries if entries is not None else walk(skill_dir)
    refs, operative, read_total = [], False, 0
    for e in entries:
        if e["kind"] == "file" and not is_credential_path(e["path"]):  # credential files are never opened
            if read_total > MAX_TOTAL_SCAN:  # same byte budget as the scan
                break
            t = _read_text_safe(os.path.join(skill_dir, e["path"]))
            read_total += len(t) if t else 0
            if t and "CLAUDE_PLUGIN_ROOT" in t:
                found = list(dict.fromkeys(_plugin_refs_in(t)))[:500]  # repeated references cost nothing
                refs += [(r, "referenced by " + e["path"]) for r in found]
                # Mentions in SKILL.md or code are operative; in other docs they may be prose.
                operative = operative or (bool(found) and (e["path"] == "SKILL.md" or is_code(e["path"])))
    refs = list({r: (r, why) for r, why in refs}.values())  # one entry per distinct reference
    root = plugin_root(skill_dir)
    refused = folder_refusal(root) if root else None
    if refused:  # a plugin root at home (or holding a credential folder) is never walked or quoted
        return {"root": None, "name": None, "refused": refused, "files": [], "missing": ["plugin root not read: " + refused],
                "hook_commands": [], "mcp_commands": [], "other_commands": [], "components": {},
                "uses_plugin_root": bool(refs), "truncated": False}
    if root is None and not operative:
        return None
    ctx = {"root": root, "name": None, "files": [], "missing": [], "hook_commands": [], "mcp_commands": [],
           "other_commands": [],
           "components": {}, "uses_plugin_root": bool(refs), "truncated": False}
    if root is None:
        ctx["missing"] = sorted({r for r, _ in refs})
        return ctx
    real_root, real_skill = os.path.realpath(root), os.path.realpath(skill_dir)
    chosen = {}

    def add(rel, reason):
        if rel.startswith("/"):  # the plugin-root variable then //abs/path: join would drop the root
            ctx["missing"].append(rel + " (absolute path; not read)")
            return
        rel = os.path.normpath(rel).replace(os.sep, "/")
        full = os.path.join(real_root, rel)
        if rel.startswith(".."):  # outside the plugin: listed as missing, never read
            ctx["missing"].append(rel + " (outside the plugin; not read)")
            return
        if inside(full, real_skill):
            return
        if not inside(os.path.dirname(full) or full, real_root):
            # A folder on the way is a link out of the plugin (hooks/ -> elsewhere): record the link itself, so the
            # scan reports it instead of dropping the hook or MCP file without a word.
            parts = rel.split("/")
            for i in range(1, len(parts)):
                anc = "/".join(parts[:i])
                if os.path.islink(os.path.join(real_root, anc)):
                    if anc not in chosen and len(chosen) < MAX_PLUGIN_FILES:
                        chosen[anc] = {"path": anc, "reason": reason + " (through this link; not followed)",
                                       "kind": "symlink"}
                    break
            return
        if rel in chosen or len(chosen) >= MAX_PLUGIN_FILES:
            ctx["truncated"] = ctx["truncated"] or len(chosen) >= MAX_PLUGIN_FILES
            return
        if os.path.islink(full):
            kind = "symlink"
        elif os.path.isfile(full):
            kind = "file"
        elif os.path.isdir(full):
            for sub in walk(full):
                if sub["kind"] != "skipped-dir":
                    add(rel + "/" + sub["path"], reason)
            return
        elif os.path.lexists(full):
            kind = "special"
        else:
            ctx["missing"].append(rel)
            return
        chosen[rel] = {"path": rel, "reason": reason, "kind": kind}

    for rel in PLUGIN_CONTEXT_FILES:
        if os.path.lexists(os.path.join(real_root, rel)):
            add(rel, "plugin context (active whenever the plugin is enabled)")
    all_plugin, glob_work = None, 0
    for ref, reason in refs:
        if any(ch in ref for ch in "*?"):
            if all_plugin is None:
                all_plugin = [e["path"] for e in walk(real_root) if e["kind"] in ("file", "symlink")]
            glob_work += len(all_plugin)
            if glob_work > 2_000_000:  # bounded: distinct globs x plugin files
                ctx["missing"].append("{} (glob not expanded: too many glob references; name the files)".format(ref))
                continue
            hits = [p for p in all_plugin if fnmatch_path(p, ref)]
            if not hits:
                ctx["missing"].append(ref)
            elif len(hits) > 50:  # a sweeping glob (** or *) is not a dependency list
                ctx["missing"].append("{} (matches {} files; not added, name the files)".format(ref, len(hits)))
                hits = []
            for h in hits:
                add(h, reason)
        else:
            add(ref.rstrip("/"), reason)

    manifest_text = _read_text_safe(os.path.join(real_root, ".claude-plugin", "plugin.json")) or ""
    m = re.search(r'"name"\s*:\s*"([^"]{1,100})"', manifest_text)
    ctx["name"] = m.group(1) if m else os.path.basename(real_root)
    done = set()
    while True:  # worklist: hook/MCP files declared in plugin.json are parsed too
        pending = [r for r in sorted(chosen) if r not in done and chosen[r]["kind"] == "file" and
                   (r in PLUGIN_CONTEXT_FILES or chosen[r]["reason"].startswith(("hooks file", "mcpServers file")))]
        if not pending:
            break
        rel = pending[0]
        done.add(rel)
        t = _read_text_safe(os.path.join(real_root, rel)) or ""
        for cmd in json_commands(t):
            if rel == ".mcp.json" or "mcpServers" in cmd[1] or chosen[rel]["reason"].startswith("mcpServers"):
                bucket = "mcp_commands"
            elif "hooks" in cmd[1] or rel.startswith("hooks/") or chosen[rel]["reason"].startswith("hooks"):
                bucket = "hook_commands"
            else:
                bucket = "other_commands"  # lspServers and similar: labelled by their JSON path
                cmd = ("{} (at {})".format(cmd[0], cmd[1] or "/"), cmd[1])
            ctx[bucket].append(cmd[0])
            for r in _plugin_refs_in(cmd[0]):
                add(r, "run by a command in " + rel)
            for m in CMD_SCRIPT_RE.finditer(cmd[0][:2000]):  # scripts named without ${CLAUDE_PLUGIN_ROOT}
                tok = m.group(1)
                if "CLAUDE_PLUGIN_ROOT" in cmd[0][max(0, m.start() - 30):m.start(1)]:
                    continue  # already added above
                if tok.startswith("/"):
                    if inside(tok, real_root):
                        add(os.path.relpath(os.path.realpath(tok), real_root), "run by a command in " + rel)
                    else:
                        ctx["missing"].append(tok + " (run by a command in {}; outside the plugin, not read)".format(rel))
                elif os.path.lexists(os.path.join(real_root, tok)) or tok.startswith(".."):
                    add(tok, "run by a command in " + rel)
        for pm in re.finditer(r'"(hooks|mcpServers)"\s*:\s*(\[[^\]]{0,2000}\]|"[^"]{1,200}")', t):
            for raw_path in re.findall(r'"([^"]{1,200})"', pm.group(2)):
                p_ = re.sub(r"^\$\{?CLAUDE_PLUGIN_ROOT\}?/", "", raw_path)
                p_ = p_[2:] if p_.startswith("./") else p_
                if p_.endswith(".json"):
                    add(p_, "{} file declared in {}".format(pm.group(1), rel))
    for comp in ("skills", "agents", "commands"):
        d = os.path.join(real_root, comp)
        if os.path.isdir(d) and not os.path.islink(d):
            try:
                ctx["components"][comp] = sorted(n for n in os.listdir(d) if not n.startswith("."))[:100]
            except OSError as exc:  # an unreadable folder is reported, never raised
                ctx["components"][comp] = ["(unreadable: {})".format(exc.strerror or exc)]
    ctx["files"] = sorted(chosen.values(), key=lambda f: f["path"])
    ctx["missing"] = sorted(set(ctx["missing"]))
    return ctx


def json_commands(text):
    """Return [(command line, json path)] for every command (+ args) in a JSON config. json.loads only."""
    import json
    try:
        data = json.loads(text)
    except Exception:  # ValueError, RecursionError on hostile nesting
        return [(redact(m.group(1), find_secrets(m.group(1))), "")
                for m in re.finditer(r'"command"\s*:\s*"((?:[^"\\]|\\.){1,500})"', text)]
    out = []

    def visit(x, path, depth=0):
        if depth > 12:
            return
        if isinstance(x, dict):
            if isinstance(x.get("url"), str) and not isinstance(x.get("command"), str) and (
                    "mcpServers" in path or str(x.get("type", "")).lower() in ("http", "sse", "streamable-http")):
                out.append(("REMOTE " + safe_cut(x["url"][:200000], 500), path))
            if isinstance(x.get("command"), str):
                args = x.get("args") if isinstance(x.get("args"), list) else []
                cmd = safe_cut(" ".join([x["command"]] + [str(a) for a in args])[:200000], 1000)
                out.append((cmd, path))
            for k, v in x.items():
                visit(v, path + "/" + str(k), depth + 1)
        elif isinstance(x, list):
            for v in x:
                visit(v, path, depth + 1)

    visit(data, "")
    return out


import fnmatch  # noqa: E402  (bracket expressions only; see _glob_piece)

_GLOB_CACHE = {}


def _glob_piece(piece):
    """Compile a star-free glob piece ('?', '[seq]', '[!seq]', literals) to (regex, fixed length)."""
    out, i, n, count = [], 0, len(piece), 0
    while i < n:
        c = piece[i]
        i += 1
        if c == "?":
            out.append(".")
        elif c == "[":  # same bracket rules as fnmatch.translate
            j = i
            if j < n and piece[j] == "!":
                j += 1
            if j < n and piece[j] == "]":
                j += 1
            while j < n and piece[j] != "]":
                j += 1
            if j >= n:
                out.append("\\[")
            else:
                # The stdlib translation of one bracket expression alone (no '*', so no backtracking): it
                # handles '!', ranges, and characters the re module would read as set operations.
                inner = fnmatch.translate(piece[i - 1:j + 1])
                m = re.fullmatch(r"\(\?s:(.*)\)\\[Zz]", inner, re.S)
                out.append(m.group(1) if m else re.escape(piece[i - 1:j + 1]))
                i = j + 1
        else:
            out.append(re.escape(c))
        count += 1
    return re.compile("(?s:" + "".join(out) + ")"), count


def _glob_split(pattern):
    """Split a glob on the '*' characters that are not inside a bracket expression."""
    pieces, cur, i, n = [], [], 0, len(pattern)
    while i < n:
        c = pattern[i]
        if c == "*":
            pieces.append("".join(cur))
            cur = []
            i += 1
            continue
        if c == "[":
            j = i + 1
            if j < n and pattern[j] == "!":
                j += 1
            if j < n and pattern[j] == "]":
                j += 1
            while j < n and pattern[j] != "]":
                j += 1
            if j < n:
                cur.append(pattern[i:j + 1])
                i = j + 1
                continue
        cur.append(c)
        i += 1
    pieces.append("".join(cur))
    return pieces


def glob_match(path, pattern):
    """fnmatch.fnmatchcase semantics ('*' crosses '/'), in time linear in the pattern pieces times the path.

    The pattern is split on '*': the first piece must match at the start, the last at the end, and each
    middle piece is matched at its leftmost place. No backtracking, so many stars cannot blow up (the
    stdlib translation backtracks badly before Python 3.9).
    """
    comp = _GLOB_CACHE.get(pattern)
    if comp is None:
        try:
            comp = [_glob_piece(x) for x in _glob_split(pattern)]
        except (re.error, ValueError):
            comp = [(re.compile(re.escape(pattern)), len(pattern))]
        if len(_GLOB_CACHE) < 5000:
            _GLOB_CACHE[pattern] = comp
    if len(comp) == 1:
        rx, ln = comp[0]
        return ln == len(path) and bool(rx.match(path))
    (frx, fln), (lrx, lln) = comp[0], comp[-1]
    if fln + lln > len(path) or not frx.match(path) or not lrx.match(path, len(path) - lln):
        return False
    pos, end = fln, len(path) - lln
    for rx, ln in comp[1:-1]:
        if ln == 0:
            continue
        m = rx.search(path, pos, end)
        if not m:
            return False
        pos = m.end()
    return True


def fnmatch_path(path, pattern):
    if len(pattern) > 300:
        return False
    return glob_match(path, pattern)
