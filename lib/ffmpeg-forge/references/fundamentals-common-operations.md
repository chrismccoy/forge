# Common FFmpeg Operations

Transcode questions and checklist, plus recipes for conversion, scaling, trimming, concatenation, target-size encodes, intermediates, audio, subtitles, images, and device-targeted output.

## Contents

- [Transcode Procedure](#transcode-procedure)
- [Quality and Preset Reference](#quality-and-preset-reference)
- [Format Conversion](#format-conversion)
- [Resolution & Scaling](#resolution--scaling)
- [Trimming & Splitting](#trimming--splitting)
- [Concatenation](#concatenation)
- [Target File Size (Two-Pass)](#target-file-size-two-pass)
- [ProRes / DNxHR Intermediates](#prores--dnxhr-intermediates)
- [Audio Operations](#audio-operations)
- [Subtitles](#subtitles)
- [Speech-to-Text](#speech-to-text)
- [Image Operations](#image-operations)
- [Output Optimization](#output-optimization)
- [Verify Output](#verify-output)

## Transcode Procedure

The core workflow (probe, remux or transcode, test a slice, verify) is in SKILL.md. Two additions for transcodes:

**Ask the user** when the request leaves these open:

- **Target format**: MP4, WebM, MKV, MOV.
- **Use case**: web delivery, archival, editing, streaming.
- **Quality preference**: best quality, balanced, smaller size, or a hard size limit (then use [two-pass](#target-file-size-two-pass)).
- **Compatibility**: universal, modern browsers, specific devices.
- **Hardware acceleration**: available GPU (NVIDIA, Intel, AMD, Apple).

**Checklist before a long encode:**

- Every option in the command has a known purpose (codec, CRF/bitrate, preset, pixel format, faststart).
- The expected output size is estimated (bitrate x duration).
- The preset is chosen with the encoding-time trade-off in mind (test speed with `-t 30`).
- The target player or platform supports the chosen codec, profile, level and container.
- A faster or higher-quality alternative is noted when the trade-off is unclear.

## Quality and Preset Reference

### CRF by Quality Level

| Quality | x264 `-crf` | x265 `-crf` | SVT-AV1 `-crf` | VP9 `-crf` (+ `-b:v 0`) | Use Case |
|---------|------------|------------|-----------------|-------------------------|----------|
| Lossless | 0 (`-qp 0`) | `-x265-params lossless=1` | - | `-lossless 1` | Editing |
| Very High | 18 | 20-22 | 24-28 | 24-28 | Archival |
| High (default range) | 20-23 | 24-28 | 30-35 | 30-35 (31 default) | General |
| Medium | 24-26 | 28-30 | 36-40 | 36-40 | Streaming |
| Low | 28+ | 30+ | 45+ | 40+ | Preview |

The default ranges match the SKILL.md Quality Quick Reference (x264 20-23, x265 24-28, SVT-AV1 30-35, VP9 31). For NVENC, the equivalent default is `-preset p5 -tune hq -rc vbr -cq 23 -b:v 0` (see `hwaccel-nvidia-nvenc.md`).

### x264 / x265 Presets

| Preset | Speed (relative, approximate) | Quality | Use Case |
|--------|-------|---------|----------|
| ultrafast | 10x | Lower | Live/preview |
| veryfast | 5x | Low | Quick encode, live streaming |
| faster | 3x | Medium-low | Draft |
| fast | 2x | Medium | General |
| medium | 1x | **Balanced** | **Default** |
| slow | 0.5x | High | Quality focus |
| slower | 0.3x | Higher | Final render |
| veryslow | 0.1x | Highest | Archival |

The speed column is a rough guide; measure on the real source with `scripts/benchmark-encoding.sh`. SVT-AV1 uses numeric presets 0-13 (lower is slower and better; 6-8 is the usual range). NVENC uses p1-p7 (p5 recommended).

## Format Conversion

```bash
# MP4 to WebM
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 31 -b:v 0 -row-mt 1 -pix_fmt yuv420p -c:a libopus output.webm

# MKV to MP4 (no re-encoding). Without -map only one audio stream is kept and
# SRT/ASS subtitles are dropped; map them all and convert text subtitles to
# mov_text (bitmap subtitles such as PGS cannot go into MP4: drop them with -sn)
ffmpeg -i input.mkv -map 0:v -map 0:a -map 0:s? -c copy -c:s mov_text output.mp4

# AVI to MP4 with H.265
ffmpeg -i input.avi -c:v libx265 -crf 26 -tag:v hvc1 -c:a aac output.mp4

# GIF to MP4 (GIFs often have odd dimensions; round them down to even for yuv420p)
ffmpeg -i input.gif -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -movflags +faststart -pix_fmt yuv420p output.mp4

# MP4 to GIF (optimized)
ffmpeg -i input.mp4 -vf "fps=15,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output.gif
```

## Resolution & Scaling

```bash
# Scale to 1920 wide, keep aspect ratio (1920x1080 only for 16:9 sources)
ffmpeg -i input.mp4 -vf "scale=1920:-2" output.mp4

# Scale to 720p
ffmpeg -i input.mp4 -vf "scale=-2:720" output.mp4

# Scale to fit within bounds (force_divisible_by=2 keeps dimensions even for 4:2:0 encoders)
ffmpeg -i input.mp4 -vf "scale='min(1920,iw)':'min(1080,ih)':force_original_aspect_ratio=decrease:force_divisible_by=2" output.mp4

# Scale with padding (letterbox)
ffmpeg -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" output.mp4
```

## Trimming & Splitting

```bash
# Extract segment (fast seek; with -c copy the cut starts at the keyframe before 1:00)
ffmpeg -ss 00:01:00 -i input.mp4 -t 00:00:30 -c copy output.mp4

# Extract from timestamp to end
ffmpeg -ss 00:05:00 -i input.mp4 -c copy output.mp4

# Extract first 10 seconds
ffmpeg -i input.mp4 -t 10 -c copy output.mp4

# Split into segments
# (-reset_timestamps 1 makes each segment start at 0; without it segment N
# starts at N*60 s)
ffmpeg -i input.mp4 -c copy -map 0 -segment_time 60 -f segment -reset_timestamps 1 output_%03d.mp4

# Frame-accurate trim (re-encode; -ss before -i is fast and still exact when re-encoding)
ffmpeg -ss 00:01:00 -i input.mp4 -t 00:00:30 -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac output.mp4
```

More segment muxer options: [Segment Muxer](streaming.md#segment-muxer).

## Concatenation

```bash
# Create file list
echo "file 'part1.mp4'" > list.txt
echo "file 'part2.mp4'" >> list.txt
echo "file 'part3.mp4'" >> list.txt

# Concatenate (same codecs)
ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4

# Concatenate with re-encoding
ffmpeg -f concat -safe 0 -i list.txt -c:v libx264 -c:a aac output.mp4
```

Clips with different resolutions, frame rates or codecs need the `concat` filter instead (see `filter-complex.md`).

## Target File Size (Two-Pass)

Use two-pass only when the file must hit a size; otherwise CRF is better.

`scripts/encode-to-size.sh <in> <out> <MB> [x264|x265] [audio_kbps]` does the whole job: it computes the video bitrate from the duration, subtracts the audio and about 2 % mux overhead, refuses bitrates too low to be useful, runs both passes with the log in a temporary directory, and checks the result against the target. When the file overshoots, it reruns pass 2 once at a bitrate scaled down by the miss. Return codes: 0 = within the target, 1 = failed, 2 = written but still over (very small targets on noisy footage can hit the encoder's floor).

```bash
# 25 MB H.264 file with 128 kb/s audio
scripts/encode-to-size.sh input.mp4 output.mp4 25
# 10 MB HEVC file with 96 kb/s audio
scripts/encode-to-size.sh input.mp4 output.mp4 10 x265 96
```

The manual equivalent: video bitrate (kb/s) = target size in kbit / duration - audio bitrate.

```bash
TARGET_MB=50          # 1 MB = 1,000,000 bytes = 8000 kbit
AUDIO_K=128
DUR=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 input.mp4)
VIDEO_K=$(echo "$TARGET_MB*8000/$DUR - $AUDIO_K" | bc)

# Keep the pass log in a temp dir (default ffmpeg2pass-0.log lands in the cwd
# and parallel jobs would overwrite each other's logs)
PASSDIR=$(mktemp -d)

# x264: pass 1 analyses only (no audio, output discarded), pass 2 encodes
ffmpeg -y -i input.mp4 -c:v libx264 -preset medium -b:v ${VIDEO_K}k \
  -pass 1 -passlogfile "$PASSDIR/x264" -an -f null /dev/null
ffmpeg -i input.mp4 -c:v libx264 -preset medium -b:v ${VIDEO_K}k \
  -pass 2 -passlogfile "$PASSDIR/x264" -c:a aac -b:a ${AUDIO_K}k output.mp4

# x265: same idea, pass settings go through -x265-params
ffmpeg -y -i input.mp4 -c:v libx265 -preset medium -b:v ${VIDEO_K}k \
  -x265-params pass=1:stats="$PASSDIR/x265.log" -an -f null /dev/null
ffmpeg -i input.mp4 -c:v libx265 -preset medium -b:v ${VIDEO_K}k \
  -x265-params pass=2:stats="$PASSDIR/x265.log" -tag:v hvc1 \
  -c:a aac -b:a ${AUDIO_K}k output_hevc.mp4

rm -rf "$PASSDIR"
```

Use the same preset, bitrate and filters in both passes. On Windows use `NUL` instead of `/dev/null`. Expect the result within a few percent of the target (container overhead and audio VBR account for the rest). Very short or noise-heavy clips can overshoot by 20-30 %; check the size and rerun with a lower bitrate if it must fit.

## ProRes / DNxHR Intermediates

Intermediate codecs are intra-only, so editors scrub and cut them without decoding long GOPs. Files are large (ProRes 422 HQ at 1080p30 is about 220 Mb/s). Use MOV for ProRes and MOV or MXF for DNxHR, with uncompressed PCM audio.

### ProRes (prores_ks)

| `-profile:v` | Name | Pixel format |
|---|---|---|
| 0 | 422 Proxy | `yuv422p10le` |
| 1 | 422 LT | `yuv422p10le` |
| 2 | 422 (standard) | `yuv422p10le` |
| 3 | 422 HQ | `yuv422p10le` |
| 4 | 4444 | `yuva444p10le` (alpha optional) |
| 5 | 4444 XQ | `yuva444p10le` |

```bash
# ProRes 422 HQ, 10-bit 4:2:2, 24-bit PCM audio
ffmpeg -i input.mp4 -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le \
  -c:a pcm_s24le output.mov

# ProRes 4444 with alpha (from a PNG sequence or a qtrle/png MOV with alpha)
ffmpeg -framerate 30 -i frame_%04d.png -c:v prores_ks -profile:v 4 -pix_fmt yuva444p10le output.mov
```

The `-profile:v` names `proxy`, `lt`, `standard`, `hq`, `4444`, `4444xq` work too. ffprobe reports 4444 files as `yuva444p12le` (the decoder's output format), even when encoded from 10-bit input. `prores_aw` is a faster, less configurable alternative encoder.

### DNxHR (dnxhd encoder)

| `-profile:v` | Bit depth / sampling | Pixel format |
|---|---|---|
| `dnxhr_lb` | 8-bit 4:2:2, low bandwidth (offline) | `yuv422p` |
| `dnxhr_sq` | 8-bit 4:2:2, standard | `yuv422p` |
| `dnxhr_hq` | 8-bit 4:2:2, high quality | `yuv422p` |
| `dnxhr_hqx` | 10-bit 4:2:2 | `yuv422p10le` |
| `dnxhr_444` | 10-bit 4:4:4 | `yuv444p10le` |

```bash
# DNxHR HQ (8-bit) in MOV
ffmpeg -i input.mp4 -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p \
  -c:a pcm_s16le output.mov

# DNxHR HQX (10-bit) in MXF
ffmpeg -i input.mp4 -c:v dnxhd -profile:v dnxhr_hqx -pix_fmt yuv422p10le \
  -c:a pcm_s24le output.mxf
```

The pixel format must match the profile: `dnxhr_hqx` with 8-bit `yuv422p` fails (exit code 234). DNxHR works at any resolution and sets its own bitrate from the profile. The older DNxHD profiles (`-profile:v dnxhd`) only accept specific resolution, frame rate and bitrate combinations; check `ffmpeg -h encoder=dnxhd`.

## Audio Operations

```bash
# Extract audio
ffmpeg -i input.mp4 -vn -c:a copy output.aac
ffmpeg -i input.mp4 -vn -c:a libmp3lame -b:a 320k output.mp3

# Replace the audio, or add audio to a video that has none (same command).
# The -map options are required: without them, if video.mp4 already has audio,
# ffmpeg keeps that track and ignores audio.mp3. -shortest stops at the shorter
# of the video and the new audio.
ffmpeg -i video.mp4 -i audio.mp3 -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest output.mp4

# Remove audio
ffmpeg -i input.mp4 -an -c:v copy output.mp4

# Adjust volume
ffmpeg -i input.mp4 -c:v copy -af "volume=1.5" output.mp4
ffmpeg -i input.mp4 -c:v copy -af "volume=6dB" output.mp4

# Normalize loudness for a deliverable (two-pass EBU R128; checks the result)
scripts/loudnorm-2pass.sh input.mp4 output.mp4 -16 -1.5

# Quick single-pass preview only (-ar 48000 because loudnorm upsamples to 192 kHz)
ffmpeg -i input.mp4 -c:v copy -af loudnorm=I=-16:TP=-1.5:LRA=11 -ar 48000 preview.mp4
```

Codecs, bitrates and loudness targets: `audio.md`; processing chains: `audio-chains.md`.

## Subtitles

```bash
# Burn subtitles (hardcode)
ffmpeg -i input.mp4 -vf "subtitles=subs.srt" -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a copy output.mp4

# Add subtitle track
ffmpeg -i input.mp4 -i subs.srt -c copy -c:s mov_text output.mp4

# Extract subtitles
ffmpeg -i input.mkv -map 0:s:0 output.srt
```

Styling, positioning, path escaping and format conversion: `captions.md`.

## Speech-to-Text

FFmpeg 8.0+ can transcribe speech with the `whisper` filter (build needs `--enable-whisper` and a GGML model). Commands, models, VAD, live transcription and burn-in: `whisper.md`. `scripts/generate-whisper-subtitles.sh <video> [model] [language]` wraps it.

## Image Operations

```bash
# Video to images
ffmpeg -i input.mp4 -vf "fps=1" frame_%04d.png

# Images to video
ffmpeg -framerate 30 -i frame_%04d.png -c:v libx264 -pix_fmt yuv420p output.mp4

# Extract single frame
ffmpeg -ss 00:00:10 -i input.mp4 -vframes 1 -update 1 thumbnail.jpg

# Create video from single image
ffmpeg -loop 1 -i image.jpg -c:v libx264 -t 10 -vf "scale=out_range=tv,format=yuv420p" output.mp4
```

Thumbnails, contact sheets and frame selection: `filters-basics.md`.

## Output Optimization

### Web Delivery

```bash
# MP4 for web (faststart)
ffmpeg -i input.mp4 -c:v libx264 -crf 23 -preset medium -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart output.mp4

# WebM for web
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 31 -b:v 0 -row-mt 1 -pix_fmt yuv420p -c:a libopus -b:a 128k output.webm
```

### High-Quality Archival

```bash
ffmpeg -i INPUT \
  -c:v libx265 -preset slow -crf 22 \
  -c:a flac \
  OUTPUT.mkv
# (-tag:v hvc1 matters only in MP4/MOV; Matroska has no fourcc field)
```

### With Hardware Acceleration (NVIDIA)

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i INPUT \
  -c:v h264_nvenc -preset p5 -tune hq -rc vbr -cq 23 -b:v 0 \
  -c:a aac -b:a 128k \
  OUTPUT.mp4
```

Other vendors: `hwaccel.md`.

### iOS/Apple Compatibility

```bash
# H.265 with hvc1 tag (required for Apple)
ffmpeg -i input.mp4 -c:v libx265 -crf 26 -tag:v hvc1 -pix_fmt yuv420p -c:a aac output.mp4

# Baseline profile for older iOS. Baseline needs 4:2:0 8-bit, and level 3.1 allows
# up to 854x480 or 1280x720 at 30 fps; x264 writes the requested level even when
# the stream exceeds it, so scale down first
ffmpeg -i input.mp4 -vf "scale=-2:'min(480,ih)'" -c:v libx264 -profile:v baseline -level 3.1 -pix_fmt yuv420p -c:a aac output.mp4
```

### Android Compatibility

```bash
# Widely compatible H.264 (level 4.0 covers up to 1080p30; for 1080p60 use -level 4.2)
ffmpeg -i input.mp4 -vf "scale=-2:'min(1080,ih)'" -c:v libx264 -profile:v main -level 4.0 -pix_fmt yuv420p -c:a aac output.mp4
```

### Universal Mobile / iOS Safari

```bash
# Plays on mobile browsers from 2015 onward, including iOS Safari inline playback.
# H.264 High Profile Level 4.0, AAC-LC, yuv420p, faststart.
# Level 4.0 covers up to 1080p30, so larger sources are scaled down to 1080p
# (smaller ones are not upscaled) and faster ones capped at 30 fps.
ffmpeg -i INPUT \
  -vf "scale=-2:'min(1080,ih)',fps='min(30,source_fps)'" \
  -c:v libx264 -profile:v high -level 4.0 \
  -preset medium -crf 23 \
  -pix_fmt yuv420p \
  -c:a aac -profile:a aac_low -b:a 128k -ar 44100 -ac 2 \
  -movflags +faststart \
  OUTPUT_mobile.mp4
```

For autoplay in iOS Safari, the HTML `<video>` element also needs the `playsinline` and `muted` attributes. To fix a desktop video that will not play on a phone, run the same command: it fixes the usual causes (High 4:4:4 or 10-bit profile, wrong pixel format, missing faststart).

If only faststart is missing, remux without re-encoding:

```bash
ffmpeg -i DESKTOP_VIDEO.mp4 -c copy -movflags +faststart MOBILE_FIXED.mp4
```

### Low-Bandwidth Mobile

```bash
# Optimized for 3G/4G: up to 720p30, lower bitrate, fast loading.
# min(720,ih) avoids upscaling smaller sources; capping at 30 fps keeps 720p
# inside level 3.1 (x264 writes the requested level even when the stream exceeds it)
ffmpeg -i INPUT \
  -vf "scale=-2:'min(720,ih)',fps='min(30,source_fps)'" \
  -c:v libx264 -profile:v main -level 3.1 \
  -preset fast -crf 28 \
  -maxrate 1500k -bufsize 3000k \
  -pix_fmt yuv420p \
  -c:a aac -b:a 64k -ar 44100 -ac 1 \
  -movflags +faststart \
  OUTPUT_low_bandwidth.mp4
```

## Verify Output

```bash
# Compare before/after
ffprobe -v error -show_entries format=duration,size,bit_rate -of default=noprint_wrappers=1 INPUT
ffprobe -v error -show_entries format=duration,size,bit_rate -of default=noprint_wrappers=1 OUTPUT

# Codec, profile, level and pixel format of the output video
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,profile,level,pix_fmt,codec_tag_string \
  -of default=noprint_wrappers=1 OUTPUT
```

To check the output decodes without errors, use the full-decode check in [Validate the File](troubleshooting.md#1-validate-the-file).

When quality matters, measure PSNR/SSIM/VMAF against the source (`analysis.md`).
