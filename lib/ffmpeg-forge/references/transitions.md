# FFmpeg Transitions and Effects

Complete guide to video transitions, crossfades, and creative effects using FFmpeg.

## Contents

- [Quick Reference](#quick-reference)
- [Transition Overview](#transition-overview)
- [Basic Fade Effects](#basic-fade-effects)
- [xfade Transitions (Between Clips)](#xfade-transitions-between-clips)
- [Multiple Clip Transitions](#multiple-clip-transitions)
- [Custom Transitions with Expressions](#custom-transitions-with-expressions)
- [Advanced Transition Techniques](#advanced-transition-techniques)
- [Transition with Text/Graphics](#transition-with-textgraphics)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Quick Reference

| Transition | Command |
|------------|---------|
| Crossfade | `[0:v][1:v]xfade=transition=fade:duration=1:offset=4[v]` |
| Dissolve | `xfade=transition=dissolve:duration=1:offset=4` |
| Wipe left | `xfade=transition=wipeleft:duration=1:offset=4` |
| Circle open | `xfade=transition=circleopen:duration=1.5:offset=4` |
| Slide left | `xfade=transition=slideleft:duration=1:offset=4` |
| Fade in/out | `-vf "fade=t=in:d=1,fade=t=out:st=9:d=1"` |
| Audio crossfade | `[0:a][1:a]acrossfade=d=1[a]` |

| Offset of cut k | Formula |
|-----------------|---------|
| General | `offset_k = (D1 + ... + Dk) - (T1 + ... + Tk)`: length of the stream built so far minus this cut's own transition, i.e. `offset_k = offset_(k-1) + Dk - Tk` |
| Equal clips D, equal transitions T | `offset_k = k*D - k*T` |
| Output length | `(D1 + ... + Dn) - (T1 + ... + T(n-1))` |

---

> **Pixel format:** `xfade` (every transition type) and `fade` with a non-black `color=` output yuv444p even from yuv420p clips, so libx264/libx265 would write a High 4:4:4 stream that browsers and phones will not play. The MP4 recipes below add `-pix_fmt yuv420p`; keep it (or end the graph with `format=yuv420p`) when adapting them.

## Transition Overview

### Available Methods

| Method | Use Case | Complexity |
|--------|----------|------------|
| xfade filter | Between two clips | Medium |
| fade filter | Single clip in/out | Simple |
| blend filter | Frame blending | Simple |
| overlay + alpha | Custom transitions | Advanced |

### xfade Transition Types

FFmpeg's xfade filter has 58 built-in transitions plus `custom` (FFmpeg 8.0; `ffmpeg -h filter=xfade` lists them):

| Category | Transitions |
|----------|-------------|
| Fades | fade, fadeblack, fadewhite, fadegrays, fadefast, fadeslow, distance |
| Wipes | wipeleft, wiperight, wipeup, wipedown, wipetl, wipetr, wipebl, wipebr |
| Soft wipes | smoothleft, smoothright, smoothup, smoothdown |
| Slides | slideleft, slideright, slideup, slidedown |
| Covers / reveals | coverleft, coverright, coverup, coverdown, revealleft, revealright, revealup, revealdown |
| Open / close (curtain) | horzopen, horzclose, vertopen, vertclose |
| Shapes | circleopen, circleclose, circlecrop, rectcrop, radial |
| Diagonals | diagtl, diagtr, diagbl, diagbr |
| Pixel / slice | dissolve, pixelize, hlslice, hrslice, vuslice, vdslice |
| Blur / wind / zoom | hblur, hlwind, hrwind, vuwind, vdwind, zoomin, squeezeh, squeezev |
| Custom | custom (with `expr=`) |

## Basic Fade Effects

### Fade In/Out (Single Clip)

```bash
# Fade in from black (first 2 seconds)
ffmpeg -i video.mp4 \
  -vf "fade=t=in:st=0:d=2" \
  -c:a copy \
  fade_in.mp4

# Fade out to black (last 2 seconds)
ffmpeg -i video.mp4 \
  -vf "fade=t=out:st=8:d=2" \
  -c:a copy \
  fade_out.mp4

# Both fade in and fade out
ffmpeg -i video.mp4 \
  -vf "fade=t=in:st=0:d=1,fade=t=out:st=9:d=1" \
  -c:a copy \
  fade_both.mp4

# Fade to white instead of black
ffmpeg -i video.mp4 \
  -vf "fade=t=out:st=8:d=2:color=white" \
  -pix_fmt yuv420p -c:a copy \
  fade_white.mp4
```

### Fade with Audio

```bash
# Video and audio fade in/out together
ffmpeg -i video.mp4 \
  -vf "fade=t=in:st=0:d=2,fade=t=out:st=8:d=2" \
  -af "afade=t=in:st=0:d=2,afade=t=out:st=8:d=2" \
  fade_complete.mp4

# Audio crossfade between two files
ffmpeg -i audio1.mp3 -i audio2.mp3 \
  -filter_complex "[0][1]acrossfade=d=3:c1=tri:c2=tri" \
  crossfade.mp3
```

## xfade Transitions (Between Clips)

### Basic xfade Usage

```bash
# Simple crossfade between two clips
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=fade:duration=1:offset=4[v];\
                   [0:a][1:a]acrossfade=d=1[a]" \
  -map "[v]" -map "[a]" -pix_fmt yuv420p \
  output.mp4
```

**Parameters:**
- `transition`: Type of transition effect
- `duration`: Transition duration in seconds
- `offset`: When to start transition (from first clip)

### Common Transition Effects

```bash
# Dissolve (pixel-based crossfade)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=dissolve:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p dissolve.mp4

# Wipe right to left (edge moves left; new clip enters from the right)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=wipeleft:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p wipe_left.mp4

# Wipe left to right (edge moves right; new clip enters from the left)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=wiperight:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p wipe_right.mp4

# Slide left
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=slideleft:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p slide_left.mp4

# Circle open (iris)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=circleopen:duration=1.5:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p circle_open.mp4

# Circle close
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=circleclose:duration=1.5:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p circle_close.mp4

# Radial wipe
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=radial:duration=1.5:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p radial.mp4

# Zoom in
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=zoomin:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p zoom_in.mp4

# Pixelize transition
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=pixelize:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p pixelize.mp4

# Diagonal wipe (new clip appears in the bottom-right corner and spreads toward the top-left)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=diagtl:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p diag_tl.mp4

# Horizontal blur
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=hblur:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p hblur.mp4
```

### All xfade Transition Types

```bash
# Fades
fade        # Standard crossfade
fadeblack   # Fade through black
fadewhite   # Fade through white
fadegrays   # Fade through gray
fadefast    # Crossfade weighted toward the new clip
fadeslow    # Crossfade weighted toward the old clip
distance    # Fade by color distance between frames

# Smooth wipes (soft edge)
smoothleft  # Soft-edged wipe to the left
smoothright # Soft-edged wipe to the right
smoothup    # Soft-edged wipe upward
smoothdown  # Soft-edged wipe downward

# Wipes
# (names give the direction the edge MOVES; verified on FFmpeg 8.0.1)
wipeleft    # Right to left wipe (new clip enters from the right)
wiperight   # Left to right wipe (new clip enters from the left)
wipeup      # Bottom to top wipe
wipedown    # Top to bottom wipe
wipetl      # Wipe toward the top-left corner (starts bottom-right)
wipetr      # Wipe toward the top-right corner (starts bottom-left)
wipebl      # Wipe toward the bottom-left corner (starts top-right)
wipebr      # Wipe toward the bottom-right corner (starts top-left)

# Slides
slideleft   # Slide new clip from right
slideright  # Slide new clip from left
slideup     # Slide new clip from bottom
slidedown   # Slide new clip from top

# Reveals
revealleft  # Reveal from right edge
revealright # Reveal from left edge
revealup    # Reveal from bottom edge
revealdown  # Reveal from top edge

# Open/Close
horzopen    # Horizontal opening (curtain)
horzclose   # Horizontal closing
vertopen    # Vertical opening
vertclose   # Vertical closing
circleopen  # Circle iris open
circleclose # Circle iris close

# Shapes
circlecrop  # Circle crop transition
rectcrop    # Rectangle crop transition
radial      # Radial/clock wipe

# Diagonals
diagtl      # Soft diagonal toward top-left (starts bottom-right)
diagtr      # Soft diagonal toward top-right (starts bottom-left)
diagbl      # Soft diagonal toward bottom-left (starts top-right)
diagbr      # Soft diagonal toward bottom-right (starts top-left)

# Pixel Effects
dissolve    # Random pixel dissolve
pixelize    # Pixelization effect
hlslice     # Horizontal left slice
hrslice     # Horizontal right slice
vuslice     # Vertical up slice
vdslice     # Vertical down slice

# Other
zoomin      # Zoom into new clip
squeezeh    # Horizontal squeeze
squeezev    # Vertical squeeze
hlwind      # Horizontal left wind
hrwind      # Horizontal right wind
vuwind      # Vertical up wind
vdwind      # Vertical down wind
hblur       # Horizontal blur
coverleft   # Cover from right
coverright  # Cover from left
coverup     # Cover from bottom
coverdown   # Cover from top
```

## Multiple Clip Transitions

### Three Clips with Transitions

```bash
# Calculate offsets: clip1=5s, clip2=5s, clip3=5s, transition=1s
# offset1 = clip1_duration - transition = 5-1 = 4
# offset2 = clip1_duration + clip2_duration - 2*transition = 5+5-2 = 8

ffmpeg -i clip1.mp4 -i clip2.mp4 -i clip3.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=fade:duration=1:offset=4[v1];\
    [v1][2:v]xfade=transition=fade:duration=1:offset=8[v];\
    [0:a][1:a]acrossfade=d=1[a1];\
    [a1][2:a]acrossfade=d=1[a]" \
  -map "[v]" -map "[a]" -pix_fmt yuv420p \
  three_clips.mp4
```

### Slideshow with Transitions

`scripts/slideshow.sh` builds a slideshow from any number of images (2 or more), fitting and padding each one to the output size:

```bash
# Usage: slideshow.sh [--dur S] [--trans S] [--fps N] [--size WxH] <out.mp4> <transition|cycle> <img>...
scripts/slideshow.sh slides.mp4 fade a.jpg b.jpg c.jpg            # 3 x 3 s, 1 s fades: 7 s
scripts/slideshow.sh --dur 4 --trans 1.5 --size 1080x1920 story.mp4 cycle *.jpg
```

- `transition` is any xfade name except `custom`; `cycle` rotates through fade, wipeleft, circleopen, slideleft, dissolve.
- Defaults: `--dur 3` (seconds per image, including its transitions), `--trans 1`, `--fps 30`, `--size 1920x1080`.
- Output: H.264 High yuv420p, limited range (JPEG full range converted), faststart, no audio. The script refuses to overwrite an existing file.

The offset rule it applies, for N images of equal length `D` with transition `T`:

```text
offset_k = k*D - k*T        (start of cut k, k = 1..N-1)
length   = N*D - (N-1)*T
```

Each image is an input of its own (`-loop 1 -t D -i img`), scaled and padded, then chained: `[v0][v1]xfade=...:offset=D-T[x1]; [x1][v2]xfade=...:offset=2(D-T)[x2]; ...`, ending with `scale=out_range=tv,format=yuv420p`.

### Different Transitions per Cut

```bash
# Use different transitions between each clip (four 5 s clips).
# Each offset = length of the stream so far minus THIS cut's duration:
# x1 = 5+5-1 = 9 s, x2 = 9+5-1 = 13 s, so the 1.5 s cut starts at 13-1.5 = 11.5
# (offset 12 would run past the end of x2 and cut the transition short).
# Output length: 11.5 + 5 = 16.5 s
ffmpeg -i clip1.mp4 -i clip2.mp4 -i clip3.mp4 -i clip4.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=fade:duration=1:offset=4[x1];\
    [x1][2:v]xfade=transition=wipeleft:duration=1:offset=8[x2];\
    [x2][3:v]xfade=transition=circleopen:duration=1.5:offset=11.5[v]" \
  -map "[v]" -pix_fmt yuv420p \
  varied_transitions.mp4
```

## Custom Transitions with Expressions

### Custom xfade Expression

```bash
# NOTE: in xfade custom expressions P runs from 1 (start of the transition,
# all A) DOWN to 0 (end, all B). Use (1-P) for "progress so far".

# Custom diagonal wipe (new clip spreads from the top-left corner)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=custom:duration=1:offset=4:\
    expr='if(lt(X+Y,(W+H)*(1-P)),B,A)'[v]" \
  -map "[v]" -pix_fmt yuv420p custom_diag.mp4

# Smooth custom fade (same as transition=fade)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=custom:duration=1:offset=4:\
    expr='A*P+B*(1-P)'[v]" \
  -map "[v]" -pix_fmt yuv420p smooth_fade.mp4

# Circular reveal from the center (radius grows from 0 to the half-diagonal)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=custom:duration=1.5:offset=4:\
    expr='if(gt(sqrt(pow(X-W/2,2)+pow(Y-H/2,2)),(1-P)*sqrt(pow(W/2,2)+pow(H/2,2))),A,B)'[v]" \
  -map "[v]" -pix_fmt yuv420p circle_reveal.mp4
```

### Expression Variables

| Variable | Description |
|----------|-------------|
| X | Current pixel X coordinate |
| Y | Current pixel Y coordinate |
| W | Frame width |
| H | Frame height |
| P | Progress, running from 1.0 at the start of the transition to 0.0 at the end |
| PLANE | Index of the plane being processed (0-3) |
| A | First clip pixel value |
| B | Second clip pixel value |

## Advanced Transition Techniques

### Luma/Alpha Matte Transitions

```bash
# Using a grayscale gradient image as an animated transition mask (two 5 s
# clips, 1 s transition from t=4 to t=5): pixels whose gradient value is below
# the rising threshold 255*(T-4) switch to clip2 (dark areas change first).
# - clip2 is delayed by 4 s (tpad start) so it starts at its own beginning
#   when the wipe starts; clip1 is held on its last frame (tpad stop) so
#   maskedmerge keeps running to the end of clip2.
# - Output length = 4 + clip2 duration = 9 s.
# - Set -framerate to the clips' frame rate and scale= to the clips' size.
# - All three maskedmerge inputs are planar RGB (gbrp): in YUV the gray mask's
#   chroma planes are 128, which blends the clips' colours ~50/50.
ffmpeg -i clip1.mp4 -i clip2.mp4 -loop 1 -framerate 30 -i gradient.png \
  -filter_complex "\
    [0:v]tpad=stop_mode=clone:stop_duration=4,format=gbrp[a];\
    [1:v]tpad=start_mode=clone:start_duration=4,format=gbrp[b];\
    [2:v]format=gray,scale=1920:1080,\
         geq=lum='if(lte(lum(X,Y),255*(T-4)),255,0)',format=gbrp[mask];\
    [a][b][mask]maskedmerge,format=yuv420p[v]" \
  -map "[v]" -t 9 \
  luma_transition.mp4
```

### Motion Blur Transition

```bash
# Add motion blur during transition
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=fade:duration=1:offset=4[fade];\
    [fade]tblend=all_mode=average:enable='between(t,4,5)'[v]" \
  -map "[v]" -pix_fmt yuv420p \
  blur_transition.mp4
```

### Push/Reveal Transition

```bash
# Push left (new clip pushes old off screen)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v]fps=30[a];\
    [1:v]fps=30[b];\
    [a][b]xfade=transition=slideleft:duration=0.5:offset=4.5[v]" \
  -map "[v]" -pix_fmt yuv420p \
  push_left.mp4

# Cover transition (new clip covers old)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=coverright:duration=0.75:offset=4.25[v]" \
  -map "[v]" -pix_fmt yuv420p \
  cover_right.mp4
```

### Zoom with Ken Burns Effect

```bash
# Zoom transition with motion. With d=1 on video, zoom resets every frame,
# so the zoom is driven by the input time (it), not by the previous zoom.
# x/y keep the zoom centred (without them zoompan zooms into the top-left).
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v]scale=2*iw:-2,zoompan=z='min(1+0.1*it,1.5)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1920x1080:fps=30,settb=AVTB[a];\
    [1:v]scale=1920:1080,fps=30,settb=AVTB[b];\
    [a][b]xfade=transition=zoomin:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p -t 6 \
  zoom_transition.mp4
```

## Transition with Text/Graphics

### Title Card Transition

```bash
# Fade to title card, then fade to next clip
ffmpeg -i clip1.mp4 \
  -f lavfi -i "color=c=black:s=1920x1080:d=3" \
  -i clip2.mp4 \
  -filter_complex "\
    [0:v]scale=1920:1080,fps=30,settb=AVTB[c1];\
    [1:v]drawtext=text='Chapter 2':fontsize=72:fontcolor=white:x=(w-tw)/2:y=(h-th)/2,fps=30,settb=AVTB[title];\
    [2:v]scale=1920:1080,fps=30,settb=AVTB[c2];\
    [c1][title]xfade=transition=fadeblack:duration=1:offset=4[x1];\
    [x1][c2]xfade=transition=fadeblack:duration=1:offset=6[v]" \
  -map "[v]" -pix_fmt yuv420p \
  title_transition.mp4
```

### Lower Third Transition

```bash
# Animate lower third with clip transition
ffmpeg -i clip1.mp4 -i clip2.mp4 -i lower_third.png \
  -filter_complex "\
    [0:v][1:v]xfade=transition=fade:duration=1:offset=4[bg];\
    [2:v]format=rgba[lt];\
    [bg][lt]overlay=x=50:y=H-h-50:enable='between(t,1,4)'[v]" \
  -map "[v]" \
  lower_third_trans.mp4
```

## Performance Optimization

### Hardware-Accelerated Transitions

```bash
# Use NVENC for faster encoding after transition
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=fade:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p \
  -c:v h264_nvenc -preset p4 \
  output.mp4

# Hardware decode + CPU transition + hardware encode
ffmpeg -hwaccel cuda -i clip1.mp4 -hwaccel cuda -i clip2.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=dissolve:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p \
  -c:v h264_nvenc \
  output.mp4
```

### Optimize for Preview

```bash
# Lower resolution preview
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v]scale=640:360[a];\
    [1:v]scale=640:360[b];\
    [a][b]xfade=transition=fade:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p \
  -c:v libx264 -preset ultrafast \
  preview.mp4
```

## Troubleshooting

### Common Issues

**Size mismatch error**
```text
[Parsed_xfade_1 @ 0x...] First input link main parameters (size 320x180) do not match the corresponding second input link xfade parameters (size 160x90)
[Parsed_xfade_1 @ 0x...] Failed to configure output pad on Parsed_xfade_1
```
```bash
# Ensure both clips have same resolution
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1[a];\
    [1:v]scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1[b];\
    [a][b]xfade=transition=fade:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p output.mp4
```

**Frame rate / timebase mismatch error**
```text
[Parsed_xfade_3 @ 0x...] First input link main frame rate (30/1) do not match the corresponding second input link xfade frame rate (25/1)
[Parsed_xfade_1 @ 0x...] First input link main timebase (1/15360) do not match the corresponding second input link xfade timebase (1/25)
```
```bash
# Normalize frame rates (fps= also gives both inputs the same 1/30 timebase)
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v]fps=30[a];\
    [1:v]fps=30[b];\
    [a][b]xfade=transition=fade:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p output.mp4
```

**Offset calculation for multiple clips**
```text
offset_k = (D1 + ... + Dk) - (T1 + ... + Tk)
          = length of the stream built so far - this cut's transition
Equal clips D and equal transitions T: offset_k = k*D - k*T
Mixed transition lengths: subtract each cut's own T (e.g. 5 s clips with
1, 1, 1.5 s cuts -> offsets 4, 8, 11.5)
```

**Audio doesn't match video transition**
```bash
# Sync audio crossfade with video xfade
ffmpeg -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=fade:duration=1:offset=4[v];\
    [0:a][1:a]acrossfade=d=1:c1=tri:c2=tri[a]" \
  -map "[v]" -map "[a]" -pix_fmt yuv420p \
  output.mp4
```

### Verification Commands

```bash
# Check clip durations before creating transitions
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 clip1.mp4

# Check frame rate
ffprobe -v error -select_streams v -show_entries stream=r_frame_rate -of default=noprint_wrappers=1:nokey=1 clip1.mp4

# Check resolution
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 clip1.mp4
```

## Best Practices

### Timing
1. Standard transition duration: 0.5-1.5 seconds
2. Match transition style to content mood
3. Use consistent transitions within a sequence
4. Avoid overly long transitions (>2 seconds)

### Quality
1. Normalize resolution and frame rate before transitions
2. Use high-quality presets for final render
3. Test transitions at full resolution before batch processing
4. Consider color matching between clips

### Style Guidelines
1. Fade/dissolve: Universal, professional
2. Wipes: Energetic, action content
3. Slides/pushes: Modern, dynamic
4. Circle/iris: Dramatic, theatrical
5. Pixelize/blur: Creative, artistic

This guide covers FFmpeg transitions. For drawing shapes and graphics, see `shapes-graphics.md`.
