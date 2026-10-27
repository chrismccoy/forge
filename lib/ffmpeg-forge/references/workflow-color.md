# FFmpeg Color Effects

## Purpose
Apply professional color grading, LUTs (Look-Up Tables), chromakey (green screen removal), and cinematic color effects to video.

## Workflow

### 1. Analyze Input
```bash
ffprobe -v error -show_entries stream=width,height,pix_fmt -of default=noprint_wrappers=1 INPUT
```

### 2. Color Effect Presets

#### LUT Application (3D Look-Up Tables)
```bash
# Apply .cube LUT file
ffmpeg -i INPUT -vf "lut3d=file='cinematic.cube'" -pix_fmt yuv420p OUTPUT

# Higher-quality interpolation (for partial strength, blend with the
# original: see "Blend Original with LUT" in color-chromakey.md)
ffmpeg -i INPUT -vf "lut3d=file='vintage.cube':interp=tetrahedral" -pix_fmt yuv420p OUTPUT
```

#### Chromakey (Green Screen Removal)
```bash
# Standard green screen
ffmpeg -i INPUT -vf "chromakey=0x00FF00:0.3:0.1" -c:v libx264 OUTPUT

# Blue screen
ffmpeg -i INPUT -vf "chromakey=0x0000FF:0.3:0.1" OUTPUT

# Fine-tuned green (studio green)
ffmpeg -i INPUT -vf "chromakey=0x00B140:0.25:0.05" OUTPUT
```

#### Colorkey (Non-chroma keying)
```bash
# Remove specific color
ffmpeg -i INPUT -vf "colorkey=0xFFFFFF:0.3:0.2" -pix_fmt yuv420p OUTPUT
```

#### Green Screen Composite
```bash
# Composite foreground over background
ffmpeg -i foreground.mp4 -i background.mp4 \
  -filter_complex "[0:v]chromakey=0x00FF00:0.3:0.1[fg];[1:v][fg]overlay=format=auto" \
  -c:v libx264 -crf 18 OUTPUT
```

### 3. Cinematic Color Presets

#### Teal and Orange (Blockbuster Look)
```bash
# Teal shadows (less red, more blue/green), orange highlights (more red, less blue)
ffmpeg -i INPUT \
  -vf "colorbalance=rs=-0.15:gs=0.05:bs=0.15:rh=0.15:gh=0.05:bh=-0.15,eq=saturation=1.2:contrast=1.1" \
  -pix_fmt yuv420p OUTPUT
```

#### Film Emulation (Vintage)
```bash
ffmpeg -i INPUT \
  -vf "curves=preset=vintage,eq=saturation=0.9:brightness=0.02" \
  -pix_fmt yuv420p OUTPUT
```

#### High Contrast Noir
```bash
ffmpeg -i INPUT \
  -vf "eq=contrast=1.5:brightness=-0.1:saturation=0.1" \
  OUTPUT
```

#### Warm/Golden Hour
```bash
ffmpeg -i INPUT \
  -vf "colorbalance=rs=0.15:gs=0.05:bs=-0.1:rm=0.1:gm=0.05:bm=-0.05" \
  -pix_fmt yuv420p OUTPUT
```

#### Cool/Moonlight
```bash
ffmpeg -i INPUT \
  -vf "colorbalance=rs=-0.1:bs=0.2:rm=-0.1:bm=0.15,eq=brightness=-0.1" \
  -pix_fmt yuv420p OUTPUT
```

### 4. Color Adjustment Filters

#### Color Balance
```bash
# Shadows (s), Midtones (m), Highlights (h)
ffmpeg -i INPUT -vf "colorbalance=rs=0.1:gs=0:bs=-0.1:rm=0.05:gm=0:bm=-0.05" -pix_fmt yuv420p OUTPUT
```

#### Curves Adjustment
```bash
# Boost contrast with S-curve
ffmpeg -i INPUT -vf "curves=all='0/0 0.25/0.15 0.5/0.5 0.75/0.85 1/1'" -pix_fmt yuv420p OUTPUT

# RGB channel manipulation
ffmpeg -i INPUT -vf "curves=r='0/0 0.5/0.6 1/1':g='0/0 0.5/0.5 1/1':b='0/0.1 0.5/0.4 1/0.9'" -pix_fmt yuv420p OUTPUT
```

#### Saturation and Vibrance
```bash
# Increase saturation
ffmpeg -i INPUT -vf "eq=saturation=1.5" OUTPUT

# Selective color boost (vibrance-like)
ffmpeg -i INPUT -vf "hue=s=1.3" OUTPUT
```

#### White Balance / Color Temperature
```bash
# The filter's default (6500 K) is neutral. Lower values warm the image
# (more red/orange), higher values cool it (more blue):
# Warm (lower Kelvin value)
ffmpeg -i INPUT -vf "colortemperature=temperature=4500" -pix_fmt yuv420p OUTPUT

# Cool (higher Kelvin value)
ffmpeg -i INPUT -vf "colortemperature=temperature=8000" -pix_fmt yuv420p OUTPUT
```

### 5. Professional Workflows

#### Spill Suppression (After Chromakey)
```bash
ffmpeg -i INPUT -i BACKGROUND \
  -filter_complex "[0:v]chromakey=0x00FF00:0.3:0.1,despill=type=green:mix=0.5[fg];\
    [1:v][fg]overlay=shortest=1[out]" \
  -map "[out]" OUTPUT
```

#### Color Match Between Clips
```bash
# colorcorrect takes one input: shift the source toward the reference by eye
# (compare the two side by side with hstack while tuning)
ffmpeg -i source.mp4 \
  -vf "colorcorrect=rl=0.1:bl=-0.1:rh=0.05:bh=-0.05" \
  OUTPUT
```

### 6. Parameter Reference

| Filter | Key Parameters |
|--------|----------------|
| chromakey | color, similarity (0-1), blend (0-1) |
| lut3d | file, interp (nearest, trilinear, tetrahedral) |
| curves | preset, r/g/b/all channel curves |
| colorbalance | rs/gs/bs (shadows), rm/gm/bm (mids), rh/gh/bh (highs) |
| eq | contrast, brightness, saturation, gamma |
| colortemperature | temperature (Kelvin; 6500 neutral, lower = warmer, higher = cooler) |

### 7. Testing Tips

- **Preview first**: Use `-t 5` to test on 5 seconds
- **Check histogram**: Add `split[a][b];[b]histogram,format=yuva444p[h];[a][h]overlay` to see color distribution
- **A/B comparison**: Use `hstack` to compare original vs processed

## Checklist

- The command applies the requested look and runs on a short test (`-t 5`).
- Each colour parameter's visual effect is understood (shadows/midtones/highlights, Kelvin direction).
- Fine-tuning ranges are known (e.g. colorbalance ±0.05 steps, chromakey similarity 0.1-0.4).
- An alternative preset or look has been considered.
- Footage from multiple clips is matched (A/B with `hstack`) before final render.
