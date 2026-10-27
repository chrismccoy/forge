#!/usr/bin/env bash
# Two-pass EBU R128 loudness normalization with loudnorm, checked with ebur128.
#
# Pass 1 measures integrated loudness, threshold, LRA and true peak with ebur128
# placed just before loudnorm: loudnorm's own pass-1 "input_i" was ~2 LU off
# after a compressor (-16.8 vs -18.6 LUFS) and the result missed. target_offset
# still comes from loudnorm; it matters only if pass 2 falls back to dynamic mode.
# Linear mode (one fixed gain) needs measured LRA <= target LRA, so the LRA
# target is raised to cover the input unless --keep-lra is given.
# Pass 2 applies the measured values with linear=true, then the written file is
# measured again.
#
# Return codes: 0 = on target (within 0.5 LU), 1 = failed, 2 = written but off target.

# shellcheck source=lib/filter-escape.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/filter-escape.sh" || exit 1
require_bash_43

usage() {
    cat <<EOF
Usage: $0 [options] <input> <output> [I] [TP] [LRA] [-- extra ffmpeg output options]

  I     integrated loudness target in LUFS (default -16)
  TP    true-peak ceiling in dBTP (default -1.5)
  LRA   loudness range target in LU (default 11; raised to cover the input
        so linear mode can apply, unless --keep-lra)

Options (before <input>):
  --pre CHAIN   filters to run before loudnorm, identical in both passes
                (e.g. "highpass=f=80,acompressor=threshold=-20dB:ratio=4")
  --dual-mono   measure a MONO file as played on two speakers (+3 dB, EBU R128)
  --keep-lra    keep the LRA target even when the input's LRA is higher
                (loudnorm then runs in dynamic mode and may miss the target)
  -h, --help    show this help

The output is written at 48 kHz. Video streams are copied (-c:v copy) unless
the extra options set another video codec; audio-only outputs (.m4a, .mp3,
.wav, .flac, ...) drop the video. The output is never overwritten.

Return codes: 0 = on target (within 0.5 LU), 1 = failed, 2 = written but off target.

Examples:
  $0 input.wav broadcast.wav -23 -1 20 -- -c:a pcm_s24le
  $0 --pre "highpass=f=80" raw.wav podcast.m4a -16 -1.5 11 -- -c:a aac -b:a 96k
  $0 video.mp4 output.mp4 -- -c:a aac -b:a 160k
EOF
}

case "${1:-}" in
    "") usage >&2; exit 1 ;;
    -h|--help) usage; exit 0 ;;
esac

PRE=""
DUAL_MONO=0
KEEP_LRA="${LOUDNORM2_KEEP_LRA:-0}"
while [ $# -gt 0 ]; do
    case "$1" in
        --pre)
            [ $# -ge 2 ] || { echo "Error: --pre needs a filter chain" >&2; exit 1; }
            PRE="$2"; shift 2 ;;
        --pre=*) PRE="${1#--pre=}"; shift ;;
        --dual-mono) DUAL_MONO=1; shift ;;
        --keep-lra) KEEP_LRA=1; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        --*) echo "Error: unknown option $1" >&2; usage >&2; exit 1 ;;
        *) break ;;
    esac
done

if [ $# -lt 2 ]; then
    usage >&2
    exit 1
fi
IN="$1"; OUT="$2"; shift 2
require_tools ffmpeg ffprobe

# Optional numeric targets, then an optional "--" and extra ffmpeg output options
TARGET_I=-16; TARGET_TP=-1.5; TARGET_LRA=11
is_number() { [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; }
for name in TARGET_I TARGET_TP TARGET_LRA; do
    [ $# -gt 0 ] || break
    [ "$1" = "--" ] && break
    if ! is_number "$1"; then
        echo "Error: '$1' is not a number (expected I, TP, LRA, then -- and ffmpeg options)" >&2
        exit 1
    fi
    printf -v "$name" '%s' "$1"
    shift
done
if [ $# -gt 0 ]; then
    if [ "$1" != "--" ]; then
        echo "Error: unexpected argument '$1' (put extra ffmpeg options after --)" >&2
        exit 1
    fi
    shift
fi
EXTRA=("$@")

# loudnorm's own ranges
in_range() { awk -v v="$1" -v lo="$2" -v hi="$3" 'BEGIN { exit !(v >= lo && v <= hi) }'; }
in_range "$TARGET_I" -70 -5 || { echo "Error: I must be between -70 and -5 LUFS" >&2; exit 1; }
in_range "$TARGET_TP" -9 0 || { echo "Error: TP must be between -9 and 0 dBTP" >&2; exit 1; }
in_range "$TARGET_LRA" 1 50 || { echo "Error: LRA must be between 1 and 50 LU" >&2; exit 1; }

if [ ! -f "$IN" ]; then
    echo "Error: input not found: $IN" >&2
    exit 1
fi
if [ -e "$OUT" ]; then
    echo "Error: $OUT already exists (refusing to overwrite)" >&2
    exit 1
fi
IN=$(safe_path "$IN")
OUT=$(safe_path "$OUT")

if [ -z "$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$IN" 2>/dev/null)" ]; then
    echo "Error: no audio stream in $IN" >&2
    exit 1
fi

# Video handling for pass 2: copy it, except into audio-only formats, where a
# real video stream is dropped (cover art, which first_video_index skips, is kept)
VIDEO_OPTS=(-c:v copy)
case "${OUT,,}" in
    *.m4a|*.aac|*.mp3|*.wav|*.flac|*.opus|*.ogg|*.oga|*.ac3|*.eac3|*.w64|*.aif|*.aiff)
        [ -n "$(first_video_index "$IN")" ] && VIDEO_OPTS=(-vn) ;;
esac

TGT="I=$TARGET_I:TP=$TARGET_TP:LRA=$TARGET_LRA"
DM=""
if [ "$DUAL_MONO" = 1 ]; then
    TGT="$TGT:dual_mono=true"
    DM=":dualmono=true"
fi

# Pass 1: measure (both summaries are printed on stderr)
s=$(ffmpeg -hide_banner -nostdin -nostats -i "$IN" -vn \
      -af "${PRE:+$PRE,}ebur128=peak=true:framelog=quiet$DM,loudnorm=$TGT:print_format=json" \
      -f null - 2>&1)
ln_value() { printf '%s\n' "$s" | sed -n '/Summary:/,$p' | awk -v k="$1" '$1 == k { print $2; exit }'; }
mi=$(ln_value I:); mth=$(ln_value Threshold:); mlra=$(ln_value LRA:); mtp=$(ln_value Peak:)
off=$(printf '%s\n' "$s" | sed -n 's/.*"target_offset" : "\([^"]*\)".*/\1/p')
case "$mi" in
    ''|-70.0|*inf*)
        echo "Error: pass 1 failed or input is silent ($IN)" >&2
        printf '%s\n' "$s" | grep -iE 'error|invalid|no such' | tail -n 3 >&2
        exit 1 ;;
esac
case "$off" in ''|*inf*|*nan*) off=0 ;; esac
# loudnorm reads measured_LRA=0 as "not measured" and stays dynamic
case "$mlra" in 0|0.0) mlra=0.1 ;; esac

if [ "$KEEP_LRA" != 1 ] &&
   nl=$(awk -v m="$mlra" -v t="$TARGET_LRA" 'BEGIN { if (m > t) { n = int(m) + 1; if (n > 50) n = 50; print n; exit 0 } exit 1 }'); then
    echo "loudnorm-2pass: input LRA $mlra LU > target $TARGET_LRA LU; using LRA=$nl so linear mode can apply" >&2
    TGT="$TGT:LRA=$nl"
fi

# Pass 2: apply the measured values (linear=true: one fixed gain)
if ! log=$(ffmpeg -hide_banner -nostdin -nostats -n -i "$IN" \
      -af "${PRE:+$PRE,}loudnorm=$TGT:measured_I=$mi:measured_TP=$mtp:measured_LRA=$mlra:measured_thresh=$mth:offset=$off:linear=true:print_format=summary" \
      -ar 48000 "${VIDEO_OPTS[@]}" "${EXTRA[@]}" "$OUT" 2>&1); then
    printf '%s\n' "$log" | tail -n 5 >&2
    echo "Error: pass 2 failed" >&2
    rm -f -- "$OUT"   # did not exist before this run (checked above)
    exit 1
fi
if [ ! -s "$OUT" ]; then
    echo "Error: no output written" >&2
    exit 1
fi
type=$(printf '%s\n' "$log" | sed -n 's/^Normalization Type: *//p')

# Verify the written file with the same meter
got=$(ffmpeg -hide_banner -nostdin -nostats -i "$OUT" -vn -af "ebur128=framelog=quiet$DM" -f null - 2>&1 |
      sed -n '/Summary:/,$p' | awk '$1 == "I:" { print $2; exit }')
echo "loudnorm-2pass: ${type:-unknown} normalization, ${got:-?} LUFS (target $TARGET_I) -> $OUT" >&2
if [ -z "$got" ]; then
    echo "loudnorm-2pass: WARNING: could not measure the output" >&2
    exit 2
fi
if awk -v g="$got" -v t="$TARGET_I" 'BEGIN { d = g - t; exit !(d > 0.5 || d < -0.5) }'; then
    echo "loudnorm-2pass: WARNING: result is more than 0.5 LU from the target" >&2
    exit 2
fi
exit 0
