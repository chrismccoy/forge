# FFmpeg Captions and Subtitles

Subtitles and closed captions with FFmpeg: formats, burn-in, soft subtitle tracks, extraction, conversion, CEA-608, positioning, batch processing, and troubleshooting.

## Contents

- [Quick Reference](#quick-reference)
- [Subtitle Format Reference](#subtitle-format-reference)
- [Burning Subtitles (Hardcoding)](#burning-subtitles-hardcoding)
- [Adding Subtitle Tracks (Soft Subs)](#adding-subtitle-tracks-soft-subs)
- [Extracting Subtitles](#extracting-subtitles)
- [drawtext Overlays and Whisper Transcription](#drawtext-overlays-and-whisper-transcription)
- [CEA-608/708 Closed Captions](#cea-608708-closed-captions)
- [Subtitle Positioning](#subtitle-positioning)
- [Batch Processing](#batch-processing)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Quick Reference

| Task | Command |
|------|---------|
| Burn SRT | `ffmpeg -i video.mp4 -vf "subtitles=subs.srt" output.mp4` |
| Burn ASS | `ffmpeg -i video.mp4 -vf "ass=subs.ass" output.mp4` |
| Add soft sub | `ffmpeg -i video.mp4 -i subs.srt -c copy -c:s mov_text output.mp4` |
| Extract sub | `ffmpeg -i video.mkv -map 0:s:0 output.srt` |
| Style subs | `-vf "subtitles=s.srt:force_style='FontSize=24,PrimaryColour=&HFFFFFF'"` |
| Text overlay | `-vf "drawtext=text='Hello':x=10:y=10:fontsize=24:fontcolor=white"` |

File paths inside `subtitles=`/`ass=` are filter option values: a name containing `:`, `'`, `,`, `;`, `[` or `]` must be escaped twice (see SKILL.md). In scripts, source `scripts/lib/filter-escape.sh` and use `filter_escape "$(safe_path "$file")"`.

## Subtitle Format Reference

### Supported Formats

| Format | Extension | Features | Use Case |
|--------|-----------|----------|----------|
| SubRip | .srt | Simple timing + text | Universal, web |
| Advanced SubStation Alpha | .ass/.ssa | Rich styling, positioning, effects | Anime, styled subs |
| WebVTT | .vtt | Web standard, cues, styling | HTML5 video |
| TTML/DFXP | .ttml/.dfxp | Broadcast, accessibility | Streaming services |
| MOV Text | .mov (embedded) | QuickTime native | Apple ecosystem |
| DVB Subtitle | (embedded) | Bitmap-based | European broadcast |
| PGS | .sup | Blu-ray bitmap subtitles | Blu-ray |
| CEA-608/708 | (embedded) | Closed captions | US broadcast, streaming |

### Format Characteristics

```bash
SRT (SubRip):
- Simple text-based format
- Supports basic HTML tags (<b>, <i>, <u>)
- Widely compatible
- No positioning or advanced styling

ASS/SSA:
- Advanced styling (fonts, colors, outlines)
- Precise positioning anywhere on screen
- Animation and effects support
- Karaoke timing

WebVTT:
- HTML5 standard format
- CSS-like styling
- Cue settings for positioning
- Speaker identification
```

## Burning Subtitles (Hardcoding)

### Basic Subtitle Burn-in

```bash
# Burn SRT subtitles
ffmpeg -i video.mp4 -vf "subtitles=subs.srt" output.mp4

# Burn ASS/SSA subtitles (preserves styling)
ffmpeg -i video.mp4 -vf "ass=subs.ass" output.mp4

# Burn subtitles from MKV container
ffmpeg -i video.mkv -vf "subtitles=video.mkv" output.mp4

# Burn specific subtitle track (index 0)
ffmpeg -i video.mkv -vf "subtitles=video.mkv:si=0" output.mp4

# Burn subtitles with stream index
ffmpeg -i video.mkv -vf "subtitles=video.mkv:stream_index=1" output.mp4
```

### Styled Subtitle Burn-in

```bash
# Force style (overrides subtitle styling)
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='FontName=Arial,FontSize=24,PrimaryColour=&HFFFFFF,OutlineColour=&H000000,Outline=2,Shadow=1'" \
  output.mp4

# Yellow subtitles with black outline
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='FontSize=28,PrimaryColour=&H00FFFF,OutlineColour=&H000000,Outline=3'" \
  output.mp4

# Larger font for accessibility
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='FontSize=36,Bold=1'" \
  output.mp4
```

### ASS Style Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| FontName | Font family | `FontName=Arial` |
| FontSize | Size in script units (see below) | `FontSize=24` |
| PrimaryColour | Text color (AABBGGRR) | `PrimaryColour=&HFFFFFF` |
| SecondaryColour | Karaoke color | `SecondaryColour=&H00FFFF` |
| OutlineColour | Outline/border color | `OutlineColour=&H000000` |
| BackColour | Shadow/background color | `BackColour=&H80000000` |
| Bold | Bold text (0/1) | `Bold=1` |
| Italic | Italic text (0/1) | `Italic=1` |
| Underline | Underlined text (0/1) | `Underline=1` |
| Outline | Outline width | `Outline=2` |
| Shadow | Shadow depth | `Shadow=1` |
| Alignment | Position (numpad style) | `Alignment=2` |
| MarginL/R/V | Margins in script units | `MarginV=50` |

**Units.** `FontSize`, margins, `Outline` and `Shadow` are in script units, scaled from the script's `PlayResX`/`PlayResY` to the video size, not pixels or points. SRT, VTT and `force_style` on them use libass's default 384x288 script, so `FontSize=24` is 24/288 of the picture height at any resolution. Measured: `FontSize=48` renders at the same relative size on 640x360 and 3840x2160. An `.ass` file sets its own `PlayResY` (often 1080), so `FontSize=24` there is about a quarter of that size (24/1080 vs 24/288 of the height).

### Color Format (ASS)

```text
ASS uses &HAABBGGRR format (Alpha, Blue, Green, Red):
- White: &HFFFFFF or &H00FFFFFF
- Black: &H000000 or &H00000000
- Yellow: &H00FFFF (00-Blue, FF-Green, FF-Red)
- Red: &H0000FF
- Blue: &HFF0000
- 50% transparent black: &H80000000
```

## Adding Subtitle Tracks (Soft Subs)

### Embed SRT as Track

```bash
# Add SRT to MP4 (MOV text)
ffmpeg -i video.mp4 -i subs.srt \
  -c copy -c:s mov_text \
  output.mp4

# Add SRT to MKV
ffmpeg -i video.mp4 -i subs.srt \
  -c copy -c:s srt \
  output.mkv

# Add SRT to WebM (WebVTT)
ffmpeg -i video.webm -i subs.srt \
  -c copy -c:s webvtt \
  output.webm
```

### Multiple Subtitle Tracks

```bash
# Add multiple languages
ffmpeg -i video.mp4 -i subs_en.srt -i subs_es.srt -i subs_fr.srt \
  -map 0:v -map 0:a -map 1 -map 2 -map 3 \
  -c copy -c:s mov_text \
  -metadata:s:s:0 language=eng -metadata:s:s:0 title="English" \
  -metadata:s:s:1 language=spa -metadata:s:s:1 title="Spanish" \
  -metadata:s:s:2 language=fra -metadata:s:s:2 title="French" \
  output.mp4

# Add ASS subtitles to MKV (preserves styling)
ffmpeg -i video.mp4 -i styled.ass \
  -map 0 -map 1 \
  -c copy -c:s ass \
  output.mkv
```

### Set Default Subtitle Track

```bash
# Set subtitle as default
ffmpeg -i video.mp4 -i subs.srt \
  -c copy -c:s mov_text \
  -disposition:s:0 default \
  output.mp4

# Set forced subtitles (always display)
ffmpeg -i video.mp4 -i forced.srt \
  -c copy -c:s mov_text \
  -disposition:s:0 forced \
  output.mp4
```

## Extracting Subtitles

### Extract to External File

```bash
# Extract first subtitle track to SRT
ffmpeg -i video.mkv -map 0:s:0 output.srt

# Extract specific subtitle stream
ffmpeg -i video.mkv -map 0:s:1 output.srt

# Extract to ASS format
ffmpeg -i video.mkv -map 0:s:0 output.ass

# Extract to WebVTT
ffmpeg -i video.mkv -map 0:s:0 output.vtt

# Extract all subtitle tracks (the SRT muxer holds ONE stream per file,
# so give each track its own output)
ffmpeg -i video.mkv -map 0:s:0 subs_0.srt -map 0:s:1 subs_1.srt

# Same, for any number of tracks
n=$(ffprobe -v error -select_streams s -show_entries stream=index -of csv=p=0 video.mkv | wc -l)
for i in $(seq 0 $((n-1))); do
  ffmpeg -i video.mkv -map 0:s:$i subs_$i.srt
done
# Image-based tracks (PGS, DVD/VobSub) cannot become SRT without OCR;
# copy them instead: -map 0:s:N -c:s copy subs_N.sup (PGS) or .mks
```

### List Available Subtitle Tracks

```bash
# Show all streams including subtitles
ffprobe -v error -show_entries stream=index,codec_name,codec_type:stream_tags=language,title \
  -of csv=p=0 video.mkv

# Show only subtitle streams
ffprobe -v error -select_streams s \
  -show_entries stream=index,codec_name:stream_tags=language,title \
  -of csv=p=0 video.mkv
```

### Convert Subtitle Formats

```bash
# SRT to ASS
ffmpeg -i subs.srt subs.ass

# ASS to SRT (loses styling)
ffmpeg -i subs.ass subs.srt

# SRT to WebVTT
ffmpeg -i subs.srt subs.vtt

# WebVTT to SRT
ffmpeg -i subs.vtt subs.srt
```

## drawtext Overlays and Whisper Transcription

`drawtext` overlays (fonts, positioning, escaping, time expressions, boxes, outlines) are in `drawtext.md`, animated text in `drawtext-animation.md`. Speech-to-subtitle generation with the FFmpeg 8.0 `whisper` filter is in `whisper.md`.

## CEA-608/708 Closed Captions

### Extract Closed Captions

```bash
# Extract CEA-608 captions carried in the video bitstream (A/53 side data,
# e.g. ATSC .ts or camera/broadcast MP4). The lavfi movie source exposes them
# as a second output, "subcc", which is stream 0:1 here.
ffmpeg -f lavfi -i "movie=broadcast.ts[out0+subcc]" -map 0:1 captions.srt

# Check whether a file carries in-band captions at all
# (the video stream line then ends with "Closed Captions")
ffprobe -hide_banner video_with_cc.mp4 2>&1 | grep -i "closed captions"

# Captions stored as a separate QuickTime c608 track (not in the video)
# are an ordinary subtitle stream
ffmpeg -i video_with_c608_track.mov -map 0:s:0 -c:s srt captions.srt

# For full 608/708 extraction (all channels, SCC output) use ccextractor:
# ccextractor broadcast.ts -o captions.srt
```

### Add CEA-608 Captions

FFmpeg cannot author in-band CEA-608/708 captions: it has no encoder that
turns SRT/SCC text into A/53 caption data inside the H.264/HEVC bitstream.
What it can do:

```bash
# 1. Keep existing in-band captions when re-encoding: libx264 passes A/53
#    caption side data through by default (-a53cc 1); libx265 needs -a53cc 1
ffmpeg -i video_with_cc.ts -c:v libx264 -a53cc 1 -c:a copy output.mp4

# 2. Mux an SCC file as a separate QuickTime c608 caption track
#    (MOV only; the mp4 muxer rejects eia_608)
ffmpeg -i video.mp4 -i captions.scc \
  -map 0 -map 1 -c copy \
  output.mov
```

To embed captions in the video stream itself, use a dedicated caption
tool (e.g. libcaption, or a broadcast caption encoder) and feed its output
to FFmpeg with `-c copy`.

## Subtitle Positioning

### ASS Alignment Values

```text
7 (top-left)     8 (top-center)     9 (top-right)
4 (mid-left)     5 (mid-center)     6 (mid-right)
1 (bottom-left)  2 (bottom-center)  3 (bottom-right)
```

### Position Examples

```bash
# Top center subtitles
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='Alignment=8,MarginV=20'" \
  output.mp4

# Left-aligned subtitles
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='Alignment=1,MarginL=50,MarginV=30'" \
  output.mp4

# Right side for speaker identification
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:force_style='Alignment=3,MarginR=50'" \
  output.mp4
```

### Multiple Subtitle Positions

```bash
# Two subtitle tracks at different positions
ffmpeg -i video.mp4 \
  -vf "[in]subtitles=speaker1.srt:force_style='Alignment=1,MarginL=50'[tmp];\
       [tmp]subtitles=speaker2.srt:force_style='Alignment=3,MarginR=50'" \
  output.mp4
```

## Batch Processing

### Burn Subtitles to Multiple Videos

```bash
#!/usr/bin/env bash
# burn_subs_batch.sh - burn NAME.srt into NAME.mp4 for every pair in the folder
FORGE=/path/to/ffmpeg-forge                 # the skill directory
. "$FORGE/scripts/lib/filter-escape.sh"     # filter_escape, safe_path (bash 4.3+)
require_bash_43

mkdir -p output
fail=0
for video in *.mp4; do
  base="${video%.mp4}"
  [ -f "$base.srt" ] || continue
  out="output/${base}_subbed.mp4"
  # ffmpeg -n exits 0 when it declines to overwrite, so check first
  if [ -e "$out" ]; then echo "SKIP (exists): $out"; continue; fi
  sub=$(filter_escape "$(safe_path "$base.srt")")
  if ffmpeg -nostdin -n -loglevel error -i "$(safe_path "$video")" \
       -vf "subtitles=$sub:force_style='FontSize=24,Outline=2'" \
       -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a copy "$out" && [ -s "$out" ]; then
    echo "OK: $video"
  else
    echo "FAILED: $video" >&2; fail=1
  fi
done
exit $fail
```

`filter_escape` handles names such as `it's.srt`, `a:b.srt`, `x,y [1].srt` and `semi;colon.srt`. Unescaped, `it's.srt` fails with `No option name near ...`. `safe_path` adds `./` so `a:b.mp4` is not read as a protocol.

### Convert Subtitle Format Batch

```bash
#!/bin/bash
# convert_subs.sh

for srt in *.srt; do
    base="${srt%.srt}"
    [ -e "$base.vtt" ] && { echo "SKIP (exists): $base.vtt"; continue; }
    ffmpeg -nostdin -n -loglevel error -i "./$srt" "./$base.vtt" && [ -s "$base.vtt" ] ||
      echo "FAILED: $srt" >&2
done
```

## Troubleshooting

### Common Issues

**"Unable to find a suitable output format"**
```bash
# Specify output format explicitly
ffmpeg -i video.mkv -map 0:s:0 -f srt output.srt
```

**Garbled characters in subtitles**
```bash
# Force UTF-8 encoding
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:charenc=UTF-8" \
  output.mp4
```

**Font not found**
```bash
# Specify fonts directory
ffmpeg -i video.mp4 \
  -vf "subtitles=subs.srt:fontsdir=/path/to/fonts" \
  output.mp4

# List available fonts
fc-list : family | sort | uniq
```

**Subtitle timing offset**
```bash
# Delay subtitles by 2 seconds (-itsoffset is an INPUT option: put it
# before the -i it applies to). Write a shifted copy of the file...
ffmpeg -itsoffset 2 -i subs.srt delayed.srt

# ...then burn the shifted file (the subtitles filter has no offset option)
ffmpeg -i video.mp4 \
  -vf "subtitles=delayed.srt" \
  output.mp4

# Or shift a soft-subtitle track while muxing
ffmpeg -i video.mp4 -itsoffset 2 -i subs.srt \
  -map 0 -map 1 -c copy -c:s mov_text \
  output.mp4
```

**Subtitles too small or too large**

Burned SRT/VTT text scales with the video (sizes are relative to the 288-line default script), so a 4K encode does not shrink it. To change the size, change `FontSize` relative to the default of 16:

```bash
# About 1.5x the default size, at any resolution
ffmpeg -i video_4k.mp4 \
  -vf "subtitles=subs.srt:force_style='FontSize=24,Outline=2'" \
  output.mp4
```

For an `.ass` file, check its `PlayResY` (`grep PlayRes subs.ass`); sizes and margins in that file are relative to it.

### Verification Commands

```bash
# Check if subtitles are present
ffprobe -v error -select_streams s -show_entries stream=codec_name -of default=nw=1 video.mp4

# Count cues (one "-->" timing line per cue)
grep -c -- '-->' subs.srt

# Coarse parse check: fails (exit 183, "Invalid data found when processing
# input") only when the file cannot be read as SRT at all. A broken timestamp
# in a later cue, or an end before its start, still passes silently.
ffmpeg -v error -i subs.srt -f srt -y /dev/null

# Structural check: every cue needs a valid "start --> end" line with end > start
tr -d '\r' < subs.srt | awk -v RS= -F'\n' '
  function ms(t, a) { split(t, a, /[:,.]/); return ((a[1] * 60 + a[2]) * 60 + a[3]) * 1000 + a[4] }
  {
    n++; ts = ""
    for (i = 1; i <= NF; i++) if ($i ~ /-->/) { ts = $i; break }
    if (ts !~ /^[0-9]+:[0-5][0-9]:[0-5][0-9][,.][0-9][0-9][0-9] --> [0-9]+:[0-5][0-9]:[0-5][0-9][,.][0-9][0-9][0-9]/) {
      printf "cue %d: bad or missing timing line: %s\n", n, (ts == "" ? $1 : ts); bad++; next
    }
    split(ts, p, / --> /)
    if (ms(p[2]) <= ms(p[1])) { printf "cue %d: end is not after start: %s\n", n, ts; bad++ }
  }
  END { printf "%d cues, %d problems\n", n, bad; exit bad > 0 }'
```

## Best Practices

### Accessibility
1. Use high contrast colors (white on dark, yellow on dark)
2. Keep text large enough: at least the default SRT size (`FontSize=16` on the 288-line script, about 1/18 of picture height); larger for mobile
3. Include speaker identification for multiple speakers
4. Position subtitles to avoid obscuring important visual content
5. Keep lines short (42 characters max per line)
6. Display duration: minimum 1 second, maximum 7 seconds per caption

### Quality
1. Use ASS format for styled subtitles (anime, music videos)
2. Use SRT for simple dialogue
3. Use WebVTT for web delivery
4. Preserve original styling when possible
5. Test on target devices before distribution

### Performance
1. Burn subtitles only when necessary (streaming, compatibility)
2. Prefer soft subs for archival and flexibility
3. Use hardware encoding when burning subtitles to large files
4. Process in parallel for batch operations

This guide covers FFmpeg subtitle and caption operations. For text overlays with shapes and graphics, see `shapes-graphics.md`.
