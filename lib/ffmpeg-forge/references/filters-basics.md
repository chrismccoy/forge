# Filter Basics

Single-chain video and audio filters (`-vf`/`-af`) and frame manipulation: frame rate, timestamps, selection, thumbnails, tiles, freezing, looping, reversing, and frame extraction. Multi-input graphs and `filter_complex` syntax are in `filter-complex.md`.

## Contents

- [Video Filters (-vf)](#video-filters--vf)
- [Audio Filters (-af)](#audio-filters--af)
- [Frame Rate Conversion](#frame-rate-conversion)
- [Timestamp Manipulation (setpts)](#timestamp-manipulation-setpts)
- [Frame Selection (select)](#frame-selection-select)
- [Thumbnail Generation](#thumbnail-generation)
- [Tile / Contact Sheet](#tile--contact-sheet)
- [Frame Freezing](#frame-freezing)
- [Loop and Reverse](#loop-and-reverse)
- [Frame Extraction Patterns](#frame-extraction-patterns)

## Video Filters (-vf)

```bash
# Chain multiple filters
ffmpeg -i input.mp4 -vf "scale=1280:720,fps=30,format=yuv420p" output.mp4

# Crop
ffmpeg -i input.mp4 -vf "crop=640:480:100:50" output.mp4

# Rotate
ffmpeg -i input.mp4 -vf "transpose=1" output.mp4  # 90 deg clockwise
ffmpeg -i input.mp4 -vf "transpose=2" output.mp4  # 90 deg counter-clockwise
ffmpeg -i input.mp4 -vf "hflip" output.mp4        # Horizontal flip
ffmpeg -i input.mp4 -vf "vflip" output.mp4        # Vertical flip

# Overlay/Watermark (two inputs, so -filter_complex; see filter-complex.md)
ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=10:10" output.mp4
ffmpeg -i video.mp4 -i logo.png -filter_complex "overlay=W-w-10:H-h-10" output.mp4

# Text overlay (fonts, escaping, boxes, timecode: drawtext.md)
ffmpeg -i input.mp4 -vf "drawtext=text='Hello World':x=10:y=10:fontsize=24:fontcolor=white" output.mp4

# Fade in/out
ffmpeg -i input.mp4 -vf "fade=t=in:st=0:d=1,fade=t=out:st=9:d=1" output.mp4

# Speed up/slow down: see Timestamp Manipulation (setpts) below

# Deinterlace (field order, bwdif, inverse telecine: deinterlace.md)
ffmpeg -i input.mp4 -vf "yadif" output.mp4

# Denoise (nlmeans with default settings is very slow, under 2 fps even at
# 320x240; hqdn3d is far faster. See denoise.md for tuned nlmeans settings)
ffmpeg -i input.mp4 -vf "nlmeans" output.mp4
ffmpeg -i input.mp4 -vf "hqdn3d" output.mp4

# Sharpen
ffmpeg -i input.mp4 -vf "unsharp=5:5:1.0:5:5:0.0" output.mp4

# Color correction
ffmpeg -i input.mp4 -vf "eq=brightness=0.1:contrast=1.2:saturation=1.3" output.mp4
```

## Audio Filters (-af)

```bash
# Multiple audio filters
ffmpeg -i input.mp4 -af "volume=1.5,highpass=f=200,lowpass=f=3000" output.mp4

# Noise reduction
ffmpeg -i input.mp4 -af "afftdn=nf=-25" output.mp4

# Compressor/limiter
ffmpeg -i input.mp4 -af "acompressor=threshold=-20dB:ratio=4:attack=5:release=50" output.mp4

# Equalizer
ffmpeg -i input.mp4 -af "equalizer=f=1000:width_type=h:width=200:g=-10" output.mp4

# Fade audio
ffmpeg -i input.mp4 -af "afade=t=in:st=0:d=3,afade=t=out:st=57:d=3" output.mp4

# Channel remix (stereo to mono)
ffmpeg -i input.mp4 -af "pan=mono|c0=0.5*c0+0.5*c1" output.mp4
```

Loudness and EQ in depth: `audio.md`; processing chains: `audio-chains.md`.

## Frame Rate Conversion

```bash
# Change frame rate (drop/duplicate frames)
ffmpeg -i input.mp4 -vf "fps=30" output.mp4
ffmpeg -i input.mp4 -vf "fps=24000/1001" output.mp4  # 23.976 fps

# Blended frame rate conversion (framerate cross-fades neighbouring frames;
# no motion estimation, so fast motion ghosts. Use minterpolate for that)
ffmpeg -i input.mp4 -vf "framerate=fps=60" output.mp4

# High-quality motion interpolation (minterpolate)
ffmpeg -i input.mp4 -vf "minterpolate=fps=60:mi_mode=mci:mc_mode=aobmc:me_mode=bidir:vsbmc=1" output.mp4

# Simple motion interpolation (faster)
ffmpeg -i input.mp4 -vf "minterpolate=fps=60:mi_mode=blend" output.mp4
```

### minterpolate Modes

| mi_mode | Description | Speed | Quality |
|---------|-------------|-------|---------|
| `dup` | Duplicate frames | Fastest | Lowest |
| `blend` | Blend adjacent frames | Fast | Medium |
| `mci` | Motion-compensated interpolation | Slow | Best |

## Timestamp Manipulation (setpts)

```bash
# Speed up 2x (halve timestamps; atempo keeps the audio the same length,
# or use -an to drop it)
ffmpeg -i input.mp4 -vf "setpts=0.5*PTS" -af "atempo=2.0" output.mp4

# Slow down 2x (double timestamps)
ffmpeg -i input.mp4 -vf "setpts=2.0*PTS" -af "atempo=0.5" output.mp4

# Start from timestamp 0 (reset PTS)
ffmpeg -i input.mp4 -vf "setpts=PTS-STARTPTS" output.mp4

# Time-lapse: keep every 10th frame, at 30fps output. These select/setpts
# recipes change only the video, so drop the audio (-an) or it keeps the
# original length and the file no longer lines up
ffmpeg -i input.mp4 -vf "select='not(mod(n,10))',setpts=N/30/TB" -an output.mp4

# Variable speed (accelerate over time)
ffmpeg -i input.mp4 -vf "setpts='PTS/(1+0.001*N)'" -an output.mp4
```

### setpts Variables

| Variable | Description |
|----------|-------------|
| `PTS` | Input presentation timestamp |
| `N` | Frame count (starting at 0) |
| `PREV_INPTS` | Previous input timestamp |
| `PREV_OUTPTS` | Previous output timestamp |
| `TB` | Timebase |
| `STARTPTS` | First frame timestamp |
| `RTCSTART` | Real-time clock start |

## Frame Selection (select)

```bash
# Select every 5th frame
# (video only: -an drops the audio, which select does not shorten)
ffmpeg -i input.mp4 -vf "select='not(mod(n,5))',setpts=N/FRAME_RATE/TB" -an output.mp4

# Select I-frames only (keyframes)
ffmpeg -i input.mp4 -vf "select='eq(pict_type,I)',setpts=N/FRAME_RATE/TB" -an keyframes.mp4

# Select frames with scene change
ffmpeg -i input.mp4 -vf "select='gt(scene,0.4)',setpts=N/FRAME_RATE/TB" -an scenes.mp4

# Select frames based on time range; atrim keeps the matching audio
# (aselect='between(t,5,10)' passed every audio frame in a test on 8.0.1)
ffmpeg -i input.mp4 -vf "select='between(t,5,10)',setpts=N/FRAME_RATE/TB" \
  -af "atrim=5:10,asetpts=PTS-STARTPTS" output.mp4

# Keep only dark frames (average luma below 40 of 255)
ffmpeg -i input.mp4 -vf "signalstats,metadata=select:key=lavfi.signalstats.YAVG:value=40:function=less" -fps_mode vfr dark_%04d.png
```

### select Expressions

| Expression | Description |
|------------|-------------|
| `n` | Frame number |
| `t` | Timestamp (seconds) |
| `pict_type` | Picture type (I, P, B) |
| `scene` | Scene change score |
| `key` | 1 for keyframes |
| `interlace_type` | Interlace type |

## Thumbnail Generation

```bash
# Generate thumbnail from best frame
ffmpeg -i input.mp4 -vf "thumbnail" -frames:v 1 -update 1 thumbnail.jpg

# Thumbnail with custom frames to analyze
ffmpeg -i input.mp4 -vf "thumbnail=n=100" -frames:v 1 -update 1 thumbnail.jpg

# One frame every 10 seconds
ffmpeg -i input.mp4 -vf "fps=1/10" thumb_%04d.jpg

# Most representative frame from each batch of 300 frames (~10 s at 30 fps)
ffmpeg -i input.mp4 -vf "thumbnail=n=300" -fps_mode vfr thumb_%04d.jpg

# Thumbnail at specific time
ffmpeg -ss 00:00:30 -i input.mp4 -vframes 1 -update 1 thumbnail.jpg
```

## Tile / Contact Sheet

```bash
# Create 4x4 tile mosaic
ffmpeg -i input.mp4 -vf "fps=1/5,scale=320:180,tile=4x4" -frames:v 1 -update 1 contact_sheet.jpg

# Create tile with padding
ffmpeg -i input.mp4 -vf "fps=1/10,scale=256:144,tile=5x4:margin=5:padding=5" -frames:v 1 -update 1 contact.png

# Animated mosaic: each output frame packs 4 consecutive input frames, so the
# output runs at 1/4 of the input frame rate (not a 4-up of the same moment)
ffmpeg -i input.mp4 -vf "scale=320:180,tile=2x2" tiled.mp4
```

### tile Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `layout` | Grid dimensions | `4x4` |
| `margin` | Outer margin | `10` |
| `padding` | Inter-tile padding | `5` |
| `color` | Background color | `black` |

## Frame Freezing

```bash
# Freeze first frame for 3 seconds, then play (adelay shifts the audio by the
# same 3 s; without it the sound runs 3 s ahead of the picture)
ffmpeg -i input.mp4 -vf "tpad=start_mode=clone:start_duration=3" -af "adelay=3000:all=1" output.mp4

# Freeze last frame for 3 seconds
ffmpeg -i input.mp4 -vf "tpad=stop_mode=clone:stop_duration=3" output.mp4

# Add 90 black frames at start (3 s at 30 fps; delay the audio to match)
ffmpeg -i input.mp4 -vf "tpad=start=90:color=black" -af "adelay=3000:all=1" output.mp4

# Freeze specific frame range (frames 100-150)
# freezeframes takes two inputs: the stream to edit and the source of the replacement frame
ffmpeg -i input.mp4 -filter_complex "[0:v]split[a][b];[a][b]freezeframes=first=100:last=150:replace=100" output.mp4
```

## Loop and Reverse

```bash
# Play the video 4 times (original + 3 extra loops; -stream_loop -1 = forever)
ffmpeg -stream_loop 3 -i input.mp4 -c copy output.mp4

# Loop filter: repeat the first 30 frames 3 more times (video only; the audio
# is not looped, so drop it or loop it with aloop)
ffmpeg -i input.mp4 -vf "loop=loop=3:size=30:start=0" -an output.mp4

# Reverse video (reverse buffers the whole clip in RAM: trim long inputs first;
# -an because the audio would still play forwards)
ffmpeg -i input.mp4 -vf "reverse" -an reversed.mp4

# Reverse audio too
ffmpeg -i input.mp4 -vf "reverse" -af "areverse" reversed.mp4

# Boomerang effect (forward then reverse)
ffmpeg -i input.mp4 -filter_complex "[0:v]split[v1][v2];[v2]reverse[r];[v1][r]concat=n=2:v=1:a=0[v]" -map "[v]" boomerang.mp4
```

## Frame Extraction Patterns

```bash
# Extract all frames (the image2 muxer does not create directories)
mkdir -p frames
ffmpeg -i input.mp4 frames/frame_%05d.png

# Extract at specific FPS
mkdir -p frames
ffmpeg -i input.mp4 -vf "fps=1" frames/frame_%04d.jpg

# Extract keyframes only
ffmpeg -i input.mp4 -vf "select='eq(pict_type,I)'" -fps_mode vfr keyframe_%04d.png

# Extract frames with timestamp filename (-frame_pts writes the PTS in encoder
# time-base units; with fps=1 that equals seconds, with other rates it does not)
ffmpeg -i input.mp4 -vf "fps=1" -frame_pts 1 "frame_%d.jpg"
```
