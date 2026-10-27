#!/usr/bin/env bash
# FFmpeg slideshow from still images with xfade transitions
# Usage: ./slideshow.sh [options] <output.mp4> <transition|cycle> <image1> <image2> [image...]
#
# Each image is shown for --dur seconds, including its transitions, and
# consecutive images overlap by --trans seconds:
#   length   = N*DUR - (N-1)*TRANS
#   offset_k = k*(DUR - TRANS)   (start of cut k, k = 1..N-1)

# safe_path, require_bash_43
# shellcheck source=lib/filter-escape.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/filter-escape.sh" || exit 1
require_bash_43

set -e

DURATION=3      # seconds each image is shown, including its transitions
TRANSITION=1    # transition length; must be shorter than DURATION
FPS=30
SIZE=1920x1080
CYCLE=(fade wipeleft circleopen slideleft dissolve)   # used by "cycle"

show_help() {
    echo "FFmpeg slideshow with xfade transitions"
    echo ""
    echo "Usage: $0 [options] <output.mp4> <transition|cycle> <image1> <image2> [image...]"
    echo ""
    echo "  transition   any xfade transition except custom (fade, wipeleft, circleopen,"
    echo "               slideleft, dissolve, pixelize, ...; list: ffmpeg -h filter=xfade)"
    echo "  cycle        rotate through: ${CYCLE[*]}"
    echo ""
    echo "Options:"
    echo "  --dur S      seconds per image, including its transitions (default $DURATION)"
    echo "  --trans S    transition length in seconds, less than --dur (default $TRANSITION)"
    echo "  --fps N      output frame rate (default $FPS)"
    echo "  --size WxH   output size; images are fitted and padded (default $SIZE)"
    echo ""
    echo "Length = N*dur - (N-1)*trans seconds. Output: H.264 yuv420p, faststart, no audio."
    echo ""
    echo "Examples:"
    echo "  $0 slides.mp4 fade a.jpg b.jpg c.jpg"
    echo "  $0 --dur 4 --trans 1.5 --size 1080x1920 story.mp4 cycle *.jpg"
}

# Usage: is_number <value>  (positive decimal, e.g. 3 or 0.5)
is_number() {
    [[ "$1" =~ ^([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] && awk -v v="$1" 'BEGIN{exit !(v > 0)}'
}

POSITIONAL=()
while (( $# )); do
    case "$1" in
        -h|--help) show_help; exit 0 ;;
        --dur|--trans|--fps|--size)
            [[ $# -ge 2 && -n "$2" ]] || { echo "Error: $1 needs a value" >&2; exit 1; }
            case "$1" in
                --dur) DURATION="$2" ;;
                --trans) TRANSITION="$2" ;;
                --fps) FPS="$2" ;;
                --size) SIZE="$2" ;;
            esac
            shift 2
            ;;
        --dur=*) DURATION="${1#*=}"; shift ;;
        --trans=*) TRANSITION="${1#*=}"; shift ;;
        --fps=*) FPS="${1#*=}"; shift ;;
        --size=*) SIZE="${1#*=}"; shift ;;
        --) shift; POSITIONAL+=("$@"); break ;;
        -?*) echo "Error: Unknown option: $1 (see $0 -h)" >&2; exit 1 ;;
        *) POSITIONAL+=("$1"); shift ;;
    esac
done
set -- "${POSITIONAL[@]}"

if (( $# == 0 )); then
    show_help
    exit 1
fi
if (( $# < 4 )); then
    echo "Error: Need an output, a transition and at least two images (see $0 -h)" >&2
    exit 1
fi

OUTPUT="$1"
TRANS_NAME="$2"
shift 2
require_tools ffmpeg ffprobe
IMAGES=("$@")

# Validate options
is_number "$DURATION" || { echo "Error: --dur must be a positive number of seconds: $DURATION" >&2; exit 1; }
is_number "$TRANSITION" || { echo "Error: --trans must be a positive number of seconds: $TRANSITION" >&2; exit 1; }
if ! awk -v d="$DURATION" -v t="$TRANSITION" 'BEGIN{exit !(t < d)}'; then
    echo "Error: --trans ($TRANSITION) must be shorter than --dur ($DURATION)" >&2
    exit 1
fi
[[ "$FPS" =~ ^[1-9][0-9]{0,2}$ ]] || { echo "Error: --fps must be a whole number from 1 to 999: $FPS" >&2; exit 1; }
if [[ "$SIZE" =~ ^([1-9][0-9]{1,4})x([1-9][0-9]{1,4})$ ]]; then
    W=${BASH_REMATCH[1]}; H=${BASH_REMATCH[2]}
else
    echo "Error: --size must be WIDTHxHEIGHT, e.g. 1920x1080: $SIZE" >&2
    exit 1
fi
if (( W % 2 || H % 2 )); then
    echo "Error: --size needs even numbers for yuv420p: $SIZE" >&2
    exit 1
fi

# Transition: "cycle", or a name this build's xfade knows (custom needs an expression)
if [[ "$TRANS_NAME" != cycle ]]; then
    known=$(ffmpeg -hide_banner -h filter=xfade 2>/dev/null |
        awk '/^ *transition /{on=1; next} on && /^ *[a-z_]+ +-?[0-9]+ /{print $1; next} on{exit}')
    if [[ "$TRANS_NAME" == custom ]]; then
        echo "Error: custom needs an expression; build that graph by hand (see references/transitions.md)" >&2
        exit 1
    fi
    if [[ -n "$known" ]] && ! grep -qx -- "$TRANS_NAME" <<< "$known"; then
        echo "Error: Unknown transition: $TRANS_NAME (list: ffmpeg -h filter=xfade, or use cycle)" >&2
        exit 1
    fi
fi

for img in "${IMAGES[@]}"; do
    if [[ ! -f "$img" || ! -r "$img" ]]; then
        echo "Error: Image not found or not readable: $img" >&2
        exit 1
    fi
    # An undecodable file behind -loop 1 makes ffmpeg retry forever, so
    # decode one frame of each image first
    if ! ffmpeg -nostdin -v error -xerror -i "$(safe_path "$img")" -frames:v 1 -f null - >/dev/null 2>&1; then
        echo "Error: Not a decodable image: $img" >&2
        exit 1
    fi
done

case "${OUTPUT##*.}" in
    mp4|MP4|m4v|mov|mkv) ;;
    *) echo "Error: Output must end in .mp4, .m4v, .mov or .mkv: $OUTPUT" >&2; exit 1 ;;
esac
if [[ -e "$OUTPUT" ]]; then
    echo "Error: Output already exists: $OUTPUT" >&2
    exit 1
fi
for img in "${IMAGES[@]}"; do
    if [[ "$img" -ef "$OUTPUT" ]]; then
        echo "Error: Output is one of the input images: $OUTPUT" >&2
        exit 1
    fi
done

# Inputs: each image looped for DURATION seconds, fitted into WxH and padded
args=(); graph=""; n=0
for img in "${IMAGES[@]}"; do
    args+=(-loop 1 -t "$DURATION" -i "$(safe_path "$img")")
    graph+="[$n:v]scale=$W:$H:force_original_aspect_ratio=decrease,pad=$W:$H:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=${FPS}[v$n];"
    n=$((n+1))
done

# Cut k starts where the stream built so far ends minus one transition:
# offset_k = k*DURATION - k*TRANSITION (equal-length images)
prev="v0"
for ((k=1; k<n; k++)); do
    offset=$(awk -v k="$k" -v d="$DURATION" -v t="$TRANSITION" 'BEGIN{print k*(d-t)}')
    if [[ "$TRANS_NAME" == cycle ]]; then
        tr=${CYCLE[$(( (k-1) % ${#CYCLE[@]} ))]}
    else
        tr="$TRANS_NAME"
    fi
    graph+="[$prev][v$k]xfade=transition=$tr:duration=$TRANSITION:offset=${offset}[x$k];"
    prev="x$k"
done
# xfade outputs yuv444p and JPEGs are full range: convert to limited-range
# 4:2:0 so the file plays everywhere
graph+="[$prev]scale=out_range=tv,format=yuv420p[v]"

LENGTH=$(awk -v n="$n" -v d="$DURATION" -v t="$TRANSITION" 'BEGIN{print n*d-(n-1)*t}')
echo "Building ${LENGTH} s slideshow from $n images (${W}x${H}, $FPS fps)..."

# The output did not exist before, so remove a partial file if ffmpeg fails
SAFE_OUTPUT=$(safe_path "$OUTPUT")
if ! ffmpeg -nostdin -hide_banner -loglevel error -n "${args[@]}" -filter_complex "$graph" -map "[v]" \
    -c:v libx264 -crf 20 -preset medium -pix_fmt yuv420p -movflags +faststart "$SAFE_OUTPUT"; then
    rm -f -- "$SAFE_OUTPUT"
    echo "Error: ffmpeg failed" >&2
    exit 1
fi
if [[ ! -s "$OUTPUT" ]]; then
    echo "Error: ffmpeg did not write $OUTPUT" >&2
    exit 1
fi

echo "Done! Output saved to: $OUTPUT"
