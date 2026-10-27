# FFmpeg drawtext: Static Text Overlays

Static `drawtext` overlays: fonts, positioning, escaping, boxes, outlines, timed visibility, timecode, clock time, frame numbers and frame metadata. Animated text (motion, fades, typewriter, credits, tickers, countdowns, size changes) is in `drawtext-animation.md`. ASS karaoke and styled subtitles are in `karaoke-text.md`; subtitle files, burn-in and soft tracks are in `captions.md`.

## Contents

- [Basics and Positioning](#basics-and-positioning)
- [Fonts](#fonts)
- [Escaping](#escaping)
- [Boxes, Outlines and Shadows](#boxes-outlines-and-shadows)
- [Timed Visibility](#timed-visibility)
- [Multi-Line Text](#multi-line-text)
- [Lower Thirds](#lower-thirds)
- [Timecode, Clock and Frame Numbers](#timecode-clock-and-frame-numbers)
- [Frame Metadata and Container Tags](#frame-metadata-and-container-tags)
- [Troubleshooting](#troubleshooting)

`fontcolor` defaults to black, so set it in every recipe. Burned-in text needs a re-encode: add `-c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy` (or the encoder of choice) for delivery files.

## Basics and Positioning

```bash
# Simple text overlay
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Hello World':x=10:y=10:fontsize=24:fontcolor=white" \
  output.mp4

# Centered text
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Centered Text':x=(w-tw)/2:y=(h-th)/2:fontsize=48:fontcolor=white" \
  output.mp4

# Text at bottom center
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Bottom Text':x=(w-tw)/2:y=h-th-20:fontsize=32:fontcolor=white" \
  output.mp4
```

| Variable | Meaning |
|----------|---------|
| `w`, `h` | Frame width and height |
| `tw`, `th` | Rendered text width and height |
| `lh` | Line height of the font at this size |
| `t` | Time in seconds (for `x`, `y`, `alpha`, `enable`) |
| `n` | Frame number (in expressions) |

A constant `fontsize` expression such as `fontsize=h/20` is fine and scales the text with the frame. A `fontsize` that changes per frame (uses `t` or `n`) segfaults FFmpeg 8.0.1; for size animation see `drawtext-animation.md`.

## Fonts

```bash
# Font file
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Custom Font':fontfile=/path/to/font.ttf:fontsize=24:fontcolor=white" \
  output.mp4

# Font by fontconfig name (default "Sans")
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Mono':font='DejaVu Sans Mono':fontsize=24:fontcolor=white:x=10:y=10" \
  output.mp4

# List installed families, and see which file a name resolves to
fc-list : family | sort -u
fc-match -f '%{file}\n' 'DejaVu Sans'
```

`fontfile=` is the reliable choice when a script must give the same result on every machine. `font=` depends on the fontconfig setup of the build and the system. Neither reports a missing font: a wrong path or name silently falls back to the default font, so check the first frame.

## Escaping

Values in `-vf` are unescaped twice, once by the option parser and once by the filtergraph parser (see SKILL.md):

- Put the text in single quotes inside the double-quoted filter: `text='Hello World'`.
- A `:` inside the text needs a backslash: `text='Time\: 12\:30'`.
- `%{...}` starts a text expansion. A bare `%` fails with "Stray %". For text with `%`, apostrophes or other awkward characters, write it to a file and use `textfile=FILE:expansion=none`. That needs no escaping at all.
- `fontfile=` and `textfile=` paths are option values too. A path containing `:`, `'`, `,`, `;`, `[` or `]` must be escaped twice; in scripts use `filter_escape` from `scripts/lib/filter-escape.sh`.

```bash
# Text with an apostrophe, a colon, brackets and a percent sign
printf "It's 5:00, [ok]; 50%%\n" > msg.txt
ffmpeg -i video.mp4 \
  -vf "drawtext=textfile=msg.txt:expansion=none:fontsize=32:fontcolor=white:x=10:y=10" \
  output.mp4

# textfile is read once; reload=N re-reads it every N frames (live tickers, scores)
ffmpeg -i video.mp4 \
  -vf "drawtext=textfile=message.txt:x=10:y=10:fontsize=24:fontcolor=white:reload=1" \
  output.mp4
```

With `reload`, replace the file atomically (`mv tmp message.txt`) so drawtext never reads a half-written file.

## Boxes, Outlines and Shadows

```bash
# Text with background box
ffmpeg -i video.mp4 \
  -vf "drawtext=text='With Background':x=10:y=10:fontsize=24:fontcolor=white:box=1:boxcolor=black@0.5:boxborderw=5" \
  output.mp4

# Badge: solid box with generous padding
ffmpeg -i video.mp4 \
  -vf "drawtext=text='LIVE':x=10:y=10:fontsize=36:fontcolor=white:box=1:boxcolor=red:boxborderw=10" \
  live_badge.mp4

# Text with outline (border)
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Outlined Text':x=10:y=10:fontsize=48:fontcolor=white:borderw=3:bordercolor=black" \
  output.mp4

# Shadow effect
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Shadow Text':x=(w-tw)/2:y=50:fontsize=36:fontcolor=white:shadowcolor=black:shadowx=3:shadowy=3" \
  output.mp4
```

An outline (`borderw` 2-4 px at 1080p) or a semi-transparent box keeps text readable on any background.

## Timed Visibility

`enable=` takes an expression in seconds. drawtext supports timeline editing, so the filter is skipped outside the window:

```bash
# Text appears at 3 seconds
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Appears at 3s':x=10:y=10:fontsize=24:fontcolor=white:enable='gte(t,3)'" \
  output.mp4

# Text visible between 2 and 5 seconds
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Visible 2-5s':x=10:y=10:fontsize=24:fontcolor=white:enable='between(t,2,5)'" \
  output.mp4
```

`between(t,a,b)` includes both ends. For back-to-back windows use `gte(t,a)*lt(t,b)`, so two texts never share the boundary frame.

## Multi-Line Text

On the FFmpeg 8.0.1 Ubuntu build, drawtext draws a missing-glyph box at the end of each line of multi-line text. This happens with an inline newline and with `textfile=`, with every font tried. Draw one line per `drawtext` instead, spaced by the line height `lh`:

```bash
# Three centred lines, block centred vertically
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Line One':fontsize=48:fontcolor=white:x=(w-tw)/2:y=h/2-1.5*lh,\
       drawtext=text='Line Two is longer':fontsize=48:fontcolor=white:x=(w-tw)/2:y=h/2-0.5*lh,\
       drawtext=text='Line Three':fontsize=48:fontcolor=white:x=(w-tw)/2:y=h/2+0.5*lh" \
  multiline.mp4
```

On builds without the box, one `drawtext` can hold several lines. `x=(w-tw)/2` centres the whole block, but its lines stay left-aligned; add `text_align=C` to centre each line:

```bash
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=message.txt:text_align=C:fontsize=36:fontcolor=white:\
       x=(w-tw)/2:y=50:line_spacing=10" \
  from_file.mp4
```

For long text (paragraphs, credits), ASS handles line breaks (`\N`) and centring without the box; see the credits recipe in `drawtext-animation.md`.

## Lower Thirds

```bash
# Bar with accent stripe, name and title (drawbox draws the static bar)
ffmpeg -i video.mp4 \
  -vf "drawbox=x=0:y=ih-120:w=400:h=100:color=0x1a1a2e@0.9:t=fill,\
       drawbox=x=0:y=ih-120:w=5:h=100:color=0x00ff88:t=fill,\
       drawtext=text='John Smith':x=20:y=h-110:fontsize=32:fontcolor=white,\
       drawtext=text='Senior Developer':x=20:y=h-70:fontsize=24:fontcolor=0xaaaaaa" \
  lower_third.mp4
```

A sliding lower third is in `drawtext-animation.md`. More box and bar layouts are in `shapes-graphics.md`.

## Timecode, Clock and Frame Numbers

| Text expansion | Output |
|----------------|--------|
| `%{pts\:hms}` | Stream time as HH:MM:SS.mmm |
| `%{pts}` | Stream time in seconds (e.g. 1.500000) |
| `%{frame_num}` or `%{n}` | Frame number (`start_number=` sets the first) |
| `%{localtime\:FORMAT}` | Wall-clock time at render, strftime format |
| `%{eif\:EXPR\:d}` | Integer value of an expression (`d`, `x`, `X`, `u`; optional width) |
| `%{metadata\:KEY}` | Frame metadata set by an earlier filter |

```bash
# Running time
ffmpeg -i video.mp4 \
  -vf "drawtext=text='%{pts\:hms}':x=10:y=10:fontsize=24:fontcolor=white" \
  output.mp4

# Frame counter with a box
ffmpeg -i video.mp4 \
  -vf "drawtext=text='Frame\: %{frame_num}':x=10:y=10:fontsize=24:fontcolor=white:\
       box=1:boxcolor=black@0.5" \
  frame_counter.mp4

# SMPTE timecode (HH:MM:SS:FF), counting from the given start; rate = frame rate
ffmpeg -i video.mp4 \
  -vf "drawtext=timecode='00\:00\:00\:00':rate=30:x=10:y=10:\
       fontsize=32:fontcolor=white:box=1:boxcolor=black@0.6" \
  with_timecode.mp4

# Current date and time (render time, not recording time). The colons inside
# the strftime format need three levels of escaping inside double quotes.
ffmpeg -i video.mp4 \
  -vf "drawtext=text='%{localtime\:%Y-%m-%d %H\\\\\:%M\\\\\:%S}':x=10:y=10:fontsize=24:fontcolor=white" \
  output.mp4
```

Countdowns and stopwatches built from `%{eif...}` are in `drawtext-animation.md`.

## Frame Metadata and Container Tags

`%{metadata\:KEY}` reads frame metadata written by an earlier filter in the chain, not the container's tags:

```bash
# Print the average luma measured by signalstats
ffmpeg -i input.mp4 \
  -vf "signalstats,drawtext=text='Y avg %{metadata\:lavfi.signalstats.YAVG}':\
       fontsize=24:fontcolor=white:x=10:y=h-40" \
  luma.mp4
```

For a container tag such as the title, read it with ffprobe and pass it through a file. That avoids escaping problems with quotes or colons in the title:

```bash
ffprobe -v error -show_entries format_tags=title -of default=nw=1:nk=1 input.mp4 > title.txt
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=title.txt:fontsize=24:fontcolor=white:x=10:y=h-40" \
  title.mp4
```

Whisper transcription text is attached to audio frames, so `drawtext` on the video stream cannot read it. Generate an SRT file (`whisper.md`), then burn it with `subtitles=` (`captions.md`).

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| Text invisible | `fontcolor` defaults to black | Set `fontcolor=white` (or any colour) |
| Wrong font, no error | A missing `fontfile=` or an unknown `font=` name silently falls back to the default font (seen on 8.0.1) | Check the path; `fc-match NAME` shows what a name resolves to |
| "Stray %" | Bare `%` in `text=` | Use `textfile=...:expansion=none` |
| "No option name near ..." | Unescaped `:` in the text ends the option | Write `\:` inside `text='...'` |
| Box glyph at line ends | Multi-line text on some 8.0.1 builds | One `drawtext` per line, or ASS |
| Segfault | `fontsize` changes per frame | Constant `fontsize`; scale a text layer instead (`drawtext-animation.md`) |
