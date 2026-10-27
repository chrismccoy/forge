# FFmpeg Animation Timing

Timing units (FFmpeg seconds and frames, ASS centiseconds and milliseconds), perception thresholds, recommended durations, caption readability, platform pacing, audio-video sync tolerances, frame-rate limits and copy-paste timing snippets. Easing curves and spring formulas are in `easing-and-springs.md`.

## Contents

- [Quick Reference Card](#quick-reference-card)
- [ASS Time Units](#ass-time-units)
- [FFmpeg Time Units](#ffmpeg-time-units)
- [Zoompan Timing](#zoompan-timing)
- [Human Perception Thresholds](#human-perception-thresholds)
- [Recommended Durations](#recommended-durations)
- [Karaoke Timing by Genre](#karaoke-timing-by-genre)
- [Caption Readability](#caption-readability)
- [Platform Timing Profiles](#platform-timing-profiles)
- [Audio-Video Sync Tolerances](#audio-video-sync-tolerances)
- [Frame Rate Considerations](#frame-rate-considerations)
- [Copy-Paste Timing Patterns](#copy-paste-timing-patterns)
- [Workflow](#workflow)
- [Related References](#related-references)

Every duration in this file is a rule of thumb from motion-design and editing practice unless a standard is named. Adjust by eye.

## Quick Reference Card

| Context | Unit | Example |
|---------|------|---------|
| FFmpeg filters (fade, xfade, drawtext) | **Seconds** | `duration=1.5` |
| FFmpeg `zoompan` `d=` parameter | **Frames** | `d=150` (150 frames) |
| FFmpeg time variable `t` | **Seconds** | `enable='gte(t,2)'` |
| ASS karaoke tags (`\k`, `\kf`, `\ko`) | **Centiseconds** | `{\k100}` = 1 second |
| ASS animation tags (`\t`, `\fad`, `\move`) | **Milliseconds** | `\t(0,500,...)` = 0.5s |
| ASS dialogue timestamps | **H:MM:SS.CC** | `0:00:05.50` |

## ASS Time Units

**ASS has two different time units.** Karaoke tags use centiseconds; everything else (animation, fade, move) uses milliseconds. Mixing them up makes an animation run 10x too fast or 10x too slow.

| Tag Type | Unit | Conversion | Example |
|----------|------|------------|---------|
| **Karaoke tags** (`\k`, `\kf`, `\ko`, `\K`) | **Centiseconds** (1/100s) | x 100 | `{\k50}` = 0.5 seconds |
| **Animation tags** (`\t`) | **Milliseconds** (1/1000s) | x 1000 | `\t(0,200,...)` = 0.2 seconds |
| **Fade tags** (`\fad`) | **Milliseconds** | x 1000 | `\fad(300,0)` = 0.3s fade in |
| **Move tags** (`\move`) | **Milliseconds** | x 1000 | `\move(x1,y1,x2,y2,0,500)` = 0.5s |
| **Dialogue timestamps** | **H:MM:SS.CC** | Centiseconds | `0:00:01.50` = 1.5 seconds |

```ass
; Both animations last 0.5 seconds but use DIFFERENT UNITS:

; Karaoke: 50 CENTISECONDS = 0.5 seconds
{\k50}Word

; Animation: 500 MILLISECONDS = 0.5 seconds
{\t(0,500,\fscx120)}Word
```

`\t`, `\move` and `\fad` times count from the start of the Dialogue line, not from the word. In a karaoke line, offset each word's `\t` by the sum of the preceding `\k` values x 10 ms (`kinetic-captions.md`).

## FFmpeg Time Units

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

## Zoompan Timing

`zoompan d=` counts output frames per input frame (not seconds), and its `fps=` defaults to 25. The timing rules, video zooms and short-form hook zooms are in [`stabilization-360.md`](stabilization-360.md#zoompan-timing).

## Human Perception Thresholds

This is the single perception table for the skill (other files point here). The bands are approximate rules of thumb; only the frame-duration row is exact.

| Timing | Brain Response | Application |
|--------|----------------|-------------|
| <16ms | Sub-perceptual | Cannot perceive (below 60fps frame) |
| 16-50ms | Preattentive | Flash effects, subliminal |
| 50-100ms | Motion detection | Pattern interrupts, glitches |
| 100-200ms | Conscious recognition | Quick animations, snappy UI |
| 200-400ms | Attention capture | Standard animations |
| 400-800ms | Processing time | Complex transitions |
| 800ms-2s | Contemplation | Dramatic, emotional effects |
| >2s | Extended focus | Deliberate, artistic pacing |

### Distance vs Duration (Constant Perceived Speed)

```text
duration = sqrt(distance) * k

distance = pixels traveled
k = speed constant (typically 5-15)

100px -> sqrt(100)*10 = 100ms
400px -> sqrt(400)*10 = 200ms
```

FFmpeg implementation (move 500px in 224ms):

```bash
-vf "drawtext=text='MOVE':\
     x='if(lt(t,0.224),w-500*t/0.224,w-500)':\
     y=(h-th)/2:fontsize=80:fontcolor=white"
```

### Biological Rhythms

| Rhythm | Rate | Use Case |
|--------|------|----------|
| Resting heartbeat | 60-80 BPM (1-1.3 Hz) | Calm, meditative pulse |
| Walking pace | 100-120 BPM (1.7-2 Hz) | Comfortable, steady rhythm |
| Excited/anxious | 120-160 BPM (2-2.7 Hz) | Energetic, urgent feeling |
| Breathing | 12-20/min (0.2-0.33 Hz) | Slow, natural oscillation |

Use these as the `scale` factor of a fixed-size text layer ([Scale Animations (FFmpeg layer, no ASS)](easing-and-springs.md#scale-animations-ffmpeg-layer-no-ass)), not as `fontsize`:

```bash
# Heartbeat pulse (70 BPM = 1.17 Hz), up to +8%:
scale=w='iw*(1+0.08*max(0,sin(t*7.33)))':h=-2:eval=frame

# Walking pace (110 BPM = 1.83 Hz; abs() doubles the pulse rate, so use
# pi*1.83 = 5.76 rad/s; abs(sin(t*11.5)) would pulse at 3.66 Hz), up to +6%:
scale=w='iw*(1+0.06*abs(sin(t*5.76)))':h=-2:eval=frame

# Breathing (15/min = 0.25 Hz), +/-12%:
scale=w='iw*(1+0.12*sin(t*1.57))':h=-2:eval=frame
```

## Recommended Durations

### Text Animations

| Effect | Fast | Standard | Slow | Notes |
|--------|------|----------|------|-------|
| Word pop (scale) | 100-150ms | 150-250ms | 250-400ms | Script presets: 200-380ms |
| Fade in | 200-300ms | 300-500ms | 500-800ms | Smooth appearance |
| Fade out | 150-250ms | 200-400ms | 400-600ms | Slightly faster than fade in |
| Slide in | 200-300ms | 300-500ms | 500-800ms | Distance affects perception |
| Bounce | 300-400ms | 400-600ms | 600-800ms | Needs overshoot time |
| Typewriter | 30-50ms/char | 50-80ms/char | 80-120ms/char | Per character |

### Video Transitions (xfade)

| Transition | Fast | Standard | Slow | Best For |
|------------|------|----------|------|----------|
| Fade/Dissolve | 0.3-0.5s | 0.8-1.2s | 1.5-2.5s | Universal |
| Wipe | 0.2-0.4s | 0.5-0.8s | 1.0-1.5s | Directional energy |
| Slide | 0.3-0.5s | 0.6-1.0s | 1.2-2.0s | Dynamic movement |
| Circle/Iris | 0.5-0.8s | 1.0-1.5s | 2.0-3.0s | Dramatic reveal |
| Zoom | 0.4-0.6s | 0.8-1.2s | 1.5-2.5s | Impact, intensity |
| Pixelize | 0.3-0.5s | 0.5-0.8s | 1.0-1.5s | Glitch aesthetic |

### Hook Effects (First 1-3 Seconds)

| Hook Type | Effect Duration | Total Hook | Timing Pattern |
|-----------|----------------|------------|----------------|
| Pattern Interrupt | 50-150ms | 0.5-1.5s | Instant grab |
| Flash/Brightness | 80-200ms | 0.3-0.8s | Quick pulse |
| Zoom Punch | 200-400ms | 1-2s | Start zoomed in, snap back to 1x, hold |
| Glitch | 100-300ms | 0.5-1.5s | Multiple bursts |
| Text Slam | 150-250ms | 1-2s | Quick appear, hold |

### Karaoke and Caption Animations

| Content | Duration Formula | Example |
|---------|------------------|---------|
| Single word | Word length * 50-100ms | "Hello" = 250-500ms |
| Short phrase | 1-2 seconds | "Check this out" |
| Sentence | Words / 3 per second | 9 words = 3 seconds |
| Reading captions | See [Caption Readability](#caption-readability) | Based on WPM |

### Duration Cheat Sheet

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

Floors: house styles typically keep a subtitle on screen for at least ~1-1.5s (Netflix's floor is 5/6 s, i.e. 20 frames at 24 fps); WCAG itself sets no minimum duration. Minimum perceivable animation is ~67ms at 30fps, ~33ms at 60fps.

## Karaoke Timing by Genre

| Genre | Typical tempo | Syllable timing | Animation style | Colour scheme |
|-------|---------------|-----------------|-----------------|---------------|
| **Ballad** | 60-80 BPM | 40-100 cs (held notes 100-200 cs) | `\kf` smooth fill (most syllables reach 50 cs) | White -> soft blue |
| **Pop** | 80-120 BPM | 25-75 cs | `\k` with a scale bounce | White -> bright pink |
| **Rock** | 100-140 BPM | 20-60 cs | `\k` with shake | White -> orange |
| **EDM** | 120-140 BPM | 20-50 cs | `\ko` outline | Neon colours |
| **Rap** | 140+ BPM (or double-time) | 15-40 cs | `\k` instant | White -> red |

Syllable ranges follow the tempo table in `karaoke-text.md` (half to one beat, rule of thumb); time real lyrics from the audio. `\kf` is used for syllables of 50 cs or longer, `\k`/`\ko` below that.

## Caption Readability

Caption display time from reading-speed research and broadcaster/streaming style guides (BBC Subtitle Guidelines, Netflix Timed Text Style Guide, DCMP Captioning Key). WCAG 2.2 requires that captions exist; it does not set durations or reading speeds.

### Reading Speed

| Audience | Words Per Minute (WPM) | Use Case |
|----------|------------------------|----------|
| Slow readers | 120-140 WPM | Accessibility, elderly |
| **Average** | **160-180 WPM** | **Recommended default** |
| Fast readers | 200-220 WPM | Experienced viewers |
| Skim reading | 250-300 WPM | Not recommended for video |

### Duration Formula

```python
# Basic formula:
caption_duration = (word_count / words_per_minute) * 60

# With minimum duration (house-style floor, not a WCAG rule;
# Netflix's minimum is 5/6 s, many styles use 1-1.5 s):
minimum_duration = 1.5  # seconds
duration = max(minimum_duration, caption_duration)

# Recommended formula (matches calculate_caption_duration below):
# 160 WPM plus a 0.5 s processing buffer, 1.5 s floor
duration = max(1.5, (word_count / 160) * 60 + 0.5)
```

| Word Count | @ 160 WPM | @ 180 WPM | Recommended (160 WPM + 0.5 s, 1.5 s floor) |
|------------|-----------|-----------|-------------|
| 1-2 words | 0.75s | 0.67s | **1.5s** (minimum) |
| 3 words | 1.13s | 1.0s | **1.6s** |
| 4 words | 1.5s | 1.33s | **2.0s** |
| 5 words | 1.88s | 1.67s | **2.4s** |
| 6 words | 2.25s | 2.0s | **2.8s** |
| 8 words | 3.0s | 2.67s | **3.5s** |
| 10 words | 3.75s | 3.33s | **4.3s** |
| 15 words | 5.63s | 5.0s | **6.1s** |

```python
def calculate_caption_duration(text: str, wpm: int = 160) -> float:
    """
    Calculate optimal caption display duration.

    Args:
        text: Caption text
        wpm: Words per minute (default 160 for comfortable reading)

    Returns:
        Duration in seconds
    """
    word_count = len(text.split())
    calculated = (word_count / wpm) * 60

    # House-style floor (not a WCAG requirement): 1.5 seconds for any caption
    minimum = 1.5

    # Add 0.5s buffer for cognitive processing
    buffer = 0.5

    return max(minimum, calculated + buffer)

# Examples:
print(calculate_caption_duration("Hello"))           # 1.5s (minimum)
print(calculate_caption_duration("This is a test")) # 2.0s
print(calculate_caption_duration("Check out this incredible transformation")) # 2.375s
```

### Caption Style Rules and Their Sources

These limits come from broadcaster and platform style guides, not from WCAG:

| Rule | Typical value | Source |
|------|---------------|--------|
| Reading rate | 160-180 WPM | BBC Subtitle Guidelines |
| Reading rate (characters) | 20 characters/second adult, 17 children | Netflix Timed Text Style Guide |
| Characters per line | 42 (Netflix, most Latin-script languages); 32 (DCMP); ~37 (BBC) | Netflix, DCMP Captioning Key, BBC |
| Lines per caption | Maximum 2 | BBC, Netflix, DCMP |
| Minimum duration | 5/6 s (20 frames at 24 fps) | Netflix Timed Text Style Guide |
| Maximum duration | 7 s | Netflix Timed Text Style Guide |

### What WCAG 2.2 Actually Requires

- **SC 1.2.2 Captions (Prerecorded), Level A**: captions are provided for all prerecorded audio content in synchronized media.
- **SC 1.2.4 Captions (Live), Level AA**: captions are provided for all live audio content in synchronized media.

WCAG does not specify caption duration, reading speed, characters per line, or line count. Use the style guides above for those, and cite them (not WCAG) when explaining a timing choice.

## Platform Timing Profiles

The platforms publish no official animation or pacing timings. Every figure in these profiles is a rule of thumb from common editing practice. The **Text animation** rows are the per-platform durations used across this skill (`kinetic-captions.md` points here).

### TikTok (Fast, Energetic)

| Element | Timing | Notes |
|---------|--------|-------|
| Cut/transition | 0.5-1.5s between clips | Fast pacing |
| Text animation | 100-200ms | Snappy, punchy |
| Hook window | 1-1.5s | Immediate grab |
| Caption duration | 1-1.5s per 1-3 word phrase | Longer phrases: use the readability formula (1.5s floor) |
| Zoom effects | 200-400ms | Quick, impactful |
| Video length | 15-30s common | Rule of thumb |

### YouTube Shorts (Medium-Fast)

| Element | Timing | Notes |
|---------|--------|-------|
| Cut/transition | 1-2s between clips | Slightly slower than TikTok |
| Text animation | 150-300ms | Smooth but quick |
| Hook window | 2-3s | Slightly more time |
| Caption duration | 1.2-2s per phrase | More readable |
| Zoom effects | 300-600ms | Noticeable but smooth |
| Video length | Up to 3 min allowed (since Oct 2024) | No reliable "optimal" length |

### Instagram Reels (Aesthetic, Polished)

| Element | Timing | Notes |
|---------|--------|-------|
| Cut/transition | 1.5-2.5s between clips | More polished |
| Text animation | 150-250ms | Stylish timing |
| Hook window | 2-3s | Visual-first platform |
| Caption duration | 1-1.8s per phrase | Instagram style |
| Zoom effects | 400-800ms | Cinematic feel |
| Video length | 15-30s common | Rule of thumb |

### Professional/Broadcast

| Element | Timing | Notes |
|---------|--------|-------|
| Cut/transition | 2-4s between clips | Deliberate pacing |
| Text animation | 300-500ms | Smooth, professional |
| Lower third entrance | 400-600ms | Broadcast standard |
| Caption duration | 2-4s per phrase | Full readability |
| Zoom effects | 800-1500ms | Subtle, cinematic |
| Typical segment | 30-90s | Standard TV timing |

## Audio-Video Sync Tolerances

| Sync Type | Detectability threshold | Recommended | Notes |
|-----------|-------------------|-------------|-------|
| Lip sync | audio early ≤45ms, audio late ≤125ms | audio early ≤20ms, late ≤40ms | Asymmetric: audio leading video is noticed sooner (ITU-R BT.1359) |
| Music beat sync | ~+/-50ms (rule of thumb) | +/-20ms | Musical precision |
| Karaoke lyrics | ~100ms early or late (rule of thumb) | 0 to +50 ms after the word, never before | A highlight ahead of the voice reads as wrong sooner than a late one |
| Sound effects | ~+/-30ms (rule of thumb) | +/-10ms | Impact synchronization |
| Transition + audio | ~+/-100ms (rule of thumb) | +/-50ms | Cross-fade sync |

Only the lip-sync row is from a standard (ITU-R BT.1359 detectability). Its acceptability limits are wider:

```yaml
Source: ITU-R BT.1359 (sign convention: + = audio leads video)
Detectability threshold: +45ms (audio early) / -125ms (audio late)
Acceptability threshold: +90ms (audio early) / -185ms (audio late)
Recommendation: Keep within about +20ms / -40ms for professional quality

Audio Leading (sound before picture): MORE noticeable - real-world sound
  never arrives before light, so keep audio-early offsets small (< 45ms)
Audio Lagging (sound after picture): Less noticeable - viewers tolerate
  up to ~125ms before detecting it
```

### Music Sync

```text
Beat length = 60 / BPM seconds
120 BPM = 2 beats/second = 500ms per beat
140 BPM = 2.33 beats/second = 429ms per beat

At 120 BPM, beats fall at 0, 500, 1000, 1500, 2000 ms...; put cuts and
xfade offsets on those times.
```

### Karaoke Highlight Timing

```text
Word highlight should START when the word begins (not before)
Early highlight: confusing, breaks immersion
Late highlight: frustrating for singers

Rule of thumb: highlight 0-50ms AFTER the word starts (a slight lag reads better than an early one)
```

## Frame Rate Considerations

| Frame Rate | Frame Duration | 30 Frames | 60 Frames |
|------------|----------------|-----------|-----------|
| 24 fps | 41.67 ms | 1.25 s | 2.5 s |
| 25 fps | 40 ms | 1.2 s | 2.4 s |
| 30 fps | 33.33 ms | 1 s | 2 s |
| 50 fps | 20 ms | 0.6 s | 1.2 s |
| 60 fps | 16.67 ms | 0.5 s | 1 s |

The frame duration is the timing precision: an effect cannot start or end between frames.

### Animation Smoothness

FFmpeg expressions and ASS `\t` are evaluated at each frame's timestamp, so a duration that is not a whole number of frames does not stutter; it just ends between two frames, and the last step is shorter. Snapping to whole frames matters only when an effect must land on an exact frame (a cut, a flash, a beat):

```text
30fps: 100ms = 3 frames, 200ms = 6 frames, 333ms = 10 frames; 150ms ends mid-frame
60fps: 100ms = 6 frames, 167ms = 10 frames, 200ms = 12 frames
```

### Minimum Visible Duration

```text
Animation duration must be at least 2-3 frames to be perceived:
- 30fps minimum: ~67-100ms
- 60fps minimum: ~33-50ms

Very short effects (<50ms) may not render consistently
```

### Frame-Safe Duration Table

| Desired Duration | 30fps Safe | 60fps Safe |
|------------------|------------|------------|
| ~100ms | 100ms (3f) | 100ms (6f) |
| ~150ms | 167ms (5f) | 150ms (9f) |
| ~200ms | 200ms (6f) | 200ms (12f) |
| ~250ms | 233ms (7f) | 250ms (15f) |
| ~300ms | 300ms (9f) | 300ms (18f) |
| ~500ms | 500ms (15f) | 500ms (30f) |

## Copy-Paste Timing Patterns

### FFmpeg

```bash
# 2-second fade in:
-vf "fade=t=in:d=2"

# Text visible from 1s to 5s:
-vf "drawtext=text='Hello':enable='between(t,1,5)':..."

# 1.5s xfade starting at 4s:
-filter_complex "[0:v][1:v]xfade=duration=1.5:offset=4"

# Fade text in over 0.5s, hold, fade out over 0.3s (5s total):
-vf "drawtext=text='Hello':alpha='if(lt(t,0.5),t/0.5,if(lt(t,4.7),1,(5-t)/0.3))':enable='lt(t,5)':..."

# 2-second zoom on VIDEO (d=1: one output frame per input frame, zoom driven by `it` seconds):
-vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,zoompan=z='1+0.5*min(it/2,1)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1080x1920:fps=30"
```

Still-image zooms and hook zooms: [`stabilization-360.md`](stabilization-360.md#zoompan---pan-and-zoom-animation).

### ASS

```ass
; Word karaoke (centiseconds): 0.5s + 0.4s + 0.6s + 0.5s
{\k50}This {\k40}is {\k60}the {\k50}test

; 200ms pop animation (milliseconds): 50% -> 115% -> 100%
{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}Pop

; 500ms slide + 300ms fade:
{\move(0,1920,540,960,0,500)\fad(300,0)}Slide in

; Bounce: 100ms up to 120%, 100ms back to 95%, 100ms settle (total 300ms)
{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx95\fscy95)\t(200,300,\fscx100\fscy100)}Bounce
```

## Workflow

1. **Identify the context** (FFmpeg filter, ASS karaoke, ASS animation, dialogue timestamp) and confirm the unit in the Quick Reference Card.
2. **Pick a target duration** from [Recommended Durations](#recommended-durations) and the [Platform Timing Profiles](#platform-timing-profiles).
3. **Snap to frames** only when the effect must land on an exact frame ([Frame-Safe Duration Table](#frame-safe-duration-table)).
4. **Choose an easing curve** when the motion needs polish (`easing-and-springs.md`).
5. **Check perception thresholds and sync tolerances**, so animations are not too short to see and captions stay in sync.
6. **Copy the matching pattern** from [Copy-Paste Timing Patterns](#copy-paste-timing-patterns) and adapt it.

## Related References

- `easing-and-springs.md`: easing curves, spring physics, oscillation formulas
- `karaoke-text.md`: ASS karaoke and the tempo table
- `kinetic-captions.md`: word-pop and word-grow captions
- `drawtext-animation.md`: animated drawtext recipes
- `transitions.md`: xfade transitions
- `captions.md`: subtitle fundamentals
