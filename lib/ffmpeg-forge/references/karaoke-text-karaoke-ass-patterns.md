# Karaoke ASS Patterns

Detailed ASS/SSA karaoke subtitle recipes, timing tags, styling patterns, and burn-in commands.

## ASS Karaoke Basics

ASS (Advanced SubStation Alpha) supports karaoke timing with `\k` tags.

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
| `\kf` or `\K` | Smooth fill (fade) | `{\kf100}Word` |
| `\ko` | Instant highlight; outline hidden until the syllable starts | `{\ko100}Word` |

Duration is in **centiseconds** (100 = 1 second).

## Advanced Karaoke Timing Parameters

### Optimal Karaoke Timing by Song Tempo

| BPM Range | Syllable Duration | Tag Value | Notes |
|-----------|-------------------|-----------|-------|
| 60-80 (Slow ballad) | 600-800ms | `\kf60-80` | Long, emotional |
| 80-100 (Moderate) | 400-600ms | `\kf40-60` | Standard pop |
| 100-120 (Upbeat) | 300-500ms | `\kf30-50` | Most common |
| 120-140 (Fast) | 250-400ms | `\kf25-40` | Energetic |
| 140+ (Rapid) | 200-300ms | `\kf20-30` | Rap, EDM |

### Karaoke Tag Selection Guide

#### `\k` (Instant Fill) - Best For

- Very short syllables: <120 centiseconds (1.2s)
- Rap/hip-hop: Fast lyric delivery
- Staccato rhythm: Percussive, sharp delivery

```ass
; Rap example (fast succession):
{\k25}Yo {\k20}this {\k15}is {\k30}rapid {\k25}fire {\k35}flow
```

#### `\kf` (Progressive Fill) - Best For

- Long syllables: >120 centiseconds (1.2s)
- Ballads: Drawn-out emotional delivery
- Smooth transitions: Clean visual sweep

```ass
; Ballad example (sustained notes):
{\kf150}Loooooove {\kf120}yoooou {\kf180}foreeeever
```

Recommended: Use `\kf` for any syllable >100 centiseconds for smoothest visual effect.

#### `\ko` (Outline Reveal) - Best For

- High contrast: Text that needs to "pop"
- Neon/glow styles: Outline-heavy fonts
- Special emphasis: Chorus, key phrases

```ass
; Neon karaoke style:
[V4+ Styles]
; Unsung: grey fill, no outline (\ko hides it). Sung: black fill + green neon outline
Style: NeonKaraoke,Arial,80,&H00000000,&H00808080,&H0000FF00,&H00000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,50,1

[Events]
Dialogue: 0,0:00:01.00,0:00:05.00,NeonKaraoke,,0,0,0,,{\ko50}Electric {\ko60}neon {\ko40}glow
```

## Multi-Color Karaoke Transitions

Create dynamic color changes during karaoke fill:

```ass
; Gradient karaoke: Yellow → Orange → Red
[V4+ Styles]
Style: GradientKaraoke,Impact,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H00000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,50,1
;                                   Primary^      Secondary^
;                                   Yellow(sung)  White(unsung)

; Animate the sung colour (\1c) with \t; \t times are ms from the line start,
; so each word's \t starts where its \kf starts (Word2 starts at 800 ms):
[Events]
Dialogue: 0,0:00:01.00,0:00:05.00,GradientKaraoke,,0,0,0,,{\kf80\t(0,800,\1c&H0000A5FF&)}Word1 {\kf100\t(800,1800,\1c&H000000FF&)}Word2
;                                                         ↑ yellow→orange        ↑ orange→red
```

Color progression formula:

```yaml
Start: &H0000FFFF (Yellow)  - PrimaryColour at line start
Mid:   &H0000A5FF (Orange)  - reached when Word1's fill ends (800 ms)
End:   &H000000FF (Red)     - reached when Word2's fill ends (1800 ms)
Unsung text stays SecondaryColour (white) throughout
```

## Per-Character Karaoke

For very precise timing (character-by-character):

```ass
; Each character gets individual timing (manual, tedious)
{\k10}H{\k8}e{\k12}l{\k10}l{\k15}o {\k20}w{\k18}o{\k15}r{\k12}l{\k10}d

; Best practice: Use tools like Aegisub Karaoke Timer
; Manual character timing only for special effects
```

Use character-level karaoke for:

- Slow-motion word reveal
- Dramatic emphasis
- Non-linear character highlighting (e.g., every other letter)

## Apply Karaoke ASS to Video

```bash
# Burn karaoke subtitles into video
ffmpeg -i input.mp4 \
  -vf "ass=karaoke.ass" \
  -c:v libx264 -crf 18 -c:a copy \
  output_karaoke.mp4

# With specific fonts directory
ffmpeg -i input.mp4 \
  -vf "ass=karaoke.ass:fontsdir=/path/to/fonts" \
  output.mp4
```

## Advanced ASS Karaoke Styles

```ass
[V4+ Styles]
; Gradient karaoke: white unsung, yellow sung (animate \1c toward red as above)
Style: KaraokeGradient,Impact,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H80000000,1,0,0,0,100,100,0,0,1,4,2,2,10,10,60,1

; Glow effect karaoke: white unsung, magenta sung, purple outline (blurred into a glow by \blur in the line)
Style: KaraokeGlow,Arial Black,72,&H00FF00FF,&H00FFFFFF,&H00800080,&H00000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,50,1

; Neon style for \ko: grey unsung (no outline), black fill + green outline when sung
Style: KaraokeNeon,Arial,80,&H00000000,&H00808080,&H0000FF00,&H00000000,1,0,0,0,100,100,0,0,1,4,0,2,10,10,50,1

[Events]
; Word-by-word with effects
Dialogue: 0,0:00:01.00,0:00:05.00,KaraokeGradient,,0,0,0,,{\k50\fad(200,0)}Never {\k50}gonna {\k50}give {\k50}you {\k50}up
; With positioning
Dialogue: 0,0:00:05.00,0:00:09.00,KaraokeGlow,,0,0,0,,{\pos(960,900)\blur3\k50}Never {\k50}gonna {\k50}let {\k50}you {\k50}down
```

## ASS Color Format

ASS uses `&HAABBGGRR` format (Alpha, Blue, Green, Red):

- `&H00FFFFFF` = White (fully opaque)
- `&H000000FF` = Red
- `&H0000FF00` = Green
- `&H00FF0000` = Blue
- `&H80000000` = 50% transparent black

## Karaoke with Animation Effects

```ass
[Events]
; Spin effect per word (\fry360 = one full turn around the Y axis)
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\r\k50\t(0,500,\fry360)}Word1 {\r\k50\t(500,1000,\fry360)}Word2

; Scale pop on highlight
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\k50\t(0,100,\fscx120\fscy120)\t(100,200,\fscx100\fscy100)}Pop
; (multi-word lines: prefix each word with \r and offset its \t by the
;  cumulative \k time, as in the spin line above)

; Color transition
Dialogue: 0,0:00:01.00,0:00:05.00,Karaoke,,0,0,0,,{\r\k100\t(0,1000,\c&H0000FF&)}Red {\r\k100\t(1000,2000,\c&H00FF00&)}Green
```

## ASS Animation Tags Reference

| Tag | Effect |
|-----|--------|
| `\t(t1,t2,tags)` | Animate tags from t1 to t2 |
| `\move(x1,y1,x2,y2)` | Move text from point to point |
| `\fad(fadein,fadeout)` | Fade in/out (milliseconds) |
| `\fscx`, `\fscy` | Scale X/Y percentage |
| `\frx`, `\fry`, `\frz` | Rotate on axis |
| `\pos(x,y)` | Position text |
| `\an1-9` | Alignment (numpad positions) |
