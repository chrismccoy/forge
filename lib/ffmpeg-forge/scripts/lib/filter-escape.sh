# shellcheck shell=bash
# Shared helpers for the ffmpeg-forge scripts. Source it, do not run it:
#   . "$(dirname "${BASH_SOURCE[0]}")/lib/filter-escape.sh"
#
# Keep require_bash_43 parseable by bash 3.2 (no 4.x syntax above it), so an
# old bash reaches the error message instead of a syntax error.

# Stop with a clear message on bash older than 4.3 (macOS /bin/bash is 3.2).
# filter_escape relies on 4.3+ quoting of ${var//pattern/replacement}.
require_bash_43() {
    if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ] ||
       { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 3 ]; }; then
        echo "Error: bash 4.3 or newer is required (this is bash ${BASH_VERSION:-unknown})." >&2
        echo "On macOS: brew install bash, then run the script again (it uses /usr/bin/env bash)." >&2
        exit 1
    fi
    # BASH_COMPAT=4.2 or lower brings the old quoting back on a new bash
    case "${BASH_COMPAT:-}" in
        3*|4.0|4.1|4.2|40|41|42)
            echo "Error: BASH_COMPAT=$BASH_COMPAT is not supported; unset it (bash 4.3+ behavior is required)." >&2
            exit 1
            ;;
    esac
}

# Stop with a clear message when a required program (ffmpeg, ffprobe, ...) is
# not on PATH, instead of a raw "command not found" later
require_tools() {
    local t
    for t in "$@"; do
        if ! command -v "$t" >/dev/null 2>&1; then
            echo "Error: $t not found on PATH. Install FFmpeg (it provides ffmpeg and ffprobe) or add it to PATH." >&2
            exit 1
        fi
    done
}

# Stop with a clear message when bc (used for decimal math) is missing
require_bc() {
    if ! command -v bc >/dev/null 2>&1; then
        echo "Error: bc is required but not installed (e.g. apt install bc / dnf install bc)." >&2
        exit 1
    fi
}

# Escape a string for use as a filter option value inside -vf/-af/-filter_complex.
# FFmpeg unescapes it twice:
#   1. option level (av_get_token): \ ' : =  and spaces (so edge spaces are kept)
#   2. filtergraph level:           \ ' , ; [ ]  and spaces
# Each level escapes its own backslashes first, before adding new ones.
filter_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\'/\\\'}"; s="${s//:/\\:}"; s="${s//=/\\=}"; s="${s// /\\ }"
    s="${s//\\/\\\\}"; s="${s//\'/\\\'}"
    s="${s//,/\\,}"; s="${s//;/\\;}"; s="${s//\[/\\[}"; s="${s//\]/\\]}"; s="${s// /\\ }"
    printf '%s' "$s"
}

# A relative path like "clip:1.mp4" would be read by ffmpeg as a protocol
# ("clip:"), and "-x.mp4" as an option, so give such paths a ./ prefix
safe_path() {
    case "$1" in
        /*|./*|../*) printf '%s' "$1" ;;
        *) printf './%s' "$1" ;;
    esac
}

# Index of the first real video stream of file $1 (empty if none).
# Cover art (attached_pic) is reported as video but is not. A still-image track
# (mjpeg/png/... thumbnail without the attached_pic flag) is only used when there
# is nothing else, matching ffmpeg's own default pick. compact, not csv: csv adds
# a trailing comma when the stream has side data (rotated phone video).
first_video_index() {
    ffprobe -v error -select_streams v -show_entries stream=index,codec_name:stream_disposition=attached_pic \
        -of compact=p=0:nk=1 "$1" | awk -F'|' '
        $3 != 0 { next }
        $2 ~ /^(mjpeg|png|bmp|tiff|webp|jpegls|jpeg2000|gif)$/ { if (still == "") still = $1; next }
        { print $1; found = 1; exit }
        END { if (!found && still != "") print still }'
}

# Field order of stream $2 in file $1 if it is interlaced (tt/bb/tb/bt), else empty
interlaced_field_order() {
    local fo
    fo=$(ffprobe -v error -select_streams "$2" -show_entries stream=field_order \
        -of default=nw=1:nk=1 "$1" | head -n1)
    case "$fo" in tt|bb|tb|bt) printf '%s' "$fo" ;; esac
}
