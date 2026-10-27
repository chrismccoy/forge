# FFmpeg Kinetic Captions

## Purpose
Create animated kinetic captions with professional effects like word-grow karaoke, bouncy text, elastic effects, and CapCut-style word pop animations for viral social media videos.

## Workflow

### 1. Quick Effect Reference

| Effect | Description | Best For |
|--------|-------------|----------|
| `pop` | Words pop in from small to normal with overshoot | TikTok, fast-paced content |
| `grow` | Words smoothly scale up when highlighted | Karaoke, music videos |
| `bounce` | Elastic bounce with multiple oscillations | YouTube Shorts, emphasis |
| `elastic` | Spring physics with natural damping | Professional, premium feel |
| `karaoke-grow` | Combined karaoke fill + grow animation | Lyric videos, singalongs |

### 2. Generate Kinetic ASS Subtitles

#### Using the Script
```bash
# Basic kinetic captions
scripts/generate-karaoke.sh kinetic lyrics.txt output.ass pop

# Platform-optimized
scripts/generate-karaoke.sh kinetic lyrics.txt output.ass bounce tiktok
scripts/generate-karaoke.sh kinetic lyrics.txt output.ass elastic youtube
scripts/generate-karaoke.sh kinetic lyrics.txt output.ass karaoke-grow instagram
```

#### Manual ASS Creation

**Pop Effect (CapCut-Style):**
```ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Kinetic,Montserrat,72,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,0,2,50,50,30,1
; Karaoke: SecondaryColour (white) before a word is sung, PrimaryColour (yellow) after
Style: KineticKaraoke,Montserrat,72,&H0000FFFF,&H00FFFFFF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,0,2,50,50,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:02.00,Kinetic,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}Hello
Dialogue: 0,0:00:02.00,0:00:03.00,Kinetic,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}World
```

**Word-Grow Karaoke Effect** (uses the `KineticKaraoke` style above):
```ass
Dialogue: 0,0:00:01.00,0:00:05.00,KineticKaraoke,,0,0,0,,{\r\k80\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}First {\r\k60\t(800,1000,\fscx115\fscy115)\t(1000,1200,\fscx100\fscy100)}word {\r\k100\t(1400,1600,\fscx115\fscy115)\t(1600,1800,\fscx100\fscy100)}grows
```

**Bounce Effect:**
```ass
Dialogue: 0,0:00:01.00,0:00:02.00,Kinetic,,0,0,0,,{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx95\fscy95)\t(200,300,\fscx100\fscy100)}Bounce
```

**Elastic Effect:**
```ass
Dialogue: 0,0:00:01.00,0:00:02.00,Kinetic,,0,0,0,,{\fscx60\fscy60\t(0,80,\fscx125\fscy125)\t(80,160,\fscx92\fscy92)\t(160,240,\fscx105\fscy105)\t(240,320,\fscx98\fscy98)\t(320,400,\fscx100\fscy100)}Elastic
```

### 3. Apply to Video

```bash
# Burn subtitles into video
ffmpeg -i input.mp4 -vf "ass=kinetic.ass" -c:v libx264 -crf 18 -c:a copy output.mp4

# With hardware acceleration (NVENC)
ffmpeg -i input.mp4 -vf "ass=kinetic.ass" -c:v h264_nvenc -preset p4 -rc vbr -cq 20 -b:v 0 -c:a copy output.mp4

# 9:16 vertical with kinetic captions
ffmpeg -i input.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,ass=kinetic.ass" -c:v libx264 -crf 18 output.mp4
```

### 4. Platform-Specific Timing

| Platform | Animation Speed | Recommended Effect |
|----------|----------------|-------------------|
| TikTok | Fast (100-200ms) | pop, bounce |
| YouTube Shorts | Medium (150-300ms) | grow, elastic |
| Instagram Reels | Stylish (200-400ms) | elastic, karaoke-grow |

### 5. Critical ASS Timing Notes

**IMPORTANT: ASS uses TWO different time units:**
- **Karaoke tags (`\k`, `\kf`, `\ko`)**: Centiseconds (100 = 1 second)
- **Animation tags (`\t`)**: Milliseconds (1000 = 1 second)

Example combining both:
```ass
{\k80\t(0,200,\fscx115\fscy115)}Word
```
- `\k80` = word highlighted for 0.8 seconds (80 centiseconds)
- `\t(0,200,...)` = animation over 200 milliseconds
- `\t` times are relative to the **start of the Dialogue line**, not the word. For word N, offset `\t` by the sum of the preceding `\k` values × 10 ms (or emit one Dialogue line per word, as `scripts/generate-karaoke.sh` does).
- Start each word's block with `\r` (reset to the style). Override tags carry over to the rest of the line, so without it one word's `\t` also scales every later word.

### 6. Color Variations

```ass
; Yellow highlight on grow
{\k80\t(0,200,\fscx115\fscy115\c&H00FFFF&)\t(200,400,\fscx100\fscy100)}Word

; Gradient glow effect
{\k80\t(0,200,\fscx115\fscy115\3c&H0000FF&)\t(200,400,\fscx100\fscy100\3c&H000000&)}Word
```

### 7. Advanced: Python Generator

For complex projects, use the Python generator:

```python
import json

def generate_kinetic_ass(words, effect="pop", platform="tiktok"):
    """Generate kinetic ASS subtitle file"""

    effects = {
        "pop": r"{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}",
        "grow": r"{\fscx90\fscy90\t(0,150,\fscx110\fscy110)\t(150,300,\fscx100\fscy100)}",
        "bounce": r"{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx95\fscy95)\t(200,300,\fscx100\fscy100)}",
        "elastic": r"{\fscx60\fscy60\t(0,80,\fscx125\fscy125)\t(80,160,\fscx92\fscy92)\t(160,240,\fscx105\fscy105)\t(240,320,\fscx98\fscy98)\t(320,400,\fscx100\fscy100)}"
    }

    header = """[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Kinetic,Montserrat,72,&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,0,2,50,50,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

    if effect not in effects:
        raise ValueError(f"unknown effect {effect!r}; choose one of {sorted(effects)}")
    effect_code = effects[effect]
    lines = []

    for word_data in words:
        word = word_data["word"]
        start = word_data["start"]
        end = word_data["end"]
        lines.append(f"Dialogue: 0,{start},{end},Kinetic,,0,0,0,,{effect_code}{word}")

    return header + "\n".join(lines)

# Usage
words = [
    {"word": "Hello", "start": "0:00:01.00", "end": "0:00:02.00"},
    {"word": "World", "start": "0:00:02.00", "end": "0:00:03.00"}
]
ass_content = generate_kinetic_ass(words, effect="bounce", platform="tiktok")
```

## Checklist

- The ASS file has `[Script Info]`, `[V4+ Styles]` (with a `Format:` line) and `[Events]` sections, and renders with `-vf "ass=captions.ass"` on a short test (`-t 5`).
- Karaoke styles use SecondaryColour for not-yet-sung text and PrimaryColour for sung text.
- `\k`/`\kf` durations are in centiseconds; `\t`, `\move`, `\fad` times are in milliseconds from the line start.
- Font size, margins and word count suit the target platform.
- Word timings are checked against the audio (word-level timestamps, not sentence-level).
