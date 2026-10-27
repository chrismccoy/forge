# FFmpeg Animation Timing Reference

This reference is the authoritative answer to "what unit is this timing value in?" and "how long should this animation be?" for FFmpeg filters and ASS/SSA subtitles. Use it whenever animation, transition, caption, or sync timing is in play.

## Quick Reference Card

| Context | Unit | Example |
|---------|------|---------|
| FFmpeg filters (fade, xfade, drawtext) | **Seconds** | `duration=1.5` |
| FFmpeg `zoompan` `d=` parameter | **Frames** | `d=150` (150 frames) |
| FFmpeg time variable `t` | **Seconds** | `enable='gte(t,2)'` |
| ASS karaoke tags (`\k`, `\kf`, `\ko`) | **Centiseconds** | `{\k100}` = 1 second |
| ASS animation tags (`\t`, `\fad`, `\move`) | **Milliseconds** | `\t(0,500,...)` = 0.5s |
| ASS dialogue timestamps | **H:MM:SS.CC** | `0:00:05.50` |

---

## CRITICAL: ASS Has TWO Different Time Units!

**This is the most common source of confusion in subtitle animations.** Karaoke tags use centiseconds; everything else (animation, fade, move) uses milliseconds. Mixing them up causes animations to run 10x too fast or 10x too slow.

### ASS/SSA Time Unit Disambiguation

| Tag Type | Unit | Conversion | Example |
|----------|------|------------|---------|
| **Karaoke tags** (`\k`, `\kf`, `\ko`, `\K`) | **Centiseconds** (1/100s) | x 100 | `{\k50}` = 0.5 seconds |
| **Animation tags** (`\t`) | **Milliseconds** (1/1000s) | x 1000 | `\t(0,200,...)` = 0.2 seconds |
| **Fade tags** (`\fad`) | **Milliseconds** | x 1000 | `\fad(300,0)` = 0.3s fade in |
| **Move tags** (`\move`) | **Milliseconds** | x 1000 | `\move(x1,y1,x2,y2,0,500)` = 0.5s |
| **Dialogue timestamps** | **H:MM:SS.CC** | Centiseconds | `0:00:01.50` = 1.5 seconds |

### Same Duration, Different Units

```ass
; Both animations last 0.5 seconds but use DIFFERENT UNITS:

; Karaoke: 50 CENTISECONDS = 0.5 seconds
{\k50}Word

; Animation: 500 MILLISECONDS = 0.5 seconds
{\t(0,500,\fscx120)}Word
```

For full karaoke, fade, and move examples plus centisecond/millisecond conversion tables, see `animation-timing-copy-paste-patterns.md`.

---

## FFmpeg Time Units (Cheat Sheet)

Most FFmpeg filters take seconds (floating point). The big exception is `zoompan d=`, which is in **frames**.

| Filter / Context | Parameter | Unit |
|------------------|-----------|------|
| `fade` / `afade` | `d`, `st` | Seconds |
| `xfade` / `acrossfade` | `duration`, `offset` | Seconds |
| `drawtext` | `t` variable, `enable` | Seconds |
| `zoompan` | `d` | **Frames** |
| `zoompan` | `it` / `in_time` (input time), `ot` / `time` (output time) inside `z=`/`x=`/`y=` | Seconds (zoompan has no `t`; `in` / `on` are frame counts) |
| `trim` | `start`, `end` | Seconds |
| `fps` | `fps` | Frames/second |

### Zoompan Duration: Frames, Not Seconds

```bash
# d= is FRAMES. For a 2-second zoom:
# 30fps: d=60   (60 frames / 30fps)
# 60fps: d=120  (120 frames / 60fps)
# Formula: frames = seconds * fps
# d= is per INPUT frame, so use it on a single still image (on a video,
# every input frame would be repeated 60 times). scale+crop first so a
# non-9:16 photo is cropped, not stretched, to the 1080x1920 output:
ffmpeg -i photo.jpg -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,zoompan=z='min(zoom+0.0015,1.2)':d=60:s=1080x1920:fps=30,scale=out_range=tv,format=yuv420p" output.mp4
```

For viral-style hooks always use `d=1` (per-frame processing) and gate the effect with a time conditional on the input timestamp, like `if(lt(it,0.5),...)` (zoompan has no `t` variable; `z='...t...'` fails with "Undefined constant"). Setting `d=60` on a video would repeat every input frame 60 times. Also set zoompan's own `fps=` to the input rate: it defaults to 25, so a 60 fps input would come out slowed down. Full hook formulas and platform-specific zoom parameters are in `animation-timing-optimal-durations.md`.

---

## Core Workflow

1. **Identify the context** (FFmpeg filter vs ASS karaoke vs ASS animation vs dialogue timestamp) and read the Quick Reference Card to confirm the unit.
2. **Pick a target duration** based on perception (`animation-timing-optimal-durations.md`) and platform pacing (`animation-timing-platform-and-sync.md`).
3. **Snap to frame boundaries** if the value is short (<300ms) using the frame-safe table in `animation-timing-platform-and-sync.md`.
4. **Choose an easing curve** when the motion needs polish (`animation-timing-easing-and-springs.md`).
5. **Validate against perception thresholds and sync tolerances** so animations don't fall under the flicker threshold or break lip sync.
6. **Copy the matching pattern** from `animation-timing-copy-paste-patterns.md` and adapt parameters.

## Activation Guidance

Pull the right reference based on the question:

| Question shape | Load |
|----------------|------|
| "How long should this caption / transition / hook be?" | `animation-timing-optimal-durations.md` |
| "Why does my caption feel too fast / fail WCAG?" | `animation-timing-caption-readability.md` |
| "Does this work for TikTok / Shorts / Reels / broadcast?" | `animation-timing-platform-and-sync.md` |
| "Is my lip sync / beat sync within tolerance?" | `animation-timing-platform-and-sync.md` |
| "Will this duration look smooth at 30fps / 60fps?" | `animation-timing-platform-and-sync.md` |
| "Which easing curve / spring should I use?" | `animation-timing-easing-and-springs.md` |
| "Give me a ready-to-paste timing snippet." | `animation-timing-copy-paste-patterns.md` |

## Quick Duration Cheat Sheet

| Duration | Use For |
|----------|---------|
| 50-100ms | Glitch, flash |
| 100-200ms | Quick UI feedback |
| 200-300ms | Standard animation |
| 300-500ms | Smooth transition |
| 500-800ms | Noticeable movement |
| 800-1500ms | Dramatic effect |
| 1.5-3s | Caption display |
| 3-5s | Long text reading |

Floors: house styles typically keep a subtitle on screen for at least ~1-1.5s (Netflix's floor is 5/6 s, i.e. 20 frames at 24 fps); WCAG itself sets no minimum duration. Minimum perceivable animation is ~67ms at 30fps, ~33ms at 60fps. Lip sync is asymmetric (ITU-R BT.1359): audio leading video is detectable from ~45ms, audio lagging from ~125ms; aim for under ~20ms early / ~40ms late.

---

## Reference Map

Sub-references (load on demand):

- `animation-timing-optimal-durations.md` - Human perception thresholds, recommended durations for text animations, video transitions, hook effects, karaoke; viral-video 1.3s attention threshold and platform-specific zoom parameters/hook formulas.
- `animation-timing-caption-readability.md` - Reading speed standards (WPM), caption duration formula, Python implementation, caption style-guide rules (BBC, Netflix, DCMP) and what WCAG 2.2 actually requires.
- `animation-timing-platform-and-sync.md` - TikTok / YouTube Shorts / Instagram Reels / Broadcast timing profiles, audio-video sync tolerances (lip sync, music, karaoke, SFX), frame rate precision and frame-safe duration table.
- `animation-timing-easing-and-springs.md` - Material Design timing, FFmpeg easing expressions, complete easing formulas (linear, quadratic, cubic, exponential, sine, circular, elastic, bounce, back), spring physics (mass-spring-damper), oscillation/wave/Lissajous formulas, pseudo-random noise, jitter/shake, fade/scale/position/rotation cookbook, biological rhythms, sources.
- `animation-timing-copy-paste-patterns.md` - Ready-to-paste FFmpeg and ASS timing snippets, frame rate conversion table, zoompan duration calculation.

## Related References

- `karaoke-text.md` - Karaoke subtitle creation
- `transitions.md` - Video transitions
- `captions.md` - Subtitle fundamentals
