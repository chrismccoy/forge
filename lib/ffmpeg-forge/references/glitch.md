## Quick Reference

| Effect | Command |
|--------|---------|
| Datamosh | `-vf "minterpolate='mi_mode=mci:mc_mode=aobmc:me_mode=bidir'"` |
| Chromatic aberration | `-vf "rgbashift=rh=-5:bh=5"` |
| VHS noise | `-vf "noise=c0s=20:c0f=t,eq=saturation=1.2"` |
| Pixelate | `-vf "scale=iw/10:ih/10,scale=iw*10:ih*10:flags=neighbor"` |
| Wave distortion | `-vf "displace=..."` with displacement map |
| Echo/trails | `-vf "lagfun=decay=0.95"` |
| Scan lines | `-vf "drawgrid=w=iw:h=2:t=1:c=black@0.5"` |

**MP4 output:** `rgbashift`, `curves` and `colorbalance` work in RGB/4:4:4, so libx264 picks yuv444p (High 4:4:4 Predictive), which many browsers and phones will not play. Add `-pix_fmt yuv420p` whenever the chain uses one of them, as the recipes below do (`eq` and `hue` stay 4:2:0; a final `overlay` or `blend` converts back).

---

# FFmpeg Glitch & Distortion Effects

Complete guide to datamosh, glitch art, VHS effects, displacement, and creative video distortion with FFmpeg.

## Datamosh Effects

Datamosh creates the "pixel bleeding" effect by manipulating motion compensation.

### Basic Datamosh with minterpolate

```bash
# Basic datamosh effect
ffmpeg -i input.mp4 \
  -vf "minterpolate='mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1'" \
  -c:v libx264 -crf 18 datamosh.mp4

# Parameters explained:
# mi_mode=mci: Motion compensated interpolation
# mc_mode=aobmc: Adaptive overlapped block motion compensation
# me_mode=bidir: Bidirectional motion estimation
# vsbmc=1: Variable size block motion compensation
```

### Intense Datamosh

```bash
# Heavy datamosh (more chaos)
ffmpeg -i input.mp4 \
  -vf "minterpolate='fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:me=epzs:vsbmc=1:scd=none'" \
  -c:v libx264 -crf 18 heavy_datamosh.mp4

# scd=none: Disable scene change detection (more bleeding across cuts)
# me=epzs: Enhanced predictive zonal search (faster, rougher)
```

### Datamosh with Frame Manipulation

```bash
# Datamosh-style smear: motion-interpolated frames blended with a frame
# difference (simulated; this re-encodes and does NOT remove I-frames)
ffmpeg -i input.mp4 \
  -vf "minterpolate='mi_mode=mci:mc_mode=aobmc',\
       tblend=all_mode=difference:all_opacity=0.5" \
  datamosh_blend.mp4

# Combine with echo for trails
ffmpeg -i input.mp4 \
  -vf "minterpolate='mi_mode=mci:mc_mode=aobmc',lagfun=decay=0.9" \
  datamosh_trails.mp4
```

### Controlled Datamosh (Specific Sections)

```bash
# minterpolate has no timeline (enable=) support and only invents frames when the
# output rate exceeds the input rate: drop frames on a branch, interpolate back to
# the source rate (30 here; match yours), then overlay that branch where wanted.
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split[base][m];\
    [m]fps=10,minterpolate='fps=30:mi_mode=mci:mc_mode=aobmc:scd=none'[mosh];\
    [base][mosh]overlay=enable='between(t,5,10)'" \
  controlled_datamosh.mp4
```

## Chromatic Aberration

Color channel separation for that "broken lens" look.

### rgbashift Filter

```bash
# Horizontal chromatic aberration
ffmpeg -i input.mp4 \
  -vf "rgbashift=rh=-5:bh=5" \
  -pix_fmt yuv420p chromatic.mp4

# Parameters:
# rh/rv: Red horizontal/vertical shift
# gh/gv: Green horizontal/vertical shift
# bh/bv: Blue horizontal/vertical shift
# ah/av: Alpha horizontal/vertical shift

# Vertical chromatic aberration
ffmpeg -i input.mp4 \
  -vf "rgbashift=rv=-3:bv=3" \
  -pix_fmt yuv420p chromatic_v.mp4

# Both directions
ffmpeg -i input.mp4 \
  -vf "rgbashift=rh=-4:rv=-2:bh=4:bv=2" \
  -pix_fmt yuv420p chromatic_both.mp4
```

### Animated Chromatic Aberration

```bash
# rgbashift takes integers only, not expressions. To animate it, blend between
# the clean and the shifted frame with a time expression:
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split[a][b];[b]rgbashift=rh=-5:bh=5[s];\
    [a][s]blend=all_expr='A+(B-A)*(0.5+0.5*sin(T*3))'" \
  pulsing_chromatic.mp4

# Or step the shift over time with sendcmd (time in seconds, then commands)
ffmpeg -i input.mp4 \
  -vf "sendcmd=c='0 rgbashift rh -2\, rgbashift bh 2; 4 rgbashift rh -6\, rgbashift bh 6; 8 rgbashift rh -10\, rgbashift bh 10',rgbashift" \
  -pix_fmt yuv420p increasing_chromatic.mp4
```

### chromashift Filter (Chroma Only)

```bash
# Shift chroma channels (U/V in YUV)
ffmpeg -i input.mp4 \
  -vf "chromashift=cbh=5:crh=-5" \
  chroma_shift.mp4

# cbh/cbv: Cb (blue-difference) horizontal/vertical
# crh/crv: Cr (red-difference) horizontal/vertical
```

## VHS/Analog Effects

### Complete VHS Simulation

```bash
# Full VHS effect
ffmpeg -i input.mp4 \
  -vf "\
    noise=c0s=15:c0f=t:c1s=10:c1f=t,\
    eq=saturation=1.4:contrast=1.1:brightness=-0.02,\
    chromashift=cbh=3:crh=-3,\
    rgbashift=rh=2:bh=-2,\
    unsharp=3:3:-0.5,\
    drawgrid=w=iw:h=2:t=1:c=black@0.3,\
    curves=preset=vintage" \
  -c:v libx264 -crf 20 -pix_fmt yuv420p vhs_effect.mp4
```

### VHS Components Breakdown

```bash
# 1. VHS Noise (temporal noise)
ffmpeg -i input.mp4 \
  -vf "noise=c0s=20:c0f=t:c1s=15:c1f=t" \
  vhs_noise.mp4

# 2. VHS Color bleeding
ffmpeg -i input.mp4 \
  -vf "chromashift=cbh=4:cbv=2:crh=-3:crv=1" \
  vhs_color_bleed.mp4

# 3. VHS Scan lines
ffmpeg -i input.mp4 \
  -vf "drawgrid=w=iw:h=2:t=1:c=black@0.4" \
  vhs_scanlines.mp4

# 4. VHS Tracking issues (simulated)
ffmpeg -i input.mp4 \
  -vf "crop=iw:ih-20:0:'20*random(1)',pad=iw:ih+20:0:10" \
  vhs_tracking.mp4

# 5. VHS Oversaturated colors
ffmpeg -i input.mp4 \
  -vf "eq=saturation=1.5:contrast=1.1,curves=preset=vintage" \
  -pix_fmt yuv420p vhs_colors.mp4
```

### VHS Static/Snow

```bash
# Static overlay blend
# (color source, not nullsrc: nullsrc frame contents are undefined)
ffmpeg -f lavfi -i "color=c=gray:s=1920x1080:d=10" \
  -vf "noise=c0s=100:c0f=a+t,format=gray" \
  -c:v libx264 -t 10 static.mp4

# Blend static with video (static.mp4 must match the video size)
ffmpeg -i input.mp4 -i static.mp4 \
  -filter_complex "[0:v][1:v]blend=all_mode=screen:all_opacity=0.1" \
  vhs_static.mp4
```

## Pixelation & Mosaic

### Basic Pixelation

```bash
# Pixelate entire video
ffmpeg -i input.mp4 \
  -vf "scale=iw/10:ih/10,scale=iw*10:ih*10:flags=neighbor" \
  pixelated.mp4

# Parameters:
# First scale: Reduce resolution (divide by pixelation level)
# Second scale: Scale back up with nearest neighbor (no interpolation)

# Variable pixelation level
ffmpeg -i input.mp4 \
  -vf "scale=iw/20:ih/20,scale=iw*20:ih*20:flags=neighbor" \
  heavy_pixel.mp4
```

### Animated Pixelation

```bash
# Pixelation that increases over time. eval=frame re-evaluates the size each
# frame; the second scale must name a fixed size (your source size, here 1280x720)
ffmpeg -i input.mp4 \
  -vf "scale=w='max(16,iw/max(1,t*2))':h='max(16,ih/max(1,t*2))':eval=frame,scale=1280:720:flags=neighbor" \
  animated_pixel.mp4

# Note: This is approximate; true animated requires geq or external scripts
```

### Mosaic/Censoring Effect

```bash
# Mosaic specific region (face blur style)
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]crop=200:200:300:200[face];\
    [face]scale=iw/10:ih/10,scale=iw*10:ih*10:flags=neighbor[blurred];\
    [0:v][blurred]overlay=300:200" \
  mosaic_region.mp4
```

## Wave & Ripple Distortion

### Displacement Map

```bash
# displace takes THREE inputs: source, xmap, ymap (same size as the source).
# Map value 128 = no shift; value v moves the pixel by (v-128) pixels.

# X map: horizontal sine wave (+/-20 px, 60-line period)
ffmpeg -f lavfi \
  -i "color=c=gray:s=1920x1080:d=1:r=1,format=gray,geq=lum='128+20*sin(2*PI*Y/60)'" \
  -frames:v 1 -update 1 displacement_h.png

# Y map: neutral gray (no vertical shift)
ffmpeg -f lavfi -i "color=c=0x808080:s=1920x1080:d=1:r=1,format=gray" \
  -frames:v 1 -update 1 displacement_none.png

# Apply horizontal wave displacement (still map images are reused for
# every frame)
ffmpeg -i input.mp4 -i displacement_h.png -i displacement_none.png \
  -filter_complex "[0:v][1:v][2:v]displace=edge=wrap" \
  wave_h.mp4
```

### Animated Wave with geq

```bash
# geq X/Y are per-plane coordinates. On 4:2:0 video the chroma planes are half
# size, so displacing lum/cb/cr with one expression misaligns color. Work in RGB
# (gbrp, all planes full size) and convert back for the encoder.

# Horizontal wave using geq
ffmpeg -i input.mp4 \
  -vf "format=gbrp,geq=r='r(X+10*sin(Y/20+T*5),Y)':g='g(X+10*sin(Y/20+T*5),Y)':b='b(X+10*sin(Y/20+T*5),Y)',format=yuv420p" \
  wave_animated.mp4

# Vertical wave
ffmpeg -i input.mp4 \
  -vf "format=gbrp,geq=r='r(X,Y+10*sin(X/20+T*5))':g='g(X,Y+10*sin(X/20+T*5))':b='b(X,Y+10*sin(X/20+T*5))',format=yuv420p" \
  wave_v.mp4

# Ripple from center
ffmpeg -i input.mp4 \
  -vf "format=gbrp,geq=r='r(X+5*sin(sqrt(pow(X-W/2,2)+pow(Y-H/2,2))/10-T*5),Y+5*cos(sqrt(pow(X-W/2,2)+pow(Y-H/2,2))/10-T*5))':g='g(X+5*sin(sqrt(pow(X-W/2,2)+pow(Y-H/2,2))/10-T*5),Y+5*cos(sqrt(pow(X-W/2,2)+pow(Y-H/2,2))/10-T*5))':b='b(X+5*sin(sqrt(pow(X-W/2,2)+pow(Y-H/2,2))/10-T*5),Y+5*cos(sqrt(pow(X-W/2,2)+pow(Y-H/2,2))/10-T*5))',format=yuv420p" \
  ripple.mp4
```

### lenscorrection (Barrel/Pincushion)

```bash
# Barrel distortion (fisheye-like)
ffmpeg -i input.mp4 \
  -vf "lenscorrection=cx=0.5:cy=0.5:k1=0.5:k2=0.5" \
  barrel.mp4

# Pincushion distortion (opposite of barrel)
ffmpeg -i input.mp4 \
  -vf "lenscorrection=cx=0.5:cy=0.5:k1=-0.3:k2=-0.3" \
  pincushion.mp4

# Parameters:
# cx, cy: Lens center (0-1, 0.5 = center)
# k1, k2: Distortion coefficients (positive = barrel, negative = pincushion)
```

## Echo & Trails (lagfun)

### Basic Trails

```bash
# Motion trails
ffmpeg -i input.mp4 \
  -vf "lagfun=decay=0.95" \
  trails.mp4

# Parameters:
# decay: How fast trails fade (0-1, higher = longer trails)

# Heavy trails
ffmpeg -i input.mp4 \
  -vf "lagfun=decay=0.98" \
  heavy_trails.mp4

# Light trails
ffmpeg -i input.mp4 \
  -vf "lagfun=decay=0.85" \
  light_trails.mp4
```

### Trails with Color

```bash
# Trails with color shift
ffmpeg -i input.mp4 \
  -vf "lagfun=decay=0.95,hue=h=t*10" \
  color_trails.mp4

# Inverted trails (bright areas leave dark trails)
ffmpeg -i input.mp4 \
  -vf "negate,lagfun=decay=0.95,negate" \
  inverted_trails.mp4
```

## Frame Blending (tmix, tblend)

### tmix (Temporal Mix)

```bash
# Average 5 frames (motion blur effect)
ffmpeg -i input.mp4 \
  -vf "tmix=frames=5:weights='1 1 1 1 1'" \
  motion_blur.mp4

# Echo effect (repeat previous frames)
ffmpeg -i input.mp4 \
  -vf "tmix=frames=10:weights='1 0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1'" \
  echo.mp4

# Ghosting
ffmpeg -i input.mp4 \
  -vf "tmix=frames=3:weights='1 0.5 0.25'" \
  ghosting.mp4
```

### tblend (Frame Difference)

```bash
# Frame difference (motion highlight)
ffmpeg -i input.mp4 \
  -vf "tblend=all_mode=difference" \
  frame_diff.mp4

# Available modes:
# addition, addition128, multiply, multiply128
# average, difference, difference128
# divide, exclusion, extremity, freeze
# glow, hardlight, hardmix, heat
# lighten, darken, linearlight, negation
# normal, overlay, phoenix, pinlight
# reflect, screen, softdifference
# softlight, stain, subtract, vividlight, xor
```

### Creative tblend Effects

```bash
# Neon edges
ffmpeg -i input.mp4 \
  -vf "tblend=all_mode=difference128,eq=brightness=0.1:contrast=2" \
  neon_edges.mp4

# Psychedelic blend
ffmpeg -i input.mp4 \
  -vf "tblend=all_mode=phoenix" \
  psychedelic.mp4

# Burn effect
ffmpeg -i input.mp4 \
  -vf "tblend=all_mode=heat" \
  burn_effect.mp4
```

## Digital Corruption

### Random Artifacts

```bash
# Digital glitch noise
ffmpeg -i input.mp4 \
  -vf "\
    noise=c0s=30:c0f=a+t:c1s=20:c1f=a+t,\
    rgbashift=rh=5:bh=-5:enable='lt(mod(t,1),0.15)'" \
  -pix_fmt yuv420p digital_glitch.mp4

# rgbashift values must be integers; enable= turns the shift on in short bursts
```

### Compression Artifact Simulation

```bash
# Heavy compression artifacts
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 51 -preset ultrafast \
  temp_compressed.mp4

ffmpeg -i temp_compressed.mp4 \
  -c:v libx264 -crf 18 \
  artifacts.mp4

# Blocky artifacts with multiple re-encodes
# Work on a copy: the loop replaces its working file each pass
cp input.mp4 work.mp4
for i in {1..5}; do
  ffmpeg -y -i work.mp4 -c:v libx264 -crf 40 temp.mp4
  mv temp.mp4 work.mp4
done
```

### Bit Manipulation (geq)

```bash
# Bit-depth reduction (posterization)
ffmpeg -i input.mp4 \
  -vf "geq=lum='floor(lum(X,Y)/32)*32':cb='floor(cb(X,Y)/32)*32':cr='floor(cr(X,Y)/32)*32'" \
  bit_crush.mp4

# XOR pattern. FFmpeg expressions have no bitwise operators (no bitxor()),
# so build an 8-bit XOR of luma and (X+Y) one bit at a time in a while() loop
ffmpeg -i input.mp4 \
  -vf "geq=lum='st(0,lum(X,Y));st(1,mod(X+Y,256));st(2,0);st(3,1);\
while(lt(ld(3),256),st(2,ld(2)+ld(3)*mod(floor(ld(0)/ld(3))+floor(ld(1)/ld(3)),2));\
st(3,2*ld(3)));ld(2)':cb='cb(X,Y)':cr='cr(X,Y)'" \
  xor_pattern.mp4
```

## Scan Lines & CRT Effects

### Scan Lines

```bash
# Horizontal scan lines
ffmpeg -i input.mp4 \
  -vf "drawgrid=w=iw:h=2:t=1:c=black@0.5" \
  scanlines.mp4

# Heavier scan lines
ffmpeg -i input.mp4 \
  -vf "drawgrid=w=iw:h=4:t=2:c=black@0.7" \
  heavy_scanlines.mp4

# RGB scan lines (trinitron style)
ffmpeg -i input.mp4 \
  -vf "drawgrid=w=3:h=ih:t=1:c=black@0.3" \
  rgb_scanlines.mp4
```

### CRT Simulation

```bash
# Full CRT effect
ffmpeg -i input.mp4 \
  -vf "\
    gblur=sigma=0.5,\
    drawgrid=w=iw:h=2:t=1:c=black@0.4,\
    vignette=PI/4,\
    eq=saturation=1.2:contrast=1.1,\
    lenscorrection=k1=0.1:k2=0.1,\
    noise=c0s=5:c0f=t" \
  crt_effect.mp4
```

### Interlacing Effects

```bash
# Add interlacing artifacts (fieldorder outputs 4:2:2; convert back to 4:2:0)
ffmpeg -i input.mp4 \
  -vf "interlace=scan=tff,fieldorder=bff,scale=interl=1,format=yuv420p" \
  interlaced.mp4

# Fake interlacing (comb effect)
ffmpeg -i input.mp4 \
  -vf "tinterlace=merge" \
  comb_effect.mp4
```

## Mirror & Kaleidoscope

### Mirror Effects

```bash
# Horizontal mirror (left to right)
ffmpeg -i input.mp4 \
  -vf "crop=iw/2:ih:0:0,split[a][b];[b]hflip[b];[a][b]hstack" \
  mirror_h.mp4

# Vertical mirror (top to bottom)
ffmpeg -i input.mp4 \
  -vf "crop=iw:ih/2:0:0,split[a][b];[b]vflip[b];[a][b]vstack" \
  mirror_v.mp4

# Quad mirror (kaleidoscope-lite)
ffmpeg -i input.mp4 \
  -vf "\
    crop=iw/2:ih/2:0:0,split=4[a][b][c][d];\
    [b]hflip[b];[c]vflip[c];[d]hflip,vflip[d];\
    [a][b]hstack[top];[c][d]hstack[bottom];\
    [top][bottom]vstack" \
  quad_mirror.mp4
```

## Combined Glitch Presets

### Music Video Glitch

```bash
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split[base][m];\
    [m]fps=10,minterpolate='fps=30:mi_mode=mci:mc_mode=aobmc:scd=none'[mosh];\
    [base][mosh]overlay=enable='lt(mod(t,2),0.2)',\
    rgbashift=rh=3:bh=-3:enable='lt(mod(t,1),0.15)',\
    lagfun=decay=0.9:enable='gt(mod(t,3),2.5)',\
    noise=c0s=10:c0f=t:enable='lt(mod(t,5),0.3)'" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p music_glitch.mp4
```

### Horror Glitch

```bash
# chromashift offsets are ints parsed once (random() would stay fixed), so the
# shift is varied over time with enable= bursts (sendcmd also works)
ffmpeg -i input.mp4 \
  -vf "\
    eq=brightness=-0.1:contrast=1.2:saturation=0.7,\
    chromashift=cbh=5:crh=-3:enable='lt(mod(t,0.7),0.15)',\
    chromashift=cbh=-4:crh=2:enable='between(mod(t,1.3),0.6,0.7)',\
    noise=c0s=15:c0f=a+t,\
    tblend=all_mode=difference:all_opacity=0.1:enable='lt(mod(t,3),0.1)',\
    drawgrid=w=iw:h=2:t=1:c=black@0.5" \
  horror_glitch.mp4
```

### Cyberpunk Glitch

```bash
ffmpeg -i input.mp4 \
  -vf "\
    eq=saturation=1.5:contrast=1.3,\
    colorbalance=rs=0.2:bs=0.2,\
    rgbashift=rh='-3':bh='3',\
    drawgrid=w=iw:h=3:t=1:c=black@0.3,\
    unsharp=5:5:1.5" \
  -pix_fmt yuv420p cyberpunk.mp4
```

### Analog TV Signal Loss

```bash
ffmpeg -i input.mp4 \
  -vf "\
    noise=c0s=50:c0f=t:enable='lt(mod(t,10),0.5)',\
    chromashift=cbh=10:crh=-6:enable='lt(mod(t,10),0.5)',\
    eq=brightness='-0.3*lt(mod(t,10),0.5)':eval=frame" \
  signal_loss.mp4
```

## Performance Tips

1. **geq is CPU-intensive** - Use sparingly or on short clips
2. **minterpolate is slow** - Consider reducing resolution first
3. **lagfun accumulates** - May need periodic "reset" cuts
4. **Test on short clips** before processing full videos
5. **Hardware encoding** - Use NVENC/QSV for final encode after effects

```bash
# Process effects, then encode with hardware
ffmpeg -i input.mp4 \
  -vf "your_glitch_filters" \
  -c:v rawvideo -pix_fmt yuv420p -f nut - | \
ffmpeg -i - \
  -c:v h264_nvenc -preset p4 -rc vbr -cq 20 -b:v 0 \
  output.mp4
```

This guide covers FFmpeg glitch and distortion effects. For color grading see `color-chromakey.md`, for transitions see `transitions.md`.
