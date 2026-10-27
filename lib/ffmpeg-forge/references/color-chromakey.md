# FFmpeg Color Grading & Chromakey

Complete guide to color manipulation, green screen removal, LUT grading, and advanced color effects with FFmpeg.

## Contents

- [Quick Reference](#quick-reference)
- [Workflow](#workflow)
- [Green Screen (Chromakey) Removal](#green-screen-chromakey-removal)
- [Colorkey Filter (Transparency)](#colorkey-filter-transparency)
- [LUT Color Grading](#lut-color-grading)
- [Color Curves](#color-curves)
- [Color Balance](#color-balance)
- [Hue and Saturation](#hue-and-saturation)
- [White Balance](#white-balance)
- [Color Space Conversions](#color-space-conversions)
- [Selective Color Manipulation](#selective-color-manipulation)
- [Professional Grading Chains](#professional-grading-chains)
- [Animated Color Effects](#animated-color-effects)
- [Troubleshooting](#troubleshooting)

## Quick Reference

| Task | Command |
|------|---------|
| Green screen composite | `-filter_complex "[0:v]chromakey=0x00FF00:0.3:0.1[fg];[1:v][fg]overlay"` |
| Blue screen composite | `-filter_complex "[0:v]chromakey=0x0000FF:0.3:0.1[fg];[1:v][fg]overlay"` |
| Apply LUT | `-vf "lut3d=cinematic.cube"` |
| Color curves | `-vf "curves=preset=vintage"` |
| Adjust saturation | `-vf "eq=saturation=1.5"` |
| Hue shift | `-vf "hue=h=30"` |
| White balance | `-vf "colortemperature=5000"` (below 6500 K = warmer, above = cooler; 6500 is neutral) |

**MP4 output:** `curves`, `colorbalance`, `colortemperature`, `colorchannelmixer`, `colorhold`, `lut3d`, `despill` and `colorkey` work in RGB/4:4:4, so libx264 picks yuv444p (High 4:4:4 Predictive), which many browsers and phones will not play. Add `-pix_fmt yuv420p` whenever the chain uses one of them, as the recipes below do (`eq` and `hue` stay 4:2:0; a final `overlay` outputs yuv420p, but `blend` keeps whatever format its inputs share, so keep `-pix_fmt yuv420p` after it).

**Keying needs a composite or an alpha-capable output.** `chromakey`/`colorkey` only write an alpha channel. Encoding that straight to yuv420p H.264 drops the alpha and the green screen stays visible, so either `overlay` the keyed layer on a background or write a format that keeps alpha (see [Colorkey Filter](#colorkey-filter-transparency)).

---

## Workflow

### 1. Probe

```bash
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height,r_frame_rate,pix_fmt,color_range,color_space,color_primaries,color_transfer \
  -of default=noprint_wrappers=1 INPUT
```

Note:
- **Bit depth and chroma** (`pix_fmt`): 8-bit 4:2:0 (`yuv420p`), 10-bit (`yuv420p10le`), or full-range JPEG-style (`yuvj420p`).
- **Range** (`color_range`): `tv` (limited) or `pc` (full).
- **Transfer**: `smpte2084` (PQ) or `arib-std-b67` (HLG) means HDR; tone map before any SDR grade.
- **Frame rate and size**: needed when compositing a still or a second clip.

### 2. Decide

| Goal | Recipe |
|------|--------|
| Apply a `.cube`/`.3dl` LUT | [LUT Color Grading](#lut-color-grading) |
| Partial-strength LUT | "Blend Original with LUT" under LUT Color Grading |
| Look without a LUT (teal/orange, vintage, warm, cool) | [Popular LUT Styles](#popular-lut-styles), [Professional Grading Chains](#professional-grading-chains), or `scripts/apply-color-grade.sh` (cinematic, vintage, noir, warm, cool, bleach, instagram, matrix) |
| Black and white, high-contrast noir | [Black and White / Noir](#black-and-white--noir) |
| Shadows/midtones/highlights balance | [Color Balance](#color-balance) |
| Curves, presets | [Color Curves](#color-curves) |
| White balance | [White Balance](#white-balance): `colortemperature` 6500 K is neutral, lower is warmer, higher is cooler |
| Green/blue screen | [Green Screen (Chromakey) Removal](#green-screen-chromakey-removal) |
| Transparent output (alpha) | [Colorkey Filter](#colorkey-filter-transparency) |
| HDR to SDR | [HDR to SDR Tone Mapping](#hdr-to-sdr-tone-mapping) |
| Fix or set color tags | [Color Space Conversions](#color-space-conversions) |
| Animated grade | [Animated Color Effects](#animated-color-effects) |

### 3. Build

- Test on a short slice first: `-t 5`.
- End every MP4/web chain with `-pix_fmt yuv420p` (or `format=yuv420p`); see the MP4 output note above.
- Run `blend` modes other than plain mixing (screen, multiply, overlay, softlight, ...) in planar RGB: `format=gbrp` on both inputs, then `format=yuv420p` after. On YUV the chroma planes are blended too and the picture shifts green or magenta.
- For a still background, loop it at the foreground frame rate and convert JPEG full range: `-loop 1 -framerate 30 -i bg.jpg` with `scale=W:H:out_range=tv,format=yuv420p` and `overlay=shortest=1`.
- Match two clips by eye with `colorcorrect`. It takes one input, so shift the source toward the reference while comparing them side by side:

```bash
# Tune rl/bl/rh/bh while watching the comparison, then render with the same values
ffmpeg -i source.mp4 -i reference.mp4 -filter_complex \
  "[0:v]colorcorrect=rl=0.1:bl=-0.1:rh=0.05:bh=-0.05[s];[s][1:v]hstack" \
  -t 5 -pix_fmt yuv420p compare.mp4
```

### 4. Verify

```bash
# Pixel format and profile (want yuv420p / High for web delivery)
ffprobe -v error -select_streams v:0 -show_entries stream=profile,pix_fmt,color_range,color_primaries -of csv=p=0 OUTPUT

# Look at a frame from the middle
ffmpeg -ss 2 -i OUTPUT -frames:v 1 -update 1 check.png

# Before/after side by side
ffmpeg -i INPUT -i OUTPUT -filter_complex "[0:v][1:v]hstack" -t 5 -pix_fmt yuv420p ab.mp4

# Histogram overlay to check clipping and colour distribution
ffmpeg -i OUTPUT -filter_complex \
  "[0:v]split[a][b];[b]histogram,format=yuva444p[h];[a][h]overlay" \
  -t 5 -pix_fmt yuv420p histo.mp4
```

### Checklist

- The test slice (`-t 5`) shows the requested look.
- The output is `yuv420p`, High profile, for web/phone delivery (or a deliberate 10-bit/HEVC target).
- Range and tags are correct (`tv`, bt709 for SDR); HDR sources were tone mapped, not just retagged.
- Keyed footage was composited or written to an alpha-capable format.
- The direction of each adjustment is understood: shadows/midtones/highlights, Kelvin (lower = warmer).
- Fine-tuning steps are small: colorbalance ±0.05, chromakey similarity 0.1-0.4.
- Multiple clips were compared with `hstack` before the final render.

---

## Green Screen (Chromakey) Removal

### Basic Chromakey

```bash
# Remove green screen (standard green 0x00FF00)
ffmpeg -i foreground.mp4 -i background.mp4 \
  -filter_complex "[0:v]chromakey=0x00FF00:0.3:0.1[fg];[1:v][fg]overlay" \
  -c:v libx264 -crf 18 output.mp4

# Parameters:
# - color: The key color (hex 0xRRGGBB)
# - similarity: How close to key color (0.0-1.0, lower = more precise)
# - blend: Edge softness (0.0-1.0, higher = softer edges)
```

### Chromakey Parameter Tuning

```bash
# A still background must be the overlay's main (first) input, and overlay
# emits one frame per main-input frame. So loop the image at the foreground's
# frame rate (-loop 1 -framerate 30), scale it to the foreground size, and end
# with shortest=1. JPEGs are full range (yuvj420p): out_range=tv converts them.

# Tight key (clean edges, may leave green fringe)
ffmpeg -i green_screen.mp4 -loop 1 -framerate 30 -i background.jpg \
  -filter_complex "[1:v]scale=1920:1080:out_range=tv,format=yuv420p[bg];\
    [0:v]chromakey=0x00FF00:0.1:0.0[fg];[bg][fg]overlay=shortest=1" \
  -c:v libx264 -pix_fmt yuv420p output.mp4

# Loose key (removes all green, may eat into subject)
ffmpeg -i green_screen.mp4 -loop 1 -framerate 30 -i background.jpg \
  -filter_complex "[1:v]scale=1920:1080:out_range=tv,format=yuv420p[bg];\
    [0:v]chromakey=0x00FF00:0.5:0.2[fg];[bg][fg]overlay=shortest=1" \
  -c:v libx264 -pix_fmt yuv420p output.mp4

# Balanced (recommended starting point)
ffmpeg -i green_screen.mp4 -loop 1 -framerate 30 -i background.jpg \
  -filter_complex "[1:v]scale=1920:1080:out_range=tv,format=yuv420p[bg];\
    [0:v]chromakey=0x00FF00:0.3:0.1[fg];[bg][fg]overlay=shortest=1" \
  -c:v libx264 -pix_fmt yuv420p output.mp4
```

### Blue Screen Removal

```bash
# Remove blue screen
ffmpeg -i blue_screen.mp4 -i background.mp4 \
  -filter_complex "[0:v]chromakey=0x0000FF:0.3:0.1[fg];[1:v][fg]overlay" \
  output.mp4

# Chroma blue (common broadcast blue)
ffmpeg -i footage.mp4 -i background.mp4 \
  -filter_complex "[0:v]chromakey=0x0047AB:0.3:0.15[fg];[1:v][fg]overlay" \
  output.mp4
```

### Sample Green Screen Colors

| Name | Hex | Use Case |
|------|-----|----------|
| Pure Green | 0x00FF00 | Digital green screens |
| Chroma Green | 0x00B140 | Professional film/TV |
| Light Green | 0x90EE90 | Lighter backgrounds |
| Pure Blue | 0x0000FF | Digital blue screens |
| Chroma Blue | 0x0047AB | Professional broadcast |

### Advanced Chromakey with Despill

Green spill removal (green reflection on subject):

```bash
# Remove green screen with despill
ffmpeg -i green_screen.mp4 -i background.mp4 \
  -filter_complex "\
    [0:v]chromakey=0x00FF00:0.3:0.1,\
    colorbalance=gs=-0.1:gm=-0.1:gh=-0.1[fg];\
    [1:v][fg]overlay" \
  output.mp4

# Dedicated despill filter (works on RGB; key first, then despill keeps alpha)
# mix = how much of the spill map is used (0-1), expand = widen the spill
# map (0-1); raise both for stronger spill. type=blue for blue screens.
ffmpeg -i green_screen.mp4 -i background.mp4 \
  -filter_complex "\
    [0:v]chromakey=0x00FF00:0.3:0.1,\
    format=rgba,despill=type=green:mix=0.5:expand=0.1[fg];\
    [1:v][fg]overlay" \
  output.mp4
```

## Colorkey Filter (Transparency)

Colorkey creates actual transparency (alpha channel) instead of compositing:

```bash
# Create transparent video (WebM with alpha)
ffmpeg -i green_screen.mp4 \
  -vf "colorkey=0x00FF00:0.3:0.1" \
  -c:v libvpx-vp9 -pix_fmt yuva420p \
  output_transparent.webm

# Create transparent PNG sequence
ffmpeg -i green_screen.mp4 \
  -vf "colorkey=0x00FF00:0.3:0.1" \
  frame_%04d.png
```

### Colorkey vs Chromakey

| Feature | colorkey | chromakey |
|---------|----------|-----------|
| Matching | Distance in RGB | Distance in chroma (U/V) only, so lighting changes on the screen key more evenly |
| Output | Frame with alpha (RGBA) | Frame with alpha (YUVA) |
| Compositing | Follow with `overlay` | Follow with `overlay` |
| Keep alpha in a file | WebM (VP9 `yuva420p`), PNG, ProRes 4444 | Same: plain H.264 MP4 has no alpha |

## LUT Color Grading

### Apply 3D LUT

```bash
# Apply .cube LUT file
ffmpeg -i input.mp4 \
  -vf "lut3d=cinematic.cube" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p output.mp4

# Apply .3dl LUT
ffmpeg -i input.mp4 \
  -vf "lut3d=film_look.3dl" \
  -pix_fmt yuv420p output.mp4

# Specify interpolation method
ffmpeg -i input.mp4 \
  -vf "lut3d=lut.cube:interp=trilinear" \
  -pix_fmt yuv420p output.mp4
```

### LUT Interpolation Methods

| Method | Quality | Speed |
|--------|---------|-------|
| nearest | Lowest | Fastest |
| trilinear | Good | Fast |
| tetrahedral (default) | Best | Slower |
| pyramid, prism | Between trilinear and tetrahedral | Fast |

```bash
# tetrahedral is already the default; naming it only documents the choice
ffmpeg -i input.mp4 \
  -vf "lut3d=film.cube:interp=tetrahedral" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p output.mp4
```

### Blend Original with LUT

```bash
# 50% LUT strength
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split[a][b];\
    [a]lut3d=cinematic.cube[graded];\
    [b][graded]blend=all_expr='A*0.5+B*0.5'" \
  output.mp4

# Variable LUT intensity: change the weights (here 30% LUT, 70% original;
# A = first blend input = original, B = graded)
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split[a][b];\
    [a]lut3d=lut.cube[graded];\
    [b][graded]blend=all_expr='A*0.7+B*0.3'" \
  output.mp4
```

### Popular LUT Styles

Create common looks without external LUTs:

```bash
# Teal and Orange (blockbuster look): teal shadows (less red, more blue/green),
# orange highlights (more red, less blue). Gray ramp check: dark 47 -> (37,50,57)
# teal, light 208 -> (235,217,181) orange
ffmpeg -i input.mp4 \
  -vf "colorbalance=rs=-0.15:gs=0.05:bs=0.15:rh=0.15:gh=0.05:bh=-0.15" \
  -pix_fmt yuv420p output.mp4

# Vintage/Retro
ffmpeg -i input.mp4 \
  -vf "curves=preset=vintage,eq=saturation=0.8:contrast=1.1" \
  -pix_fmt yuv420p output.mp4

# High Contrast Cinematic
ffmpeg -i input.mp4 \
  -vf "eq=contrast=1.2:brightness=-0.05:saturation=1.1,unsharp=5:5:0.8" \
  output.mp4

# Desaturated/Bleach Bypass
ffmpeg -i input.mp4 \
  -vf "eq=saturation=0.5:contrast=1.3:brightness=-0.02" \
  output.mp4

# Warm/Golden Hour (colortemperature below the 6500 K default = warmer/oranger)
ffmpeg -i input.mp4 \
  -vf "colortemperature=5000,eq=saturation=1.2:brightness=0.05" \
  -pix_fmt yuv420p output.mp4

# Cool/Moonlight (above 6500 K = cooler/bluer)
ffmpeg -i input.mp4 \
  -vf "colortemperature=8000,eq=saturation=0.9:brightness=-0.05" \
  -pix_fmt yuv420p output.mp4
```

## Color Curves

### Preset Curves

```bash
# Vintage look
ffmpeg -i input.mp4 -vf "curves=preset=vintage" -pix_fmt yuv420p output.mp4

# Cross process (film developing effect)
ffmpeg -i input.mp4 -vf "curves=preset=cross_process" -pix_fmt yuv420p output.mp4

# Negative image
ffmpeg -i input.mp4 -vf "curves=preset=negative" -pix_fmt yuv420p output.mp4

# Increase contrast
ffmpeg -i input.mp4 -vf "curves=preset=strong_contrast" -pix_fmt yuv420p output.mp4

# Lighter
ffmpeg -i input.mp4 -vf "curves=preset=lighter" -pix_fmt yuv420p output.mp4

# Darker
ffmpeg -i input.mp4 -vf "curves=preset=darker" -pix_fmt yuv420p output.mp4

# Linear contrast
ffmpeg -i input.mp4 -vf "curves=preset=linear_contrast" -pix_fmt yuv420p output.mp4

# Medium contrast
ffmpeg -i input.mp4 -vf "curves=preset=medium_contrast" -pix_fmt yuv420p output.mp4
```

### Custom Curves

```bash
# S-curve for contrast (RGB)
ffmpeg -i input.mp4 \
  -vf "curves=all='0/0 0.25/0.20 0.5/0.5 0.75/0.80 1/1'" \
  -pix_fmt yuv420p output.mp4

# Lift shadows, lower highlights
ffmpeg -i input.mp4 \
  -vf "curves=all='0/0.05 0.5/0.5 1/0.95'" \
  -pix_fmt yuv420p output.mp4

# Per-channel curves (R, G, B)
ffmpeg -i input.mp4 \
  -vf "curves=r='0/0 0.5/0.6 1/1':g='0/0 0.5/0.5 1/1':b='0/0 0.5/0.4 1/1'" \
  -pix_fmt yuv420p output.mp4

# Crushed blacks (film look)
ffmpeg -i input.mp4 \
  -vf "curves=all='0/0.03 0.15/0.15 0.5/0.5 0.85/0.85 1/1'" \
  -pix_fmt yuv420p output.mp4
```

## Color Balance

### colorbalance Filter

```bash
# Warm highlights, cool shadows
ffmpeg -i input.mp4 \
  -vf "colorbalance=rs=-0.1:gs=-0.05:bs=0.1:rh=0.1:gh=0.05:bh=-0.1" \
  -pix_fmt yuv420p output.mp4

# Parameters:
# rs/gs/bs = red/green/blue shadows (-1 to 1)
# rm/gm/bm = red/green/blue midtones (-1 to 1)
# rh/gh/bh = red/green/blue highlights (-1 to 1)
```

### Common Color Balance Presets

```bash
# Orange and Teal: see "Teal and Orange" under Popular LUT Styles

# Warm overall
ffmpeg -i input.mp4 \
  -vf "colorbalance=rs=0.1:rm=0.05:rh=0.1:bs=-0.05:bm=-0.03:bh=-0.05" \
  -pix_fmt yuv420p output.mp4

# Cool shadows, warm highlights (split toning)
ffmpeg -i input.mp4 \
  -vf "colorbalance=rs=-0.1:bs=0.1:rh=0.15:bh=-0.1" \
  -pix_fmt yuv420p output.mp4
```

## Hue and Saturation

### hue Filter

```bash
# Rotate hue by 30 degrees
ffmpeg -i input.mp4 -vf "hue=h=30" output.mp4

# Increase saturation
ffmpeg -i input.mp4 -vf "hue=s=1.5" output.mp4

# Decrease saturation (desaturate)
ffmpeg -i input.mp4 -vf "hue=s=0.5" output.mp4

# Adjust brightness
ffmpeg -i input.mp4 -vf "hue=b=0.1" output.mp4

# Animated hue rotation
ffmpeg -i input.mp4 \
  -vf "hue=h=t*36" \
  output.mp4  # Full rotation every 10 seconds
```

### eq Filter (Comprehensive)

```bash
# Full color adjustment
ffmpeg -i input.mp4 \
  -vf "eq=contrast=1.1:brightness=0.05:saturation=1.2:gamma=1.1" \
  output.mp4

# eq parameters:
# contrast: -1000 to 1000 (default 1; negative values invert the image)
# brightness: -1 to 1 (default 0)
# saturation: 0-3 (default 1)
# gamma: 0.1-10 (default 1)
# gamma_r/gamma_g/gamma_b: per-channel gamma
```

## White Balance

### colortemperature Filter (FFmpeg 4.4+)

```bash
# Warm up (lower temperature)
ffmpeg -i input.mp4 \
  -vf "colortemperature=temperature=5000" \
  -pix_fmt yuv420p output.mp4

# Cool down (higher temperature)
ffmpeg -i input.mp4 \
  -vf "colortemperature=temperature=8000" \
  -pix_fmt yuv420p output.mp4

# Neutral daylight
ffmpeg -i input.mp4 \
  -vf "colortemperature=temperature=6500" \
  -pix_fmt yuv420p output.mp4
```

### Manual White Balance

```bash
# Using colorbalance for white balance
# Correct blue cast (add warmth)
ffmpeg -i input.mp4 \
  -vf "colorbalance=rs=0.1:rm=0.05:bs=-0.1:bm=-0.05" \
  -pix_fmt yuv420p output.mp4

# Correct yellow/orange cast (add blue)
ffmpeg -i input.mp4 \
  -vf "colorbalance=rs=-0.1:rm=-0.05:bs=0.1:bm=0.05" \
  -pix_fmt yuv420p output.mp4
```

## Color Space Conversions

### SDR Color Spaces

```bash
# Convert BT.601 to BT.709
ffmpeg -i input.mp4 \
  -vf "colorspace=bt709:iall=bt601-6-625:fast=1" \
  -c:v libx264 -crf 18 \
  output.mp4

# Force color space metadata (tags only, no pixel conversion)
# On FFmpeg 8.0 the output options -color_primaries/-color_trc are
# overwritten by the frame values when re-encoding, so set them on the
# frames with setparams instead
ffmpeg -i input.mp4 \
  -vf "setparams=color_primaries=bt709:color_trc=bt709:colorspace=bt709:range=tv" \
  -c:v libx264 -crf 18 output.mp4

# libx265: also pass the VUI values to x265
ffmpeg -i input.mp4 \
  -vf "setparams=color_primaries=bt709:color_trc=bt709:colorspace=bt709:range=tv" \
  -c:v libx265 -crf 20 \
  -x265-params colorprim=bt709:transfer=bt709:colormatrix=bt709 output.mp4

# Without re-encoding (H.264; use hevc_metadata for HEVC)
ffmpeg -i input.mp4 -c copy \
  -bsf:v h264_metadata=colour_primaries=1:transfer_characteristics=1:matrix_coefficients=1 \
  output.mp4

# Verify: VUI should show colour_primaries/transfer_characteristics/matrix_coefficients = 1
ffmpeg -i output.mp4 -c copy -bsf:v trace_headers -f null - 2>&1 | grep -E "colour_primaries|transfer_char|matrix_coef"
```

### HDR to SDR Tone Mapping

```bash
# Basic HDR to SDR (BT.2020/PQ to BT.709)
ffmpeg -i hdr_input.mp4 \
  -vf "zscale=t=linear:npl=100,format=gbrpf32le,\
       zscale=p=bt709,tonemap=tonemap=hable:desat=0,\
       zscale=t=bt709:m=bt709:r=tv,format=yuv420p" \
  -c:v libx264 -crf 18 sdr_output.mp4

# HDR10 to SDR with better quality
ffmpeg -i hdr10_input.mp4 \
  -vf "zscale=t=linear:npl=100,format=gbrpf32le,\
       zscale=p=bt709,tonemap=tonemap=reinhard:param=0.4:desat=0,\
       zscale=t=bt709:m=bt709,format=yuv420p" \
  -c:v libx264 -crf 18 output.mp4
```

### Tone Mapping Algorithms

| Algorithm | Characteristic |
|-----------|----------------|
| none | Clipping only |
| clip | Hard clip to SDR range |
| linear | Linear scale |
| gamma | Gamma curve |
| reinhard | Soft rolloff, natural |
| hable | Film-like, John Hable |
| mobius | S-curve, smooth |

## Selective Color Manipulation

### Color Isolation (Selective Desaturation)

```bash
# Keep only red, desaturate rest (Sin City effect)
# colorhold keeps colours within `similarity` of `color` and turns the rest gray
ffmpeg -i input.mp4 \
  -vf "colorhold=color=red:similarity=0.3:blend=0.1" \
  -pix_fmt yuv420p output.mp4

# Push it further: crush contrast after isolating red
ffmpeg -i input.mp4 \
  -vf "colorhold=color=red:similarity=0.3:blend=0.1,eq=contrast=1.4" \
  -pix_fmt yuv420p output.mp4

# Isolate specific color range using selectivecolor
# Note: Use colorchannelmixer for more control
```

### colorchannelmixer

```bash
# Convert to grayscale with proper luminance weights
ffmpeg -i input.mp4 \
  -vf "colorchannelmixer=.3:.59:.11:0:.3:.59:.11:0:.3:.59:.11" \
  -pix_fmt yuv420p output.mp4

# Sepia tone
ffmpeg -i input.mp4 \
  -vf "colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131" \
  -pix_fmt yuv420p output.mp4

# Swap red and blue channels
ffmpeg -i input.mp4 \
  -vf "colorchannelmixer=0:0:1:0:0:1:0:0:1:0:0:0" \
  -pix_fmt yuv420p output.mp4

# Boost reds, reduce blues
ffmpeg -i input.mp4 \
  -vf "colorchannelmixer=1.2:0:0:0:0:1:0:0:0:0:0.8:0" \
  -pix_fmt yuv420p output.mp4
```

## Professional Grading Chains

### Film Emulation

```bash
# 35mm Film Look
ffmpeg -i input.mp4 \
  -vf "\
    eq=contrast=1.1:saturation=0.95:gamma=1.05,\
    curves=preset=cross_process,\
    colorbalance=rs=0.05:bh=-0.05,\
    noise=c0s=3:c1s=3:c0f=t:c1f=t,\
    unsharp=3:3:0.5" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p film_look.mp4

# Kodak Portra Style
ffmpeg -i input.mp4 \
  -vf "\
    eq=saturation=0.9:contrast=1.05,\
    colorbalance=rs=0.1:gs=-0.02:rm=0.05:gm=-0.02,\
    curves=r='0/0.02 1/0.98':g='0/0 1/1':b='0/0.02 1/0.95'" \
  -pix_fmt yuv420p output.mp4

# Fuji Film Style
ffmpeg -i input.mp4 \
  -vf "\
    eq=saturation=1.1:contrast=1.05,\
    colorbalance=gs=0.05:bs=0.08:gm=0.02:bm=0.05,\
    curves=g='0/0.02 1/1'" \
  -pix_fmt yuv420p output.mp4
```

### Modern Cinematic

```bash
# Blockbuster Orange & Teal (teal shadows, orange highlights)
ffmpeg -i input.mp4 \
  -vf "\
    eq=contrast=1.15:saturation=1.1:brightness=-0.02,\
    colorbalance=rs=-0.12:gs=0.03:bs=0.12:rh=0.1:gh=0.03:bh=-0.12,\
    curves=all='0/0.02 0.5/0.5 1/0.98',\
    unsharp=5:5:0.6" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p cinematic.mp4

# Moody/Dark Cinematic
ffmpeg -i input.mp4 \
  -vf "\
    eq=contrast=1.2:brightness=-0.08:saturation=0.85,\
    colorbalance=bs=0.1:bm=0.05:gh=-0.05,\
    curves=all='0/0.05 0.5/0.45 1/0.9'" \
  -pix_fmt yuv420p output.mp4

# High Key Bright
ffmpeg -i input.mp4 \
  -vf "\
    eq=contrast=0.9:brightness=0.1:saturation=0.9:gamma=0.85,\
    colorbalance=rs=0.05:gs=0.02:bs=0.02" \
  -pix_fmt yuv420p output.mp4
```

### Black and White / Noir

```bash
# High Contrast Noir: hue=s=0 removes all colour (chroma becomes neutral, the
# frame stays yuv420p), then eq pushes contrast and pulls the blacks down
ffmpeg -i input.mp4 \
  -vf "hue=s=0,eq=contrast=1.4:brightness=-0.05" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p noir.mp4

# Near-monochrome: keeps a trace (10%) of the original colour
ffmpeg -i input.mp4 \
  -vf "eq=contrast=1.5:brightness=-0.1:saturation=0.1" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p noir_tint.mp4

# Film noir with vignette and fine grain (noise on luma only stays gray)
ffmpeg -i input.mp4 \
  -vf "hue=s=0,eq=contrast=1.4:brightness=-0.05,vignette=PI/5,noise=c0s=8:c0f=t" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p film_noir.mp4
```

For a red-only accent on black and white (Sin City look), see [Color Isolation](#color-isolation-selective-desaturation).

### Music Video Styles

```bash
# Neon/Cyberpunk
ffmpeg -i input.mp4 \
  -vf "\
    eq=contrast=1.3:saturation=1.5:brightness=-0.05,\
    colorbalance=rs=0.2:bs=0.2:rm=-0.1:bm=0.15,\
    unsharp=5:5:1.0" \
  -pix_fmt yuv420p output.mp4

# VHS/Retro
ffmpeg -i input.mp4 \
  -vf "\
    eq=saturation=1.2:contrast=0.95,\
    chromashift=cbh=2:cbv=2,\
    noise=c0s=10:c1s=5:allf=t,\
    curves=preset=vintage" \
  -pix_fmt yuv420p output.mp4

# Dream/Ethereal. blend works plane by plane, so on YUV a screen blend also
# "screens" the chroma planes and tints the frame magenta (gray 128 came out
# as RGB 184,130,192). Blend in planar RGB (gbrp), then convert back.
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]format=gbrp,split[a][b];\
    [a]gblur=sigma=15,eq=brightness=0.1[blur];\
    [b][blur]blend=all_mode=screen:all_opacity=0.3,format=yuv420p[out]" \
  -map "[out]" -c:v libx264 -crf 18 dream.mp4
```

## Animated Color Effects

### Time-Based Color Changes

```bash
# Gradually warm over 30 s. colorbalance takes numbers, not expressions,
# so blend from the clean frame (A) to the graded frame (B) over time
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split[a][b];[b]colorbalance=rs=0.1:bs=-0.1[w];\
    [a][w]blend=all_expr='A+(B-A)*min(T/30,1)'" \
  output.mp4

# Pulsing saturation
ffmpeg -i input.mp4 \
  -vf "hue=s='1+0.3*sin(t*2)'" \
  output.mp4

# Day to night transition over 30 s. eq accepts time expressions with
# eval=frame; colortemperature does not, so it is blended in instead
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split[a][b];[b]colortemperature=temperature=9000[n];\
    [a][n]blend=all_expr='A+(B-A)*min(T/30,1)',\
    eq=brightness='-0.2*min(t/30,1)':saturation='1-0.3*min(t/30,1)':eval=frame" \
  output.mp4
```

## Troubleshooting

### Common Issues

**Banding in gradients after grading:**
```bash
# 8-bit delivery: add subtle noise after the grade so the 8-bit encode
# breaks up the bands (output stays High yuv420p, playable everywhere)
ffmpeg -i input.mp4 \
  -vf "lut3d=lut.cube,noise=c0s=2:c0f=a" \
  -pix_fmt yuv420p output.mp4

# 10-bit output removes banding at the source, but only for players that
# decode 10-bit. Use HEVC Main 10 (hardware decode on most recent devices);
# avoid 10-bit H.264 (High 10), which browsers and most phones cannot play.
# format=gbrp16le runs the LUT at 16-bit before the 10-bit conversion.
ffmpeg -i input.mp4 \
  -vf "format=gbrp16le,lut3d=lut.cube,format=yuv420p10le" \
  -c:v libx265 -crf 20 -tag:v hvc1 output_10bit.mp4
```

**Color shift after encoding:**
```bash
# Force color space flags. Replace lut3d with the real grading chain and keep
# format=yuv420p and setparams last: -color_primaries/-color_trc output
# options are overwritten by frame values when re-encoding in 8.0
ffmpeg -i input.mp4 \
  -vf "lut3d=lut.cube,format=yuv420p,setparams=color_primaries=bt709:color_trc=bt709:colorspace=bt709:range=tv" \
  -c:v libx264 -crf 18 output.mp4
```

**Chromakey green fringe:**
```bash
# Use despill with colorbalance
ffmpeg -i green_screen.mp4 -i bg.mp4 \
  -filter_complex "\
    [0:v]chromakey=0x00FF00:0.25:0.1,\
    colorbalance=gs=-0.15:gm=-0.1[fg];\
    [1:v][fg]overlay" \
  output.mp4
```

This guide covers FFmpeg color grading and chromakey operations. For transitions see `transitions.md`, for shapes see `shapes-graphics.md`.
