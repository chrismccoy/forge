#!/bin/bash
# Benchmark FFmpeg encoding performance with different presets and encoders

set -e

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

# A relative path like "clip:1.mp4" would be read by ffmpeg as a protocol
# ("clip:"), so give such paths a ./ prefix
safe_path() {
    case "$1" in
        /*|./*|../*) printf '%s' "$1" ;;
        *) printf './%s' "$1" ;;
    esac
}

# bc prints values below 1 without the leading zero (".96"); add it back
leading_zero() {
    sed 's/^\(-\{0,1\}\)\./\10./'
}

INPUT="$1"
DURATION="${2:-10}"  # Default 10 seconds for benchmark

if ! [[ "$DURATION" =~ ^([0-9]+(\.[0-9]*)?|\.[0-9]+)$ ]] || (( $(echo "$DURATION <= 0" | bc -l) )); then
    echo -e "${RED}Error: Benchmark duration must be a positive number of seconds: $DURATION${NC}"
    exit 1
fi

echo "=== FFmpeg Encoding Benchmark ==="
echo ""

# Temp files are removed on any exit; the source is only generated (and so
# only deleted) when no input was given
OUTPUT="$(safe_path "$(mktemp "${TMPDIR:-/tmp}/ffmpeg_benchmark.XXXXXX")")"
GENERATED_SOURCE=""
cleanup() { rm -f "$OUTPUT" ${GENERATED_SOURCE:+"$GENERATED_SOURCE"}; }
trap cleanup EXIT

# Create test source if no input provided
if [ -z "$INPUT" ]; then
    echo "No input file provided, generating test source..."
    GENERATED_SOURCE="$(safe_path "$(mktemp "${TMPDIR:-/tmp}/ffmpeg_benchmark_source.XXXXXX")")"
    INPUT="$GENERATED_SOURCE"
    ffmpeg -y -f lavfi -i testsrc=size=1280x720:rate=30 \
        -f lavfi -i sine=frequency=1000 \
        -t "$DURATION" -c:v libx264 -preset ultrafast -c:a aac \
        -f mp4 "$INPUT" 2>/dev/null
    echo "Generated test source: ${DURATION}s of 720p30"
    echo ""
fi

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Error: Input file not found: $INPUT${NC}"
    exit 1
fi
INPUT=$(safe_path "$INPUT")

# Get input info (one value per line; csv would add a trailing comma when the
# stream has side data, e.g. the display matrix of a rotated phone video)
{ read -r WIDTH; read -r HEIGHT; read -r FPS; read -r AVG_FPS; } < <(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width,height,r_frame_rate,avg_frame_rate \
    -of default=nw=1:nk=1 "$INPUT") || true

# Frame rate as ffmpeg will use it: real_fps <r_frame_rate> <avg_frame_rate>
# Raw .h264/.hevc streams have no timestamps: avg_frame_rate is the demuxer's
# 25/1 default whatever the stream says. The real rate is the stream's VUI
# timing, shown as r_frame_rate (doubled for H.264, which counts field ticks:
# 30 fps reports 60/1). Without VUI timing r_frame_rate is the 1200000/1
# timebase and ffmpeg itself falls back to 25 fps.
# Other containers: avg_frame_rate when known; r_frame_rate is a timebase guess.
real_fps() {
    local fmt num den
    fmt=$(ffprobe -v error -show_entries format=format_name -of default=nw=1:nk=1 "$INPUT")
    if [[ "$fmt" == h264 || "$fmt" == hevc ]]; then
        num=${1%/*}; den=${1#*/}
        if [[ "$1" =~ ^[1-9][0-9]*/[1-9][0-9]*$ ]] && (( num <= 1000 * den )); then
            if [[ "$fmt" == h264 ]]; then
                if (( num % 2 == 0 )); then num=$((num / 2)); else den=$((den * 2)); fi
            fi
            echo "${num}/${den}"
        else
            echo "25/1"
        fi
    elif [[ "$2" =~ ^[1-9][0-9]*/[1-9][0-9]*$ ]]; then
        echo "$2"
    else
        echo "$1"
    fi
}
FPS=$(real_fps "$FPS" "$AVG_FPS")

if [ -z "$WIDTH" ] || [ -z "$HEIGHT" ]; then
    echo -e "${RED}Error: No video stream found in: $INPUT${NC}"
    exit 1
fi

# Seconds actually encoded: the input may be shorter than the requested duration
INPUT_DURATION=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$INPUT")
ENCODE_DURATION="$DURATION"
if [[ "$INPUT_DURATION" =~ ^[0-9.]+$ ]] && (( $(echo "$INPUT_DURATION < $DURATION" | bc -l) )); then
    ENCODE_DURATION="$INPUT_DURATION"
fi

echo "Input: ${WIDTH}x${HEIGHT} @ ${FPS} fps"
echo "Benchmark duration: ${ENCODE_DURATION}s"
echo ""

# Benchmark function
# Args: name, encoder, encoder options, extra output options, global options
# (option strings are split on whitespace; do not quote inside them)
benchmark_encode() {
    local name="$1"
    local encoder="$2"
    local preset extra_args global_args
    read -ra preset <<< "$3"
    read -ra extra_args <<< "$4"
    read -ra global_args <<< "$5"

    echo -e "${CYAN}Testing: $name${NC}"

    # Check if encoder is available
    if ! ffmpeg -encoders 2>/dev/null | grep -q "^ V..... $encoder "; then
        echo -e "${YELLOW}  [SKIP] Encoder not available${NC}"
        echo ""
        return
    fi

    # Hardware encoders can be compiled in with no usable device; a 1-frame
    # probe encode tells "no device" apart from a real benchmark failure
    case "$encoder" in
        *_nvenc|*_qsv|*_amf|*_vaapi|*_vulkan|*_v4l2m2m|*_videotoolbox|*_mf)
            if ! ffmpeg -nostdin -v error "${global_args[@]}" -f lavfi -i color=size=256x256:rate=30 \
                -frames:v 1 -c:v "$encoder" "${preset[@]}" "${extra_args[@]}" \
                -f null - &>/dev/null; then
                echo -e "${YELLOW}  [SKIP] no usable device${NC}"
                echo ""
                return
            fi
            ;;
    esac

    START_TIME=$(date +%s.%N)

    if ffmpeg -nostdin -y "${global_args[@]}" -i "$INPUT" -t "$DURATION" \
        -c:v "$encoder" "${preset[@]}" "${extra_args[@]}" \
        -c:a aac -b:a 128k \
        -f mp4 "$OUTPUT" 2>/dev/null; then

        END_TIME=$(date +%s.%N)
        local elapsed_raw
        elapsed_raw=$(echo "$END_TIME - $START_TIME" | bc)
        # Shown rounded to 2 decimals (bc's scale only truncates, so add half a unit)
        ELAPSED=$(echo "scale=2; ($elapsed_raw + 0.005) / 1" | bc | leading_zero)
        # Measure what was actually written, falling back to the expected length
        local actual
        actual=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUTPUT" 2>/dev/null)
        [[ "$actual" =~ ^[0-9.]+$ ]] && (( $(echo "$actual > 0" | bc -l) )) || actual="$ENCODE_DURATION"
        SPEED=$(echo "scale=2; $actual / $elapsed_raw" | bc | leading_zero)
        OUTPUT_SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
        OUTPUT_BYTES=$(stat -c %s "$OUTPUT" 2>/dev/null || stat -f %z "$OUTPUT" 2>/dev/null)
        BITRATE=$(echo "scale=0; $OUTPUT_BYTES * 8 / $actual / 1000" | bc)

        echo "  Time: ${ELAPSED}s"
        echo "  Speed: ${SPEED}x real-time"
        echo "  Output size: $OUTPUT_SIZE"
        echo "  Bitrate: ${BITRATE} kbps"

        if (( $(echo "$SPEED >= 1" | bc -l) )); then
            echo -e "  ${GREEN}[✓] Real-time capable${NC}"
        else
            echo -e "  ${YELLOW}[!] Slower than real-time${NC}"
        fi

    else
        echo -e "  ${RED}[FAIL] Encoding failed${NC}"
    fi

    echo ""
}

echo "=== Software Encoders ==="
echo ""

# x264 presets
benchmark_encode "x264 ultrafast" "libx264" "-preset ultrafast -crf 23"
benchmark_encode "x264 veryfast" "libx264" "-preset veryfast -crf 23"
benchmark_encode "x264 medium" "libx264" "-preset medium -crf 23"
benchmark_encode "x264 slow" "libx264" "-preset slow -crf 23"

# x265
benchmark_encode "x265 medium" "libx265" "-preset medium -crf 23" "-tag:v hvc1"

# VP9
benchmark_encode "VP9 good quality" "libvpx-vp9" "-crf 30 -b:v 0"

# AV1 (slow but best compression)
benchmark_encode "AV1 (libaom)" "libaom-av1" "-crf 30 -cpu-used 8"
benchmark_encode "AV1 (SVT-AV1)" "libsvtav1" "-crf 30 -preset 8"

echo "=== Hardware Encoders ==="
echo ""

# NVIDIA NVENC
benchmark_encode "NVENC H.264 p1" "h264_nvenc" "-preset p1 -rc vbr -cq 23 -b:v 0"
benchmark_encode "NVENC H.264 p4" "h264_nvenc" "-preset p4 -rc vbr -cq 23 -b:v 0"
benchmark_encode "NVENC H.264 p7" "h264_nvenc" "-preset p7 -rc vbr -cq 23 -b:v 0"
benchmark_encode "NVENC H.265" "hevc_nvenc" "-preset p4 -rc vbr -cq 23 -b:v 0"
benchmark_encode "NVENC AV1" "av1_nvenc" "-preset p4 -rc vbr -cq 23 -b:v 0"

# Intel QSV
benchmark_encode "QSV H.264" "h264_qsv" "-preset fast"
benchmark_encode "QSV H.265" "hevc_qsv" "-preset fast"

# AMD AMF
benchmark_encode "AMF H.264" "h264_amf" "-quality speed"
benchmark_encode "AMF H.265" "hevc_amf" "-quality speed"

# VAAPI
benchmark_encode "VAAPI H.264" "h264_vaapi" "" "-vf format=nv12,hwupload" "-vaapi_device /dev/dri/renderD128"
benchmark_encode "VAAPI H.265" "hevc_vaapi" "" "-vf format=nv12,hwupload" "-vaapi_device /dev/dri/renderD128"

echo "=== VVC (FFmpeg 7.1+) ==="
echo ""

benchmark_encode "VVC faster" "libvvenc" "-vvenc-params preset=faster" "-qp 28"
benchmark_encode "VVC medium" "libvvenc" "-vvenc-params preset=medium" "-qp 28"

# Summary
echo "=== Summary ==="
echo ""
echo "Encoder recommendations based on benchmark:"
echo ""
echo "For live streaming (real-time required):"
echo "  1. NVENC (if NVIDIA GPU available)"
echo "  2. QSV (if Intel GPU available)"
echo "  3. x264 ultrafast/veryfast"
echo ""
echo "For offline encoding (quality priority):"
echo "  1. x264 slow/veryslow"
echo "  2. x265 medium/slow"
echo "  3. AV1 (SVT-AV1) for best compression"
echo ""
echo "For cutting-edge compression (FFmpeg 7.1+):"
echo "  1. VVC/H.266 (slow but 25-50% better than HEVC)"
echo ""

echo "Done!"
