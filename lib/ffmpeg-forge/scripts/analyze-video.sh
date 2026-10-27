#!/bin/bash
# Analyze video file and provide encoding recommendations

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

if [ -z "$1" ]; then
    echo "Usage: $0 <video-file>"
    echo ""
    echo "Analyzes a video file and provides encoding recommendations"
    exit 1
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
calc() {
    echo "scale=2; $1" | bc | sed 's/^\(-\{0,1\}\)\./\10./'
}

# Frame rate of video stream $VSEL, as ffmpeg will use it.
# Raw .h264/.hevc streams have no timestamps: avg_frame_rate is the demuxer's
# 25/1 default whatever the stream says. The real rate is the stream's VUI
# timing, shown as r_frame_rate (doubled for H.264, which counts field ticks:
# 30 fps reports 60/1). Without VUI timing r_frame_rate is the 1200000/1
# timebase and ffmpeg itself falls back to 25 fps.
# Other containers: average rate first; 0/0 means unknown, so fall back to
# r_frame_rate (a timebase guess)
video_fps() {
    local fps num den
    if [[ "$FORMAT" == h264 || "$FORMAT" == hevc ]]; then
        fps=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
        num=${fps%/*}; den=${fps#*/}
        if [[ "$fps" =~ ^[1-9][0-9]*/[1-9][0-9]*$ ]] && (( num <= 1000 * den )); then
            if [[ "$FORMAT" == h264 ]]; then
                if (( num % 2 == 0 )); then num=$((num / 2)); else den=$((den * 2)); fi
            fi
            echo "${num}/${den}"
        else
            echo "25/1"
        fi
        return
    fi
    fps=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    [[ "$fps" =~ ^[1-9][0-9]*/[1-9][0-9]*$ ]] || fps=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    echo "$fps"
}

INPUT="$1"

if [ ! -f "$INPUT" ]; then
    echo -e "${RED}Error: File not found: $INPUT${NC}"
    exit 1
fi
INPUT=$(safe_path "$INPUT")

echo "=== Video Analysis: $(basename "$INPUT") ==="
echo ""

# Get file info
echo "=== File Information ==="
FILE_SIZE=$(ls -lh "$INPUT" | awk '{print $5}')
FILE_SIZE_BYTES=$(stat -c %s "$INPUT" 2>/dev/null || stat -f %z "$INPUT" 2>/dev/null)
echo "File size: $FILE_SIZE"

# Stop early if ffprobe cannot read the container at all (e.g. truncated MP4)
if ! PROBE_ERR=$(ffprobe -v error -show_format "$INPUT" 2>&1 >/dev/null); then
    echo -e "${RED}[✗] ffprobe cannot read this file:${NC}"
    echo "$PROBE_ERR" | head -5
    exit 1
fi

# Get container format
FORMAT=$(ffprobe -v error -show_entries format=format_name -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
DURATION=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
# Raw streams (e.g. .h264) report duration/bitrate as N/A
if [[ "$DURATION" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    DUR_S=${DURATION%.*}
    DURATION_HMS=$(printf '%02d:%02d:%02d' $((DUR_S / 3600)) $((DUR_S % 3600 / 60)) $((DUR_S % 60)))
else
    DURATION_HMS="unknown"
fi
BITRATE=$(ffprobe -v error -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
if [[ "$BITRATE" =~ ^[0-9]+$ ]]; then
    BITRATE_MBPS=$(calc "$BITRATE / 1000000")
else
    BITRATE_MBPS="N/A"
fi

echo "Container: $FORMAT"
echo "Duration: $DURATION_HMS"
echo "Overall bitrate: ${BITRATE_MBPS} Mbps"
echo ""

# Video stream info
echo "=== Video Stream ==="
HAS_VIDEO=1
# First real video stream: cover art (attached_pic) is reported as video but is not
# (compact, not csv: csv adds a trailing comma when the stream has side data,
# e.g. the display matrix of a rotated phone video)
VSEL=$(ffprobe -v error -select_streams v -show_entries stream=index:stream_disposition=attached_pic -of compact=p=0:nk=1 "$INPUT" | awk -F'|' '$2 == 0 { print $1; exit }')
VIDEO_CODEC=""
if [ -n "$VSEL" ]; then
    VIDEO_CODEC=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    VIDEO_WIDTH=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=width -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    VIDEO_HEIGHT=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=height -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    VIDEO_FPS=$(video_fps)
    VIDEO_BITRATE=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    PIXEL_FORMAT=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=pix_fmt -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    COLOR_SPACE=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream=color_space -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null | head -1)
    [ -n "$COLOR_SPACE" ] || COLOR_SPACE="unknown"
    # Phone videos store a display rotation; width/height are the stored (unrotated) size
    ROTATION=$(ffprobe -v error -select_streams "$VSEL" -show_entries stream_side_data=rotation -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
fi

if [ -z "$VIDEO_CODEC" ]; then
    HAS_VIDEO=0
    echo "No video stream found"
else
echo "Codec: $VIDEO_CODEC"
# Display size: ffmpeg autorotates, so a 90/270 rotation swaps width and height
DISPLAY_WIDTH=$VIDEO_WIDTH DISPLAY_HEIGHT=$VIDEO_HEIGHT
if [[ "$ROTATION" =~ ^-?(90|270)$ ]]; then
    DISPLAY_WIDTH=$VIDEO_HEIGHT DISPLAY_HEIGHT=$VIDEO_WIDTH
    echo "Resolution: ${DISPLAY_WIDTH}x${DISPLAY_HEIGHT} (stored ${VIDEO_WIDTH}x${VIDEO_HEIGHT}, rotated ${ROTATION}°)"
else
    echo "Resolution: ${VIDEO_WIDTH}x${VIDEO_HEIGHT}"
fi
# Classify by the long side, so portrait video is not rated by its short side
LONG_SIDE=$(( ${VIDEO_WIDTH:-0} > ${VIDEO_HEIGHT:-0} ? ${VIDEO_WIDTH:-0} : ${VIDEO_HEIGHT:-0} ))
echo "Frame rate: $VIDEO_FPS"
echo "Pixel format: $PIXEL_FORMAT"
[ "$COLOR_SPACE" != "unknown" ] && echo "Color space: $COLOR_SPACE"

if [ -n "$VIDEO_BITRATE" ] && [ "$VIDEO_BITRATE" != "N/A" ]; then
    VIDEO_BITRATE_MBPS=$(calc "$VIDEO_BITRATE / 1000000" 2>/dev/null || echo "N/A")
    echo "Video bitrate: ${VIDEO_BITRATE_MBPS} Mbps"
fi
fi

echo ""

# Audio stream info
echo "=== Audio Stream ==="
# head -1 on every stream probe: MPEG-TS/M2TS print each stream twice (again under its program)
AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null | head -1)

if [ -n "$AUDIO_CODEC" ]; then
    AUDIO_CHANNELS=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    AUDIO_SAMPLE_RATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" | head -1)
    AUDIO_BITRATE=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate -of default=noprint_wrappers=1:nokey=1 "$INPUT" 2>/dev/null | head -1)

    echo "Codec: $AUDIO_CODEC"
    echo "Channels: $AUDIO_CHANNELS"
    echo "Sample rate: ${AUDIO_SAMPLE_RATE} Hz"
    [[ "$AUDIO_BITRATE" =~ ^[0-9]+$ ]] && echo "Bitrate: $((AUDIO_BITRATE / 1000)) kbps"
else
    echo "No audio stream found"
fi

echo ""

if [ "$HAS_VIDEO" -eq 0 ]; then
    echo "=== Encoding Recommendations ==="
    echo ""
    echo -e "${CYAN}Audio-only file (AAC):${NC}"
    echo "ffmpeg -i \"$INPUT\" -c:a aac -b:a 160k output.m4a"
    echo ""
else
# Quality assessment
echo "=== Quality Assessment ==="

# Resolution classification
if [ "$LONG_SIDE" -ge 3840 ]; then
    RESOLUTION_CLASS="4K/UHD"
elif [ "$LONG_SIDE" -ge 2560 ]; then
    RESOLUTION_CLASS="1440p/QHD"
elif [ "$LONG_SIDE" -ge 1920 ]; then
    RESOLUTION_CLASS="1080p/FHD"
elif [ "$LONG_SIDE" -ge 1280 ]; then
    RESOLUTION_CLASS="720p/HD"
elif [ "$LONG_SIDE" -ge 854 ]; then
    RESOLUTION_CLASS="480p/SD"
else
    RESOLUTION_CLASS="Low Resolution"
fi
echo "Resolution class: $RESOLUTION_CLASS"

# Frame rate classification
FPS_NUM=$(echo "$VIDEO_FPS" | cut -d'/' -f1)
FPS_DEN=$(echo "$VIDEO_FPS" | cut -d'/' -f2)
FPS_FLOAT=$(calc "$FPS_NUM / $FPS_DEN" 2>/dev/null || echo "30")

if (( $(echo "$FPS_FLOAT >= 50" | bc -l) )); then
    echo "Frame rate: High (${FPS_FLOAT} fps - good for gaming/sports)"
elif (( $(echo "$FPS_FLOAT >= 24" | bc -l) )); then
    echo "Frame rate: Standard (${FPS_FLOAT} fps)"
else
    echo -e "${YELLOW}Frame rate: Low (${FPS_FLOAT} fps)${NC}"
fi

echo ""

# Encoding recommendations
echo "=== Encoding Recommendations ==="
echo ""

# 4:2:0 output needs even dimensions; crop drops the odd last row/column
EVEN_VF=""
if (( ${VIDEO_WIDTH:-0} % 2 || ${VIDEO_HEIGHT:-0} % 2 )); then
    EVEN_VF='-vf "crop=trunc(iw/2)*2:trunc(ih/2)*2" '
    echo -e "${YELLOW}Odd dimensions (${VIDEO_WIDTH}x${VIDEO_HEIGHT}): the commands below crop to even size for 4:2:0${NC}"
    echo ""
fi

echo -e "${CYAN}For Web Delivery (Maximum Compatibility):${NC}"
echo "ffmpeg -i \"$INPUT\" \\"
echo "  ${EVEN_VF}-c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p \\"
echo "  -c:a aac -b:a 160k \\"
echo "  -movflags +faststart \\"
echo "  output.mp4"
echo ""

echo -e "${CYAN}For Smaller File Size (H.265):${NC}"
echo "ffmpeg -i \"$INPUT\" \\"
echo "  ${EVEN_VF}-c:v libx265 -preset medium -crf 26 -pix_fmt yuv420p \\"
echo "  -tag:v hvc1 -c:a aac -b:a 160k \\"
echo "  -movflags +faststart \\"
echo "  output_h265.mp4"
echo ""

if [ "$LONG_SIDE" -ge 3840 ]; then
    echo -e "${CYAN}For 4K with VVC (FFmpeg 7.1+):${NC}"
    echo "ffmpeg -i \"$INPUT\" \\"
    echo "  ${EVEN_VF}-c:v libvvenc -qp 28 \\"
    echo "  -vvenc-params \"preset=medium:tiles=4x4\" \\"
    echo "  -c:a aac -b:a 160k \\"
    echo "  output_vvc.mp4"
    echo ""
fi

echo -e "${CYAN}With NVIDIA Hardware Acceleration:${NC}"
if [ -n "$EVEN_VF" ]; then
    # crop runs on the CPU, so frames are not kept in GPU memory here
    echo "ffmpeg -hwaccel cuda -i \"$INPUT\" \\"
else
    echo "ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i \"$INPUT\" \\"
fi
echo "  ${EVEN_VF}-c:v h264_nvenc -preset p4 -rc vbr -cq 23 -b:v 0 \\"
echo "  -c:a aac -b:a 160k \\"
echo "  output_nvenc.mp4"
echo ""
fi

# File validation
echo "=== File Validation ==="
echo ""

echo "Checking file integrity..."
# ffmpeg exits 0 on many decode errors, so any error output counts as a failure
DECODE_ERRORS=$(ffmpeg -nostdin -v error -i "$INPUT" -f null - 2>&1) || DECODE_ERRORS="${DECODE_ERRORS:-ffmpeg failed}"
if [ -z "$DECODE_ERRORS" ]; then
    echo -e "${GREEN}[✓] File is valid and playable${NC}"
else
    echo -e "${RED}[✗] File has errors or corruption${NC}"
    echo "$DECODE_ERRORS" | head -5
fi

echo ""
echo "Done!"
# Non-zero status so scripts/CI can act on a corrupt file
[ -z "$DECODE_ERRORS" ] || exit 2
