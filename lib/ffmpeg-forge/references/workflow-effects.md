# FFmpeg Creative Effects

## Purpose
Apply creative video effects including glitch art, VHS simulation, datamosh, chromatic aberration, motion trails, and distortion effects.

## Workflow

### 1. Analyze Input
```bash
ffprobe -v error -show_entries stream=width,height,r_frame_rate,duration -of default=noprint_wrappers=1 INPUT
```

### 2. Effect Presets

#### Glitch (Combined)
```bash
# minterpolate runs on a branch (it has no enable= support); 30 = source fps
ffmpeg -i INPUT \
  -filter_complex "[0:v]split[base][m];\
    [m]fps=10,minterpolate='fps=30:mi_mode=mci:mc_mode=aobmc:scd=none'[mosh];\
    [base][mosh]overlay=enable='lt(mod(t,3),0.2)',\
    rgbashift=rh=3:bh=-3:enable='lt(mod(t,1),0.15)',\
    noise=c0s=10:c0f=t:enable='lt(mod(t,2),0.1)'" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p OUTPUT
```

#### VHS/Analog
```bash
ffmpeg -i INPUT \
  -vf "\
    noise=c0s=15:c0f=t:c1s=10:c1f=t,\
    eq=saturation=1.4:contrast=1.1:brightness=-0.02,\
    chromashift=cbh=3:crh=-3,\
    rgbashift=rh=2:bh=-2,\
    drawgrid=w=iw:h=2:t=1:c=black@0.3,\
    curves=preset=vintage" \
  -c:v libx264 -crf 20 -pix_fmt yuv420p OUTPUT
```

#### Datamosh (Pixel Bleeding)
```bash
ffmpeg -i INPUT \
  -vf "minterpolate='mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1'" \
  -c:v libx264 -crf 18 OUTPUT
```

#### Chromatic Aberration
```bash
# Static
ffmpeg -i INPUT -vf "rgbashift=rh=-5:bh=5" -pix_fmt yuv420p OUTPUT

# Pulsing (animated): rgbashift takes integers, so blend clean and shifted frames
ffmpeg -i INPUT -filter_complex "[0:v]split[a][b];[b]rgbashift=rh=-5:bh=5[s];[a][s]blend=all_expr='A+(B-A)*(0.5+0.5*sin(T*10))'" OUTPUT
```

#### Motion Trails
```bash
ffmpeg -i INPUT -vf "lagfun=decay=0.95" OUTPUT
```

#### Wave Distortion
```bash
# Work in RGB: on 4:2:0 the chroma planes are half size, so the same X/Y
# offsets in cb/cr would misalign colour against luma
ffmpeg -i INPUT \
  -vf "format=gbrp,geq=r='r(X+10*sin(Y/20+T*5),Y)':g='g(X+10*sin(Y/20+T*5),Y)':b='b(X+10*sin(Y/20+T*5),Y)',format=yuv420p" \
  OUTPUT
```

#### Barrel/Fisheye Distortion
```bash
ffmpeg -i INPUT \
  -vf "lenscorrection=cx=0.5:cy=0.5:k1=0.5:k2=0.5" \
  OUTPUT
```

### 3. Timing Effects

Apply effects only during specific time ranges:
```bash
# Effect between 5-10 seconds (filter with no options: filter=enable=...)
-vf "effect_filter=enable='between(t,5,10)'"

# Effect at regular intervals (filter with options: filter=opts:enable=...)
-vf "effect_filter=opts:enable='lt(mod(t,4),0.3)'"
```

### 4. Effect Parameters

| Effect | Key Parameters |
|--------|----------------|
| Datamosh | mi_mode, mc_mode, scd (scene change) |
| Chromatic | rh, bh, rv, bv (shift amounts) |
| VHS noise | c0s, c0f (strength, flags) |
| Trails | decay (0-1, higher = longer trails) |
| Distortion | k1, k2 (barrel/pincushion) |

### 5. Combining Effects

Chain multiple effects:
```bash
ffmpeg -i INPUT \
  -vf "effect1,effect2,effect3" \
  OUTPUT
```

### 6. Performance Tips

- **Datamosh is CPU-intensive**: Consider processing at lower resolution
- **Test on short clips**: Use `-t 5` to process only 5 seconds
- **Hardware encode final**: After effects, use NVENC/QSV for encoding

## Checklist

- The effect command runs on a short test (`-t 5`).
- Each effect parameter's visual impact is understood before tuning.
- Timing/triggering is set where needed (`enable='between(t,a,b)'`, expressions on `t`).
- Combined effects are chained in a sensible order (geometry, then colour, then grain/noise).
- Performance is acceptable: heavy effects tested at lower resolution first.
