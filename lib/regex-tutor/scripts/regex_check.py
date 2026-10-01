#!/usr/bin/env python3
"""Check regexes against real engines: Python re, JavaScript (node), Perl (stand-in for PCRE), Go RE2.

Subcommands:
  compile  Report which engines compile each pattern.
      regex_check.py compile [--engines ...] [--flags ...] -- 'PATTERN' ['PATTERN' ...]
  test     Run strings against one pattern in chosen engines, with a timeout per run.
      regex_check.py test -m 'should match' -n 'should not match' \
          [--engines py,js,perl,go] [--flags ims] [--full] [--escapes] [--timeout 3] -- 'PATTERN'

Put options first and "--" before the pattern, so a pattern starting with "-"
is not read as an option. For a test string starting with "-", use the long
form with "=": --match=-abc / --nomatch=-abc.

Semantics: "match" means search (a match anywhere), like re.search / RegExp.test.
Use --full to require the whole string to match (fullmatch, anchored at the
absolute start and end even with the m flag). Anchors in the pattern always apply.
--escapes decodes \\n \\t \\r \\\\ \\xHH \\uHHHH in test strings.

Flags: i (ignore case), m (multiline), s (dotall), x (verbose; py/perl only;
js/go report n/a). The JS-only flags g, y, d, u are dropped with a note: they
do not change whether a string matches in this check.

Output per engine: OK / ERR <message> (compile); MATCH / NOMATCH / ERR /
TIMEOUT / n/a (test). Exit codes:
  0  compile: every engine compiled | test: every result agreed with expectation
  1  test: at least one MATCH/NOMATCH disagreed with expectation ("WRONG")
  2  bad arguments (argparse)
  3  compile: at least one engine reported ERR | test: no wrong results, but at
     least one result is ERR / TIMEOUT / n/a, so that example is unverified there

Every engine call runs in its own subprocess with --timeout seconds, so a
catastrophic-backtracking input reports TIMEOUT instead of hanging.

Perl syntax is close to PCRE, but Perl caches some backtracking states, so a
pattern that hangs PCRE may finish fast in Perl. Judge ReDoS by the py and js
columns (both backtrack without that cache). Go RE2 never backtracks: it always
runs in linear time, and it rejects backreferences and lookaround.
"""
import argparse, json, shutil, subprocess, sys, tempfile
from pathlib import Path

ENGINES = ["py", "js", "perl", "go"]
MATCH_FLAGS, DROPPED_FLAGS = set("imsx"), set("gydu")

PY_SRC = r"""
import re, sys, json
a = json.loads(sys.argv[1])
fl = 0
for c in a["flags"]:
    fl |= {"i": re.I, "m": re.M, "s": re.S, "x": re.X}[c]
try:
    p = re.compile(a["pat"], fl)
except re.error as e:
    print("ERR " + str(e)); sys.exit(0)
if a["s"] is None: print("OK"); sys.exit(0)
m = (p.fullmatch if a["full"] else p.search)(a["s"])
print("MATCH" if m else "NOMATCH")
"""

# Full mode: sticky flag anchors at index 0; (?![\s\S]) is an absolute end anchor, unaffected by m.
JS_SRC = r"""
const a = JSON.parse(process.argv[1]);
let r;
try {
  new RegExp(a.pat, a.flags);
  r = a.full ? new RegExp("(?:" + a.pat + ")(?![\\s\\S])", a.flags + "y") : new RegExp(a.pat, a.flags);
} catch (e) { console.log("ERR " + e.message); process.exit(0); }
if (a.s === null) { console.log("OK"); process.exit(0); }
console.log(r.test(a.s) ? "MATCH" : "NOMATCH");
"""

PERL_SRC = r"""
use strict; use JSON::PP;
my $a = decode_json($ARGV[0]);
my $p = $a->{pat};
$p = "\\A(?:$p)\\z" if $a->{full};
$p = "(?" . $a->{flags} . ")" . $p if length $a->{flags};
my $r = eval { qr/$p/ };
if (!defined $r) { my $e = $@; $e =~ s/\s+at .* line \d+.*//s; print "ERR $e\n"; exit 0; }
if (!defined $a->{s}) { print "OK\n"; exit 0; }
print(($a->{s} =~ $r) ? "MATCH\n" : "NOMATCH\n");
"""

GO_SRC = r"""
package main
import ("encoding/json";"fmt";"os";"regexp")
type A struct { Pat string `json:"pat"`; Flags string `json:"flags"`; Full bool `json:"full"`; S *string `json:"s"` }
func main() {
	var a A
	json.Unmarshal([]byte(os.Args[1]), &a)
	if _, err := regexp.Compile(a.Pat); err != nil { fmt.Println("ERR " + err.Error()); return }
	p := a.Pat
	if a.Full { p = `\A(?:` + p + `)\z` }
	if a.Flags != "" { p = "(?" + a.Flags + ")" + p }
	r, err := regexp.Compile(p)
	if err != nil { fmt.Println("ERR " + err.Error()); return }
	if a.S == nil { fmt.Println("OK"); return }
	if r.MatchString(*a.S) { fmt.Println("MATCH") } else { fmt.Println("NOMATCH") }
}
"""


class Runner:
    def __init__(self, tmp, timeout, engines):
        self.timeout = timeout
        self.cmd = {"py": [sys.executable, "-c", PY_SRC]}
        if shutil.which("node"):
            self.cmd["js"] = ["node", "-e", JS_SRC]
        if shutil.which("perl"):
            self.cmd["perl"] = ["perl", "-e", PERL_SRC]
        if "go" in engines and shutil.which("go"):
            src, exe = Path(tmp) / "m.go", Path(tmp) / "m"
            src.write_text(GO_SRC)
            if subprocess.run(["go", "build", "-o", str(exe), str(src)], capture_output=True).returncode == 0:
                self.cmd["go"] = [str(exe)]

    def run(self, engine, pat, flags="", s=None, full=False):
        if engine not in self.cmd:
            return "n/a (engine not installed)"
        if engine in ("js", "go") and "x" in flags:
            return "n/a (no x flag)"
        arg = json.dumps({"pat": pat, "flags": flags, "full": full, "s": s})
        try:
            p = subprocess.run(self.cmd[engine] + [arg], capture_output=True, text=True, timeout=self.timeout)
        except subprocess.TimeoutExpired:
            return f"TIMEOUT (>{self.timeout}s)"
        if p.stdout.strip():
            return p.stdout.strip()
        err = p.stderr.strip().splitlines()
        return "ERR " + (err[-1] if err else "(no output)")


def decode(s):
    return s.encode("latin-1", "backslashreplace").decode("unicode_escape")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("compile")
    c.add_argument("patterns", nargs="+")
    t = sub.add_parser("test")
    t.add_argument("pattern")
    t.add_argument("-m", "--match", action="append", default=[], help="string expected to match")
    t.add_argument("-n", "--nomatch", action="append", default=[], help="string expected not to match")
    t.add_argument("--full", action="store_true")
    t.add_argument("--escapes", action="store_true")
    for p in (c, t):
        p.add_argument("--engines", default=",".join(ENGINES))
        p.add_argument("--flags", default="")
        p.add_argument("--timeout", type=float, default=3.0)
    a = ap.parse_args()

    engines = [e for e in a.engines.split(",") if e]
    unknown = [e for e in engines if e not in ENGINES]
    if unknown:
        ap.error(f"unknown engine(s) {unknown}; choose from {ENGINES}")
    bad_flags = set(a.flags) - MATCH_FLAGS - DROPPED_FLAGS
    if bad_flags:
        ap.error(f"unsupported flag(s) {sorted(bad_flags)}; supported: i m s x (g y d u are dropped)")
    dropped = "".join(f for f in a.flags if f in DROPPED_FLAGS)
    flags = "".join(f for f in a.flags if f in MATCH_FLAGS)
    if dropped:
        print(f"note: dropped flag(s) {dropped}: no effect on whether a string matches")

    with tempfile.TemporaryDirectory() as tmp:
        r = Runner(tmp, a.timeout, engines)
        if a.cmd == "compile":
            failed = False
            for pat in a.patterns:
                print(f"pattern: {pat}")
                for e in engines:
                    res = r.run(e, pat, flags)
                    failed |= res != "OK"
                    print(f"  {e:5} {res}")
            sys.exit(3 if failed else 0)

        wrong = unverified = 0
        cases = [(s, True) for s in a.match] + [(s, False) for s in a.nomatch]
        print(f"pattern: {a.pattern}  flags: {flags or '-'}  mode: {'fullmatch' if a.full else 'search'}")
        for e in engines:
            print(f"  {e:5} compile: {r.run(e, a.pattern, flags)}")
        for raw, want in cases:
            s = decode(raw) if a.escapes else raw
            marks = []
            for e in engines:
                got = r.run(e, a.pattern, flags, s, a.full)
                if got not in ("MATCH", "NOMATCH"):
                    unverified += 1
                    marks.append(f"{e}={got}")
                elif (got == "MATCH") != want:
                    wrong += 1
                    marks.append(f"{e}={got} WRONG")
                else:
                    marks.append(f"{e}={got}")
            print(f"  expect {'match   ' if want else 'no match'} {json.dumps(s)}: " + "  ".join(marks))
        print(f"{wrong} wrong, {unverified} unverified (ERR/TIMEOUT/n/a) result(s)")
        sys.exit(1 if wrong else 3 if unverified else 0)


if __name__ == "__main__":
    main()
