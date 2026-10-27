#!/bin/bash
# Check FFmpeg codec and encoder availability

set -e  # check_* functions return 1 on "missing"; callers below append "|| true"

# Colors (only when stdout is a terminal, so piped/logged output stays clean)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

echo "=== FFmpeg Codec Availability Check ==="
echo ""

# Check FFmpeg version
echo "=== FFmpeg Version ==="
FFMPEG_VERSION=$(ffmpeg -version 2>/dev/null | head -1)
if [ -n "$FFMPEG_VERSION" ]; then
    echo -e "${GREEN}$FFMPEG_VERSION${NC}"
else
    echo -e "${RED}FFmpeg not found!${NC}"
    exit 1
fi
echo ""

# Several features checked below (whisper, WHIP, Vulkan AV1 encoding) need 8.0+
MAJOR_VERSION=$(echo "$FFMPEG_VERSION" | grep -oE 'version n?[0-9]+' | grep -oE '[0-9]+' || true)
if [ "$MAJOR_VERSION" -lt 8 ] 2>/dev/null; then
    echo -e "${YELLOW}Note: FFmpeg 8.0 or newer is needed for whisper, WHIP and Vulkan AV1 encoding${NC}"
    echo "  Visit https://ffmpeg.org/download.html to update"
    echo ""
fi

# Video Encoders
echo "=== Video Encoders ==="
echo ""

check_encoder() {
    local encoder=$1
    local name=$2
    if ffmpeg -encoders 2>/dev/null | grep -q "^ [VAS]..... $encoder "; then
        echo -e "${GREEN}[✓] $name ($encoder)${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name ($encoder)${NC}"
        return 1
    fi
}

echo "Software Encoders:"
check_encoder "libx264" "H.264/AVC" || true
check_encoder "libx265" "H.265/HEVC" || true
check_encoder "libvpx-vp9" "VP9" || true
check_encoder "libaom-av1" "AV1 (libaom)" || true
check_encoder "libsvtav1" "AV1 (SVT-AV1)" || true
check_encoder "libvvenc" "VVC/H.266 (FFmpeg 7.1+)" || true
check_encoder "prores" "ProRes" || true

echo ""
echo "Hardware Encoders (NVIDIA):"
check_encoder "h264_nvenc" "NVENC H.264" || true
check_encoder "hevc_nvenc" "NVENC H.265" || true
check_encoder "av1_nvenc" "NVENC AV1" || true

echo ""
echo "Hardware Encoders (Intel QSV):"
check_encoder "h264_qsv" "QSV H.264" || true
check_encoder "hevc_qsv" "QSV H.265" || true
check_encoder "av1_qsv" "QSV AV1" || true
check_encoder "vp9_qsv" "QSV VP9" || true

echo ""
echo "Hardware Encoders (AMD/VAAPI):"
check_encoder "h264_vaapi" "VAAPI H.264" || true
check_encoder "hevc_vaapi" "VAAPI H.265" || true
check_encoder "av1_vaapi" "VAAPI AV1" || true
check_encoder "h264_amf" "AMF H.264" || true
check_encoder "hevc_amf" "AMF H.265" || true

echo ""
echo "Vulkan Encoders:"
check_encoder "h264_vulkan" "Vulkan H.264 (FFmpeg 7.1+)" || true
check_encoder "hevc_vulkan" "Vulkan H.265 (FFmpeg 7.1+)" || true
check_encoder "av1_vulkan" "Vulkan AV1 (FFmpeg 8.0+)" || true

echo ""

# Video Decoders
echo "=== Video Decoders ==="
echo ""

check_decoder() {
    local decoder=$1
    local name=$2
    if ffmpeg -decoders 2>/dev/null | grep -q "^ V..... $decoder "; then
        echo -e "${GREEN}[✓] $name ($decoder)${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name ($decoder)${NC}"
        return 1
    fi
}

echo "VVC/H.266 Decoders:"
check_decoder "vvc" "VVC Native" || true

echo ""
echo "Hardware Decoders:"
check_decoder "h264_cuvid" "CUVID H.264" || true
check_decoder "hevc_cuvid" "CUVID H.265" || true
check_decoder "av1_cuvid" "CUVID AV1" || true
check_decoder "vvc_qsv" "QSV VVC (FFmpeg 7.1+)" || true

echo ""

# Audio Codecs
echo "=== Audio Codecs ==="
echo ""

echo "Encoders:"
check_encoder "aac" "AAC (native)" || true
check_encoder "libfdk_aac" "AAC (Fraunhofer FDK)" || true
check_encoder "libmp3lame" "MP3" || true
check_encoder "libopus" "Opus" || true
check_encoder "flac" "FLAC" || true
check_encoder "libvorbis" "Vorbis" || true

echo ""

# Filters
echo "=== Special Filters ==="
echo ""

check_filter() {
    local filter=$1
    local name=$2
    if ffmpeg -filters 2>/dev/null | grep -q " $filter "; then
        echo -e "${GREEN}[✓] $name ($filter)${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name ($filter)${NC}"
        return 1
    fi
}

check_filter "whisper" "Whisper AI (FFmpeg 8.0+)" || true
check_filter "loudnorm" "EBU R128 Loudness" || true
check_filter "scale_cuda" "CUDA Scaling" || true
check_filter "scale_npp" "NPP Scaling" || true
check_filter "scale_qsv" "QSV Scaling" || true
check_filter "pad_cuda" "CUDA Padding (FFmpeg 8.0+)" || true
check_filter "colordetect" "Color Detection (FFmpeg 8.0+)" || true

echo ""

# Hardware Acceleration
echo "=== Hardware Acceleration ==="
echo "(✓ means compiled into this build, not that the GPU and driver are present and working)"
echo ""

HWACCELS=$(ffmpeg -hwaccels 2>/dev/null | tail -n +2)
if [ -n "$HWACCELS" ]; then
    echo "Available hardware accelerators:"
    echo "$HWACCELS" | while read hw; do
        [ -n "$hw" ] && echo -e "  ${GREEN}[✓] $hw${NC}"
    done
else
    echo -e "${YELLOW}No hardware acceleration available${NC}"
fi

echo ""

# Muxers/Protocols
echo "=== Streaming Protocols ==="
echo ""

check_muxer() {
    local muxer=$1
    local name=$2
    if ffmpeg -muxers 2>/dev/null | grep -q " $muxer "; then
        echo -e "${GREEN}[✓] $name${NC}"
        return 0
    else
        echo -e "${RED}[✗] $name${NC}"
        return 1
    fi
}

check_muxer "flv" "RTMP (FLV)" || true
check_muxer "hls" "HLS" || true
check_muxer "dash" "DASH" || true
check_muxer "rtsp" "RTSP" || true
check_muxer "whip" "WHIP/WebRTC (FFmpeg 8.0+)" || true

echo ""

# Summary
echo "=== Summary ==="
echo ""

# Only the codec rows (" V....D name  ..."), not the legend line " V..... = Video"
ENCODER_COUNT=$(ffmpeg -encoders 2>/dev/null | grep -cE '^ V[^ ]{5} [^ =]')
DECODER_COUNT=$(ffmpeg -decoders 2>/dev/null | grep -cE '^ V[^ ]{5} [^ =]')
# Only the filter rows (" TS name  A->V  ..."), not the legend above them
FILTER_COUNT=$(ffmpeg -filters 2>/dev/null | grep -cE '^ [T.][S.] [^ ]+ +[^ ]*->')

echo "Note: ✓ means compiled in. Hardware encoders also need the matching GPU and driver."
echo "Video encoders: $ENCODER_COUNT"
echo "Video decoders: $DECODER_COUNT"
echo "Filters: $FILTER_COUNT"

echo ""
echo "Done!"
