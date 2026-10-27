#!/bin/bash
# Generate subtitles using FFmpeg 8.0 Whisper filter

set -eo pipefail

# Colors (only when stdout is a terminal, so piped/logged output stays clean)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' NC=''
fi

echo "=== FFmpeg Whisper Subtitle Generator ==="
echo ""

# Escape a path for use as a filter option value inside -vf/-af.
# Two levels: the option parser (\ : ') then the filtergraph parser (\ ').
# Paths containing , ; [ ] are not supported.
filter_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//:/\\:}"; s="${s//\'/\\\'}"
    s="${s//\\/\\\\}"; s="${s//\'/\\\'}"
    printf '%s' "$s"
}

# A relative path like "clip:1.mp4" would be read by ffmpeg as a protocol
# ("clip:"), so give such paths a ./ prefix
safe_path() {
    case "$1" in
        /*|./*|../*) printf '%s' "$1" ;;
        *) printf './%s' "$1" ;;
    esac
}

# Check for arguments
if [ -z "$1" ]; then
    echo "Usage: $0 <input-video> [model] [language]"
    echo ""
    echo "Arguments:"
    echo "  input-video  Path to video file"
    echo "  model        Whisper model (tiny, base, small, medium, large-v3, large-v3-turbo) [default: base]"
    echo "  language     Language code (en, es, fr, auto, etc.) [default: auto]"
    echo ""
    echo "Examples:"
    echo "  $0 video.mp4"
    echo "  $0 video.mp4 medium en"
    echo "  $0 video.mp4 base auto"
    exit 1
fi

INPUT="$1"
MODEL="${2:-base}"
# "large" alone no longer exists upstream; map it to large-v3
[ "$MODEL" = "large" ] && MODEL="large-v3"
LANGUAGE="${3:-auto}"

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Error: Input file not found: $INPUT${NC}"
    exit 1
fi

INPUT=$(safe_path "$INPUT")

# Fail clearly up front instead of on the extraction step
if [ -z "$(ffprobe -v error -select_streams a -show_entries stream=index -of default=nw=1:nk=1 "$INPUT")" ]; then
    echo -e "${RED}Error: No audio stream found in: $INPUT${NC}"
    exit 1
fi

# Check FFmpeg version
# Capture whole outputs before filtering: under pipefail, "cmd | head"/"cmd | grep -q"
# can fail with SIGPIPE (141) when the reader exits before cmd finishes writing
FFMPEG_VERSION=$(ffmpeg -version 2>/dev/null || true)
FFMPEG_VERSION="${FFMPEG_VERSION%%$'\n'*}"
MAJOR_VERSION=$(echo "$FFMPEG_VERSION" | grep -oE 'version n?[0-9]+' | grep -oE '[0-9]+' || true)

if [ "$MAJOR_VERSION" -lt 8 ] 2>/dev/null; then
    echo -e "${RED}Error: FFmpeg 8.0+ required for Whisper filter${NC}"
    echo "Current version: $FFMPEG_VERSION"
    echo ""
    echo "Please update FFmpeg from: https://ffmpeg.org/download.html"
    exit 1
fi

# Check for Whisper filter
FILTERS=$(ffmpeg -hide_banner -filters 2>/dev/null || true)
if ! grep -qw whisper <<< "$FILTERS"; then
    echo -e "${RED}Error: Whisper filter not available in this FFmpeg build${NC}"
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

# Model file paths
MODEL_DIR="${WHISPER_MODEL_DIR:-$HOME/.cache/whisper}"
MODEL_FILE="$(safe_path "$MODEL_DIR/ggml-${MODEL}.bin")"

# Download model if not present
if [ ! -f "$MODEL_FILE" ]; then
    echo -e "${YELLOW}Model not found, downloading...${NC}"
    mkdir -p "$MODEL_DIR"

    MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${MODEL}.bin"

    # Download to a temp file and move it into place only on success,
    # so a failed or 404 download is never mistaken for a model
    TMP_MODEL="$MODEL_FILE.part"
    if command -v curl &> /dev/null; then
        curl -fL -o "$TMP_MODEL" "$MODEL_URL" || { rm -f "$TMP_MODEL"; echo -e "${RED}Error: download failed: $MODEL_URL${NC}"; exit 1; }
    elif command -v wget &> /dev/null; then
        wget -O "$TMP_MODEL" "$MODEL_URL" || { rm -f "$TMP_MODEL"; echo -e "${RED}Error: download failed: $MODEL_URL${NC}"; exit 1; }
    else
        echo -e "${RED}Error: wget or curl required to download model${NC}"
        exit 1
    fi
    mv "$TMP_MODEL" "$MODEL_FILE"

    echo -e "${GREEN}Model downloaded to: $MODEL_FILE${NC}"
    echo ""
fi

# Generate output filename
BASENAME=$(basename "$INPUT" | sed 's/\.[^.]*$//')
# safe_path: the whisper filter opens destination= as a URL, so "clip:1.srt" would be a protocol
OUTPUT_SRT="$(safe_path "${BASENAME}.srt")"
OUTPUT_VTT="$(safe_path "${BASENAME}.vtt")"

for f in "$OUTPUT_SRT" "$OUTPUT_VTT"; do
    if [ -e "$f" ]; then
        echo -e "${RED}Error: Output already exists: $f${NC}"
        exit 1
    fi
done

# Extract audio first (for long videos, this is faster)
echo "=== Extracting audio ==="
TEMP_AUDIO="$(mktemp "${TMPDIR:-/tmp}/whisper_audio.XXXXXX")"
trap 'rm -f "$TEMP_AUDIO"' EXIT
if ! ffmpeg -nostdin -hide_banner -v error -y -i "$INPUT" -map 0:a:0 -vn -c:a pcm_s16le -ar 16000 -ac 1 -f wav "$TEMP_AUDIO"; then
    echo -e "${RED}Error: audio extraction failed (see ffmpeg error above)${NC}"
    exit 1
fi
echo -e "${GREEN}Audio extracted${NC}"
echo ""

# Generate subtitles
echo "=== Generating subtitles ==="
echo "This may take a while for long videos..."
echo ""

START_TIME=$(date +%s)

# The whisper filter writes the transcript itself via destination=;
# the audio stream is discarded with -f null.
ffmpeg -hide_banner -f wav -i "$TEMP_AUDIO" \
    -af "whisper=model=$(filter_escape "$MODEL_FILE"):language=$LANGUAGE:destination=$(filter_escape "$OUTPUT_SRT"):format=srt" \
    -f null -

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# Convert to VTT as well
ffmpeg -v error -i "$OUTPUT_SRT" "$OUTPUT_VTT"

# Results
echo ""
echo "=== Results ==="
echo ""
echo -e "${GREEN}Generated:${NC}"
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
echo "ffmpeg -i \"$INPUT\" -vf '$SRT_ARG' \\"
echo "  -c:v libx264 -crf 20 -c:a copy \\"
echo "  \"${BASENAME}_with_subs.mp4\""
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
