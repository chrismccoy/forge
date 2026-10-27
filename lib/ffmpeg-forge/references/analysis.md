# FFmpeg Video Analysis Filters

Video analysis filters for quality control and automation: detection (black, freeze, blur, scene, crop, interlace), quality metrics (PSNR, SSIM, VMAF), signal statistics, and frame information.

## Contents

- [Quick Reference](#quick-reference)
- [Detection Filters](#detection-filters): blackdetect, blackframe, freezedetect, blurdetect, scdet, cropdetect, idet
- [Quality Metrics](#quality-metrics): psnr, ssim, libvmaf, vmafmotion, signalstats
- [Frame Information](#frame-information): showinfo, siti
- [Automation Patterns](#automation-patterns): QC pipeline script, scene-change frame extraction, quality comparison batch
- [Best Practices](#best-practices)

## Quick Reference

| Task | Filter | Command Pattern |
|------|--------|-----------------|
| Detect black frames | `blackdetect` | `-vf blackdetect=d=0.5:pic_th=0.98` |
| Detect frozen frames | `freezedetect` | `-vf freezedetect=n=0.003:d=2` |
| Detect blur | `blurdetect` | `-vf blurdetect=low=0.05:high=0.12` |
| Auto crop | `cropdetect` | `-vf cropdetect=24:16:0` |
| Scene changes | `scdet` | `-vf scdet=threshold=10` (log lines `lavfi.scd.time`) |
| Quality metrics | `psnr`, `ssim` | `-lavfi "[0:v][1:v]psnr" -f null -` |
| Frame info | `showinfo` | `-vf showinfo` |

Detectors log to stderr. When piping that log into `grep`, add `-hide_banner -nostats`: without `-nostats` the progress line (`frame= ... speed=`) is written with a carriage return and can share a line with a detector message.


## Detection Filters

### blackdetect - Detect Black Frames

Detects video sequences that are completely black, useful for finding commercial breaks, scene boundaries, or encoding issues.

```bash
# Basic black detection
ffmpeg -i input.mp4 -vf "blackdetect=d=0.5:pic_th=0.98:pix_th=0.10" -f null -

# More sensitive detection (darker threshold)
ffmpeg -i input.mp4 -vf "blackdetect=d=0.1:pic_th=0.90" -f null -

# Save detection results to log
ffmpeg -hide_banner -nostats -i input.mp4 -vf "blackdetect=d=0.5" -f null - 2>&1 | grep blackdetect

# Detect and extract black segments (start and end times, one per line)
ffmpeg -hide_banner -nostats -i input.mp4 -vf "blackdetect=d=2.0" -f null - 2>&1 | \
  grep -oP 'black_start:\K[0-9.]+|black_end:\K[0-9.]+'
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `d` | Minimum duration (seconds) | 2.0 | > 0 |
| `pic_th` | Picture black ratio threshold | 0.98 | 0-1 |
| `pix_th` | Pixel black threshold | 0.10 | 0-1 |

**Output format:**
```text
[blackdetect @ 0x...] black_start:10.5 black_end:12.3 black_duration:1.8
```

### blackframe - Detect Nearly Black Frames

Similar to blackdetect but reports individual frames and their blackness amount.

```bash
# Detect frames that are 98% black
ffmpeg -i input.mp4 -vf "blackframe=amount=98:threshold=32" -f null -

# Output includes frame number and percentage
ffmpeg -hide_banner -nostats -i input.mp4 -vf "blackframe=amount=90" -f null - 2>&1 | grep blackframe
# [Parsed_blackframe_0 @ 0x...] frame:50 pblack:100 pts:25600 t:2.000000 type:B last_keyframe:0
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `amount` | Percentage threshold | 98 | 0-100 |
| `threshold` | Pixel brightness threshold | 32 | 0-255 |

### freezedetect - Detect Frozen Frames

Detects sequences where the video appears frozen (repeated frames).

```bash
# Basic freeze detection
ffmpeg -i input.mp4 -vf "freezedetect=n=0.003:d=2" -f null -

# More sensitive (detect shorter freezes)
ffmpeg -i input.mp4 -vf "freezedetect=n=0.001:d=0.5" -f null -

# Very strict (only perfectly identical frames)
ffmpeg -i input.mp4 -vf "freezedetect=n=0:d=1" -f null -
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `n` | Noise tolerance (frame diff) | 0.001 | 0-1 |
| `d` | Minimum freeze duration | 2.0 | > 0 |

**Output format** (FFmpeg 8.0.1; the same keys are attached as frame metadata):
```text
[freezedetect @ 0x...] lavfi.freezedetect.freeze_start: 4
[freezedetect @ 0x...] lavfi.freezedetect.freeze_duration: 3.04
[freezedetect @ 0x...] lavfi.freezedetect.freeze_end: 7.04
```

### blurdetect - Detect Blurry Frames

Detects frames that are out of focus or motion blurred.

```bash
# Basic blur detection
ffmpeg -i input.mp4 -vf "blurdetect=low=0.05:high=0.12:radius=50" -f null -

# More sensitive detection
ffmpeg -i input.mp4 -vf "blurdetect=low=0.03:high=0.1" -f null -

# Output blur values per frame
ffmpeg -i input.mp4 -vf "blurdetect,metadata=print:file=blur.txt" -f null -

# Average over the file (printed at the end)
ffmpeg -hide_banner -nostats -i input.mp4 -vf blurdetect -f null - 2>&1 | grep -o 'blur mean: .*'
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `low` | Low edge threshold (fraction of full scale) | 0.0588 (15/255) | 0-1 |
| `high` | High edge threshold (fraction of full scale) | 0.1176 (30/255) | 0-1 |
| `radius` | Search radius | 50 | 1-100 |
| `block_pct` | Block percentage | 80 | 1-100 |
| `block_width` | Block width | -1 (whole frame) | -1 or > 0 |
| `block_height` | Block height | -1 (whole frame) | -1 or > 0 |
| `planes` | Planes to analyze | 1 | 0-15 |

**Output metadata:**
- `lavfi.blur` - Blur value (**higher = blurrier**). Measured: testsrc2 4.48, the same with `gblur=sigma=4` 12.87.
- Flat frames (black, solid colour) have no edges and give `nan`. One such frame makes the end-of-file `blur mean` print `-nan`; exclude flat sections or average the per-frame values that are numbers.

### scdet - Scene Change Detection

Detects scene changes based on frame-to-frame differences.

```bash
# Basic scene detection (each cut is logged: lavfi.scd.score: 31.337, lavfi.scd.time: 2)
ffmpeg -i input.mp4 -vf "scdet=threshold=10" -f null -

# More sensitive (detect more scene changes)
ffmpeg -i input.mp4 -vf "scdet=threshold=5" -f null -

# Write only the scene changes with timestamps to a file
# (metadata=print alone writes mafd/score for EVERY frame)
ffmpeg -i input.mp4 -vf "scdet=t=10,metadata=select:key=lavfi.scd.time,metadata=print:file=scenes.txt" -f null -

# Same with sc_pass: scdet itself drops all non-cut frames
ffmpeg -i input.mp4 -vf "scdet=t=10:sc_pass=1,metadata=print:file=scenes.txt" -f null -

# Extract one thumbnail per cut: scdet with sc_pass passes only the cut frames
ffmpeg -i input.mp4 -vf "scdet=threshold=10:sc_pass=1,showinfo" \
  -fps_mode vfr scene_%04d.png

# Alternative: select's own scene score (0-1 scale, independent of scdet)
ffmpeg -i input.mp4 -vf "select='gt(scene,0.4)',showinfo" \
  -fps_mode vfr scene_%04d.png
```

> **Gotcha (verified on 8.0.1):** if no frame passes (`select` or `sc_pass`), JPEG output fails with `Non full-range YUV is non-standard` and exit code 234, because the encoder never sees a frame to negotiate range from. Write `.png` instead, or treat that error as "no scenes found" in scripts.

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `threshold` / `t` | Scene change threshold | 10.0 | 0-100 |
| `sc_pass` / `s` | Output only scene-change frames (drops all others) | 0 | 0-1 |

**Output metadata:**
- `lavfi.scd.score` - Scene change score (0-100, same scale as `threshold`)
- `lavfi.scd.mafd` - Mean absolute frame difference
- `lavfi.scd.time` - Timestamp of scene change

### cropdetect - Auto Crop Detection

Automatically detects optimal crop values to remove black borders.

```bash
# Basic crop detection
ffmpeg -i input.mp4 -vf "cropdetect=24:16:0" -f null -

# More aggressive detection (lower threshold)
ffmpeg -i input.mp4 -vf "cropdetect=16:2:0" -f null -

# Detect, then apply the last reported crop
crop=$(ffmpeg -hide_banner -nostats -i input.mp4 -vf "cropdetect=24:16:0" -f null - 2>&1 | \
  grep -oP 'crop=\K[0-9]+:[0-9]+:[0-9]+:[0-9]+' | tail -1)
[ -n "$crop" ] || { echo "cropdetect found nothing" >&2; exit 1; }
ffmpeg -n -i input.mp4 -vf "crop=$crop" -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a copy output.mp4

# Detect letterbox dimensions
ffmpeg -i input.mp4 -vf "cropdetect=round=2:reset=0" -f null - 2>&1 | grep crop
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `limit` | Threshold for black pixels (values <= 1 are a fraction of full scale; larger values are absolute, e.g. 24) | 0.0941 (24/255) | 0-65535 |
| `round` | Round to nearest multiple | 16 | >= 0 |
| `reset` | Reset counter (frames) | 0 | >= 0 |
| `skip` | Skip initial frames | 2 | >= 0 |

**Output format:**
```text
[cropdetect @ 0x...] x1:0 x2:1919 y1:140 y2:939 w:1920 h:800 x:0 y:140 crop=1920:800:0:140
```

### idet - Interlace Detection

Detects whether video is interlaced and identifies field order.

```bash
# Basic interlace detection
ffmpeg -i input.mp4 -vf "idet" -frames:v 500 -f null -

# Output detection summary (last copy = real counts)
ffmpeg -hide_banner -nostats -i input.mp4 -vf "idet" -f null - 2>&1 | \
  grep -E "Repeated Fields|frame detection" | tail -3
```

**Output includes** (the summary is printed twice; the first copy is all
zeros, use the last one):
- `Single frame detection: TFF / BFF / Progressive / Undetermined` - each
  frame classified on its own
- `Multi frame detection: TFF / BFF / Progressive / Undetermined` - the same
  classification smoothed over neighbouring frames (more reliable)
- `Repeated Fields: Neither / Top / Bottom` - frames whose top or bottom field
  repeats the previous frame (a high share, ~40%, indicates 3:2 pulldown)

Decide by comparing counts (TFF+BFF vs Progressive), not by checking for
non-zero values: progressive sources often show a few TFF/BFF frames.

---

## Quality Metrics

### psnr - Peak Signal-to-Noise Ratio

Compares two videos and outputs PSNR quality metric.

```bash
# Compare original vs encoded
ffmpeg -i original.mp4 -i encoded.mp4 \
  -lavfi "[0:v][1:v]psnr" -f null -

# Output PSNR per frame to file
ffmpeg -i original.mp4 -i encoded.mp4 \
  -lavfi "[0:v][1:v]psnr=stats_file=psnr.log" -f null -

# Get average PSNR only ("inf" when the inputs are identical)
ffmpeg -hide_banner -nostats -i original.mp4 -i encoded.mp4 \
  -lavfi "[0:v][1:v]psnr" -f null - 2>&1 | grep -oE 'average:([0-9.]+|inf)'
```

**Output format:**
```text
[Parsed_psnr_0 @ 0x...] PSNR y:45.123 u:48.456 v:49.789 average:46.234 min:35.123 max:inf
```

**Quality guidelines:**
| PSNR (dB) | Quality |
|-----------|---------|
| > 40 | Excellent (indistinguishable) |
| 35-40 | Good |
| 30-35 | Fair |
| < 30 | Poor |

### ssim - Structural Similarity Index

More perceptually accurate than PSNR for quality comparison.

```bash
# Compare original vs encoded
ffmpeg -i original.mp4 -i encoded.mp4 \
  -lavfi "[0:v][1:v]ssim" -f null -

# Output SSIM per frame to file
ffmpeg -i original.mp4 -i encoded.mp4 \
  -lavfi "[0:v][1:v]ssim=stats_file=ssim.log" -f null -
```

**Output format:**
```text
[Parsed_ssim_0 @ 0x...] SSIM Y:0.987 (18.87) U:0.992 (20.97) V:0.993 (21.55) All:0.989 (19.59)
```

**Quality guidelines:**
| SSIM | Quality |
|------|---------|
| > 0.98 | Excellent |
| 0.95-0.98 | Good |
| 0.90-0.95 | Fair |
| < 0.90 | Poor |

### libvmaf - VMAF Perceptual Quality Score

Netflix's VMAF (0-100, higher is better). Needs an FFmpeg built with `--enable-libvmaf` (check: `ffmpeg -hide_banner -filters | grep libvmaf`). The commands in this section are help/source-checked only: the test build has no libvmaf.

```bash
# Distorted (encoded) input FIRST, reference (original) SECOND
ffmpeg -i distorted.mp4 -i reference.mp4 \
  -lavfi "[0:v]setpts=PTS-STARTPTS[d];[1:v]setpts=PTS-STARTPTS[r];[d][r]libvmaf=log_fmt=json:log_path=vmaf.json:n_threads=4" \
  -f null -

# Distorted at a lower resolution: scale it to the reference size (and the same
# pixel format; libvmaf rejects inputs whose width, height or pix_fmt differ)
ffmpeg -i distorted_720p.mp4 -i reference_1080p.mp4 \
  -lavfi "[0:v]scale=1920:1080:flags=bicubic,format=yuv420p,setpts=PTS-STARTPTS[d];[1:v]format=yuv420p,setpts=PTS-STARTPTS[r];[d][r]libvmaf=log_fmt=json:log_path=vmaf.json:n_threads=4" \
  -f null -

# 4K content: use the 4K model (default is model=version=vmaf_v0.6.1)
ffmpeg -i distorted_4k.mp4 -i reference_4k.mp4 \
  -lavfi "[0:v]setpts=PTS-STARTPTS[d];[1:v]setpts=PTS-STARTPTS[r];[d][r]libvmaf=model=version=vmaf_4k_v0.6.1:log_fmt=json:log_path=vmaf.json:n_threads=4" \
  -f null -
```

**Output format:** the pooled score is printed at the end; per-frame scores go to `log_path` (`log_fmt` is `xml` by default; also `json`, `csv`, `sub`).
```text
[Parsed_libvmaf_2 @ 0x...] VMAF score: 93.412345
```

**Notes:** `n_subsample=N` scores every Nth frame for speed. Both inputs need the same frame count and frame rate; trim or `fps=` them first if they differ.

### vmafmotion - VMAF Motion Score

Calculates motion activity score used by VMAF.

```bash
# Calculate motion score (per-frame values: vmafmotion=stats_file=motion.log)
ffmpeg -i input.mp4 -vf "vmafmotion" -f null -

# Get average motion: the line is "[Parsed_vmafmotion_0 @ ...] VMAF Motion avg: 1.449"
ffmpeg -hide_banner -nostats -i input.mp4 -vf "vmafmotion" -f null - 2>&1 | \
  grep -oE 'VMAF Motion avg: [0-9.]+'
```

### signalstats - Video Signal Statistics

Comprehensive signal analysis for broadcast QC.

```bash
# Full signal analysis
ffmpeg -i input.mp4 -vf "signalstats=stat=tout+vrep+brng" -f null -

# Output to file
ffmpeg -i input.mp4 -vf "signalstats,metadata=print:file=stats.txt" -f null -

# Check for broadcast-safe levels
ffmpeg -hide_banner -nostats -i input.mp4 -vf "signalstats=stat=brng,metadata=print" -f null - 2>&1 | \
  grep "lavfi.signalstats.BRNG"
```

**Statistics available:**
| Stat | Description |
|------|-------------|
| `tout` | Temporal outliers |
| `vrep` | Vertical line repetition |
| `brng` | Broadcast range violations |

**Output metadata includes:**
- `YMIN`, `YMAX` - Luma range
- `YAVG` - Average luma
- `UMIN`, `UMAX`, `VMIN`, `VMAX` - Chroma range
- `SATMIN`, `SATMAX`, `SATAVG` - Saturation
- `HUEAVG` - Average hue
- `BRNG` - Fraction of pixels outside broadcast range (0-1, e.g. `0.0087`; only with `stat=brng`)

---

## Frame Information

### showinfo - Display Frame Information

Outputs detailed information about each frame.

```bash
# Show all frame info
ffmpeg -i input.mp4 -vf "showinfo" -f null -

# Show specific frames only
ffmpeg -i input.mp4 -vf "select='eq(n,0)+eq(n,100)',showinfo" -f null -

# Parse specific information
ffmpeg -hide_banner -nostats -i input.mp4 -vf "showinfo" -f null - 2>&1 | grep -o "n: *[0-9]* pts: *[0-9]* pts_time:[0-9.]*"
```

**Output includes:**
```text
[Parsed_showinfo_0 @ 0x...] n:   0 pts:      0 pts_time:0       duration:   1001
 duration_time:0.0417083 fmt:yuv420p cl:left sar:1/1 s:1920x1080 i:P iskey:1
 type:I checksum:12345678 plane_checksum:[AAAAAAAA BBBBBBBB CCCCCCCC]
```

**Fields:**
- `n` - Frame number
- `pts` - Presentation timestamp
- `pts_time` - PTS in seconds
- `duration` - Frame duration
- `fmt` - Pixel format
- `s` - Size (resolution)
- `i` - Interlaced (P=progressive, T=top, B=bottom)
- `iskey` - Is keyframe
- `type` - Frame type (I/P/B)

### siti - Spatial and Temporal Information

ITU-T P.910 compliant SI/TI calculation.

```bash
# Calculate SI/TI and print the summary (siti prints nothing by default;
# ffmpeg logs the summary twice, the last block is the real one)
ffmpeg -hide_banner -nostats -i input.mp4 -vf "siti=print_summary=1" -f null - 2>&1 | grep -A11 "SITI Summary" | tail -11

# Per-frame SI/TI to file (lavfi.siti.si / lavfi.siti.ti metadata)
ffmpeg -i input.mp4 -vf "siti,metadata=print:file=siti.txt" -f null -
```

**Output:**
- `SI` - Spatial Information (edge/texture complexity)
- `TI` - Temporal Information (motion activity)

---

## Automation Patterns

Repeatable QC pipelines, scene extraction, and batch quality comparison built on the filters above.

### QC Pipeline Script

```bash
#!/bin/bash
# qc.sh - video QC: black, freeze, scene cuts, crop, interlace, broadcast range
INPUT="$1"
OUTPUT_DIR="qc_results"
[ -f "$INPUT" ] || { echo "usage: $0 VIDEO" >&2; exit 1; }
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of csv=p=0 "$INPUT" |
  grep -q . || { echo "No video stream in $INPUT" >&2; exit 1; }
mkdir -p "$OUTPUT_DIR"

# Run ffmpeg on the input; the log goes to stdout (no banner, no progress lines)
ff() { ffmpeg -hide_banner -nostdin -nostats -i "$INPUT" "$@" -f null - 2>&1; }

echo "Analyzing: $INPUT"

# 1. Black segments
ff -vf "blackdetect=d=0.5" | grep -o 'black_start.*' > "$OUTPUT_DIR/black_frames.txt"

# 2. Freezes
ff -vf "freezedetect=n=0.003:d=2" | grep -o 'lavfi.freezedetect.*' > "$OUTPUT_DIR/frozen_frames.txt"

# 3. Scene cuts only (score and time per cut)
ff -vf "scdet=threshold=10" | grep -o 'lavfi.scd.score.*' > "$OUTPUT_DIR/scenes.txt"

# 4. Crop (last estimate)
ff -vf "cropdetect=24:16:0" | grep -o 'crop=[0-9:]*' | tail -1 > "$OUTPUT_DIR/crop.txt"

# 5. Interlace (idet prints an all-zero summary first; keep the final one)
ff -vf "idet" -frames:v 500 | grep -oE '(Repeated Fields|[A-Za-z]+ frame detection):.*' |
  tail -3 > "$OUTPUT_DIR/interlace.txt"

# 6. Broadcast range: frames with more than 1% of pixels out of range
ff -vf "signalstats=stat=brng,metadata=print" |
  awk -F= '/lavfi.signalstats.BRNG/ { n++; if ($2 > 0.01) bad++ }
           END { printf "frames: %d, BRNG > 1%%: %d\n", n, bad }' > "$OUTPUT_DIR/signal.txt"

# A run that analyzed nothing (decode failure) leaves no idet counts
grep -q 'TFF' "$OUTPUT_DIR/interlace.txt" || { echo "Analysis failed for $INPUT" >&2; exit 1; }

echo "QC analysis complete. Results in $OUTPUT_DIR/"
for f in "$OUTPUT_DIR"/*.txt; do echo "== $f"; cat "$f"; done
```

### Extract Frames at Scene Changes

```bash
# One frame per cut: scdet with sc_pass passes only the cut frames.
# -frame_pts 1 numbers files by the frame timestamp in output time-base units
# (the frame index for constant-rate input: scene_00000050.png = frame 50), not 1, 2, 3.
# PNG output: with zero cuts a JPEG encoder fails with "Non full-range YUV" (exit 234).
ffmpeg -n -i input.mp4 \
  -vf "scdet=threshold=10:sc_pass=1" \
  -fps_mode vfr \
  -frame_pts 1 \
  scene_%08d.png

# Log timestamps alongside extracted frames (image2 does not expand %{pts} in filenames)
ffmpeg -hide_banner -nostats -n -i input.mp4 \
  -vf "scdet=threshold=10:sc_pass=1,showinfo" \
  -fps_mode vfr \
  scene_%04d.png 2>&1 | grep -o 'pts_time:[0-9.]*'
```

### Quality Comparison Batch

```bash
#!/bin/bash
# Compare multiple encodes against a reference
REFERENCE="reference.mp4"
[ -f "$REFERENCE" ] || { echo "Missing $REFERENCE" >&2; exit 1; }

for encoded in encode_*.mp4; do
  [ -f "$encoded" ] || continue
  echo "Comparing: $encoded"

  # PSNR ("inf" when the two inputs are identical)
  psnr=$(ffmpeg -hide_banner -nostdin -nostats -i "$encoded" -i "$REFERENCE" \
    -lavfi "[0:v][1:v]psnr" -f null - 2>&1 | grep -oE 'average:([0-9.]+|inf)' | cut -d: -f2)

  # SSIM
  ssim=$(ffmpeg -hide_banner -nostdin -nostats -i "$encoded" -i "$REFERENCE" \
    -lavfi "[0:v][1:v]ssim" -f null - 2>&1 | grep -oE 'All:[0-9.]+' | cut -d: -f2)

  if [ -z "$psnr" ] || [ -z "$ssim" ]; then
    echo "  FAILED (could not compare)" >&2
  else
    echo "  PSNR: $psnr dB, SSIM: $ssim"
  fi
done
```

Both inputs need the same resolution and frame count; scale or trim first if they differ (see the libvmaf notes above).

---

## Best Practices

1. **Use appropriate thresholds** - Start with defaults, adjust based on content
2. **Sample long videos** - Use `-t` to analyze portions first
3. **Combine filters** - Chain detection filters for comprehensive analysis
4. **Parse output** - Use grep/awk to extract relevant data; add `-hide_banner -nostats` so progress lines do not mix into the log
5. **Batch processing** - Create scripts for consistent QC workflows
6. **Log results** - Use `metadata=print:file=` to save results

Audio measurement (astats, ebur128, volumedetect) is in `audio-measurement.md`. Encoder quality settings are in `fundamentals-common-operations.md`; GPU filter support is in `hwaccel.md`.
