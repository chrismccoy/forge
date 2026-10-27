# FFmpeg Deinterlacing & Telecine

Comprehensive guide to deinterlacing, field processing, and telecine removal.

## Contents

- [Quick Reference](#quick-reference)
- [Understanding Interlaced Video](#understanding-interlaced-video)
- [Deinterlacing Filters](#deinterlacing-filters)
- [Hardware-Accelerated Deinterlacing](#hardware-accelerated-deinterlacing)
- [Inverse Telecine (IVTC)](#inverse-telecine-ivtc)
- [Field Processing](#field-processing)
- [Common Workflows](#common-workflows)
- [Quality Comparison](#quality-comparison)
- [Best Practices](#best-practices)

## Quick Reference

| Task | Filter | Command Pattern |
|------|--------|-----------------|
| Basic deinterlace | `yadif` | `-vf yadif` |
| High quality deinterlace | `bwdif` | `-vf bwdif` |
| CUDA deinterlace | `yadif_cuda` | `-vf yadif_cuda` |
| Inverse telecine | `pullup` | `-vf pullup` |
| Field order | `fieldorder` | `-vf fieldorder=tff` |
| Detect interlace | `idet` | `-vf idet` |

---

## Understanding Interlaced Video

### What is Interlacing?

Interlaced video stores two half-resolution fields per frame:
- **Top field**: odd lines counting from 1 (1, 3, 5, ...)
- **Bottom field**: even lines (2, 4, 6, ...)

Field *order* says which field was captured first: TFF (top field first) or
BFF (bottom field first).

Common interlaced formats:
- 1080i (1920x1080, 50i or 60i)
- 576i (720x576, 50i - PAL)
- 480i (720x480, 60i - NTSC)

### Detecting Interlaced Content

```bash
# Use idet filter to detect interlacing
ffmpeg -i input.mp4 -vf "idet" -frames:v 500 -f null -

# Output shows field types:
# TFF = Top Field First
# BFF = Bottom Field First
# Progressive = Not interlaced
# Undetermined = Mixed or uncertain
```

---

## Deinterlacing Filters

### yadif - Yet Another DeInterlacing Filter

The most widely used deinterlacing filter. Good balance of speed and quality.

```bash
# Basic deinterlacing (output same frame rate)
ffmpeg -i interlaced.mp4 -vf "yadif" output.mp4

# Double frame rate (output both fields as frames)
ffmpeg -i interlaced.mp4 -vf "yadif=1" output.mp4

# Specify field parity (auto-detect by default)
ffmpeg -i interlaced.mp4 -vf "yadif=0:0:0" output.mp4  # TFF
ffmpeg -i interlaced.mp4 -vf "yadif=0:1:0" output.mp4  # BFF

# Only deinterlace if detected as interlaced
ffmpeg -i input.mp4 -vf "yadif=deint=interlaced" output.mp4
```

**Parameters:**
| Parameter | Description | Values |
|-----------|-------------|--------|
| `mode` | Output mode | 0=same fps, 1=double fps |
| `parity` | Field parity | -1=auto, 0=TFF, 1=BFF |
| `deint` | Frames to deinterlace | 0=all, 1=interlaced only |

**Mode options:**
- `0` / `send_frame` - Output one frame per input frame
- `1` / `send_field` - Output one frame per field (double fps)
- `2` / `send_frame_nospatial` - Like 0, without spatial interlacing check
- `3` / `send_field_nospatial` - Like 1, without spatial interlacing check

### bwdif - Bob Weaver Deinterlacing Filter

Higher quality than yadif: motion adaptive like yadif, with w3fdif-style
interpolation from more fields.
Unlike yadif, bwdif's default mode is `send_field` (double frame rate).

```bash
# Basic bwdif (default send_field: one frame per field, e.g. 25i -> 50p)
ffmpeg -i interlaced.mp4 -vf "bwdif" output.mp4

# Same frame rate as the input (one frame per frame)
ffmpeg -i interlaced.mp4 -vf "bwdif=mode=send_frame" output.mp4

# Same frame rate, auto parity, only frames flagged as interlaced
ffmpeg -i interlaced.mp4 -vf "bwdif=0:-1:1" output.mp4
```

**Parameters:** Same names as yadif (`mode`, `parity`, `deint`), but `mode`
only accepts 0/`send_frame` and 1/`send_field`, and defaults to `send_field`.

### w3fdif - Martin Weston 3-Field Deinterlacing

Uses three fields with fixed filter coefficients. It is not motion adaptive,
so static detail is softer than with `bwdif`.

```bash
# Simple filter (faster); default mode=field doubles the frame rate (30i -> 60p)
ffmpeg -i interlaced.mp4 -vf "w3fdif=filter=simple" output.mp4

# Complex filter (better quality)
ffmpeg -i interlaced.mp4 -vf "w3fdif=filter=complex" output.mp4

# Keep the original frame rate
ffmpeg -i interlaced.mp4 -vf "w3fdif=filter=complex:mode=frame" output.mp4
```

**Parameters:**
| Parameter | Description | Values |
|-----------|-------------|--------|
| `filter` | Filter coefficients | simple, complex |
| `mode` | Output one frame per field (doubles rate) or per frame | field (default), frame |
| `parity` | Field order | tff, bff, auto (default) |
| `deint` | Frames to deinterlace | all, interlaced |

### kerndeint - Kernel Deinterlacing

Adaptive kernel-based deinterlacing.

```bash
# Basic kerndeint
ffmpeg -i interlaced.mp4 -vf "kerndeint" output.mp4

# With threshold adjustment
ffmpeg -i interlaced.mp4 -vf "kerndeint=thresh=10:map=0:order=0:sharp=0:twoway=0" output.mp4
```

---

## Hardware-Accelerated Deinterlacing

### yadif_cuda - NVIDIA CUDA

```bash
# Full GPU pipeline with CUDA deinterlacing
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i interlaced.mp4 \
  -vf "yadif_cuda=0:-1:0" \
  -c:v h264_nvenc output.mp4

# Double framerate with CUDA
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i interlaced.mp4 \
  -vf "yadif_cuda=1" \
  -c:v h264_nvenc output.mp4
```

### bwdif_cuda - NVIDIA CUDA (FFmpeg 6.1+)

```bash
# Higher quality CUDA deinterlacing
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i interlaced.mp4 \
  -vf "bwdif_cuda" \
  -c:v h264_nvenc output.mp4
```

### bwdif_vulkan - Vulkan (FFmpeg 6.1+)

Cross-platform GPU deinterlacing.

```bash
# Vulkan deinterlacing (works on AMD, Intel, NVIDIA)
ffmpeg -init_hw_device vulkan \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i interlaced.mp4 \
  -vf "bwdif_vulkan" \
  -c:v h264_vulkan output.mp4
```

### deinterlace_vaapi - VAAPI (Linux)

```bash
# VAAPI deinterlacing
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i interlaced.mp4 \
  -vf "deinterlace_vaapi" \
  -c:v h264_vaapi output.mp4

# Specify deinterlace mode
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i interlaced.mp4 \
  -vf "deinterlace_vaapi=mode=motion_adaptive:rate=frame" \
  -c:v h264_vaapi output.mp4
```

**VAAPI deinterlace modes:**
- `default` - Use driver default
- `bob` - Simple bob (double rate)
- `weave` - Weave fields together
- `motion_adaptive` - Motion-adaptive (best quality)
- `motion_compensated` - Motion-compensated (highest quality)

### deinterlace_qsv - Intel QSV

```bash
# QSV deinterlacing
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i interlaced.mp4 \
  -vf "vpp_qsv=deinterlace=2" \
  -c:v h264_qsv output.mp4
```

**VPP_QSV deinterlace modes:**
- `0` - Off
- `1` - Bob
- `2` - Advanced (motion adaptive)

---

## Inverse Telecine (IVTC)

### Understanding Telecine (3:2 Pulldown)

Telecine converts 24fps film to 30fps video by duplicating fields:
```yaml
Film frames:   A     B     C     D
Fields:        A A   B B B C C   D D D     (2-3-2-3 pattern, 4 frames -> 10 fields)
Video frames:  AA    BB    BC    CD    DD  (5 frames; 2 of every 5 are mixed)
```

### pullup - Pullup Filter

Removes 3:2 telecine by detecting and removing duplicate fields.

```bash
# Basic IVTC
ffmpeg -i telecined.mp4 -vf "pullup" -r 24000/1001 output.mp4

# With metric output
ffmpeg -i telecined.mp4 -vf "pullup=mp=y" -r 24000/1001 output.mp4
```

**Parameters:**
| Parameter | Description | Values |
|-----------|-------------|--------|
| `jl`, `jr` | Left/right junk size | 0+ (default 1) |
| `jt`, `jb` | Top/bottom junk size | 1+ (default 4) |
| `sb` | Strict breaks | 0 or 1 |
| `mp` | Metric plane | y, u, v |

### fieldmatch - Field Matching

More advanced telecine removal with field matching.

```bash
# Basic field matching
ffmpeg -i telecined.mp4 -vf "fieldmatch" output.mp4

# Full IVTC pipeline with decimation
ffmpeg -i telecined.mp4 -vf "fieldmatch,decimate" output.mp4

# Specify field order
ffmpeg -i telecined.mp4 -vf "fieldmatch=order=tff,decimate" output.mp4
```

**Combined IVTC workflow:**
```bash
# Complete telecine removal pipeline
ffmpeg -i telecined.mp4 \
  -vf "fieldmatch=order=auto:combmatch=full,decimate" \
  -r 24000/1001 \
  output.mp4
```

### decimate - Frame Decimation

Drops one frame in every `cycle` frames: the one most similar to its
neighbour (the duplicate left by fieldmatch). It does not just drop every
5th frame blindly.

```bash
# Drop the most-duplicate frame in each group of 5 (29.97 -> 23.976 fps)
ffmpeg -i input.mp4 -vf "decimate=cycle=5" output.mp4

# Stricter duplicate threshold (default dupthresh=1.1)
ffmpeg -i input.mp4 -vf "decimate=cycle=5:dupthresh=0.5" output.mp4

# ppsrc=1 takes TWO inputs: the first (pre-processed, e.g. denoised) is only
# used to measure duplicates, frames are output from the second (clean) input
ffmpeg -i input.mp4 -filter_complex \
  "[0:v]split[a][clean];[a]hqdn3d=4[pp];[pp][clean]decimate=cycle=5:ppsrc=1" \
  output.mp4
```

---

## Field Processing

### fieldorder - Change Field Order

Transforms field order between TFF and BFF.

```bash
# fieldorder outputs 4:2:2 (yuv422p) from 4:2:0 input; scale=interl=1,format=yuv420p
# converts back field by field so libx264 does not write a High 4:2:2 stream.
# -flags +ildct+ilme makes libx264 encode (and tag) the output as interlaced;
# without it the result is tagged progressive. libx264 tags the stream TFF
# unless told otherwise, so BFF output also needs -x264-params bff=1
# (without it the frames are BFF but ffprobe reports field_order=tt).
# Convert BFF to TFF
ffmpeg -i bff_input.mp4 -vf "fieldorder=tff,scale=interl=1,format=yuv420p" \
  -c:v libx264 -flags +ildct+ilme output.mp4

# Convert TFF to BFF
ffmpeg -i tff_input.mp4 -vf "fieldorder=bff,scale=interl=1,format=yuv420p" \
  -c:v libx264 -flags +ildct+ilme -x264-params bff=1 output.mp4
```

### separatefields - Separate Fields

Splits each frame into two fields.

```bash
# Separate fields (doubles frame count, halves height)
ffmpeg -i interlaced.mp4 -vf "separatefields" output.mp4
```

### weave - Weave Fields Together

Combines two consecutive frames (each one field, half height) into one frame
of double height at half the frame rate. It is the inverse of `separatefields`.
On normal full-height progressive video it doubles the height (640x360 30p
becomes 640x720 15p), so do not use it to make interlaced video; use
`tinterlace=interleave_top` instead.

```bash
# Re-weave separated fields (round trip is bit-exact: PSNR inf);
# first_field must match the source field order
ffmpeg -i interlaced.mp4 -vf "separatefields,weave=first_field=top" \
  -c:v libx264 -flags +ildct+ilme output.mp4
```

### tinterlace - Temporal Interlacing

Create interlaced output from progressive or modify interlaced content.
Always add `-flags +ildct+ilme` when encoding the result with libx264 (and
`-x264-params bff=1` for bottom-field-first output), or it is encoded and
tagged as progressive.

```bash
# Progressive to interlaced at half frame rate, same height
# (50p -> 25i TFF; 640x360 30p -> 640x360 15i, field_order=tt)
ffmpeg -i progressive.mp4 -vf "tinterlace=interleave_top" \
  -c:v libx264 -flags +ildct+ilme interlaced.mp4

# Bottom field first
ffmpeg -i progressive.mp4 -vf "tinterlace=interleave_bottom" \
  -c:v libx264 -flags +ildct+ilme -x264-params bff=1 interlaced_bff.mp4

# Bob deinterlace (each field line-doubled into its own frame; tinterlace
# itself only creates interlacing, it does not deinterlace)
ffmpeg -i interlaced.mp4 -vf "separatefields,scale=iw:ih*2,setsar=1" bobbed.mp4
```

**Modes:**
| Mode | Description |
|------|-------------|
| `merge` / `0` | Stack two consecutive frames as fields: double height, half frame rate |
| `drop_even` / `1` | Output only odd frames: same height, half frame rate, no interlacing |
| `drop_odd` / `2` | Output only even frames: same height, half frame rate, no interlacing |
| `pad` / `3` | Each frame becomes one field, other lines black: double height, same rate |
| `interleave_top` / `4` | Top field from odd frame, bottom from even: same height, half rate, TFF |
| `interleave_bottom` / `5` | As above, bottom field first (BFF) |
| `interlacex2` / `6` | Each output frame takes fields from two consecutive frames: double frame rate |
| `mergex2` / `7` | Like `merge` (double height) but keeps the frame rate: each frame is merged with the next |

### il - Interleave/Deinterleave Lines

Low-level line interleaving. Modes for `l`/`c`/`a` (luma/chroma/alpha) are
`none`, `i` (interleave) and `d` (deinterleave); swapping fields is a separate
boolean (`ls`, `cs`, `as`).

```bash
# Deinterleave: top field to the upper half, bottom field to the lower half
ffmpeg -i input.mp4 -vf "il=l=d:c=d" output.mp4

# Swap the two fields (luma and chroma)
ffmpeg -i input.mp4 -vf "il=ls=1:cs=1" output.mp4
```

---

## Common Workflows

### DVD to Progressive MP4

```bash
# Step 1: Detect interlacing
ffmpeg -i dvd_rip.vob -vf "idet" -frames:v 500 -f null -

# Step 2: Deinterlace (if interlaced)
ffmpeg -i dvd_rip.vob \
  -vf "yadif=1:-1:1" \
  -c:v libx264 -crf 18 \
  -c:a aac -b:a 192k \
  output.mp4

# For telecined content (film-based DVDs):
ffmpeg -i dvd_rip.vob \
  -vf "fieldmatch,decimate" \
  -r 24000/1001 \
  -c:v libx264 -crf 18 \
  output.mp4
```

### Broadcast 1080i to 1080p

```bash
# High quality deinterlacing
ffmpeg -i broadcast_1080i.ts \
  -vf "bwdif=1:-1:0" \
  -c:v libx264 -crf 18 -preset slow \
  -c:a copy \
  output_1080p.mp4

# With GPU acceleration
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i broadcast_1080i.ts \
  -vf "bwdif_cuda=1" \
  -c:v h264_nvenc -preset p4 \
  -c:a copy \
  output_1080p.mp4
```

### Mixed Content Detection and Processing

```bash
#!/bin/bash
# Detect and process based on content type

INPUT="$1"

# Detect interlacing type
# idet prints its summary twice (the first copy is all zeros), so keep the
# LAST "Multi frame detection" and "Repeated Fields" lines and compare counts.
# Any non-zero TFF/BFF count is normal for progressive video, so never test
# for "non-zero"; compare the categories instead.
result=$(ffmpeg -hide_banner -i "$INPUT" -vf "idet" -frames:v 1000 -an -f null - 2>&1)
multi=$(echo "$result" | grep "Multi frame detection" | tail -1)
rep=$(echo "$result" | grep "Repeated Fields" | tail -1)
num() { echo "$1" | sed -E "s/.*$2: *([0-9]+).*/\1/"; }
tff=$(num "$multi" TFF); bff=$(num "$multi" BFF); prog=$(num "$multi" Progressive)
rtop=$(num "$rep" Top); rbot=$(num "$rep" Bottom); neither=$(num "$rep" Neither)
total=$((rtop + rbot + neither))

# 3:2 pulldown repeats a field in 2 of every 5 frames (~40%); check it first,
# because telecined frames also look interlaced
if [ "$total" -gt 0 ] && [ $(( (rtop + rbot) * 100 / total )) -ge 15 ]; then
  echo "Telecined content detected - applying IVTC"
  ffmpeg -i "$INPUT" -vf "fieldmatch,decimate" -c:v libx264 -crf 18 output.mp4
elif [ $((tff + bff)) -gt "$prog" ]; then
  echo "Interlaced content detected - applying bwdif"
  ffmpeg -i "$INPUT" -vf "bwdif" -c:v libx264 -crf 18 output.mp4
else
  echo "Progressive content - no deinterlacing needed"
  ffmpeg -i "$INPUT" -c:v libx264 -crf 18 output.mp4
fi
```

---

## Quality Comparison

| Filter | Quality | Speed | Best For |
|--------|---------|-------|----------|
| `yadif` | Good | Fast | General use |
| `bwdif` | Best (motion adaptive, yadif + w3fdif hybrid) | Medium | Quality-focused default |
| `w3fdif` | Good (not motion adaptive) | Medium | Soft, flicker-free output |
| `yadif_cuda` | Good | Very Fast | GPU systems |
| `bwdif_cuda` | Better | Fast | GPU systems |
| `deinterlace_vaapi` | Good | Very Fast | Linux/VAAPI |

---

## Best Practices

1. **Always detect first** - Use `idet` to determine content type
2. **Preserve frame rate** - Use mode 0 for same fps, mode 1 for double
3. **Match field order** - Use auto-detection or specify correct parity
4. **Use GPU when available** - CUDA/VAAPI filters are much faster
5. **IVTC for film content** - Don't deinterlace telecined film, use pullup/fieldmatch
6. **Test on sample** - Check a short segment before processing full video

This guide covers deinterlacing and telecine. For hardware acceleration details, see `hwaccel.md`. For video analysis, see `analysis.md`.
