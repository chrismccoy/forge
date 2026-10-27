# Kinetic Captions (ASS)

ASS kinetic captions for short-form video: word-grow karaoke, word pop, bounce, elastic, spring and shake, typewriter reveals, colour karaoke, per-platform styles, and the two caption generators (`scripts/generate-karaoke.sh kinetic` for LRC lyrics, `scripts/kinetic_captions.py` for word timestamps).

## Contents

- [Quick Reference](#quick-reference)
- [Workflow](#workflow)
- [Generators](#generators)
- [Timing Rules](#timing-rules)
- [1. Karaoke with Word-Grow Effect](#1-karaoke-with-word-grow-effect)
- [2. CapCut-Style Word Pop Effects](#2-capcut-style-word-pop-effects)
- [3. Spring Physics Animation](#3-spring-physics-animation)
- [4. Shake and Tremor Effects](#4-shake-and-tremor-effects)
- [5. Typewriter and Reveal Effects](#5-typewriter-and-reveal-effects)
- [6. Color Transitions](#6-color-transitions)
- [7. Platform-Specific Caption Styles](#7-platform-specific-caption-styles)
- [8. Best Practices and Troubleshooting](#8-best-practices-and-troubleshooting)

## Quick Reference

The five named presets (`pop`, `grow`, `bounce`, `elastic`, `karaoke-grow`) use the same keyframes in `scripts/generate-karaoke.sh`, `scripts/kinetic_captions.py` and this file.

| Effect | ASS Code | Duration | Use Case |
|--------|----------|----------|----------|
| `pop`: 50% -> 115% -> 100% | `{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}` | 200ms | Word appear; TikTok, fast content |
| `grow`: 80% -> 115% -> 100% | `{\fscx80\fscy80\t(0,150,\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}` | 300ms | Smooth word appear; Shorts, calmer delivery |
| `bounce`: one overshoot, 80% -> 120% -> 95% -> 100% | `{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx95\fscy95)\t(200,300,\fscx100\fscy100)}` | 300ms | Emphasis |
| `elastic`: several overshoots, 40% -> 130% -> 90% -> 105% -> 100% | `{\fscx40\fscy40\t(0,80,\fscx130\fscy130)\t(80,160,\fscx90\fscy90)\t(160,260,\fscx105\fscy105)\t(260,380,\fscx100\fscy100)}` | 380ms | High-energy words |
| `karaoke-grow`: highlight + 115% grow | `{\k80\t(0,150,\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}` (later words: `\r` + offset `\t`) | 300ms grow within the `\k` time | Lyric videos, singalongs |
| Spring entry | `{\move(540,1100,540,960,0,300)\t(0,150,\fscx110\fscy110)\t(150,300,\fscx100\fscy100)}` | 300ms | Entry from below |
| Shake | One short Dialogue line per jitter step, each with `{\move(x1,y1,x2,y2)}` (e.g. 540->545, 545->535, 535->540); `\pos` cannot be animated with `\t` | 150ms | Impact emphasis |
| Karaoke fill | `{\kf100}Word` | 1000ms | Progressive highlight |

## Workflow

1. **Get word timing.** Word-level timestamps (openai-whisper with word timestamps, or aligned lyrics) for word effects; LRC lines for lyric videos. Check timings against the audio, not sentence-level timestamps.
2. **Pick the canvas.** PlayResX x PlayResY must match the output frame's aspect ratio (1080x1920 for 9:16, 1920x1080 for 16:9). The ASS canvas is stretched to the frame, so a 1080x1920 file burned onto a 16:9 video is distorted.
3. **Generate the ASS file** with a generator (next section), or write the lines by hand from the sections below.
4. **Test-burn a short slice** (`-t 5`) and look at a few frames. Check that libass prints no warnings.
5. **Burn the full video:**

```bash
# Burn subtitles into video
ffmpeg -i input.mp4 -vf "ass=kinetic.ass" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy output.mp4

# Or with the script (warns when the ASS canvas and the video aspect differ)
scripts/generate-karaoke.sh apply input.mp4 kinetic.ass output.mp4

# With hardware encoding (NVENC)
ffmpeg -i input.mp4 -vf "ass=kinetic.ass" -c:v h264_nvenc -preset p4 -rc vbr -cq 20 -b:v 0 -pix_fmt yuv420p -c:a copy output.mp4

# 9:16 vertical from a landscape source: pad to 1080x1920 first, so a
# 1080x1920 ASS canvas matches the frame
ffmpeg -i input.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,ass=kinetic.ass" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy output.mp4
```

### Checklist

- The ASS file has `[Script Info]`, `[V4+ Styles]` (with a `Format:` line) and `[Events]` sections, and renders with `-vf "ass=captions.ass"` on a short test.
- PlayResX x PlayResY matches the output frame's aspect ratio.
- Karaoke styles use SecondaryColour for not-yet-sung text and PrimaryColour for sung text.
- `\k`/`\kf` durations are in centiseconds; `\t`, `\move`, `\fad` times are in milliseconds from the line start.
- Words that share one screen position do not overlap in time.
- Font size (~72 px or more on a 1080-px-wide canvas), margins and word count suit the target platform.
- Word timings are checked against the audio.

## Generators

Both generators write the five presets above, refuse to overwrite an existing output file, and set the canvas per platform: 1080x1920 for `tiktok` and `instagram`, 1920x1080 for `youtube`. MarginV is 280/1920 of the height on portrait canvases and 8% on landscape.

### From LRC Lyrics: `scripts/generate-karaoke.sh kinetic`

`scripts/generate-karaoke.sh kinetic <lyrics.txt> <output.ass> [effect] [platform] [--res WxH | --video FILE]`

- Effects: `pop`, `grow`, `bounce`, `elastic`, `karaoke-grow`. Platforms: `tiktok` (default), `youtube`, `instagram`.
- Lyrics use LRC timing, one line per lyric line: `[MM:SS.xx] Line text` (`[HH:MM:SS.xx]` also works; a tag with no text ends the previous line). LRC tags such as `[ar:Artist]` and lines starting with `#` are ignored. Words in a line share its duration evenly.
- `karaoke-grow` writes one Dialogue line per lyric line with offset `\t` per word; the other effects write one Dialogue line per word, so every `\t` starts at 0.
- `--video FILE` takes the canvas from the display size of the video the captions are for; `--res WxH` sets it. Font sizes, outlines and margins scale with the canvas.

```bash
# Basic kinetic captions (TikTok, 1080x1920)
scripts/generate-karaoke.sh kinetic lyrics.txt pop.ass pop

# Platform-specific
scripts/generate-karaoke.sh kinetic lyrics.txt bounce_tiktok.ass bounce tiktok
scripts/generate-karaoke.sh kinetic lyrics.txt elastic_youtube.ass elastic youtube
scripts/generate-karaoke.sh kinetic lyrics.txt karaoke_reels.ass karaoke-grow instagram

# Match the canvas to the actual video
scripts/generate-karaoke.sh kinetic lyrics.txt captions.ass pop tiktok --video input.mp4
```

`generate-karaoke.sh` also has `create` (plain ASS karaoke from LRC, see `karaoke-text.md`), `template <style> <output.ass>` (an editable ASS file for one style, e.g. `kinetic-pop`) and `apply` (burn). Run it with no arguments for the full usage.

### From Word Timestamps: `scripts/kinetic_captions.py`

`scripts/kinetic_captions.py <transcript.json> <output.ass> [style] [platform]`

- Styles: `pop` (default), `grow`, `karaoke` (the karaoke-grow preset), `bounce`, `elastic`, `shake` (scale punch plus a decaying `\frz` jitter). Platforms: `tiktok` (default), `youtube`, `instagram`.
- Word effects write one Dialogue line per word, each ending when the next word starts, so words never overlap. `karaoke` writes one line per segment; each `\k` runs until the next word starts, so pauses stay in sync.
- `{` and `}` in words are escaped, so they show as literal braces.
- Errors (missing or invalid JSON, words without times, no words) print a message and exit 1.

Input JSON (seconds), e.g. from openai-whisper with word timestamps. FFmpeg's own `whisper` filter emits segments, not words, so it cannot feed this generator:

```json
{
  "segments": [
    {
      "words": [
        {"word": "This", "start": 0.0, "end": 0.5},
        {"word": "is", "start": 0.5, "end": 0.8}
      ]
    }
  ]
}
```

```bash
scripts/kinetic_captions.py transcript.json captions.ass pop tiktok
ffmpeg -i input.mp4 -vf "ass=captions.ass" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy output.mp4
```

Pick the platform whose canvas matches the video: `tiktok`/`instagram` for 9:16, `youtube` for 16:9.

### By Hand

A complete 9:16 file with a plain style and a karaoke style. MarginV 280 on a 1920-px-tall canvas keeps captions in the lower part but clear of the TikTok/Reels bottom UI, and MarginL/R 108 (10%) clears the right-hand buttons. These are rules of thumb; check the platform's current safe-zone overlay.

```ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Kinetic,Montserrat,76,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,0,2,108,108,280,1
; Karaoke: SecondaryColour (white) before a word is sung, PrimaryColour (yellow) after
Style: KineticKaraoke,Montserrat,76,&H0000FFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,4,0,2,108,108,280,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:02.00,Kinetic,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}Hello
Dialogue: 0,0:00:02.00,0:00:03.00,Kinetic,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}World
Dialogue: 0,0:00:03.00,0:00:07.00,KineticKaraoke,,0,0,0,,{\r\k80\t(0,150,\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}First {\r\k60\t(800,950,\fscx115\fscy115)\t(950,1100,\fscx100\fscy100)}word {\r\k100\t(1400,1550,\fscx115\fscy115)\t(1550,1700,\fscx100\fscy100)}grows
```

## Timing Rules

Units: `\k` tags count centiseconds, `\t`/`\move`/`\fad` milliseconds from the start of the Dialogue line ([ASS Time Units](animation-timing.md#ass-time-units)). For word N, offset `\t` by the sum of the preceding `\k` values x 10 ms.

- Start each word's block with `\r` (reset to the style). Override tags carry over to the rest of the line, so without it one word's `\t` also scales every later word.
- `\pos` cannot be animated with `\t`, and a line holds only one `\move`. Multi-step motion is one short Dialogue line per step (see Shake).

---

## 1. Karaoke with Word-Grow Effect

The **word-grow highlight** is the most requested kinetic effect - words scale up when highlighted, then return to normal size.

### Basic Word-Grow Karaoke

```ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: KaraokeGrow,Arial Black,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
; Word grows when karaoke highlight reaches it (white before, yellow once sung).
; \t times are ms from the line start, so each word is offset by the
; cumulative \k time (0, 800, 1400 ms) and \r stops the previous word's
; scale animation from carrying over.
Dialogue: 0,0:00:01.00,0:00:05.00,KaraokeGrow,,0,0,0,,{\r\k80\t(0,150,\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}This {\r\k60\t(800,950,\fscx115\fscy115)\t(950,1100,\fscx100\fscy100)}is {\r\k100\t(1400,1550,\fscx115\fscy115)\t(1550,1700,\fscx100\fscy100)}AMAZING
```

#### Understanding the Animation Tags

```ass
{\k80\t(0,150,\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}Word

Breaking it down:
- \k80 = Karaoke duration (80 centiseconds = 0.8 seconds)
- \t(0,150,...) = Animation from 0-150ms
- \fscx115\fscy115 = Scale to 115% (grow)
- \t(150,300,...) = Animation from 150-300ms
- \fscx100\fscy100 = Scale back to 100% (shrink)
```

`\k` is in centiseconds and `\t` in milliseconds from the line start (see [Timing Rules](#timing-rules)).

---

### Advanced Word-Grow Patterns

#### Pattern 1: Grow + Color Change

Words grow AND change color when highlighted:

```ass
[V4+ Styles]
Style: GrowColor,Arial Black,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
;                                 Primary = yellow (sung)  Secondary = white (not yet sung)

[Events]
; Karaoke fill (kf) + grow; the fill colour comes from PrimaryColour.
; Each word's \t is offset by the cumulative \kf time (0, 600, 1400 ms)
; and \r resets the previous word's scale.
Dialogue: 0,0:00:00.00,0:00:03.00,GrowColor,,0,0,0,,{\r\kf60\t(0,150,\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}Check {\r\kf80\t(600,750,\fscx115\fscy115)\t(750,900,\fscx100\fscy100)}this {\r\kf100\t(1400,1550,\fscx115\fscy115)\t(1550,1700,\fscx100\fscy100)}out
```

#### Pattern 2: Grow + Bounce (Overshoot)

Spring physics overshoot for more dynamic feel:

```ass
; Grows to 120%, bounces back to 95%, settles at 100%
Dialogue: 0,0:00:00.00,0:00:03.00,Style,,0,0,0,,{\k80\t(0,120,\fscx120\fscy120)\t(120,220,\fscx95\fscy95)\t(220,350,\fscx100\fscy100)}Bouncy
```

#### Pattern 3: Grow + Outline Pulse

Outline expands during highlight:

```ass
; Border/outline grows with text
Dialogue: 0,0:00:00.00,0:00:02.00,Style,,0,0,0,,{\k100\t(0,200,\fscx115\fscy115\bord8)\t(200,400,\fscx100\fscy100\bord5)}IMPACT
```

---

### Fast and Smooth Grow

Per-platform durations: [Platform Timing Profiles](animation-timing.md#platform-timing-profiles).

#### TikTok Optimized (Fast)

```ass
; Quick 200ms total animation
{\k60\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}Fast
```

#### YouTube Shorts Optimized (Smooth)

```ass
; Smooth 300ms total animation
{\k80\t(0,150,\fscx112\fscy112)\t(150,300,\fscx100\fscy100)}Smooth
```

---

## 2. CapCut-Style Word Pop Effects

The **word pop** effect makes each word appear with a bounce, popularized by CapCut.

### Basic Word Pop

```ass
[V4+ Styles]
Style: WordPop,Arial Black,84,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,280,1

[Events]
; Each word starts at 50% scale, pops to 115%, settles at 100%.
; All words share one screen position, so each line ends when the next starts
; (overlapping lines at the same spot are drawn on top of each other).
Dialogue: 0,0:00:00.00,0:00:00.30,WordPop,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}This
Dialogue: 0,0:00:00.30,0:00:00.50,WordPop,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}is
Dialogue: 0,0:00:00.50,0:00:01.20,WordPop,,0,0,0,,{\c&H0000FFFF&\fscx50\fscy50\t(0,100,\fscx120\fscy120)\t(100,250,\fscx100\fscy100)}VIRAL
```

#### Word Pop with Stagger Delay

Words appear one after another at the same position; each word's line ends when the next word's starts:

| Word | Start | End | Delay from Previous |
|------|-------|-----|---------------------|
| Word 1 | 0.00s | 0.25s | - |
| Word 2 | 0.25s | 0.50s | 250ms |
| Word 3 | 0.50s | 0.75s | 250ms |
| Word 4 | 0.75s | 1.25s | 250ms |

To keep earlier words visible (a phrase building up), place each word with its own `\pos` instead of sharing one position. Here three words stack vertically, each with the `pop` keyframes, the last one red:

```ass
; PlayResX 1920, PlayResY 1080; \an5 centres each word on its \pos
Dialogue: 0,0:00:01.00,0:00:08.00,Default,,0,0,0,,{\an5\pos(960,440)\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}THIS
Dialogue: 0,0:00:02.00,0:00:08.00,Default,,0,0,0,,{\an5\pos(960,540)\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}IS
Dialogue: 0,0:00:03.00,0:00:08.00,Default,,0,0,0,,{\an5\pos(960,640)\c&H0000FF&\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}KINETIC
```

#### Elastic Word Pop (Multiple Bounces)

```ass
; More dramatic with multiple oscillations
; 40% -> 130% -> 90% -> 105% -> 100% over 380 ms
Dialogue: 0,0:00:00.00,0:00:01.00,Style,,0,0,0,,{\fscx40\fscy40\t(0,80,\fscx130\fscy130)\t(80,160,\fscx90\fscy90)\t(160,260,\fscx105\fscy105)\t(260,380,\fscx100\fscy100)}ELASTIC
```

---

### Word Pop with Movement

#### Pop In from Below

```ass
; Word moves up while popping
Dialogue: 0,0:00:00.00,0:00:01.00,Style,,0,0,0,,{\move(540,1100,540,960,0,200)\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}BounceUp
```

#### Pop In from Side

```ass
; Word slides in from right while popping
Dialogue: 0,0:00:00.00,0:00:01.00,Style,,0,0,0,,{\move(1200,960,540,960,0,250)\fscx50\fscy50\t(0,120,\fscx110\fscy110)\t(120,250,\fscx100\fscy100)}SlideIn
```

#### Pop with Rotation

```ass
; Word rotates while appearing
Dialogue: 0,0:00:00.00,0:00:01.00,Style,,0,0,0,,{\frz-15\fscx50\fscy50\t(0,150,\frz0\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}Twist
```

---

## 3. Spring Physics Animation

ASS keyframes that imitate a damped spring: more overshoot steps read as a bouncier (lower-damped) spring. The damping-ratio and frequency guide for formula-driven springs is in `easing-and-springs.md` (Spring Physics).

### Spring Bounce in ASS

#### Low Damping (Bouncy)

```ass
; Multiple oscillations: 120% → 90% → 105% → 98% → 100%
{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx90\fscy90)\t(200,300,\fscx105\fscy105)\t(300,400,\fscx98\fscy98)\t(400,500,\fscx100\fscy100)}Bouncy
```

#### Medium Damping (Balanced)

```ass
; Single overshoot: 115% → 95% → 100%
{\fscx80\fscy80\t(0,120,\fscx115\fscy115)\t(120,250,\fscx95\fscy95)\t(250,400,\fscx100\fscy100)}Balanced
```

#### High Damping (Quick Settle)

```ass
; Minimal overshoot: 110% → 100%
{\fscx80\fscy80\t(0,150,\fscx110\fscy110)\t(150,300,\fscx100\fscy100)}Quick
```

### Position Spring (Vertical Bounce)

```ass
; Word bounces to final position
; Starts 100px below, overshoots 20px above, settles.
; \pos cannot be animated inside \t (libass ignores it), and a line can hold
; only one \move, so each motion segment is its own short Dialogue line:
Dialogue: 0,0:00:00.00,0:00:00.15,Style,,0,0,0,,{\move(540,1060,540,940)}Position Bounce
Dialogue: 0,0:00:00.15,0:00:00.25,Style,,0,0,0,,{\move(540,940,540,980)}Position Bounce
Dialogue: 0,0:00:00.25,0:00:00.35,Style,,0,0,0,,{\move(540,980,540,960)}Position Bounce
Dialogue: 0,0:00:00.35,0:00:02.00,Style,,0,0,0,,{\pos(540,960)}Position Bounce
```

---

## 4. Shake and Tremor Effects

Impact emphasis with controlled shake animation.

### Horizontal Shake

```ass
; Shake left-right (±5px) then settle: one \move per 50 ms line
; (\move(x1,y1,x2,y2) without t1,t2 spans the whole line)
Dialogue: 0,0:00:00.00,0:00:00.05,Style,,0,0,0,,{\move(540,960,545,960)}SHAKE
Dialogue: 0,0:00:00.05,0:00:00.10,Style,,0,0,0,,{\move(545,960,535,960)}SHAKE
Dialogue: 0,0:00:00.10,0:00:00.15,Style,,0,0,0,,{\move(535,960,542,960)}SHAKE
Dialogue: 0,0:00:00.15,0:00:00.20,Style,,0,0,0,,{\move(542,960,538,960)}SHAKE
Dialogue: 0,0:00:00.20,0:00:00.25,Style,,0,0,0,,{\move(538,960,540,960)}SHAKE
Dialogue: 0,0:00:00.25,0:00:02.00,Style,,0,0,0,,{\pos(540,960)}SHAKE
```

### Decaying Impact Shake

```ass
; Strong shake that decays: 10px → 6px → 3px → 0px
Dialogue: 0,0:00:00.00,0:00:00.05,Style,,0,0,0,,{\move(540,960,550,960)}IMPACT
Dialogue: 0,0:00:00.05,0:00:00.10,Style,,0,0,0,,{\move(550,960,530,960)}IMPACT
Dialogue: 0,0:00:00.10,0:00:00.16,Style,,0,0,0,,{\move(530,960,546,960)}IMPACT
Dialogue: 0,0:00:00.16,0:00:00.22,Style,,0,0,0,,{\move(546,960,534,960)}IMPACT
Dialogue: 0,0:00:00.22,0:00:00.28,Style,,0,0,0,,{\move(534,960,543,960)}IMPACT
Dialogue: 0,0:00:00.28,0:00:00.35,Style,,0,0,0,,{\move(543,960,540,960)}IMPACT
Dialogue: 0,0:00:00.35,0:00:02.00,Style,,0,0,0,,{\pos(540,960)}IMPACT
```

### Shake + Scale Combo

```ass
; Word shakes AND scales for maximum impact
; (\t without times spans the whole line, so scale and move stay in step)
Dialogue: 0,0:00:00.00,0:00:00.05,Style,,0,0,0,,{\move(540,960,545,960)\fscx100\fscy100\t(\fscx120\fscy120)}BOOM
Dialogue: 0,0:00:00.05,0:00:00.10,Style,,0,0,0,,{\move(545,960,535,960)\fscx120\fscy120\t(\fscx115\fscy115)}BOOM
Dialogue: 0,0:00:00.10,0:00:00.20,Style,,0,0,0,,{\move(535,960,540,960)\fscx115\fscy115\t(\fscx100\fscy100)}BOOM
Dialogue: 0,0:00:00.20,0:00:02.00,Style,,0,0,0,,{\pos(540,960)}BOOM
```

### Shake Amplitude Guidelines

| Font Size | Max Horizontal | Max Vertical | Notes |
|-----------|----------------|--------------|-------|
| 64-72px | 8px | 6px | Readable |
| 76-84px | 10px | 8px | Noticeable |
| 88-96px | 12px | 10px | Dramatic |
| 100+px | 15px | 12px | Impact only |

**Rule of thumb**: keep shake amplitude at or below ~15% of the font size for readability (the table stays within it).

---

## 5. Typewriter and Reveal Effects

Character-by-character text reveal.

### Character Reveal (Typewriter)

Each character appears sequentially:

```ass
; Manual character timing (50ms per character)
Dialogue: 0,0:00:00.00,0:00:00.05,Style,,0,0,0,,H
Dialogue: 0,0:00:00.05,0:00:00.10,Style,,0,0,0,,He
Dialogue: 0,0:00:00.10,0:00:00.15,Style,,0,0,0,,Hel
Dialogue: 0,0:00:00.15,0:00:00.20,Style,,0,0,0,,Hell
Dialogue: 0,0:00:00.20,0:00:01.00,Style,,0,0,0,,Hello
```

Typewriter speeds (ms per character): [Text Animations](animation-timing.md#text-animations). For long text, the one-line `\ko` typewriter in `drawtext-animation.md` avoids writing a line per character.

### Word-by-Word Reveal

Less tedious than character reveal:

```ass
Dialogue: 0,0:00:00.00,0:00:00.30,Style,,0,0,0,,{\fad(100,0)}This
Dialogue: 0,0:00:00.30,0:00:00.60,Style,,0,0,0,,{\fad(100,0)}is
Dialogue: 0,0:00:00.60,0:00:00.90,Style,,0,0,0,,{\fad(100,0)}word
Dialogue: 0,0:00:00.90,0:00:01.20,Style,,0,0,0,,{\fad(100,0)}by
Dialogue: 0,0:00:01.20,0:00:02.00,Style,,0,0,0,,{\fad(100,0)}word
```

### Reveal with Pop

Combine typewriter timing with pop animation:

```ass
; Word appears AND pops
Dialogue: 0,0:00:00.00,0:00:00.25,Style,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx110\fscy110)\t(100,200,\fscx100\fscy100)}This
Dialogue: 0,0:00:00.25,0:00:00.50,Style,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx110\fscy110)\t(100,200,\fscx100\fscy100)}is
Dialogue: 0,0:00:00.50,0:00:01.00,Style,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx110\fscy110)\t(100,200,\fscx100\fscy100)}great
```

---

## 6. Color Transitions

Progressive `\kf` fill and multi-colour (yellow -> orange -> red) karaoke: [Multi-Colour Karaoke](karaoke-text.md#multi-colour-karaoke).

### Color Flash on Highlight

```ass
; Word flashes bright color then returns (\c = sung colour; \k shows it
; from the syllable's start, which is 0 ms here)
Dialogue: 0,0:00:00.00,0:00:02.00,Style,,0,0,0,,{\k80\c&HFFFFFF&\t(0,100,\c&H00FFFF&)\t(100,400,\c&HFFFFFF&)}Flash
```

### Grow with Colour

```ass
; Yellow sung colour while the word grows (karaoke-grow keyframes)
{\k80\t(0,150,\fscx115\fscy115\c&H00FFFF&)\t(150,300,\fscx100\fscy100)}Word

; Red outline glow while growing, back to black as it settles
{\k80\t(0,150,\fscx115\fscy115\3c&H0000FF&)\t(150,300,\fscx100\fscy100\3c&H000000&)}Word
```

---

## 7. Platform-Specific Caption Styles

### TikTok Viral Style

```ass
[V4+ Styles]
Style: TikTokViral,Arial Black,88,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,320,1

[Events]
; Fast pop, high energy
Dialogue: 0,0:00:00.00,0:00:00.20,TikTokViral,,0,0,0,,{\fscx50\fscy50\t(0,80,\fscx118\fscy118)\t(80,160,\fscx100\fscy100)}THIS
Dialogue: 0,0:00:00.20,0:00:00.40,TikTokViral,,0,0,0,,{\fscx50\fscy50\t(0,80,\fscx118\fscy118)\t(80,160,\fscx100\fscy100)}IS
Dialogue: 0,0:00:00.40,0:00:01.00,TikTokViral,,0,0,0,,{\c&H00FFFF&\fscx50\fscy50\t(0,100,\fscx125\fscy125)\t(100,200,\fscx100\fscy100)}VIRAL
```

**TikTok Parameters:**
- Font size: 84-96px
- Animation: 160-200ms total (within TikTok's 100-200ms)
- Pop scale: 115-125%
- Word delay: 150-250ms
- Phrase-style captions (words placed side by side): 3-5 words on screen
- All parameters are rules of thumb

### YouTube Shorts Professional

```ass
[V4+ Styles]
Style: ShortsPro,Montserrat,76,&H00FFFFFF,&H00FFFFFF,&H00333333,&H80000000,1,0,0,0,100,100,0,0,1,4,2,2,10,10,300,1

[Events]
; Smoother, more professional
Dialogue: 0,0:00:00.00,0:00:00.30,ShortsPro,,0,0,0,,{\fscx80\fscy80\t(0,150,\fscx108\fscy108)\t(150,300,\fscx100\fscy100)}This
Dialogue: 0,0:00:00.30,0:00:00.60,ShortsPro,,0,0,0,,{\fscx80\fscy80\t(0,150,\fscx108\fscy108)\t(150,300,\fscx100\fscy100)}is
Dialogue: 0,0:00:00.60,0:00:01.40,ShortsPro,,0,0,0,,{\fscx80\fscy80\t(0,150,\fscx112\fscy112)\t(150,300,\fscx100\fscy100)}professional
```

**YouTube Shorts Parameters:**
- Font size: 72-84px
- Animation: 150-300ms total
- Pop scale: 108-115%
- Word delay: 250-350ms
- Phrase-style captions: 4-6 words on screen
- All parameters are rules of thumb

### Instagram Reels Trendy

```ass
[V4+ Styles]
Style: ReelsTrend,Impact,82,&H00FFFFFF,&H00FF00FF,&H00000000,&H00000000,1,0,0,0,100,100,2,0,1,5,0,2,10,10,280,1

[Events]
; Stylish with slight rotation
Dialogue: 0,0:00:00.00,0:00:00.25,ReelsTrend,,0,0,0,,{\frz-5\fscx50\fscy50\t(0,120,\frz0\fscx115\fscy115)\t(120,250,\fscx100\fscy100)}Trendy
Dialogue: 0,0:00:00.25,0:00:00.50,ReelsTrend,,0,0,0,,{\frz5\fscx50\fscy50\t(0,120,\frz0\fscx115\fscy115)\t(120,250,\fscx100\fscy100)}Caption
Dialogue: 0,0:00:00.50,0:00:01.20,ReelsTrend,,0,0,0,,{\c&H00FF00FF&\fscx50\fscy50\t(0,150,\fscx120\fscy120)\t(150,300,\fscx100\fscy100)}Style
```

---

## 8. Best Practices and Troubleshooting

### Kinetic Caption Best Practices

1. **Don't over-animate**: Not every word needs maximum effect
2. **Emphasize key words**: Use larger scale/longer duration for important words
3. **Match tempo**: Fast speech = fast animation, slow = smooth
4. **Platform consistency**: Use platform-appropriate styles
5. **Test readability**: Animation shouldn't hurt comprehension

### Emphasis Hierarchy

| Word Type | Animation | Scale | Duration |
|-----------|-----------|-------|----------|
| Filler words (a, the, is) | Minimal pop | 105-110% | 150-200ms |
| Normal words | Standard pop | 110-115% | 200-250ms |
| Key words | Enhanced pop | 115-120% | 250-350ms |
| EMPHASIS words | Elastic/shake | 120-130% | 300-400ms |

### Common Issues and Solutions

#### Timing Mismatch

**Problem**: Animation doesn't match audio timing
**Solution**: Use word-level timestamps (openai-whisper with word timestamps, or aligned lyrics), not sentence-level

#### Jittery Animation

**Problem**: Text appears to stutter
**Solution**: A 100-200 ms pop spans only 3-6 frames at 30 fps. Render at 60 fps, or lengthen the animation. ASS `\t` is evaluated at every frame's time, so durations do not need to be whole frames.

#### Text Too Busy

**Problem**: Animations distract from content
**Solution**: Reduce scale amplitude (115% → 108%), simplify effects

#### Poor Mobile Readability

**Problem**: Text hard to read on phones
**Solution**:
- Font size at least ~72px on a 1080-px-wide canvas (the generator and script use 76-88px)
- Outline/border 4-6px
- Keep captions clear of the platform UI: MarginV ~280 on a 1920-px-tall canvas (bottom ~15%, as `scripts/generate-karaoke.sh` uses) and side margins of ~10% of the width. These are rules of thumb; check the platform's current safe-zone overlay.

---

## Sources

This reference draws on research from:
- [ASS Override Tags - Aegisub](https://aeg-dev.github.io/AegiSite/docs/3.2/ass_tags/)
- [FFmpeg Drawtext Animation](https://www.braydenblackwell.com/blog/ffmpeg-text-rendering)
- [KFX-GUI Karaoke Template Builder](https://github.com/9vult/kfxgui)
- [CapCut Kinetic Typography Guide](https://www.capcut.com/resource/kinetic-typography-animations/)
- [Kinetic Typography Complete Guide 2026](https://www.ikagency.com/graphic-design-typography/kinetic-typography/)
- [OpusClip Text Animation Packs](https://www.opus.pro/blog/best-text-animation-packs-captions-titles)
- [Spring Physics for UI Animations](https://www.kvin.me/posts/effortless-ui-spring-animations)
- [Easing Functions Reference](https://easings.net/)

---

## Related References

- `karaoke-text.md`: ASS karaoke tags, styles, tempo table
- `animation-timing.md`: units, durations, platform timing, sync tolerances
- `easing-and-springs.md`: spring and easing formulas
- `drawtext-animation.md`: drawtext motion and the scaled text layer
- `captions.md`: subtitle files and burn-in
