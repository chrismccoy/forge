#!/bin/bash
# FFmpeg Karaoke & Kinetic Caption Generator Utility
# Generate ASS karaoke/kinetic subtitles and apply to video
# Usage: ./generate-karaoke.sh <action> [options]
#
# Actions: create, apply, template, kinetic

set -e

ACTION="${1:-help}"

# Escape a path for use as a filter option value inside -vf/-af.
# Two levels: the option parser (\ : ') then the filtergraph parser (\ ' , ; [ ]).
filter_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//:/\\:}"; s="${s//\'/\\\'}"
    s="${s//\\/\\\\}"; s="${s//\'/\\\'}"
    s="${s//,/\\,}"; s="${s//;/\\;}"; s="${s//\[/\\[}"; s="${s//\]/\\]}"
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

# Valid values; anything else is an error rather than a silent fallback
KARAOKE_STYLES="default neon outline shadow gradient"
KINETIC_EFFECTS="pop grow bounce elastic karaoke-grow"
PLATFORMS="tiktok youtube instagram"
TEMPLATE_STYLES="$KARAOKE_STYLES kinetic-pop kinetic-grow kinetic-bounce kinetic-elastic"

# Usage: require_one_of <what> <value> <space-separated valid values>
require_one_of() {
    local v
    for v in $3; do
        [[ "$2" == "$v" ]] && return 0
    done
    echo "Error: Unknown $1: $2 (valid: ${3// /, })" >&2
    exit 1
}

show_help() {
    echo "FFmpeg Karaoke & Kinetic Caption Generator Utility"
    echo ""
    echo "Usage: $0 <action> [options]"
    echo ""
    echo "Actions:"
    echo "  create <lyrics.txt> <output.ass> [style]"
    echo "      Convert timestamped lyrics to ASS karaoke format"
    echo "      Styles: default, neon, outline, shadow, gradient"
    echo ""
    echo "  kinetic <lyrics.txt> <output.ass> [effect] [platform]"
    echo "      Create kinetic captions with animation effects"
    echo "      Effects: pop, grow, bounce, elastic, karaoke-grow"
    echo "      Platforms: tiktok, youtube, instagram (default: tiktok)"
    echo ""
    echo "  apply <video> <subtitles.ass> <output>"
    echo "      Burn ASS subtitles into video"
    echo ""
    echo "  template <style> <output.ass>"
    echo "      Generate ASS template file for manual editing"
    echo "      Styles: default, neon, outline, shadow, gradient, kinetic-pop,"
    echo "              kinetic-grow, kinetic-bounce, kinetic-elastic"
    echo ""
    echo "Lyrics format (lyrics.txt):"
    echo "  [MM:SS.ms] Line text here"
    echo "  [00:05.00] First line of song"
    echo "  [00:10.50] Second line continues"
    echo ""
    echo "Examples:"
    echo "  $0 create lyrics.txt karaoke.ass neon"
    echo "  $0 kinetic lyrics.txt kinetic.ass bounce tiktok"
    echo "  $0 apply video.mp4 karaoke.ass output.mp4"
    echo "  $0 template kinetic-pop template.ass"
}

get_style_header() {
    local style="$1"
    local header="[Script Info]
Title: Karaoke Subtitles
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
Timer: 100.0000
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding"

    case "$style" in
        neon)
            echo "$header"
            echo "Style: Default,Arial Black,72,&H00FF00FF,&H0000FFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,2,2,50,50,280,1"
            echo "Style: Karaoke,Arial Black,72,&H0000FFFF,&H00FF00FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,2,2,50,50,280,1"
            ;;
        outline)
            echo "$header"
            echo "Style: Default,Impact,80,&H00FFFFFF,&H00FFFF00,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,5,0,2,50,50,280,1"
            echo "Style: Karaoke,Impact,80,&H00FFFF00,&H00FFFFFF,&H00000000,&H00000000,-1,0,0,0,100,100,0,0,1,5,0,2,50,50,280,1"
            ;;
        shadow)
            echo "$header"
            echo "Style: Default,Arial Black,68,&H00FFFFFF,&H0000FF00,&H00333333,&H80000000,-1,0,0,0,100,100,0,0,1,3,4,2,50,50,280,1"
            echo "Style: Karaoke,Arial Black,68,&H0000FF00,&H00FFFFFF,&H00333333,&H80000000,-1,0,0,0,100,100,0,0,1,3,4,2,50,50,280,1"
            ;;
        gradient)
            echo "$header"
            echo "Style: Default,Arial Black,72,&H00FFFFFF,&H00FF8800,&H00000000,&H40000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,280,1"
            echo "Style: Karaoke,Arial Black,72,&H00FF8800,&H00FFFFFF,&H00000000,&H40000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,280,1"
            ;;
        *)
            echo "$header"
            echo "Style: Default,Arial,64,&H00FFFFFF,&H000088FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,280,1"
            echo "Style: Karaoke,Arial,64,&H000088FF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,2,2,50,50,280,1"
            ;;
    esac
}

get_kinetic_header() {
    local platform="$1"
    local font_name="Arial Black"
    local font_size=88

    case "$platform" in
        youtube)
            font_name="Montserrat"
            font_size=76
            ;;
        instagram)
            font_name="Impact"
            font_size=82
            ;;
        tiktok|*)
            font_name="Arial Black"
            font_size=88
            ;;
    esac

    cat << EOF
[Script Info]
Title: Kinetic Captions
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
Timer: 100.0000
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: KineticPop,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticGrow,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticBounce,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticElastic,${font_name},${font_size},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,280,1
Style: KaraokeGrow,${font_name},${font_size},&H0000FFFF,&H00FFFFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
EOF
}

get_kinetic_effect() {
    local effect="$1"
    local word="$2"

    case "$effect" in
        pop)
            # Word pops in: 50% → 115% → 100%
            echo "{\\fscx50\\fscy50\\t(0,100,\\fscx115\\fscy115)\\t(100,200,\\fscx100\\fscy100)}${word}"
            ;;
        grow)
            # Word grows: 80% → 115% → 100%
            echo "{\\fscx80\\fscy80\\t(0,150,\\fscx115\\fscy115)\\t(150,300,\\fscx100\\fscy100)}${word}"
            ;;
        bounce)
            # Spring bounce: 80% → 120% → 95% → 100%
            echo "{\\fscx80\\fscy80\\t(0,100,\\fscx120\\fscy120)\\t(100,200,\\fscx95\\fscy95)\\t(200,300,\\fscx100\\fscy100)}${word}"
            ;;
        elastic)
            # Elastic overshoot: 40% → 130% → 90% → 105% → 100%
            echo "{\\fscx40\\fscy40\\t(0,80,\\fscx130\\fscy130)\\t(80,160,\\fscx90\\fscy90)\\t(160,260,\\fscx105\\fscy105)\\t(260,380,\\fscx100\\fscy100)}${word}"
            ;;
        karaoke-grow)
            # Karaoke with grow effect (returns just animation, karaoke tag added separately)
            echo "\\t(0,150,\\fscx115\\fscy115)\\t(150,300,\\fscx100\\fscy100)"
            ;;
        *)
            echo "{\\fscx50\\fscy50\\t(0,100,\\fscx115\\fscy115)\\t(100,200,\\fscx100\\fscy100)}${word}"
            ;;
    esac
}

get_style_for_effect() {
    local effect="$1"
    case "$effect" in
        pop) echo "KineticPop" ;;
        grow) echo "KineticGrow" ;;
        bounce) echo "KineticBounce" ;;
        elastic) echo "KineticElastic" ;;
        karaoke-grow) echo "KaraokeGrow" ;;
        *) echo "KineticPop" ;;
    esac
}

# Make lyric text literal in an ASS Dialogue line.
# "{" opens an override block, so "{...}" would be hidden: libass (0.17+)
# renders "\{" and "\}" as plain braces. "\N", "\n" and "\h" are line
# breaks/hard spaces, so a word joiner (U+2060, invisible) goes after the
# backslash to keep it as text. A lone "\" before other characters is shown
# as is.
ass_escape() {
    local s="$1" wj=$'\xe2\x81\xa0'
    s="${s//\\N/\\${wj}N}"; s="${s//\\n/\\${wj}n}"; s="${s//\\h/\\${wj}h}"
    s="${s//\{/\\\{}"; s="${s//\}/\\\}}"
    printf '%s' "$s"
}

ts_to_cs() {
    # Convert [MM:SS.frac] or MM:SS.frac to centiseconds (frac may be 1-3 digits)
    local ts="${1#[}"
    ts="${ts%]}"
    local min="${ts%%:*}"
    local rest="${ts#*:}"
    local sec="${rest%.*}"
    local frac="0"
    [[ "$rest" == *.* ]] && frac="${rest#*.}"
    frac="${frac}00"
    # 10# forces base 10 so "08"/"09" are not parsed as octal
    echo $(( 10#$min * 6000 + 10#$sec * 100 + 10#${frac:0:2} ))
}

cs_to_ass() {
    # Convert centiseconds to ASS H:MM:SS.cs
    local cs="$1"
    printf "%d:%02d:%02d.%02d" $((cs / 360000)) $(((cs / 6000) % 60)) $(((cs / 100) % 60)) $((cs % 100))
}

timestamp_to_ass() {
    cs_to_ass "$(ts_to_cs "$1")"
}

read_lyrics() {
    # Fill global arrays LYRIC_START_CS / LYRIC_TEXT from a [MM:SS.ms] Text file
    # (standard LRC: the space after ']' is optional). Exits on malformed input.
    # A timestamp with no text is an LRC end marker: it sets LYRIC_END_CS for
    # the line before it.
    LYRIC_START_CS=()
    LYRIC_TEXT=()
    LYRIC_END_CS=()
    local line text start last line_no=0 prev=-1
    while IFS= read -r line || [[ -n "$line" ]]; do
        line_no=$((line_no + 1))
        line="${line%$'\r'}"
        [[ -z "${line//[[:space:]]/}" || "$line" == \#* ]] && continue
        if [[ "$line" =~ ^\[([0-9]+:[0-9]+(\.[0-9]+)?)\][[:space:]]*(.*)$ ]]; then
            text="${BASH_REMATCH[3]}"
            text="${text%"${text##*[![:space:]]}"}"
            last=$(( ${#LYRIC_TEXT[@]} - 1 ))
            if [[ -z "$text" ]] && { (( last < 0 )) || [[ -n "${LYRIC_END_CS[last]}" ]]; }; then
                echo "Warning: line $line_no has no text and no open lyric line to end, skipped" >&2
                continue
            fi
            start=$(ts_to_cs "${BASH_REMATCH[1]}")
            if (( start <= prev )); then
                echo "Error: line $line_no: timestamps must increase ([${BASH_REMATCH[1]}])" >&2
                exit 1
            fi
            prev=$start
            if [[ -z "$text" ]]; then
                LYRIC_END_CS[last]=$start
                continue
            fi
            LYRIC_START_CS+=("$start")
            LYRIC_TEXT+=("$text")
        else
            echo "Warning: line $line_no not in [MM:SS.xx] Text format, skipped: $line" >&2
        fi
    done < "$1"
    if (( ${#LYRIC_TEXT[@]} == 0 )); then
        echo "Error: no lyric lines found in $1" >&2
        exit 1
    fi
}

check_output() {
    # Refuse to overwrite an existing file (including the input)
    if [[ -e "$1" ]]; then
        echo "Error: Output already exists: $1"
        exit 1
    fi
}

lyric_end_cs() {
    # End of line i = its LRC end marker if it has one, otherwise the start of
    # line i+1, capped at start + 0.6s per word + 1s so a line (and its \k
    # highlight) does not stretch across an instrumental gap
    local i="$1" words
    if [[ -n "${LYRIC_END_CS[i]}" ]]; then
        echo "${LYRIC_END_CS[i]}"
        return
    fi
    read -ra words <<< "${LYRIC_TEXT[i]}"
    local end=$(( LYRIC_START_CS[i] + ${#words[@]} * 60 + 100 ))
    if (( i + 1 < ${#LYRIC_START_CS[@]} && LYRIC_START_CS[i+1] < end )); then
        end=${LYRIC_START_CS[i+1]}
    fi
    echo "$end"
}

karaoke_line() {
    # Spread the line duration evenly over its words as \k tags.
    # With grow=1, each word also scales up when its highlight starts;
    # \t times are relative to the Dialogue start, so they are offset per word.
    local text="$1" total_cs="$2" grow="${3:-0}"
    local words
    read -ra words <<< "$text"
    local n=${#words[@]}
    local per=$(( total_cs / n )) offset_ms=0 out="" i k
    for ((i = 0; i < n; i++)); do
        k=$per
        (( i == n - 1 )) && k=$(( total_cs - per * (n - 1) ))
        if [[ "$grow" == 1 ]]; then
            out+="{\\r\\k${k}\\t(${offset_ms},$((offset_ms + 150)),\\fscx115\\fscy115)\\t($((offset_ms + 150)),$((offset_ms + 300)),\\fscx100\\fscy100)}$(ass_escape "${words[i]}") "
        else
            out+="{\\k${k}}$(ass_escape "${words[i]}") "
        fi
        offset_ms=$(( offset_ms + k * 10 ))
    done
    echo "${out% }"
}

create_karaoke() {
    local lyrics_file="$1"
    local output_file="$2"
    local style="${3:-default}"

    if [[ ! -f "$lyrics_file" ]]; then
        echo "Error: Lyrics file not found: $lyrics_file"
        exit 1
    fi

    require_one_of style "$style" "$KARAOKE_STYLES"
    check_output "$output_file"
    echo "Creating karaoke ASS from: $lyrics_file (style: $style)"

    read_lyrics "$lyrics_file"
    get_style_header "$style" > "$output_file"
    echo "" >> "$output_file"
    echo "[Events]" >> "$output_file"
    echo "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text" >> "$output_file"

    local i start end
    for ((i = 0; i < ${#LYRIC_TEXT[@]}; i++)); do
        start=${LYRIC_START_CS[i]}
        end=$(lyric_end_cs "$i")
        echo "Dialogue: 0,$(cs_to_ass "$start"),$(cs_to_ass "$end"),Karaoke,,0,0,0,,$(karaoke_line "${LYRIC_TEXT[i]}" $((end - start)))" >> "$output_file"
    done

    echo "Created karaoke file: $output_file (${#LYRIC_TEXT[@]} lines)"
}

create_kinetic() {
    local lyrics_file="$1"
    local output_file="$2"
    local effect="${3:-pop}"
    local platform="${4:-tiktok}"

    if [[ ! -f "$lyrics_file" ]]; then
        echo "Error: Lyrics file not found: $lyrics_file"
        exit 1
    fi

    require_one_of effect "$effect" "$KINETIC_EFFECTS"
    require_one_of platform "$platform" "$PLATFORMS"
    check_output "$output_file"
    echo "Creating kinetic captions from: $lyrics_file (effect: $effect, platform: $platform)"

    read_lyrics "$lyrics_file"
    get_kinetic_header "$platform" > "$output_file"
    echo "" >> "$output_file"
    echo "[Events]" >> "$output_file"
    echo "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text" >> "$output_file"

    local style_name=$(get_style_for_effect "$effect")
    # Words share one screen position, so each word ends exactly when the next starts
    local word_overlap=0

    local i start end words n per w word_start
    for ((i = 0; i < ${#LYRIC_TEXT[@]}; i++)); do
        start=${LYRIC_START_CS[i]}
        end=$(lyric_end_cs "$i")
        if [[ "$effect" == "karaoke-grow" ]]; then
            echo "Dialogue: 0,$(cs_to_ass "$start"),$(cs_to_ass "$end"),${style_name},,0,0,0,,$(karaoke_line "${LYRIC_TEXT[i]}" $((end - start)) 1)" >> "$output_file"
            continue
        fi
        # Word-by-word: one Dialogue per word so each \t animation starts at 0
        read -ra words <<< "${LYRIC_TEXT[i]}"
        n=${#words[@]}
        per=$(( (end - start) / n ))
        for ((w = 0; w < n; w++)); do
            word_start=$(( start + per * w ))
            echo "Dialogue: 0,$(cs_to_ass "$word_start"),$(cs_to_ass $((word_start + per + word_overlap))),${style_name},,0,0,0,,$(get_kinetic_effect "$effect" "$(ass_escape "${words[w]}")")" >> "$output_file"
        done
    done

    echo "Created kinetic captions file: $output_file (${#LYRIC_TEXT[@]} lines, $effect effect)"
}

apply_karaoke() {
    local video="$1"
    local subtitles="$2"
    local output="$3"

    if [[ ! -f "$video" ]]; then
        echo "Error: Video file not found: $video"
        exit 1
    fi

    if [[ ! -f "$subtitles" ]]; then
        echo "Error: Subtitle file not found: $subtitles"
        exit 1
    fi

    check_output "$output"
    video=$(safe_path "$video")
    subtitles=$(safe_path "$subtitles")
    output=$(safe_path "$output")
    # The output did not exist before, so remove a partial file if ffmpeg fails;
    # otherwise the leftover would make every retry stop at check_output
    PARTIAL_OUTPUT="$output"
    trap 'rc=$?; (( rc != 0 )) && rm -f -- "$PARTIAL_OUTPUT"; exit $rc' EXIT

    echo "Burning karaoke subtitles into video..."

    # yuv420p (and so even dimensions) keeps the output playable everywhere:
    # libx264 would otherwise keep a 4:4:4 or 10-bit source format (High 4:4:4 / High 10)
    ffmpeg -n -i "$video" \
        -vf "ass=$(filter_escape "$subtitles"),crop=trunc(iw/2)*2:trunc(ih/2)*2" \
        -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
        -movflags +faststart -c:a copy "$output"

    echo "Done! Output saved to: $output"
}

create_template() {
    local style="${1:-default}"
    local output="$2"

    require_one_of "template style" "$style" "$TEMPLATE_STYLES"
    check_output "$output"
    echo "Creating ASS template (style: $style)..."

    case "$style" in
        kinetic-pop|kinetic-grow|kinetic-bounce|kinetic-elastic)
            local effect="${style#kinetic-}"
            get_kinetic_header "tiktok" > "$output"
            local style_name=$(get_style_for_effect "$effect")

            cat >> "$output" << EOF

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
; Kinetic Caption Template ($effect effect)
; Each word appears with $effect animation
; Timing: Start,End in H:MM:SS.CC format
;
; Example word-by-word kinetic captions:
EOF
            local example_words=("This" "is" "an" "example")
            # Each word ends exactly when the next begins (same screen position)
            local start_cs=500 word_cs=50
            for word in "${example_words[@]}"; do
                local kinetic_text=$(get_kinetic_effect "$effect" "$word")
                echo "Dialogue: 0,$(cs_to_ass "$start_cs"),$(cs_to_ass $((start_cs + word_cs))),${style_name},,0,0,0,,${kinetic_text}" >> "$output"
                start_cs=$((start_cs + word_cs))
            done
            ;;
        *)
            get_style_header "$style" > "$output"

            cat >> "$output" << EOF

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
; Add your karaoke lines below
; Format: Dialogue: 0,START,END,Karaoke,,0,0,0,,{\\k100}Word1 {\\k100}Word2
; \\k value is duration in centiseconds (100 = 1 second)
Dialogue: 0,0:00:05.00,0:00:10.00,Karaoke,,0,0,0,,{\\k50}This {\\k50}is {\\k50}an {\\k100}example {\\k100}line
EOF
            ;;
    esac

    echo "Template created: $output"
    echo "Edit the file to add your karaoke/kinetic timing."
}

# Main execution
case "$ACTION" in
    help|--help|-h)
        show_help
        exit 0
        ;;
    create)
        [[ -z "$2" || -z "$3" ]] && { echo "Error: Missing arguments"; show_help; exit 1; }
        create_karaoke "$2" "$3" "$4"
        ;;
    kinetic)
        [[ -z "$2" || -z "$3" ]] && { echo "Error: Missing arguments"; show_help; exit 1; }
        create_kinetic "$2" "$3" "$4" "$5"
        ;;
    apply)
        [[ -z "$2" || -z "$3" || -z "$4" ]] && { echo "Error: Missing arguments"; show_help; exit 1; }
        apply_karaoke "$2" "$3" "$4"
        ;;
    template)
        [[ -z "$2" || -z "$3" ]] && { echo "Error: Missing arguments"; show_help; exit 1; }
        create_template "$2" "$3"
        ;;
    *)
        echo "Unknown action: $ACTION"
        show_help
        exit 1
        ;;
esac
