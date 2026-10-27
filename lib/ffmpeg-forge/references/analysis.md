## Quick Reference

| Task | Filter | Command Pattern |
|------|--------|-----------------|
| Detect black frames | `blackdetect` | `-vf blackdetect=d=0.5:pic_th=0.98` |
| Detect frozen frames | `freezedetect` | `-vf freezedetect=n=0.003:d=2` |
| Detect blur | `blurdetect` | `-vf blurdetect=low=0.05:high=0.12` |
| Auto crop | `cropdetect` | `-vf cropdetect=24:16:0` |
| Scene changes | `scdet` | `-vf scdet=threshold=10` |
| Quality metrics | `psnr`, `ssim` | `-lavfi "[0:v][1:v]psnr" -f null -` |
| Frame info | `showinfo` | `-vf showinfo` |

---

# FFmpeg Video Analysis Filters

Comprehensive guide to video analysis filters for quality control, automation, and professional workflows.

## Detection Filters

### blackdetect - Detect Black Frames

Detects video sequences that are completely black, useful for finding commercial breaks, scene boundaries, or encoding issues.

```bash
# Basic black detection
ffmpeg -i input.mp4 -vf "blackdetect=d=0.5:pic_th=0.98:pix_th=0.10" -f null -

# More sensitive detection (darker threshold)
ffmpeg -i input.mp4 -vf "blackdetect=d=0.1:pic_th=0.90" -f null -

# Save detection results to log
ffmpeg -i input.mp4 -vf "blackdetect=d=0.5" -f null - 2>&1 | grep blackdetect

# Detect and extract black segments
ffmpeg -i input.mp4 -vf "blackdetect=d=2.0" -f null - 2>&1 | \
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
ffmpeg -i input.mp4 -vf "blackframe=amount=90" -f null - 2>&1 | grep blackframe
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

**Output format:**
```text
[freezedetect @ 0x...] freeze_start: 45.2
[freezedetect @ 0x...] freeze_duration: 3.5
[freezedetect @ 0x...] freeze_end: 48.7
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
- `lavfi.blur` - Blur value (lower = blurrier)

### scdet - Scene Change Detection

Detects scene changes based on frame-to-frame differences.

```bash
# Basic scene detection
ffmpeg -i input.mp4 -vf "scdet=threshold=10:sc_pass=1" -f null -

# More sensitive (detect more scene changes)
ffmpeg -i input.mp4 -vf "scdet=threshold=5" -f null -

# Output scene changes with timestamps
ffmpeg -i input.mp4 -vf "scdet=t=10,metadata=print:file=scenes.txt" -f null -

# Combined with select filter to extract scene thumbnails
ffmpeg -i input.mp4 -vf "scdet=threshold=10,select='gt(scene,0.4)',showinfo" \
  -fps_mode vfr scene_%04d.jpg
```

> **Gotcha (verified on 8.0.1):** if `select` passes zero frames, JPEG output fails with `Non full-range YUV is non-standard` and exit code 234, because the encoder never sees a frame to negotiate range from. Write `.png` instead, or treat that error as "no scenes found" in scripts.

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `threshold` / `t` | Scene change threshold | 10.0 | 0-100 |
| `sc_pass` | Pass scene score to output | 0 | 0-1 |

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

# Detect and apply crop in one command
crop=$(ffmpeg -i input.mp4 -vf "cropdetect=24:16:0" -f null - 2>&1 | \
  grep -oP 'crop=\K[0-9:]+' | tail -1)
ffmpeg -i input.mp4 -vf "crop=$crop" output.mp4

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

# Output detection summary
ffmpeg -i input.mp4 -vf "idet" -f null - 2>&1 | grep -A5 "Repeated Fields"
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

# Get average PSNR only
ffmpeg -i original.mp4 -i encoded.mp4 \
  -lavfi "[0:v][1:v]psnr" -f null - 2>&1 | grep "average"
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

Netflix's VMAF (0-100, higher is better). Needs an FFmpeg built with `--enable-libvmaf` (check: `ffmpeg -hide_banner -filters | grep libvmaf`).

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
# Calculate motion score
ffmpeg -i input.mp4 -vf "vmafmotion" -f null - 2>&1 | grep vmafmotion

# Get average motion
ffmpeg -i input.mp4 -vf "vmafmotion" -f null - 2>&1 | tail -1
```

### signalstats - Video Signal Statistics

Comprehensive signal analysis for broadcast QC.

```bash
# Full signal analysis
ffmpeg -i input.mp4 -vf "signalstats=stat=tout+vrep+brng" -f null -

# Output to file
ffmpeg -i input.mp4 -vf "signalstats,metadata=print:file=stats.txt" -f null -

# Check for broadcast-safe levels
ffmpeg -i input.mp4 -vf "signalstats=stat=brng,metadata=print" -f null - 2>&1 | \
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
- `BRNG` - Out of broadcast range pixel count

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
ffmpeg -i input.mp4 -vf "showinfo" -f null - 2>&1 | grep "pts_time"
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
ffmpeg -i input.mp4 -vf "siti=print_summary=1" -f null - 2>&1 | grep -A11 "SITI Summary" | tail -11

# Per-frame SI/TI to file (lavfi.siti.si / lavfi.siti.ti metadata)
ffmpeg -i input.mp4 -vf "siti,metadata=print:file=siti.txt" -f null -
```

**Output:**
- `SI` - Spatial Information (edge/texture complexity)
- `TI` - Temporal Information (motion activity)

---

## Automation Patterns

Shell automation recipes for batch analysis, structured report generation, threshold checks, and CI-style validation around FFmpeg detection filters, quality metrics, and frame information live in `analysis-automation-patterns.md`. Load that reference when turning ad hoc analysis commands into repeatable pipelines.

---

## Best Practices

1. **Use appropriate thresholds** - Start with defaults, adjust based on content
2. **Sample long videos** - Use `-t` to analyze portions first
3. **Combine filters** - Chain detection filters for comprehensive analysis
4. **Parse output** - Use grep/awk to extract relevant data
5. **Batch processing** - Create scripts for consistent QC workflows
6. **Log results** - Use `metadata=print:file=` to save results

This guide covers video analysis filters. For encoding quality, see `fundamentals.md`. For hardware-accelerated analysis, check GPU filter support in `hwaccel.md`.
