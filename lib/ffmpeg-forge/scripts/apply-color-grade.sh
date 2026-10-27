#!/bin/bash
# FFmpeg Color Grading Utility
# Apply various color grading presets and effects
# Usage: ./apply-color-grade.sh <preset> <input> <output> [intensity]
#
# Presets: cinematic, vintage, noir, warm, cool, bleach, instagram, matrix
# Intensity: 1-10 (default: 5)

set -e

PRESET="${1:-help}"
INPUT="$2"
OUTPUT="$3"
INTENSITY="${4:-5}"

# Validate intensity range
# 10# so values like "08" are read as decimal, not octal
if ! [[ "$INTENSITY" =~ ^[0-9]+$ ]] || (( 10#$INTENSITY < 1 || 10#$INTENSITY > 10 )); then
    echo "Error: Intensity must be between 1 and 10"
    exit 1
fi
INTENSITY=$((10#$INTENSITY))

# A relative path like "clip:1.mp4" would be read by ffmpeg as a protocol
# ("clip:"), so give such paths a ./ prefix
safe_path() {
    case "$1" in
        /*|./*|../*) printf '%s' "$1" ;;
        *) printf './%s' "$1" ;;
    esac
}

# bc prints values below 1 without the leading zero (".40", "-.05"); add it back
calc() {
    echo "scale=2; $1" | bc | sed 's/^\(-\{0,1\}\)\./\10./'
}

# libx264 with yuv420p needs even dimensions; appended to every chain
# (crop drops the odd last row/column instead of resampling the image)
EVEN_DIMS="crop=trunc(iw/2)*2:trunc(ih/2)*2"

# Validate arguments shared by every effect/preset
check_io() {
    [[ -z "$INPUT" || -z "$OUTPUT" ]] && { show_help; exit 1; }
    if [[ ! -f "$INPUT" ]]; then
        echo "Error: Input file not found: $INPUT"
        exit 1
    fi
    # ffmpeg exits 0 when it declines to overwrite, so check up front
    if [[ -e "$OUTPUT" ]]; then
        echo "Error: Output already exists: $OUTPUT"
        exit 1
    fi
    # Cover art (attached_pic) is reported as a video stream but is not one
    if ! ffprobe -v error -select_streams v -show_entries stream_disposition=attached_pic \
            -of default=nw=1:nk=1 "$(safe_path "$INPUT")" | grep -qx 0; then
        echo "Error: No video stream found in: $INPUT"
        exit 1
    fi
    INPUT=$(safe_path "$INPUT")
    OUTPUT=$(safe_path "$OUTPUT")
    # The output did not exist before, so remove a partial file if ffmpeg fails;
    # otherwise the leftover would make every retry stop at the check above
    trap 'rc=$?; (( rc != 0 )) && rm -f -- "$OUTPUT"; exit $rc' EXIT
}

show_help() {
    echo "FFmpeg Color Grading Utility"
    echo ""
    echo "Usage: $0 <preset> <input> <output> [intensity]"
    echo ""
    echo "Presets:"
    echo "  cinematic  - Teal and orange blockbuster look"
    echo "  vintage    - Faded film with warm tones"
    echo "  noir       - High contrast black & white"
    echo "  warm       - Golden hour / warm sunset"
    echo "  cool       - Moonlight / blue tones"
    echo "  bleach     - Bleach bypass / desaturated contrast"
    echo "  instagram  - Bright, lifted shadows"
    echo "  matrix     - Green tinted cyberpunk"
    echo ""
    echo "Intensity: 1-10 (default: 5)"
    echo ""
    echo "Examples:"
    echo "  $0 cinematic input.mp4 output.mp4"
    echo "  $0 vintage clip.mp4 retro.mp4 8"
    echo "  $0 noir scene.mp4 bw.mp4 10"
}

apply_cinematic() {
    local sat=$(calc "1.0 + ($INTENSITY * 0.04)")
    local contrast=$(calc "1.0 + ($INTENSITY * 0.02)")
    # Split tone per channel: shadows (0.25) toward teal (less red, more blue
    # and some green), highlights (0.75) toward orange (more red, less blue).
    # Mid-gray (0.5) and black/white stay fixed, so neutrals stay neutral.
    local r_lo=$(calc "0.25 - $INTENSITY * 0.008") r_hi=$(calc "0.75 + $INTENSITY * 0.008")
    local g_lo=$(calc "0.25 + $INTENSITY * 0.004") g_hi=$(calc "0.75 + $INTENSITY * 0.002")
    local b_lo=$(calc "0.25 + $INTENSITY * 0.008") b_hi=$(calc "0.75 - $INTENSITY * 0.008")
    echo "Applying cinematic teal & orange (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "curves=r='0/0 0.25/${r_lo} 0.5/0.5 0.75/${r_hi} 1/1':g='0/0 0.25/${g_lo} 0.5/0.5 0.75/${g_hi} 1/1':b='0/0 0.25/${b_lo} 0.5/0.5 0.75/${b_hi} 1/1',\
eq=saturation=${sat}:contrast=${contrast},${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_vintage() {
    local sat=$(calc "1.0 - ($INTENSITY * 0.03)")
    local brightness=$(calc "$INTENSITY * 0.005")
    echo "Applying vintage film look (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "curves=preset=vintage,eq=saturation=${sat}:brightness=${brightness},\
colorbalance=rs=0.1:gs=0.05:bs=-0.05,${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_noir() {
    local contrast=$(calc "1.2 + ($INTENSITY * 0.05)")
    local brightness=$(calc "-0.05 - ($INTENSITY * 0.01)")
    echo "Applying noir high contrast B&W (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "eq=contrast=${contrast}:brightness=${brightness}:saturation=0,\
curves=all='0/0 0.15/0.05 0.5/0.5 0.85/0.95 1/1',${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_warm() {
    local rs=$(calc "$INTENSITY * 0.02")
    local gs=$(calc "$INTENSITY * 0.01")
    local bs=$(calc "-$INTENSITY * 0.015")
    echo "Applying warm golden tones (intensity: $INTENSITY)..."
    # Highlight terms too: without them bright content (sky, skin) barely changes
    ffmpeg -i "$INPUT" \
        -vf "colorbalance=rs=${rs}:gs=${gs}:bs=${bs}:rm=${rs}:gm=${gs}:bm=${bs}:rh=${rs}:gh=${gs}:bh=${bs},${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_cool() {
    local bs=$(calc "$INTENSITY * 0.025")
    local rs=$(calc "-$INTENSITY * 0.015")
    local brightness=$(calc "-$INTENSITY * 0.01")
    echo "Applying cool moonlight tones (intensity: $INTENSITY)..."
    # Highlight terms too: without them bright content (sky, skin) barely changes
    ffmpeg -i "$INPUT" \
        -vf "colorbalance=rs=${rs}:bs=${bs}:rm=${rs}:bm=${bs}:rh=${rs}:bh=${bs},eq=brightness=${brightness},${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_bleach() {
    local sat=$(calc "1.0 - ($INTENSITY * 0.06)")
    local contrast=$(calc "1.0 + ($INTENSITY * 0.04)")
    echo "Applying bleach bypass (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "eq=saturation=${sat}:contrast=${contrast},curves=all='0/0 0.2/0.15 0.5/0.5 0.8/0.85 1/1',${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_instagram() {
    local sat=$(calc "1.0 + ($INTENSITY * 0.03)")
    local brightness=$(calc "$INTENSITY * 0.01")
    echo "Applying instagram bright look (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "eq=saturation=${sat}:brightness=${brightness}:contrast=1.05,\
curves=all='0/0.05 0.25/0.3 0.5/0.55 0.75/0.8 1/1',${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_matrix() {
    local gs=$(calc "$INTENSITY * 0.03")
    local rs=$(calc "-$INTENSITY * 0.02")
    local contrast=$(calc "1.0 + ($INTENSITY * 0.02)")
    echo "Applying matrix green tint (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "colorbalance=rs=${rs}:gs=${gs}:rm=${rs}:gm=${gs}:rh=${rs}:gh=${gs},\
eq=contrast=${contrast}:brightness=-0.05,${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

# Main execution
case "$PRESET" in
    help|--help|-h)
        show_help
        exit 0
        ;;
    cinematic)
        check_io
        apply_cinematic
        ;;
    vintage)
        check_io
        apply_vintage
        ;;
    noir)
        check_io
        apply_noir
        ;;
    warm)
        check_io
        apply_warm
        ;;
    cool)
        check_io
        apply_cool
        ;;
    bleach)
        check_io
        apply_bleach
        ;;
    instagram)
        check_io
        apply_instagram
        ;;
    matrix)
        check_io
        apply_matrix
        ;;
    *)
        echo "Unknown preset: $PRESET"
        show_help
        exit 1
        ;;
esac

echo "Done! Output saved to: $OUTPUT"
