#!/usr/bin/env bash
# Two-pass encode to a target file size (H.264 or HEVC + AAC).
#
# Video bitrate = (target size - ~2% mux overhead) / duration - audio bitrate.
# Pass 1 writes the rate-control log to a private temp directory (removed on
# exit), pass 2 encodes. If the result still overshoots (short or noisy clips
# can), pass 2 is rerun up to twice with the bitrate scaled down by the miss.
# Ctrl-C or SIGTERM stops ffmpeg and removes a partial output (exit 130/143).
#
# Return codes: 0 = written and within the target, 1 = failed,
#               2 = written but still larger than the target,
#               130/143 = interrupted (SIGINT/SIGTERM).

# shellcheck source=lib/filter-escape.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/filter-escape.sh" || exit 1
require_bash_43

# Lowest video bitrate worth encoding; below it the picture falls apart
MIN_VIDEO_KBPS=100
# Pass-2 reruns allowed when the first result overshoots the target
MAX_RETRIES=2

usage() {
    cat <<EOF
Usage: $0 <input> <output> <size_MB> [x264|x265] [audio_kbps]

  size_MB      target size in MB (1 MB = 1,000,000 bytes); decimals allowed
  x264|x265    video encoder (default x264)
  audio_kbps   AAC bitrate in kb/s (default 128; 0 drops the audio)

Writes yuv420p video, AAC audio, and for MP4/MOV +faststart (and the hvc1 tag
for x265). Refuses to overwrite the output, and refuses targets that leave
less than $MIN_VIDEO_KBPS kb/s for the video.

Return codes: 0 = within the target, 1 = failed, 2 = written but over the target,
130/143 = interrupted (a partial output is removed).

Examples:
  $0 input.mp4 output.mp4 25
  $0 input.mov small.mp4 8 x265 96
EOF
}

case "${1:-}" in
    "") usage >&2; exit 1 ;;
    -h|--help) usage; exit 0 ;;
esac
if [ $# -lt 3 ] || [ $# -gt 5 ]; then
    usage >&2
    exit 1
fi

IN="$1"; OUT="$2"; SIZE_MB="$3"; CODEC="${4:-x264}"; AUDIO_K="${5:-128}"

if ! [[ "$SIZE_MB" =~ ^[0-9]+([.][0-9]+)?$ ]] || ! awk -v m="$SIZE_MB" 'BEGIN { exit !(m > 0) }'; then
    echo "Error: size_MB must be a positive number (got '$SIZE_MB')" >&2
    exit 1
fi
if ! [[ "$AUDIO_K" =~ ^[0-9]+$ ]]; then
    echo "Error: audio_kbps must be a whole number (got '$AUDIO_K')" >&2
    exit 1
fi
case "$CODEC" in
    x264) VCODEC=libx264 ;;
    x265) VCODEC=libx265 ;;
    *) echo "Error: codec must be x264 or x265 (got '$CODEC')" >&2; exit 1 ;;
esac
require_tools ffmpeg ffprobe
if ! ffmpeg -hide_banner -encoders 2>/dev/null | grep -qw "$VCODEC"; then
    echo "Error: this ffmpeg has no $VCODEC encoder" >&2
    exit 1
fi

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

VIDX=$(first_video_index "$IN")
if [ -z "$VIDX" ]; then
    echo "Error: no video stream in $IN" >&2
    exit 1
fi
HAS_AUDIO=$(ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$IN" | head -n1)
[ -n "$HAS_AUDIO" ] || AUDIO_K=0

DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$IN")
if ! awk -v d="$DUR" 'BEGIN { exit !(d + 0 > 0) }' 2>/dev/null; then
    DUR=$(ffprobe -v error -select_streams "$VIDX" -show_entries stream=duration -of default=nw=1:nk=1 "$IN")
fi
if ! awk -v d="$DUR" 'BEGIN { exit !(d + 0 > 0) }' 2>/dev/null; then
    echo "Error: cannot read the duration of $IN" >&2
    exit 1
fi

TARGET_BYTES=$(awk -v m="$SIZE_MB" 'BEGIN { printf "%d", m * 1000000 }')
# kbit available for the whole file after ~2% container overhead, per second
VIDEO_K=$(awk -v m="$SIZE_MB" -v d="$DUR" -v a="$AUDIO_K" 'BEGIN { printf "%d", m * 8000 * 0.98 / d - a }')
if [ "$VIDEO_K" -lt "$MIN_VIDEO_KBPS" ]; then
    echo "Error: ${SIZE_MB} MB over ${DUR} s leaves ${VIDEO_K} kb/s for the video (minimum $MIN_VIDEO_KBPS)." >&2
    echo "Raise the size, lower audio_kbps, or trim the input." >&2
    exit 1
fi

# Container-specific flags
EXTRA=()
case "${OUT,,}" in
    *.mp4|*.m4v|*.mov)
        EXTRA+=(-movflags +faststart)
        [ "$CODEC" = x265 ] && EXTRA+=(-tag:v hvc1)
        ;;
esac
if [ "$AUDIO_K" -gt 0 ]; then
    AUDIO_OPTS=(-map 0:a:0 -c:a aac -b:a "${AUDIO_K}k")
else
    AUDIO_OPTS=(-an)
fi

# Private directory for the pass log. x265 takes the log path inside
# -x265-params, where ':' and '=' are separators, so avoid such a TMPDIR.
TMPBASE="${TMPDIR:-/tmp}"
case "$TMPBASE" in *[:=,]*) TMPBASE=/tmp ;; esac
PASSDIR=$(mktemp -d "$TMPBASE/encode-to-size.XXXXXX") || { echo "Error: cannot create a temp directory" >&2; exit 1; }

# ffmpeg runs in the background and the script waits for it, so Ctrl-C and
# SIGTERM reach the traps at once. on_exit stops ffmpeg, removes the pass log,
# and removes the output while this run is still writing it (OUT did not exist
# before the run, checked above).
CHILD=""
WRITING_OUT=0
# shellcheck disable=SC2329  # invoked by the EXIT trap below
on_exit() {
    if [ -n "$CHILD" ]; then
        kill "$CHILD" 2>/dev/null || true
        wait "$CHILD" 2>/dev/null || true
    fi
    [ "$WRITING_OUT" -eq 1 ] && rm -f -- "$OUT"
    rm -rf -- "$PASSDIR"
}
trap on_exit EXIT
trap 'echo "" >&2; echo "Interrupted; partial output removed" >&2; exit 130' INT
trap 'exit 143' TERM

# Same filters and pixel format in both passes; even dimensions for 4:2:0
VF="scale=trunc(iw/2)*2:trunc(ih/2)*2,format=yuv420p"

pass_opts() {   # $1 = pass number, $2 = video kb/s
    if [ "$CODEC" = x264 ]; then
        printf '%s\n' -c:v libx264 -preset medium -b:v "${2}k" -pass "$1" -passlogfile "$PASSDIR/x264"
    else
        printf '%s\n' -c:v libx265 -preset medium -b:v "${2}k" -x265-params "pass=$1:stats=$PASSDIR/x265.log"
    fi
}

run_ffmpeg() {
    local rc=0
    ffmpeg -hide_banner -nostdin -v error "$@" 2>"$PASSDIR/ffmpeg.log" &
    CHILD=$!
    wait "$CHILD" || rc=$?
    CHILD=""
    if [ "$rc" -ne 0 ]; then
        tail -n 5 "$PASSDIR/ffmpeg.log" >&2
        return 1
    fi
}

# Pass 2 into OUT; a failed or interrupted pass removes OUT
encode_pass2() {   # $1 = video kb/s
    local opts
    mapfile -t opts < <(pass_opts 2 "$1")
    WRITING_OUT=1
    if ! run_ffmpeg -n -i "$IN" -map "0:$VIDX" -vf "$VF" "${opts[@]}" "${AUDIO_OPTS[@]}" "${EXTRA[@]}" "$OUT" \
       || [ ! -s "$OUT" ]; then
        rm -f -- "$OUT"
        WRITING_OUT=0
        return 1
    fi
    WRITING_OUT=0
}

file_size() { stat -c %s -- "$1" 2>/dev/null || wc -c < "$1"; }

echo "Duration ${DUR} s, target ${SIZE_MB} MB: video ${VIDEO_K} kb/s ($VCODEC), audio ${AUDIO_K} kb/s" >&2

mapfile -t P1 < <(pass_opts 1 "$VIDEO_K")
echo "Pass 1/2..." >&2
if ! run_ffmpeg -y -i "$IN" -map "0:$VIDX" -vf "$VF" "${P1[@]}" -an -f null /dev/null; then
    echo "Error: pass 1 failed" >&2
    exit 1
fi

echo "Pass 2/2..." >&2
if ! encode_pass2 "$VIDEO_K"; then
    echo "Error: pass 2 failed" >&2
    exit 1
fi

SIZE=$(file_size "$OUT")
CUR_K=$VIDEO_K
TRY=0
while [ "$SIZE" -gt "$TARGET_BYTES" ] && [ "$TRY" -lt "$MAX_RETRIES" ]; do
    TRY=$((TRY + 1))
    # Overshoot: take the lower of (a) the bitrate scaled by target/actual and
    # (b) the bitrate minus 1.5x the miss, each with a 3% margin. (b) matters
    # when fixed-size audio is a large part of the file.
    NEW_K=$(awk -v v="$CUR_K" -v t="$TARGET_BYTES" -v s="$SIZE" -v d="$DUR" '
        BEGIN { a = v * (t / s) * 0.97; over = (s - t) * 8 / 1000 / d
                b = (v - over * 1.5) * 0.97; n = (a < b ? a : b); printf "%d", (n > 0 ? n : 0) }')
    echo "Output is $SIZE bytes, over the $TARGET_BYTES-byte target" >&2
    if [ "$NEW_K" -lt "$MIN_VIDEO_KBPS" ]; then
        echo "Error: a retry would need under $MIN_VIDEO_KBPS kb/s of video (the encoder cannot go this small here); keeping the oversized file" >&2
        break
    fi
    echo "Retry $TRY/$MAX_RETRIES of pass 2 at ${NEW_K} kb/s" >&2
    # Keep the current result aside: a lower bitrate does not always give a
    # smaller file (x264 floor on noisy video), so the smaller one is kept
    mv -f -- "$OUT" "$PASSDIR/previous"
    if ! encode_pass2 "$NEW_K"; then
        echo "Error: pass 2 retry failed" >&2
        exit 1
    fi
    CUR_K=$NEW_K
    NEW_SIZE=$(file_size "$OUT")
    if [ "$NEW_SIZE" -gt "$SIZE" ]; then
        echo "Retry gave $NEW_SIZE bytes, larger than before; keeping the previous result" >&2
        mv -f -- "$PASSDIR/previous" "$OUT"
    else
        SIZE=$NEW_SIZE
    fi
done

echo "Wrote $OUT: $SIZE bytes (target $TARGET_BYTES)" >&2
if [ "$SIZE" -gt "$TARGET_BYTES" ]; then
    echo "WARNING: output is still larger than the target" >&2
    exit 2
fi
exit 0
