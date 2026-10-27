#!/bin/bash
# FFmpeg Glitch Effects Utility
# Apply various glitch/distortion effects to video
# Usage: ./apply-glitch-effects.sh <effect> <input> <output> [intensity]
#
# Effects: datamosh, vhs, chromatic, trails, wave, pixelate, combined
# Intensity: 1-10 (default: 5)

set -e

EFFECT="${1:-help}"
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

# bc prints values below 1 without the leading zero (".86"); add it back
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
    echo "FFmpeg Glitch Effects Utility"
    echo ""
    echo "Usage: $0 <effect> <input> <output> [intensity]"
    echo ""
    echo "Effects:"
    echo "  datamosh   - Motion interpolation glitch (pixel bleeding)"
    echo "  vhs        - VHS tape simulation (noise, tracking, color shift)"
    echo "  chromatic  - Chromatic aberration (RGB color separation)"
    echo "  trails     - Motion trails / ghosting effect"
    echo "  wave       - Wave distortion effect"
    echo "  pixelate   - Dynamic pixelation effect"
    echo "  combined   - Combined glitch effect (datamosh + chromatic + noise)"
    echo ""
    echo "Intensity: 1-10 (default: 5)"
    echo ""
    echo "Examples:"
    echo "  $0 datamosh input.mp4 output.mp4"
    echo "  $0 vhs input.mp4 retro.mp4 8"
    echo "  $0 chromatic clip.mp4 glitch.mp4 3"
}

# One stream entry of the first video stream: probe_v0 <entry> [ffprobe options]
# default=nw=1:nk=1, not csv: csv adds a trailing comma when the stream has
# side data (e.g. the display matrix of a rotated phone video).
# head -n1: MPEG-TS/M2TS print each stream twice (again under its program)
probe_v0() {
    local entry="$1"; shift
    ffprobe -v error "$@" -select_streams v:0 -show_entries "stream=$entry" \
        -of default=nw=1:nk=1 "$INPUT" | head -n1
}

# Frame rate ffmpeg will use for the input.
# Raw .h264/.hevc streams have no timestamps: avg_frame_rate is the demuxer's
# 25/1 default whatever the stream says. The real rate is the stream's VUI
# timing, shown as r_frame_rate (doubled for H.264, which counts field ticks:
# 30 fps reports 60/1). Without VUI timing r_frame_rate is the 1200000/1
# timebase and ffmpeg itself falls back to 25 fps.
# Other containers: average rate when known; r_frame_rate is a timebase guess.
source_fps() {
    local fps fmt num den
    fmt=$(ffprobe -v error -show_entries format=format_name -of default=nw=1:nk=1 "$INPUT")
    if [[ "$fmt" == h264 || "$fmt" == hevc ]]; then
        fps=$(probe_v0 r_frame_rate)
        num=${fps%/*}; den=${fps#*/}
        if [[ "$fps" =~ ^[1-9][0-9]*/[1-9][0-9]*$ ]] && (( num <= 1000 * den )); then
            if [[ "$fmt" == h264 ]]; then
                if (( num % 2 == 0 )); then num=$((num / 2)); else den=$((den * 2)); fi
            fi
            echo "${num}/${den}"
        else
            echo "25/1"
        fi
        return
    fi
    fps=$(probe_v0 avg_frame_rate)
    [[ "$fps" =~ ^[1-9][0-9]*/[1-9][0-9]*$ ]] || fps=$(probe_v0 r_frame_rate)
    echo "$fps"
}

# Video frame count: the header value if there is one (MP4), otherwise count
# the packets (MKV, raw .h264), which only demuxes and does not decode
source_frames() {
    local n
    n=$(probe_v0 nb_frames)
    [[ "$n" =~ ^[0-9]+$ ]] || n=$(probe_v0 nb_read_packets -count_packets)
    echo "$n"
}

# Filter chain that keeps 1 of every $1 frames, then motion-interpolates back
# to the source rate. The invented in-between frames are where the "bleed" comes
# from; at the source rate alone minterpolate would only pass frames through.
# fps drops the tail and minterpolate stops at the second-to-last kept frame, so
# tpad clones the last frame for 2x$1 frames first; trim cuts back to the source
# frame count (no trim if it is unknown).
mosh_chain() {
    local src num den frames trim=""
    src=$(source_fps)
    num=${src%/*}; den=${src#*/}
    frames=$(source_frames)
    [[ "$frames" =~ ^[0-9]+$ ]] && (( frames > 0 )) && trim=",trim=end_frame=${frames}"
    echo "tpad=stop_mode=clone:stop=$((2 * $1)),fps=${num}/$((den * $1)),minterpolate='fps=${src}:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1:scd=none'${trim}"
}

apply_datamosh() {
    # Higher intensity drops more frames, so more of the output is interpolated
    local keep_every=$(( (INTENSITY + 1) / 2 + 1 ))
    echo "Applying datamosh effect (intensity: $INTENSITY, 1 of every $keep_every frames kept)..."
    ffmpeg -i "$INPUT" \
        -vf "$(mosh_chain "$keep_every"),${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_vhs() {
    local noise_strength=$((INTENSITY * 3))
    local chroma_shift=$((INTENSITY / 2 + 1))
    echo "Applying VHS effect (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "noise=c0s=${noise_strength}:c0f=t:c1s=$((noise_strength/2)):c1f=t,\
eq=saturation=1.3:contrast=1.1:brightness=-0.02,\
chromashift=cbh=${chroma_shift}:crh=-${chroma_shift},\
rgbashift=rh=$((chroma_shift/2)):bh=-$((chroma_shift/2)),\
curves=preset=vintage,${EVEN_DIMS}" \
        -c:v libx264 -crf 20 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_chromatic() {
    local shift=$((INTENSITY + 2))
    echo "Applying chromatic aberration (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "rgbashift=rh=-${shift}:bh=${shift}:rv=$((shift/2)):bv=-$((shift/2)),${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_trails() {
    local decay=$(calc "0.85 + ($INTENSITY * 0.012)")
    echo "Applying motion trails (intensity: $INTENSITY, decay: $decay)..."
    ffmpeg -i "$INPUT" \
        -vf "lagfun=decay=${decay},${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_wave() {
    local amplitude=$((INTENSITY * 2 + 5))
    local frequency=$((20 - INTENSITY))
    echo "Applying wave distortion (intensity: $INTENSITY)..."
    ffmpeg -i "$INPUT" \
        -vf "format=gbrp,geq=r='r(X+${amplitude}*sin(Y/${frequency}+T*5),Y)':g='g(X+${amplitude}*sin(Y/${frequency}+T*5),Y)':b='b(X+${amplitude}*sin(Y/${frequency}+T*5),Y)',format=yuv420p,${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_pixelate() {
    local scale_factor=$((12 - INTENSITY))
    [[ "$scale_factor" -lt 2 ]] && scale_factor=2
    echo "Applying pixelation (intensity: $INTENSITY, scale: 1/${scale_factor})..."
    # Scale back to the size of the frames as decoded (scale's second input is
    # the size reference, FFmpeg 7.1+), not the probed stream size: a rotated
    # phone video is autorotated, so its frames are e.g. 360x640, not 640x360
    ffmpeg -i "$INPUT" \
        -vf "split[src][ref];[src]scale=iw/${scale_factor}:ih/${scale_factor}:flags=neighbor[small];\
[small][ref]scale=rw:rh:flags=neighbor,${EVEN_DIMS}" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

apply_combined() {
    local noise_strength=$((INTENSITY * 2))
    local shift=$((INTENSITY / 2 + 1))
    echo "Applying combined glitch effect (intensity: $INTENSITY)..."
    # minterpolate has no timeline support, so it runs on a split branch
    # that is overlaid only during the glitch bursts
    ffmpeg -i "$INPUT" \
        -filter_complex "[0:v]split[base][mosh];\
[mosh]$(mosh_chain 3)[m];\
[base][m]overlay=enable='lt(mod(t,3),0.2)',\
rgbashift=rh=${shift}:bh=-${shift}:enable='lt(mod(t,1),0.15)',\
noise=c0s=${noise_strength}:c0f=t:enable='lt(mod(t,2),0.1)',${EVEN_DIMS}[v]" \
        -map "[v]" -map 0:a? \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -c:a copy "$OUTPUT"
}

# Main execution
case "$EFFECT" in
    help|--help|-h)
        show_help
        exit 0
        ;;
    datamosh)
        check_io
        apply_datamosh
        ;;
    vhs)
        check_io
        apply_vhs
        ;;
    chromatic)
        check_io
        apply_chromatic
        ;;
    trails)
        check_io
        apply_trails
        ;;
    wave)
        check_io
        apply_wave
        ;;
    pixelate)
        check_io
        apply_pixelate
        ;;
    combined)
        check_io
        apply_combined
        ;;
    *)
        echo "Unknown effect: $EFFECT"
        show_help
        exit 1
        ;;
esac

echo "Done! Output saved to: $OUTPUT"
