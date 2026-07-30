#!/usr/bin/env bash
#
# verify.sh: run all unslop Rule 8 verification greps against a file.
#
# Usage:
#   verify.sh <file>            run all categories, show counts
#   verify.sh --verbose <file>  show counts AND the matching lines per category
#   verify.sh --category <name> <file>  run only one category (see CATEGORIES below)
#
# Exit code: number of categories with one or more hits (0 = clean).
#
# Categories:
#   1pp em-dash en-dash anthropomorphic tutorial jargon marketing
#   hyphen-compound num-word-compound britishism
#   hedging tutorial-voice connectors padding filler empty-enum apologetic
#   filler-intensifier passive-marketing tutorial-transition
#   smart-punct emoji-decor pseudo-action so-voice marketing-intros
#   self-ref empty-preamble docstring-openers human-user generic-id
#   test-voice ai-artifacts defensive stale-meta placeholder-todo
#   jsdoc-fluff type-cast pragma-py pragma-php pragma-rb pragma-go
#   output-tells

set -u

VERBOSE=0
ONLY=""
FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v|--verbose) VERBOSE=1; shift ;;
    -c|--category) ONLY="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*)
      echo "verify.sh: unknown flag: $1" >&2
      exit 2
      ;;
    *) FILE="$1"; shift ;;
  esac
done

if [[ -z "$FILE" ]]; then
  echo "verify.sh: missing <file>" >&2
  echo "usage: verify.sh [--verbose] [--category NAME] <file>" >&2
  exit 2
fi

if [[ ! -r "$FILE" ]]; then
  echo "verify.sh: cannot read file: $FILE" >&2
  exit 2
fi

# Prefer ripgrep when available.
if command -v rg >/dev/null 2>&1; then
  GREP() { rg -nE --no-heading --color=never "$1" "$FILE" 2>/dev/null; }
  IGREP() { rg -niE --no-heading --color=never "$1" "$FILE" 2>/dev/null; }
  FGREP() { rg -nF --no-heading --color=never "$1" "$FILE" 2>/dev/null; }
else
  GREP() { grep -nE "$1" "$FILE" 2>/dev/null; }
  IGREP() { grep -niE "$1" "$FILE" 2>/dev/null; }
  FGREP() { grep -nF "$1" "$FILE" 2>/dev/null; }
fi

FAILED=0

run_category() {
  local name="$1"
  local mode="$2"   # i|case|f
  local pattern="$3"

  if [[ -n "$ONLY" && "$ONLY" != "$name" ]]; then
    return
  fi

  local matches
  case "$mode" in
    i) matches="$(IGREP "$pattern")" ;;
    f) matches="$(FGREP "$pattern")" ;;
    *) matches="$(GREP  "$pattern")" ;;
  esac

  local count=0
  if [[ -n "$matches" ]]; then
    count=$(printf '%s\n' "$matches" | wc -l | tr -d ' ')
  fi

  printf '%-22s %s\n' "$name" "$count"

  if [[ "$count" -gt 0 ]]; then
    FAILED=$((FAILED + 1))
    if [[ "$VERBOSE" -eq 1 ]]; then
      printf '%s\n' "$matches" | sed 's/^/    /'
    fi
  fi
}

echo "=== unslop verification: $FILE ==="
printf '%-22s %s\n' "category" "hits"
printf '%-22s %s\n' "----------------------" "----"

# Rule 3: first-person plural (singular `I` now allowed)
run_category "1pp"               case '\b(we|us|our|we'\''re|we'\''ve|we'\''ll|we'\''d|let'\''s)\b'

# Rule 2b: em-dash and en-dash (all dev prose, not just comments)
run_category "em-dash"           f  '—'
run_category "en-dash"           f  '–'

# Rule 2: anthropomorphic + metaphor words
run_category "anthropomorphic"   case '\b(recipe|family|families|pictures|nudge|hunting|sideways|seamlessly|gracefully|magic|walks?|walking|journey|stroll|dive|delve|blueprint|skeleton|scaffold|step-by-step|shapes?|shaped)\b'

# Rule 2: tutorial-prose markers
run_category "tutorial"          i  "(note that|it'\''s worth|in order to|let'\''s|you'\''ll|you'\''d|you'\''ve|behind the scenes|under the hood)"

# Rule 2: engineering jargon
run_category "jargon"            case '\b(logic|atomic|normalise|normalize|leverage|utilize|facilitate|encapsulate|invocation|idempotent|orchestrate|canonical|subsequently|propagate|terminate)\b'

# Rule 2c A + GG: marketing / boast + hyphenated marketing compounds
run_category "marketing"         i  '\b(robust|elegant|powerful|comprehensive|seamless|seamlessly|intuitive|production-(grade|quality|ready)|enterprise-(grade|quality)|battle-tested|best-in-class|lightweight|performant|blazing|streamline|out of the box|first-class|sleek|polished|effortless|state-of-the-art|cutting-edge|next-generation|world-class|ready[- ]to[- ]use|ready out of the box|copy-paste|theme-building|page-building|site-building|baked-in|drop-in|plug-and-play|turn-key|future-proof|crucial|vital|pivotal|essential|substantial|considerable|remarkable|exceptional|outstanding|stunning|breathtaking|revolutionary|groundbreaking|transformative|disruptive|innovative|pioneering|game-changing|game-changer|premier|premium|top-tier|mission-critical|bleeding-edge|bulletproof|iron-clad|ironclad|rock-solid|airtight|watertight|holistic|omnichannel|best-of-breed|gold-standard|supercharge|turbocharge|elevate|amplify|revolutionize|hand-crafted|handcrafted|purpose-built|tailor-made|ready-made|hand-picked|handpicked|top-of-the-line|one-stop|one-stop-shop|all-in-one|ready-to-go|ready-to-ship)\b'

# Rule 2c GG Pass 1: de-hyphenate technical compounds (audit-only, edit per Rule 13)
run_category "hyphen-compound"   i  '\b(open-source|command-line|third-party|well-known|real-world|end-to-end|step-by-step|side-by-side|line-by-line|file-by-file|up-to-date|easy-to-use|high-level|low-level|top-level|cross-platform|full-stack|full-featured|server-side|client-side|in-house|long-term|short-term|free-text|AI-generated|AI-powered|AI-driven|AI-assisted)\b'

# Rule 2c GG Pass 3: number-word + noun compound modifiers
run_category "num-word-compound" i  '\b(two|three|four|five|six|seven|eight|nine|ten)-(question|step|phase|pillar|stage|tier|layer|part|point|category|level|round)\b'

# Rule O: Britishism AI tells
run_category "britishism"        i  '\b(whilst|amongst)\b'

# Rule 2c B: hedging / qualifier abuse
run_category "hedging"           i  '\b(perhaps|essentially|fundamentally|in essence|at its core|boils down to|could potentially|kind of|sort of|notably|in summary|in conclusion)\b'

# Rule 2c C: tutorial voice
run_category "tutorial-voice"    i  '(as you can see|let'\''s dive|in this function we|here we |this function will|imagine that|think of .* as)'

# Rule 2c D: verbose connectors
run_category "connectors"        i  '\b(furthermore|moreover|thus|hence|therefore|it should be noted|as mentioned earlier)\b'

# Rule 2c E: padding phrases
run_category "padding"           i  '(in the case of|in terms of|with regards? to|at the end of the day|in conjunction with|for the purpose of|subsequent to|prior to|due to the fact that|in light of)'

# Rule 2c F: vague filler
run_category "filler"            i  '\b(various|numerous|diverse|appropriate|suitable|particular|granular|paradigm|synergy|tapestry|myriad|plethora|landscape|realm|ample)\b'

# Rule 2c F: empty enumeration intros
run_category "empty-enum"        i  '\b(wide range|wide variety|a host|a wealth|an array|a suite|a collection) of\b'

# Rule 2c HH: filler intensifiers (audit only)
run_category "filler-intensifier" i '\b(incredibly|tremendously|vastly|extremely|absolutely|completely|totally|highly|thoroughly|rigorously|meticulously|extensive|extensively|exhaustive|exhaustively|significant|significantly|critical|critically|key|fully|very|really|quite|rather|simply|easily|just|flexible|customizable|modular|accelerate|transform|maximize|maximise|fine-tuned|tailored|crafted|carefully crafted)\b'
run_category "passive-marketing" i '\b(designed to|built to) \w+'

# Rule 2c II: tutorial transitions
run_category "tutorial-transition" i '(now that we have|now we can|we'\''ve now|with that said|that being said|all that said|single source of truth|source of truth|deep[- ]dive)'

# Rule 2c G: apologetic prefixes
run_category "apologetic"        i  "(please note|keep in mind|bear in mind|it'\''s worth mentioning|it'\''s important to note|^[[:space:]]*\\*?[[:space:]]*important:|^[[:space:]]*\\*?[[:space:]]*note:)"

# Rule 2c H: smart punctuation (U+2018/19/1C/1D/2026, U+00A0)
run_category "smart-punct"       case $'[\xe2\x80\x98\xe2\x80\x99\xe2\x80\x9c\xe2\x80\x9d\xe2\x80\xa6\xc2\xa0]'

# Rule 2c I: emoji / decoration in comments (samples)
run_category "emoji-decor"       case $'[\xe2\x9c\x85\xe2\x9d\x8c\xf0\x9f\x9a\x80\xf0\x9f\x92\xa1\xe2\x9a\xa0]'

# Rule 2c M: pseudo-action verbs
run_category "pseudo-action"     i  '\b(empower|unleash|unlock|harness|capability)\b'

# Rule 2c N: Stack Overflow voice
run_category "so-voice"          i  "(you can simply|you just need to|feel free to|consider doing)"

# Rule 2c P: marketing list intros
run_category "marketing-intros"  i  "(here'\''s what we'\''ll cover|in a nutshell|at a glance)"

# Rule 2c Q: self-referential meta
run_category "self-ref"          i  "(this documentation|this readme|the following section|below you'\''ll find|as shown above)"

# Rule 2c R: empty preamble
run_category "empty-preamble"    i  '(the purpose of this is|the reason for .* is that|this function takes .* and returns|this is a helper that|what this does is)'

# Rule 2c R: docstring openers
run_category "docstring-openers" i  '^\s*(\*|//|#)?\s*(this function|this class|this file|this module|this method|this script)\b'

# Rule 2c R3: human / user reader references
run_category "human-user"        i  '\b(the human|the user)\b.*(can|may|will|should|is able)'

# Rule 2d S: generic identifier names (audit)
run_category "generic-id"        case '\b(data|result|value|temp|item|obj|info|payload)\b[[:space:]]*[:=]'

# Rule 2d T: test voice
run_category "test-voice"        i  "(should correctly|should properly|should work as expected)"

# Rule 2d U: AI conversational artifacts (any hit = critical)
run_category "ai-artifacts"      i  "(as an ai|certainly!|of course!|i'\''d be happy to|here'\''s the .* you asked for|let me know if|i hope this helps)"

# Rule 2d V: defensive comments
run_category "defensive"         i  "(just in case|defensive check|belt-and-suspenders|future-proof|for safety)"

# Rule 2d W: stale metadata
run_category "stale-meta"        i  '(^|\*|//)[[:space:]]*(author|created by|modified by|date):'

# Rule 2d X: placeholder TODOs / FIXMEs
run_category "placeholder-todo"  case '(TODO|FIXME|XXX|HACK):?[[:space:]]*(implement|refactor|later|fix)'

# Rule 2d Z: JSDoc throws/return fluff
run_category "jsdoc-fluff"       i  '@throws \{.*\} (if something|an error of type)'

# Rule 2d AA: type-cast / linter suppression smells
run_category "type-cast"         case '(@ts-ignore|@ts-expect-error|eslint-disable|\bas any\b)'

# Per-language pragmas
run_category "pragma-py"         case '# noqa(:|$| )|# type: ?ignore|# pragma: no cover'
run_category "pragma-php"        case '@phpstan-ignore|@psalm-suppress'
run_category "pragma-rb"         case '# rubocop:(disable|enable)'
run_category "pragma-go"         case '//nolint'

# Rule 2d CC: output-format AI tells
run_category "output-tells"      case '^[[:space:]]*(\*|//)[[:space:]]*(IMPORTANT|WARNING|NOTE):'

echo
if [[ "$FAILED" -eq 0 ]]; then
  echo "clean — 0 categories with hits"
else
  echo "$FAILED categor$([[ $FAILED -eq 1 ]] && echo y || echo ies) with hits — review above"
fi

exit "$FAILED"
