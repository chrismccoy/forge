# FFmpeg ASS Karaoke

ASS karaoke subtitles (`\k`, `\kf`, `\ko`), karaoke styles, tempo timing, colour transitions and animated karaoke, and when to use ASS instead of drawtext.

## Contents

- [Tool Choice: ASS vs drawtext](#tool-choice-ass-vs-drawtext)
- [Time Units](#time-units)
- [Karaoke Core Pattern](#karaoke-core-pattern)
- [Karaoke Timing Tags](#karaoke-timing-tags)
- [Syllable Timing by Tempo](#syllable-timing-by-tempo)
- [Tag Selection](#tag-selection)
- [Karaoke Styles](#karaoke-styles)
- [Multi-Colour Karaoke](#multi-colour-karaoke)
- [Per-Character Karaoke](#per-character-karaoke)
- [Karaoke with Animation Effects](#karaoke-with-animation-effects)
- [ASS Colour Format](#ass-colour-format)
- [ASS Animation Tags](#ass-animation-tags)
- [Burn In and Generate](#burn-in-and-generate)
- [Workflow](#workflow)
- [Sources](#sources)

## Tool Choice: ASS vs drawtext

| Need | Best Tool | Why |
|------|-----------|-----|
| Word/syllable karaoke highlighting | ASS | Native `\k`, `\kf`, `\ko` support |
| Styled subtitles with outline/glow/rotation | ASS | Rich subtitle styling and transform tags |
| Size animation | ASS `\t(\fscx\fscy)` or a scaled drawtext layer | A per-frame drawtext `fontsize` segfaults FFmpeg 8.0.1 |
| Rotation | ASS (`\frz`, `\frx`, `\fry`) | `drawtext` does not rotate text |
| Multi-line blocks, long credits | ASS | drawtext draws a box glyph at line ends on the 8.0.1 Ubuntu build |
| Simple overlay text | `drawtext` | Fast, direct FFmpeg filter |
| Timecode, frame numbers, metadata text | `drawtext` | Built-in variable expansion |
| Tickers, formula-driven motion | `drawtext` | Position expressions in `t` |

## Time Units

Karaoke tags count centiseconds, `\t`/`\fad`/`\move` milliseconds from the line start: see [ASS Time Units](animation-timing.md#ass-time-units).

## Karaoke Core Pattern

```ass
[Script Info]
Title: Karaoke Example
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Karaoke,Arial,72,&H0000FFFF,&H00FFFFFF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,3,2,2,10,10,50,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\k50}Twinkle {\k50}twinkle {\k50}little {\k50}star
Dialogue: 0,0:00:05.00,0:00:09.00,Karaoke,,0,0,0,,{\k50}How {\k50}I {\k50}wonder {\k50}what {\k50}you {\k50}are
```

**Colour roles:** a karaoke syllable is drawn in **SecondaryColour** until its turn and in **PrimaryColour** once it has been sung (`\k` switches at the syllable's start, `\kf` sweeps left to right over its duration). So set PrimaryColour to the highlight and SecondaryColour to the plain text colour. The `Karaoke` style above is white (`&H00FFFFFF`, Secondary) before and yellow (`&H0000FFFF`, Primary) after.

## Karaoke Timing Tags

| Tag | Effect | Example |
|-----|--------|---------|
| `\k` | Instant highlight (whole syllable switches at its start) | `{\k100}Word` = 1 second syllable |
| `\kf` or `\K` | Smooth fill, sweeping left to right | `{\kf100}Word` |
| `\ko` | Instant highlight; outline hidden until the syllable starts | `{\ko100}Word` |

Duration is in **centiseconds** (100 = 1 second).

## Syllable Timing by Tempo

Always time syllables from the audio (Aegisub's karaoke timer, or word timestamps). The table is a rule of thumb for sanity-checking: a sung syllable usually lasts between half a beat and one beat (beat = 60 / BPM seconds); held notes run longer and rap often goes down to a quarter beat. This is the one tempo table for the skill; the genre styling table in `animation-timing.md` uses the same ranges.

| BPM Range | One beat | Typical syllable | Tag value | Typical genres |
|-----------|----------|------------------|-----------|----------------|
| 60-80 | 750-1000 ms | 400-1000 ms (held notes 1-2 s) | `\k40`-`\k100` (`\kf` from 50) | Ballad |
| 80-100 | 600-750 ms | 300-750 ms | `\k30`-`\k75` | Pop, rock |
| 100-120 | 500-600 ms | 250-600 ms | `\k25`-`\k60` | Pop, rock |
| 120-140 | 430-500 ms | 200-500 ms | `\k20`-`\k50` | Dance, EDM |
| 140+ | under 430 ms | 150-400 ms | `\k15`-`\k40` | Rap, EDM |

Highlights should land 0 to +50 ms after the sung word, never before ([sync tolerances](animation-timing.md#audio-video-sync-tolerances)).

## Tag Selection

Threshold used across this skill: `\kf` for syllables of 50 cs or longer, `\k`/`\ko` for shorter ones (a sweep under ~0.5 s, about 15 frames at 30 fps, is too fast to read as a sweep). Rule of thumb.

**`\k` (instant):** syllables under 50 cs, rap and fast delivery, staccato rhythm.

```ass
; Rap example (fast succession):
{\k25}Yo {\k20}this {\k15}is {\k30}rapid {\k25}fire {\k35}flow
```

**`\kf` (progressive fill):** syllables of 50 cs or longer, ballads and sustained notes, a clean visual sweep.

```ass
; Ballad example (sustained notes):
{\kf150}Loooooove {\kf120}yoooou {\kf180}foreeeever
```

**`\ko` (outline reveal):** high-contrast text that needs to pop, neon/glow styles, chorus or key phrases.

```ass
[V4+ Styles]
; Unsung: grey fill, no outline (\ko hides it). Sung: black fill + green neon outline
Style: NeonKaraoke,Arial,80,&H00000000,&H00808080,&H0000FF00,&H00000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,50,1

[Events]
Dialogue: 0,0:00:01.00,0:00:05.00,NeonKaraoke,,0,0,0,,{\ko50}Electric {\ko60}neon {\ko40}glow
```

## Karaoke Styles

```ass
[V4+ Styles]
; Gradient karaoke: white unsung, yellow sung (animate \1c toward red as in Multi-Colour Karaoke)
Style: KaraokeGradient,Impact,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,4,2,2,10,10,60,1

; Glow effect karaoke: white unsung, magenta sung, purple outline (blurred into a glow by \blur in the line)
Style: KaraokeGlow,Arial Black,72,&H00FF00FF,&H00FFFFFF,&H00800080,&H00000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,50,1

; Neon style for \ko: grey unsung (no outline), black fill + green outline when sung
Style: KaraokeNeon,Arial,80,&H00000000,&H00808080,&H0000FF00,&H00000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,50,1

[Events]
; Word-by-word with a fade-in
Dialogue: 0,0:00:01.00,0:00:05.00,KaraokeGradient,,0,0,0,,{\k50\fad(200,0)}Never {\k50}gonna {\k50}give {\k50}you {\k50}up
; With positioning and glow
Dialogue: 0,0:00:05.00,0:00:09.00,KaraokeGlow,,0,0,0,,{\pos(960,900)\blur3\k50}Never {\k50}gonna {\k50}let {\k50}you {\k50}down
```

Genre colour schemes (ballad white to soft blue, pop white to pink, rock white to orange, EDM neon, rap white to red) are in the genre table in `animation-timing.md`.

## Multi-Colour Karaoke

Animate the sung colour (`\1c`) with `\t`. `\t` times are milliseconds from the line start, so each word's `\t` starts where its `\kf` starts (Word2 starts at 800 ms):

```ass
[V4+ Styles]
Style: GradientKaraoke,Impact,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H00000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,50,1
;                                   Primary^      Secondary^
;                                   Yellow(sung)  White(unsung)

[Events]
Dialogue: 0,0:00:01.00,0:00:05.00,GradientKaraoke,,0,0,0,,{\kf80\t(0,800,\1c&H0000A5FF&)}Word1 {\kf100\t(800,1800,\1c&H000000FF&)}Word2
;                                                         yellow->orange          orange->red
```

Colour progression (each block's `\t` affects its own word and the words after it, not the words before):

```yaml
Word1: yellow -> orange over 0-800 ms, then stays orange
Word2: yellow -> orange over 0-800 ms (inherited), then orange -> red over 800-1800 ms
Unsung text stays SecondaryColour (white) throughout
```

To give each word its own colour instead, start every block with `\r` (reset to the style):

```ass
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\r\k100\t(0,1000,\c&H0000FF&)}Red {\r\k100\t(1000,2000,\c&H00FF00&)}Green
```

## Per-Character Karaoke

```ass
; Each character gets individual timing (manual, tedious)
{\k10}H{\k8}e{\k12}l{\k10}l{\k15}o {\k20}w{\k18}o{\k15}r{\k12}l{\k10}d
```

Use character-level timing for slow-motion word reveals, dramatic emphasis, or non-linear highlighting (every other letter). Time it with Aegisub's karaoke timer rather than by hand. A character typewriter built on `\ko` is in `drawtext-animation.md`.

## Karaoke with Animation Effects

```ass
[Events]
; Spin effect per word. \fry/\frz rotate around the LINE's origin (\org,
; default: the line's alignment point), so inside one line Word1 would swing
; across onto Word2. Give each word its own Dialogue line with \pos and
; \an5 so it spins around its own centre (PlayResX 1920 here):
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\an5\pos(800,980)\k50\t(0,500,\fry360)}Word1
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\an5\pos(1120,980)\k50}{\k50\t(500,1000,\fry360)}Word2
; (Word2's empty first syllable {\k50} holds it unsung for 0.5 s)

; Grow on highlight (karaoke-grow keyframes: 115% over 150 ms, back over 150 ms)
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\k50\t(0,150,\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}Pop
; (multi-word lines: prefix each word with \r and offset its \t by the
;  cumulative \k time; full example in kinetic-captions.md)
```

## ASS Colour Format

ASS uses `&HAABBGGRR` (alpha, blue, green, red; alpha 00 = opaque, FF = transparent):

- `&H00FFFFFF` = White (fully opaque)
- `&H000000FF` = Red
- `&H0000FF00` = Green
- `&H00FF0000` = Blue
- `&H80000000` = 50% transparent black

## ASS Animation Tags

| Tag | Effect |
|-----|--------|
| `\t(t1,t2,tags)` | Animate tags from t1 to t2 (ms from line start) |
| `\move(x1,y1,x2,y2[,t1,t2])` | Move text from point to point |
| `\fad(fadein,fadeout)` | Fade in/out (milliseconds) |
| `\fscx`, `\fscy` | Scale X/Y percentage |
| `\frx`, `\fry`, `\frz` | Rotate on axis |
| `\pos(x,y)` | Position text (cannot be animated with `\t`) |
| `\an1-9` | Alignment (numpad positions) |
| `\r` | Reset to the line's style |

## Burn In and Generate

```bash
# Burn karaoke subtitles into video
ffmpeg -i input.mp4 \
  -vf "ass=karaoke.ass" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy \
  output_karaoke.mp4

# With a fonts directory
ffmpeg -i input.mp4 \
  -vf "ass=karaoke.ass:fontsdir=/path/to/fonts" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy output.mp4
```

From LRC lyrics, `scripts/generate-karaoke.sh` writes the ASS file and burns it:

```bash
# Styles: default, neon, outline, shadow, gradient. --video sizes the canvas to the video.
scripts/generate-karaoke.sh create lyrics.txt karaoke.ass neon --video input.mp4
scripts/generate-karaoke.sh apply input.mp4 karaoke.ass output.mp4
```

The LRC format, canvas options and the `kinetic` action are documented in `kinetic-captions.md`.

## Workflow

1. **Choose ASS or drawtext** with the tool-choice table.
2. **Check timing units** before writing tags or expressions.
3. **Probe the input** (`ffprobe`) for duration, frame rate and resolution, and set PlayResX/PlayResY to the frame's aspect ratio.
4. **Set output encoding explicitly** when burning text (`-c:v libx264 -crf 18 -pix_fmt yuv420p`; copy audio only when compatible).
5. **Render a short test** (`-ss`, `-t`) before a full music video or credit roll.
6. **Check readability:** karaoke highlights 0 to +50 ms after the sung word, never before; captions on screen long enough to read (`animation-timing.md`).

## Sources

- [ASS Karaoke Tags Documentation](https://docs.karaokes.moe/contrib-guide/create-karaoke/karaoke/)
- [Advanced Aegisub Karaoke](https://docs.karaokes.moe/contrib-guide/create-karaoke/karaoke-advanced/)
- [ASS Override Tags](https://aegisub.org/docs/latest/ass_tags/)
