#!/usr/bin/env bash
# Run an original script and its refactored version with the same arguments, and report whether their stdout,
# stderr, and exit code match.
#
# Usage: compare-runs.sh [-C dir] [-p prep-command] <old-script> <new-script> [args...]
#   -C dir           run both scripts from this working directory (default: the current one)
#   -p prep-command  bash command run in that directory before each script, to recreate files the scripts
#                    change or delete (for example a test folder that the script removes)
#
# Output (stdout): three lines, "stdout: same|DIFF", "stderr: same|DIFF", "exit: same|DIFF (<old> vs <new>)",
# each DIFF followed by a unified diff indented by four spaces, then "result: same" or "result: DIFF".
# Before comparing, each script's own path is replaced with <script>, and bash's line numbers in ${1:?} messages
# (for example "line 12:") become "line N:", so moving code inside the file doesn't count as a difference.
# .py files run with python3, everything else with bash. stdin is /dev/null.
#
# Exit codes: 0 all three match, 1 something differs, 2 bad usage or a script file is missing.
# Caveat: the scripts really run. Only point this at inputs that are safe to run twice.

set -uo pipefail

usage='usage: compare-runs.sh [-C dir] [-p prep-command] <old-script> <new-script> [args...]'
workdir="$PWD"
prep=''
while getopts ':C:p:' opt; do
	case "$opt" in
		C) workdir="$OPTARG" ;;
		p) prep="$OPTARG" ;;
		*) printf '%s\n' "$usage" >&2; exit 2 ;;
	esac
done
shift $((OPTIND - 1))
[[ $# -ge 2 ]] || { printf '%s\n' "$usage" >&2; exit 2; }
old="$1"
new="$2"
shift 2
for script in "$old" "$new"; do
	[[ -f "$script" ]] || { printf 'compare-runs: no such script: %s\n' "$script" >&2; exit 2; }
done
[[ -d "$workdir" ]] || { printf 'compare-runs: no such directory: %s\n' "$workdir" >&2; exit 2; }

results="$(mktemp -d)"
trap 'rm -rf -- "$results"' EXIT

# interpreter_for <script>: python3 for .py files, bash for everything else.
interpreter_for() {
	case "$1" in
		*.py) printf 'python3' ;;
		*) printf 'bash' ;;
	esac
}

# run_side <name> <script> [args...]: runs the script from $workdir and saves out, err, and code under $results.
run_side() {
	local name="$1" script="$2" interpreter
	shift 2
	interpreter="$(interpreter_for "$script")"
	if [[ -n "$prep" ]]; then
		(cd "$workdir" && bash -c "$prep") >/dev/null 2>&1
	fi
	(cd "$workdir" && "$interpreter" "$script" "$@") <"/dev/null" >"$results/$name.out" 2>"$results/$name.err"
	printf '%s\n' "$?" >"$results/$name.code"
	# Normalize what is expected to differ: the script's own path and bash's line numbers.
	sed -i -e "s#$(printf '%s' "$script" | sed 's/[#.[\*^$]/\\&/g')#<script>#g" -e 's/line [0-9][0-9]*:/line N:/' \
		"$results/$name.err" "$results/$name.out"
}

run_side old "$old" "$@"
run_side new "$new" "$@"

differs=0
for part in out err code; do
	case "$part" in
		out) label='stdout' ;;
		err) label='stderr' ;;
		code) label='exit' ;;
	esac
	if cmp -s "$results/old.$part" "$results/new.$part"; then
		printf '%s: same\n' "$label"
		continue
	fi
	differs=1
	if [[ "$part" == code ]]; then
		printf 'exit: DIFF (%s vs %s)\n' "$(<"$results/old.code")" "$(<"$results/new.code")"
	else
		printf '%s: DIFF\n' "$label"
		diff -u --label old --label new "$results/old.$part" "$results/new.$part" | sed 's/^/    /'
	fi
done

if [[ $differs -eq 0 ]]; then
	printf 'result: same\n'
	exit 0
fi
printf 'result: DIFF\n'
exit 1
