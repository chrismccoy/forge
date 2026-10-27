# Kinetic Captions Master Guide

> **Crash warning: animated `fontsize`.** On FFmpeg 8.0.1 (verified with the Ubuntu 8.0.1-3ubuntu2 build), any `drawtext` whose `fontsize` is a time-varying expression (even `fontsize='72+t'`) segfaults. The recipes below marked with an animated `fontsize` will crash on that build. Test first on your version. Crash-free alternatives: animate size with ASS `\t(\fscx…\fscy…)` tags (see the ASS sections of this file, `kinetic-captions-complete-generator.md`, `karaoke-text-karaoke-ass-patterns.md`, and `scripts/generate-karaoke.sh kinetic`), or render text at a fixed size and animate `scale`/`zoompan` on that layer. Animated `x`, `y`, and `alpha` work (tested).

## Quick Reference - Kinetic Effects

| Effect | ASS Code | Duration | Use Case |
|--------|----------|----------|----------|
| Word Grow | `{\fscx80\fscy80\t(0,200,\fscx120\fscy120)\t(200,400,\fscx100\fscy100)}` | 400ms | Karaoke highlight |
| Pop Bounce | `{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}` | 200ms | Word appear |
| Elastic | `{\fscx40\fscy40\t(0,100,\fscx130\fscy130)\t(100,200,\fscx90\fscy90)\t(200,350,\fscx100\fscy100)}` | 350ms | High energy |
| Spring Bounce | `{\move(540,1100,540,960,0,300)\t(0,150,\fscx110\fscy110)\t(150,300,\fscx100\fscy100)}` | 300ms | Entry from below |
| Shake | One short Dialogue line per jitter step, each with `{\move(x1,y1,x2,y2)}` (e.g. 540→545, 545→535, 535→540); `\pos` cannot be animated with `\t` | 150ms | Impact emphasis |
| Karaoke Fill | `{\kf100}Word` | 1000ms | Progressive highlight |
| Karaoke + Grow | `{\k80\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}` | 800ms | Highlight + scale |

---

## Why Kinetic Captions Matter

- **Much social video is watched without sound**, so captions carry the message
- **Word-level animation** is widely used to hold attention (no reliable figures on the retention gain)
- **Scale/bounce effects** signal "this word matters NOW"
- **Karaoke highlighting** guides viewer timing with audio
- **Kinetic typography** is expected on TikTok/Shorts/Reels

---

# Section 1: Karaoke with Word-Grow Effect

The **word-grow highlight** is the most requested kinetic effect - words scale up when highlighted, then return to normal size.

## Basic Word-Grow Karaoke

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
Dialogue: 0,0:00:01.00,0:00:05.00,KaraokeGrow,,0,0,0,,{\r\k80\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}This {\r\k60\t(800,950,\fscx115\fscy115)\t(950,1100,\fscx100\fscy100)}is {\r\k100\t(1400,1650,\fscx120\fscy120)\t(1650,1900,\fscx100\fscy100)}AMAZING
```

### Understanding the Animation Tags

```ass
{\k80\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}Word

Breaking it down:
- \k80 = Karaoke duration (80 centiseconds = 0.8 seconds)
- \t(0,200,...) = Animation from 0-200ms
- \fscx115\fscy115 = Scale to 115% (grow)
- \t(200,400,...) = Animation from 200-400ms
- \fscx100\fscy100 = Scale back to 100% (shrink)
```

### Critical: Time Units Differ!

| Tag | Unit | 0.5 seconds = |
|-----|------|---------------|
| `\k` | Centiseconds | `\k50` |
| `\t()` | Milliseconds | `\t(0,500,...)` |

---

## Advanced Word-Grow Patterns

### Pattern 1: Grow + Color Change

Words grow AND change color when highlighted:

```ass
[V4+ Styles]
Style: GrowColor,Arial Black,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
;                                 Primary = yellow (sung)  Secondary = white (not yet sung)

[Events]
; Karaoke fill (kf) + grow; the fill colour comes from PrimaryColour.
; Each word's \t is offset by the cumulative \kf time (0, 600, 1400 ms)
; and \r resets the previous word's scale.
Dialogue: 0,0:00:00.00,0:00:03.00,GrowColor,,0,0,0,,{\r\kf60\t(0,200,\fscx115\fscy115)\t(200,400,\fscx100\fscy100)}Check {\r\kf80\t(600,800,\fscx115\fscy115)\t(800,1000,\fscx100\fscy100)}this {\r\kf100\t(1400,1650,\fscx120\fscy120)\t(1650,1900,\fscx100\fscy100)}out
```

### Pattern 2: Grow + Bounce (Overshoot)

Spring physics overshoot for more dynamic feel:

```ass
; Grows to 120%, bounces back to 95%, settles at 100%
Dialogue: 0,0:00:00.00,0:00:03.00,Style,,0,0,0,,{\k80\t(0,120,\fscx120\fscy120)\t(120,220,\fscx95\fscy95)\t(220,350,\fscx100\fscy100)}Bouncy
```

### Pattern 3: Grow + Outline Pulse

Outline expands during highlight:

```ass
; Border/outline grows with text
Dialogue: 0,0:00:00.00,0:00:02.00,Style,,0,0,0,,{\k100\t(0,200,\fscx115\fscy115\bord8)\t(200,400,\fscx100\fscy100\bord5)}IMPACT
```

---

## Word-Grow Timing by Platform

| Platform | Grow Duration | Shrink Duration | Max Scale | Animation Style |
|----------|---------------|-----------------|-----------|-----------------|
| **TikTok** | 100-150ms | 100-150ms | 115-120% | Fast, punchy |
| **YouTube Shorts** | 150-200ms | 150-200ms | 110-115% | Smooth, readable |
| **Instagram Reels** | 120-180ms | 120-180ms | 115-120% | Stylish, trendy |

### TikTok Optimized (Fast)

```ass
; Quick 200ms total animation
{\k60\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}Fast
```

### YouTube Shorts Optimized (Smooth)

```ass
; Smooth 350ms total animation
{\k80\t(0,175,\fscx112\fscy112)\t(175,350,\fscx100\fscy100)}Smooth
```

---

# Section 2: CapCut-Style Word Pop Effects

The **word pop** effect makes each word appear with a bounce, popularized by CapCut.

## Basic Word Pop

```ass
[V4+ Styles]
Style: WordPop,Arial Black,84,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,280,1

[Events]
; Each word starts at 50% scale, pops to 115%, settles at 100%
Dialogue: 0,0:00:00.00,0:00:00.50,WordPop,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}This
Dialogue: 0,0:00:00.30,0:00:00.80,WordPop,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}is
Dialogue: 0,0:00:00.50,0:00:01.20,WordPop,,0,0,0,,{\c&H0000FFFF&\fscx50\fscy50\t(0,100,\fscx120\fscy120)\t(100,250,\fscx100\fscy100)}VIRAL
```

### Word Pop with Stagger Delay

Words appear sequentially with overlapping timing:

| Word | Start | End | Delay from Previous |
|------|-------|-----|---------------------|
| Word 1 | 0.00s | 0.50s | - |
| Word 2 | 0.25s | 0.75s | 250ms |
| Word 3 | 0.50s | 1.00s | 250ms |
| Word 4 | 0.75s | 1.25s | 250ms |

### Elastic Word Pop (Multiple Bounces)

```ass
; More dramatic with multiple oscillations
; 40% → 130% → 90% → 105% → 100%
Dialogue: 0,0:00:00.00,0:00:01.00,Style,,0,0,0,,{\fscx40\fscy40\t(0,100,\fscx130\fscy130)\t(100,200,\fscx90\fscy90)\t(200,350,\fscx105\fscy105)\t(350,500,\fscx100\fscy100)}ELASTIC
```

---

## Word Pop with Movement

### Pop In from Below

```ass
; Word moves up while popping
Dialogue: 0,0:00:00.00,0:00:01.00,Style,,0,0,0,,{\move(540,1100,540,960,0,200)\fscx50\fscy50\t(0,100,\fscx115\fscy115)\t(100,200,\fscx100\fscy100)}BounceUp
```

### Pop In from Side

```ass
; Word slides in from right while popping
Dialogue: 0,0:00:00.00,0:00:01.00,Style,,0,0,0,,{\move(1200,960,540,960,0,250)\fscx50\fscy50\t(0,120,\fscx110\fscy110)\t(120,250,\fscx100\fscy100)}SlideIn
```

### Pop with Rotation

```ass
; Word rotates while appearing
Dialogue: 0,0:00:00.00,0:00:01.00,Style,,0,0,0,,{\frz-15\fscx50\fscy50\t(0,150,\frz0\fscx115\fscy115)\t(150,300,\fscx100\fscy100)}Twist
```

---

# Section 3: Spring Physics Animation

Natural-feeling bounce using spring physics formulas.

## Spring Parameter Guide

| Parameter | Low Value | High Value | Effect |
|-----------|-----------|------------|--------|
| **Damping** | 2-3 | 5-8 | More bouncy → Less bouncy (faster settle) |
| **Frequency** | 8-10 rad/s | 15-20 rad/s | Slow oscillation → Fast oscillation |
| **Amplitude** | 5-10% | 15-25% | Subtle → Dramatic |

### Damping Ratio Interpretation

- **ζ < 0.5**: Very bouncy, multiple oscillations
- **ζ = 0.5-0.8**: Balanced bounce, 1-2 oscillations
- **ζ = 1.0**: Critical damping (no overshoot)
- **ζ > 1.0**: Over-damped (sluggish)

## Spring Bounce in ASS

### Low Damping (Bouncy)

```ass
; Multiple oscillations: 120% → 90% → 105% → 98% → 100%
{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx90\fscy90)\t(200,300,\fscx105\fscy105)\t(300,400,\fscx98\fscy98)\t(400,500,\fscx100\fscy100)}Bouncy
```

### Medium Damping (Balanced)

```ass
; Single overshoot: 115% → 95% → 100%
{\fscx80\fscy80\t(0,120,\fscx115\fscy115)\t(120,250,\fscx95\fscy95)\t(250,400,\fscx100\fscy100)}Balanced
```

### High Damping (Quick Settle)

```ass
; Minimal overshoot: 110% → 100%
{\fscx80\fscy80\t(0,150,\fscx110\fscy110)\t(150,300,\fscx100\fscy100)}Quick
```

## Position Spring (Vertical Bounce)

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

# Section 4: Shake and Tremor Effects

Impact emphasis with controlled shake animation.

## Horizontal Shake

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

## Decaying Impact Shake

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

## Shake + Scale Combo

```ass
; Word shakes AND scales for maximum impact
; (\t without times spans the whole line, so scale and move stay in step)
Dialogue: 0,0:00:00.00,0:00:00.05,Style,,0,0,0,,{\move(540,960,545,960)\fscx100\fscy100\t(\fscx120\fscy120)}BOOM
Dialogue: 0,0:00:00.05,0:00:00.10,Style,,0,0,0,,{\move(545,960,535,960)\fscx120\fscy120\t(\fscx115\fscy115)}BOOM
Dialogue: 0,0:00:00.10,0:00:00.20,Style,,0,0,0,,{\move(535,960,540,960)\fscx115\fscy115\t(\fscx100\fscy100)}BOOM
Dialogue: 0,0:00:00.20,0:00:02.00,Style,,0,0,0,,{\pos(540,960)}BOOM
```

## Shake Amplitude Guidelines

| Font Size | Max Horizontal | Max Vertical | Notes |
|-----------|----------------|--------------|-------|
| 64-72px | 8px | 6px | Readable |
| 76-84px | 12px | 10px | Noticeable |
| 88-96px | 16px | 14px | Dramatic |
| 100+px | 20px | 18px | Impact only |

**Rule**: Shake amplitude < 15% of font size for readability.

---

# Section 5: Typewriter and Reveal Effects

Character-by-character text reveal.

## Character Reveal (Typewriter)

Each character appears sequentially:

```ass
; Manual character timing (50ms per character)
Dialogue: 0,0:00:00.00,0:00:00.05,Style,,0,0,0,,H
Dialogue: 0,0:00:00.05,0:00:00.10,Style,,0,0,0,,He
Dialogue: 0,0:00:00.10,0:00:00.15,Style,,0,0,0,,Hel
Dialogue: 0,0:00:00.15,0:00:00.20,Style,,0,0,0,,Hell
Dialogue: 0,0:00:00.20,0:00:01.00,Style,,0,0,0,,Hello
```

### Typewriter Speed Reference

| Speed | ms/character | Characters/second | Feel |
|-------|--------------|-------------------|------|
| Fast | 30-40ms | 25-33 | Energetic |
| Normal | 50-70ms | 14-20 | Comfortable |
| Slow | 80-120ms | 8-12 | Dramatic |

## Word-by-Word Reveal

Less tedious than character reveal:

```ass
Dialogue: 0,0:00:00.00,0:00:00.30,Style,,0,0,0,,{\fad(100,0)}This
Dialogue: 0,0:00:00.30,0:00:00.60,Style,,0,0,0,,{\fad(100,0)}is
Dialogue: 0,0:00:00.60,0:00:00.90,Style,,0,0,0,,{\fad(100,0)}word
Dialogue: 0,0:00:00.90,0:00:01.20,Style,,0,0,0,,{\fad(100,0)}by
Dialogue: 0,0:00:01.20,0:00:02.00,Style,,0,0,0,,{\fad(100,0)}word
```

## Reveal with Pop

Combine typewriter timing with pop animation:

```ass
; Word appears AND pops
Dialogue: 0,0:00:00.00,0:00:00.50,Style,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx110\fscy110)\t(100,200,\fscx100\fscy100)}This
Dialogue: 0,0:00:00.25,0:00:00.75,Style,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx110\fscy110)\t(100,200,\fscx100\fscy100)}is
Dialogue: 0,0:00:00.50,0:00:01.00,Style,,0,0,0,,{\fscx50\fscy50\t(0,100,\fscx110\fscy110)\t(100,200,\fscx100\fscy100)}great
```

---

# Section 6: Color Transitions and Multi-Color Karaoke

## Progressive Color Fill (Karaoke)

```ass
[V4+ Styles]
; Secondary = not-yet-sung colour, Primary = sung (filled) colour
Style: ColorKaraoke,Arial Black,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
;                                   Yellow     White

[Events]
; \kf creates smooth left-to-right color fill
Dialogue: 0,0:00:00.00,0:00:03.00,ColorKaraoke,,0,0,0,,{\kf80}This {\kf60}fills {\kf100}smoothly
```

## Multi-Color Gradient Karaoke

Words transition through multiple colors:

```ass
; Sung colour: Yellow → Orange → Red progression; unsung stays white
[V4+ Styles]
Style: GradientK,Impact,80,&H0000FFFF,&H00FFFFFF,&H00000000,&H00000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1

[Events]
; Animate the sung colour (\1c); each \t starts where its word's \kf starts
Dialogue: 0,0:00:00.00,0:00:02.00,GradientK,,0,0,0,,{\kf80\t(0,800,\1c&H0000A5FF&)}Word1 {\kf100\t(800,1800,\1c&H000000FF&)}Word2
;                                                  yellow→orange          orange→red
```

## Color Flash on Highlight

```ass
; Word flashes bright color then returns (\c = sung colour; \k shows it
; from the syllable's start, which is 0 ms here)
Dialogue: 0,0:00:00.00,0:00:02.00,Style,,0,0,0,,{\k80\c&HFFFFFF&\t(0,100,\c&H00FFFF&)\t(100,400,\c&HFFFFFF&)}Flash
```

---

# Section 7: Platform-Specific Caption Styles

## TikTok Viral Style

```ass
[V4+ Styles]
Style: TikTokViral,Arial Black,88,&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,320,1

[Events]
; Fast pop, high energy
Dialogue: 0,0:00:00.00,0:00:00.40,TikTokViral,,0,0,0,,{\fscx50\fscy50\t(0,80,\fscx118\fscy118)\t(80,160,\fscx100\fscy100)}THIS
Dialogue: 0,0:00:00.20,0:00:00.60,TikTokViral,,0,0,0,,{\fscx50\fscy50\t(0,80,\fscx118\fscy118)\t(80,160,\fscx100\fscy100)}IS
Dialogue: 0,0:00:00.40,0:00:01.00,TikTokViral,,0,0,0,,{\c&H00FFFF&\fscx50\fscy50\t(0,100,\fscx125\fscy125)\t(100,200,\fscx100\fscy100)}VIRAL
```

**TikTok Parameters:**
- Font size: 84-96px
- Animation: 160-200ms total
- Pop scale: 115-125%
- Word delay: 150-250ms
- Max 3-5 words on screen

## YouTube Shorts Professional

```ass
[V4+ Styles]
Style: ShortsPro,Montserrat,76,&H00FFFFFF,&H00FFFFFF,&H00333333,&H80000000,1,0,0,0,100,100,0,0,1,4,2,2,10,10,300,1

[Events]
; Smoother, more professional
Dialogue: 0,0:00:00.00,0:00:00.60,ShortsPro,,0,0,0,,{\fscx80\fscy80\t(0,150,\fscx108\fscy108)\t(150,300,\fscx100\fscy100)}This
Dialogue: 0,0:00:00.30,0:00:00.90,ShortsPro,,0,0,0,,{\fscx80\fscy80\t(0,150,\fscx108\fscy108)\t(150,300,\fscx100\fscy100)}is
Dialogue: 0,0:00:00.60,0:00:01.40,ShortsPro,,0,0,0,,{\fscx80\fscy80\t(0,180,\fscx112\fscy112)\t(180,350,\fscx100\fscy100)}professional
```

**YouTube Shorts Parameters:**
- Font size: 72-84px
- Animation: 250-400ms total
- Pop scale: 108-115%
- Word delay: 250-350ms
- Max 4-6 words on screen

## Instagram Reels Trendy

```ass
[V4+ Styles]
Style: ReelsTrend,Impact,82,&H00FFFFFF,&H00FF00FF,&H00000000,&H00000000,1,0,0,0,100,100,2,0,1,5,0,2,10,10,280,1

[Events]
; Stylish with slight rotation
Dialogue: 0,0:00:00.00,0:00:00.50,ReelsTrend,,0,0,0,,{\frz-5\fscx50\fscy50\t(0,120,\frz0\fscx115\fscy115)\t(120,250,\fscx100\fscy100)}Trendy
Dialogue: 0,0:00:00.25,0:00:00.75,ReelsTrend,,0,0,0,,{\frz5\fscx50\fscy50\t(0,120,\frz0\fscx115\fscy115)\t(120,250,\fscx100\fscy100)}Caption
Dialogue: 0,0:00:00.50,0:00:01.20,ReelsTrend,,0,0,0,,{\c&H00FF00FF&\fscx50\fscy50\t(0,150,\fscx120\fscy120)\t(150,300,\fscx100\fscy100)}Style
```

---

# Section 8: Python Script for Kinetic Caption Generation

A full Python kinetic-caption generator that turns word-level transcripts into animated ASS subtitle files (combining all the word-grow, word-pop, spring-bounce, shake, reveal, and karaoke patterns above) lives in `kinetic-captions-complete-generator.md`. Load that reference when you need a ready-to-run script rather than building per-effect filter graphs by hand.

## Pulse/Breathing Effect

```bash
# Text pulses 72 ± 8 pixels at ~1.5 Hz
# ⚠ crashes FFmpeg 8.0.1 (animated fontsize) — see warning above
ffmpeg -i input.mp4 \
  -vf "drawtext=text='SUBSCRIBE':fontsize='72+8*sin(t*9.42)':fontcolor=yellow:x=(w-tw)/2:y=h-150:borderw=3:bordercolor=black" \
  output.mp4
# 9.42 rad/s = 1.5 Hz (1.5 * 2π = 9.42)
```

## Bounce Text Entry

```bash
# Text bounces from below (spring physics), starting at t=1
# Use (t-1), not t: with absolute t the bounce would have decayed by the time
# the text appears
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BOUNCE':fontsize=80:fontcolor=white:x=(w-tw)/2:y='(h-th)/2-30*exp(-(t-1)*3)*sin((t-1)*15)':borderw=3:bordercolor=black:enable='gte(t,1)'" \
  output.mp4
```

## Scale Pop (Font Size Animation)

```bash
# Text pops from small to normal over 0.3 s, starting at t=0.5
# ⚠ crashes FFmpeg 8.0.1 (animated fontsize) — see warning above
ffmpeg -i input.mp4 \
  -vf "drawtext=text='POP':fontsize='if(lt(t-0.5,0.3),40+40*(t-0.5)/0.3,80)':fontcolor=white:x=(w-tw)/2:y=(h-th)/2:enable='gte(t,0.5)'" \
  output.mp4
```

## Shake on Impact

```bash
# Text shakes with decaying amplitude, starting at t=2 (decay uses t-2)
ffmpeg -i input.mp4 \
  -vf "drawtext=text='IMPACT':fontsize=100:fontcolor=white:x='(w-tw)/2+15*exp(-(t-2)*4)*sin((t-2)*50)':y='(h-th)/2+10*exp(-(t-2)*4)*cos((t-2)*47)':enable='gte(t,2)'" \
  output.mp4
```

## Sequential Word Appear

```bash
# Multiple drawtext filters for word-by-word reveal
ffmpeg -f lavfi -i "color=c=black:s=1080x1920:d=5" \
  -vf "\
    drawtext=text='THIS':fontsize=80:fontcolor=white:x=(w-tw)/2:y=h/2-80:alpha='if(lt(t-0.5,0.5),(t-0.5)*2,1)':enable='gte(t,0.5)',\
    drawtext=text='IS':fontsize=80:fontcolor=white:x=(w-tw)/2:y=h/2:alpha='if(lt(t-1,0.5),(t-1)*2,1)':enable='gte(t,1)',\
    drawtext=text='KINETIC':fontsize=80:fontcolor=yellow:x=(w-tw)/2:y=h/2+80:alpha='if(lt(t-1.5,0.5),(t-1.5)*2,1)':enable='gte(t,1.5)'" \
  kinetic_reveal.mp4
```

---

# Section 9: Best Practices and Troubleshooting

## Kinetic Caption Best Practices

1. **Don't over-animate**: Not every word needs maximum effect
2. **Emphasize key words**: Use larger scale/longer duration for important words
3. **Match tempo**: Fast speech = fast animation, slow = smooth
4. **Platform consistency**: Use platform-appropriate styles
5. **Test readability**: Animation shouldn't hurt comprehension

## Emphasis Hierarchy

| Word Type | Animation | Scale | Duration |
|-----------|-----------|-------|----------|
| Filler words (a, the, is) | Minimal pop | 105-110% | 150-200ms |
| Normal words | Standard pop | 110-115% | 200-250ms |
| Key words | Enhanced pop | 115-120% | 250-350ms |
| EMPHASIS words | Elastic/shake | 120-130% | 300-400ms |

## Common Issues and Solutions

### Timing Mismatch

**Problem**: Animation doesn't match audio timing
**Solution**: Use word-level timestamps from Whisper, not sentence-level

### Jittery Animation

**Problem**: Text appears to stutter
**Solution**: Ensure animation durations are multiples of frame duration
- 30fps: Use 33ms, 67ms, 100ms, 133ms, etc.
- 60fps: Use 17ms, 33ms, 50ms, 67ms, etc.

### Text Too Busy

**Problem**: Animations distract from content
**Solution**: Reduce scale amplitude (115% → 108%), simplify effects

### Poor Mobile Readability

**Problem**: Text hard to read on phones
**Solution**:
- Increase font size (80px minimum for 1080x1920)
- Increase outline/border (4-6px)
- Use safe margins (50px from edges)

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

- `karaoke-text.md` - Karaoke fundamentals
- `animation-timing.md` - Timing formulas
- `captions.md` - Subtitle basics
