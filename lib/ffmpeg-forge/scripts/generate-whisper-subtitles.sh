#!/usr/bin/env bash
# Generate subtitles using FFmpeg 8.0 Whisper filter

# filter_escape, safe_path, require_bash_43
# shellcheck source=lib/filter-escape.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/filter-escape.sh" || exit 1
require_bash_43

set -eo pipefail

# Colors (only when stdout is a terminal, so piped/logged output stays clean)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' NC=''
fi

# Colored line; the text goes through %s, so backslashes in file names stay literal
say() { printf '%b%s%b\n' "$1" "$2" "$NC"; }

usage() {
    echo "Usage: $0 <input-video> [model] [language]"
    echo ""
    echo "Arguments:"
    echo "  input-video  Path to video file"
    echo "  model        Whisper model (tiny, base, small, medium, large-v3, large-v3-turbo) [default: base]"
    echo "  language     Language code (en, es, fr, auto, etc.) [default: auto]"
    echo ""
    echo "Writes <input-name>.srt and <input-name>.vtt to the current directory"
    echo "(never overwrites). Models are cached in \$WHISPER_MODEL_DIR"
    echo "(default ~/.cache/whisper) and downloaded on first use."
    echo ""
    echo "Examples:"
    echo "  $0 video.mp4"
    echo "  $0 video.mp4 medium en"
    echo "  $0 video.mp4 base auto"
}

case "$1" in
    -h|--help) usage; exit 0 ;;
    "") usage; exit 1 ;;
esac
require_tools ffmpeg ffprobe

echo "=== FFmpeg Whisper Subtitle Generator ==="
echo ""

INPUT="$1"
MODEL="${2:-base}"
# "large" alone no longer exists upstream; map it to large-v3
[ "$MODEL" = "large" ] && MODEL="large-v3"
LANGUAGE="${3:-auto}"

# The model name becomes part of a file path and a download URL, and the
# language a filter option: allow only plain names
if ! [[ "$MODEL" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && "$MODEL" != *..* ]]; then
    say "$RED" "Error: Invalid model name: $MODEL"
    echo "Use a whisper.cpp model name such as tiny, base, small, medium, large-v3, large-v3-turbo"
    exit 1
fi
if ! [[ "$LANGUAGE" =~ ^([a-z]{2,3}|auto)$ ]]; then
    say "$RED" "Error: Invalid language: $LANGUAGE (use a 2-3 letter code such as en, or auto)"
    exit 1
fi

if [ ! -f "$INPUT" ]; then
    say "$RED" "Error: Input file not found: $INPUT"
    exit 1
fi

INPUT=$(safe_path "$INPUT")

# Fail clearly up front instead of on the extraction step
if [ -z "$(ffprobe -v error -select_streams a -show_entries stream=index -of default=nw=1:nk=1 "$INPUT")" ]; then
    say "$RED" "Error: No audio stream found in: $INPUT"
    exit 1
fi

# Check FFmpeg version
# Capture whole outputs before filtering: under pipefail, "cmd | head"/"cmd | grep -q"
# can fail with SIGPIPE (141) when the reader exits before cmd finishes writing
FFMPEG_VERSION=$(ffmpeg -version 2>/dev/null || true)
FFMPEG_VERSION="${FFMPEG_VERSION%%$'\n'*}"
MAJOR_VERSION=$(echo "$FFMPEG_VERSION" | grep -oE 'version n?[0-9]+' | grep -oE '[0-9]+' || true)

if [ "$MAJOR_VERSION" -lt 8 ] 2>/dev/null; then
    say "$RED" "Error: FFmpeg 8.0+ required for Whisper filter"
    echo "Current version: $FFMPEG_VERSION"
    echo ""
    echo "Please update FFmpeg from: https://ffmpeg.org/download.html"
    exit 1
fi

# Check for Whisper filter
FILTERS=$(ffmpeg -hide_banner -filters 2>/dev/null || true)
if ! grep -qw whisper <<< "$FILTERS"; then
    say "$RED" "Error: Whisper filter not available in this FFmpeg build"
    echo ""
    echo "The Whisper filter requires FFmpeg built with whisper.cpp support."
    echo "See: https://github.com/FFmpeg/FFmpeg/blob/master/doc/filters.texi"
    exit 1
fi

echo "FFmpeg version: $FFMPEG_VERSION"
echo "Input: $INPUT"
echo "Model: $MODEL"
echo "Language: $LANGUAGE"
echo ""

# Output names (in the current directory), checked before any model download
BASENAME=$(basename "$INPUT" | sed 's/\.[^.]*$//')
# safe_path: the whisper filter opens destination= as a URL, so "clip:1.srt" would be a protocol
OUTPUT_SRT="$(safe_path "${BASENAME}.srt")"
OUTPUT_VTT="$(safe_path "${BASENAME}.vtt")"

for f in "$OUTPUT_SRT" "$OUTPUT_VTT"; do
    if [ -e "$f" ]; then
        say "$RED" "Error: Output already exists: $f"
        exit 1
    fi
done

# Model file paths
MODEL_DIR="${WHISPER_MODEL_DIR:-$HOME/.cache/whisper}"
MODEL_FILE="$(safe_path "$MODEL_DIR/ggml-${MODEL}.bin")"

# Download model if not present
if [ ! -f "$MODEL_FILE" ]; then
    say "$YELLOW" "Model not found, downloading..."
    mkdir -p "$MODEL_DIR"

    MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL}.bin"

    # Download to a temp file and move it into place only on success,
    # so a failed or 404 download is never mistaken for a model
    TMP_MODEL="$MODEL_FILE.part"
    if command -v curl &> /dev/null; then
        curl -fL -o "$TMP_MODEL" "$MODEL_URL" || { rm -f "$TMP_MODEL"; say "$RED" "Error: download failed: $MODEL_URL"; exit 1; }
    elif command -v wget &> /dev/null; then
        wget -O "$TMP_MODEL" "$MODEL_URL" || { rm -f "$TMP_MODEL"; say "$RED" "Error: download failed: $MODEL_URL"; exit 1; }
    else
        say "$RED" "Error: wget or curl required to download model"
        exit 1
    fi
    mv "$TMP_MODEL" "$MODEL_FILE"

    say "$GREEN" "Model downloaded to: $MODEL_FILE"
    echo ""
fi

# Extract audio first (for long videos, this is faster)
echo "=== Extracting audio ==="
TEMP_AUDIO="$(mktemp "${TMPDIR:-/tmp}/whisper_audio.XXXXXX")"
# On failure also remove the subtitle files this run started: whisper writes
# the SRT as it goes, and a partial one would block every retry
# shellcheck disable=SC2154  # rc is assigned inside the trap string
trap 'rc=$?; rm -f "$TEMP_AUDIO"; (( rc != 0 )) && rm -f -- "$OUTPUT_SRT" "$OUTPUT_VTT"; exit $rc' EXIT
if ! ffmpeg -nostdin -hide_banner -v error -y -i "$INPUT" -map 0:a:0 -vn -c:a pcm_s16le -ar 16000 -ac 1 -f wav "$TEMP_AUDIO"; then
    say "$RED" "Error: audio extraction failed (see ffmpeg error above)"
    exit 1
fi
say "$GREEN" "Audio extracted"
echo ""

# Generate subtitles
echo "=== Generating subtitles ==="
echo "This may take a while for long videos..."
echo ""

START_TIME=$(date +%s)

# The whisper filter writes the transcript itself via destination=;
# the audio stream is discarded with -f null.
ffmpeg -nostdin -hide_banner -f wav -i "$TEMP_AUDIO" \
    -af "whisper=model=$(filter_escape "$MODEL_FILE"):language=$(filter_escape "$LANGUAGE"):destination=$(filter_escape "$OUTPUT_SRT"):format=srt" \
    -f null -
if [ ! -s "$OUTPUT_SRT" ]; then
    say "$RED" "Error: whisper produced no subtitles (see ffmpeg output above)"
    exit 1
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# Convert to VTT as well
ffmpeg -nostdin -n -v error -i "$OUTPUT_SRT" "$OUTPUT_VTT"

# Results
echo ""
echo "=== Results ==="
echo ""
say "$GREEN" "Generated:"
echo "  SRT: $OUTPUT_SRT"
echo "  VTT: $OUTPUT_VTT"
echo ""
echo "Processing time: ${ELAPSED}s"

# Show preview
echo ""
echo "=== Subtitle Preview (first 5 entries) ==="
head -20 "$OUTPUT_SRT"
echo ""

# Suggest burn-in command
echo "=== To Burn Subtitles into Video ==="
echo ""
# Filter-escape the name, then make it safe inside a single-quoted shell word
SRT_ARG="subtitles=$(filter_escape "$OUTPUT_SRT")"
SRT_ARG="${SRT_ARG//\'/\'\\\'\'}"
echo "ffmpeg -i $(printf '%q' "$INPUT") -vf '$SRT_ARG' \\"
echo "  -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a copy \\"
echo "  $(printf '%q' "${BASENAME}_with_subs.mp4")"
echo ""

# Show accuracy tips
echo "=== Tips for Better Accuracy ==="
echo ""
echo "1. Use a larger model (medium or large) for better accuracy"
echo "2. Specify the language explicitly if known (e.g., 'en' instead of 'auto')"
echo "3. Clean up audio with noise reduction before transcription:"
echo "   ffmpeg -i input.mp4 -vn -af \"afftdn=nf=-25\" clean_audio.wav"
echo ""

echo "Done!"
