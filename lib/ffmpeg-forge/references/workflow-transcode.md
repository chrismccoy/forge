# FFmpeg Transcode

## Purpose
Analyze input media and generate optimal FFmpeg commands for transcoding to target format with best quality/size/compatibility balance.

## Workflow

### 1. Analyze Input
Before transcoding, analyze the source file:

```bash
# Get comprehensive media info
ffprobe -v quiet -print_format json -show_format -show_streams INPUT_FILE
```

Key information to extract:
- Video codec, resolution, frame rate, bitrate
- Audio codec, sample rate, channels, bitrate
- Duration and container format

### 2. Determine Target Requirements

Ask user about:
- **Target format**: MP4, WebM, MKV, etc.
- **Use case**: Web delivery, archival, editing, streaming
- **Quality preference**: Best quality, balanced, smaller size
- **Compatibility**: Universal, modern browsers, specific devices
- **Hardware acceleration**: Available GPU (NVIDIA, Intel, AMD)

### 3. Generate Transcode Command

#### Web Delivery (MP4)
```bash
ffmpeg -i INPUT \
  -c:v libx264 -preset medium -crf 23 \
  -c:a aac -b:a 128k \
  -movflags +faststart \
  -pix_fmt yuv420p \
  OUTPUT.mp4
```

#### High Quality Archival
```bash
ffmpeg -i INPUT \
  -c:v libx265 -preset slow -crf 20 \
  -c:a flac \
  -tag:v hvc1 \
  OUTPUT.mkv
```

#### WebM for Web
```bash
ffmpeg -i INPUT \
  -c:v libvpx-vp9 -crf 30 -b:v 0 \
  -c:a libopus -b:a 128k \
  OUTPUT.webm
```

#### With Hardware Acceleration (NVIDIA)
```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i INPUT \
  -c:v h264_nvenc -preset p4 -rc vbr -cq 23 -b:v 0 \
  -c:a aac -b:a 128k \
  OUTPUT.mp4
```

### 4. Quality Settings Reference

| Quality | CRF (x264) | CRF (x265) | CRF (VP9) | Use Case |
|---------|------------|------------|-----------|----------|
| Lossless | 0 | `-x265-params lossless=1` | `-lossless 1` | Editing |
| Very High | 18 | 20 | 15 | Archival |
| High | 20-23 | 22-25 | 23-28 | General |
| Medium | 24-26 | 26-28 | 30-35 | Streaming |
| Low | 28+ | 30+ | 40+ | Preview |

### 5. Preset Reference

| Preset | Speed | Quality | Use Case |
|--------|-------|---------|----------|
| ultrafast | 10x | Lower | Live/preview |
| veryfast | 5x | Low | Quick encode |
| faster | 3x | Medium-low | Draft |
| fast | 2x | Medium | General |
| medium | 1x | **Balanced** | **Default** |
| slow | 0.5x | High | Quality focus |
| slower | 0.3x | Higher | Final render |
| veryslow | 0.1x | Highest | Archival |

### 6. Resolution & Scaling

```bash
# Scale to 1080p (maintain aspect ratio)
-vf "scale=1920:-2"

# Scale to 720p
-vf "scale=-2:720"

# Fit within bounds (force_divisible_by=2 avoids odd widths, e.g. 207x360)
-vf "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2"
```

### 7. Mobile-Compatible Encoding

#### Universal Mobile Preset
```bash
# Plays on all mobile browsers from 2015 onward
# H.264 High Profile Level 4.0, AAC-LC, yuv420p, faststart
ffmpeg -i INPUT \
  -c:v libx264 -profile:v high -level 4.0 \
  -preset medium -crf 23 \
  -pix_fmt yuv420p \
  -c:a aac -profile:a aac_low -b:a 128k -ar 44100 -ac 2 \
  -movflags +faststart \
  OUTPUT_mobile.mp4
```

#### iOS Safari-Safe Preset
```bash
# Ensures compatibility with iOS Safari inline playback
# Note: HTML must include playsinline and muted attributes for autoplay
ffmpeg -i INPUT \
  -c:v libx264 -profile:v high -level 4.0 \
  -preset medium -crf 22 \
  -pix_fmt yuv420p \
  -c:a aac -profile:a aac_low -b:a 128k -ar 44100 -ac 2 \
  -movflags +faststart \
  -tag:v avc1 \
  OUTPUT_ios.mp4
```

#### Low-Bandwidth Mobile Preset
```bash
# Optimized for 3G/4G: 720p, lower bitrate, fast loading
ffmpeg -i INPUT \
  -vf "scale=-2:720" \
  -c:v libx264 -profile:v main -level 3.1 \
  -preset fast -crf 28 \
  -maxrate 1500k -bufsize 3000k \
  -pix_fmt yuv420p \
  -c:a aac -b:a 64k -ar 44100 -ac 1 \
  -movflags +faststart \
  OUTPUT_low_bandwidth.mp4
```

#### Fix Desktop Video for Mobile Playback
```bash
# Quick fix: re-encode desktop video that won't play on mobile
# Common issues: wrong profile, missing faststart, wrong pixel format
ffmpeg -i DESKTOP_VIDEO.mp4 \
  -c:v libx264 -profile:v high -level 4.0 \
  -preset fast -crf 23 \
  -pix_fmt yuv420p \
  -c:a aac -profile:a aac_low -b:a 128k -ar 44100 -ac 2 \
  -movflags +faststart \
  MOBILE_FIXED.mp4

# If only faststart is missing (no re-encode needed):
ffmpeg -i DESKTOP_VIDEO.mp4 -c copy -movflags +faststart MOBILE_FIXED.mp4
```

### 8. Verify Output

```bash
# Compare before/after
ffprobe -v error -show_entries format=duration,size,bit_rate -of default=noprint_wrappers=1 INPUT
ffprobe -v error -show_entries format=duration,size,bit_rate -of default=noprint_wrappers=1 OUTPUT

# Check for decode errors (exit code stays 0 on concealed corruption,
# so test that nothing was printed at -v error)
[ -z "$(ffmpeg -v error -i OUTPUT -f null - 2>&1)" ] && echo "Valid" || echo "Error"
```

## Checklist

- Every option in the command has a known purpose (codec, CRF/bitrate, preset, pixel format, faststart).
- The expected output size is estimated (bitrate x duration) before a long encode.
- The preset is chosen with the encoding-time trade-off in mind (test speed with `-t 30`).
- The target player or platform supports the chosen codec, profile, level and container.
- A faster or higher-quality alternative is noted when the trade-off is unclear.
- The output is checked with the verification commands above.
