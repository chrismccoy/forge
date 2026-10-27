# FFmpeg Fundamentals

Codec and container tables, probing commands, capability discovery, and exit codes for FFmpeg 7.1 LTS and 8.x. The core workflow, option order, seeking, and delivery defaults are in SKILL.md.

## Contents

- [Quick Reference](#quick-reference)
- [Codec Reference](#codec-reference)
- [Container Compatibility](#container-compatibility)
- [Probing](#probing)
- [Capability Discovery](#capability-discovery)
- [Exit Codes](#exit-codes)
- [Related Files](#related-files)

## Quick Reference

| Task | Command Pattern |
|------|-----------------|
| Convert format | `ffmpeg -i input.ext output.ext` |
| Set quality (CRF) | `-c:v libx264 -crf 23` |
| Bitrate mode | `-c:v libx264 -b:v 5M` |
| Scale video | `-vf "scale=-2:1080"` |
| Trim video | `-ss 00:00:10 -t 00:00:30` |
| Extract audio | `-vn -c:a aac output.m4a` |
| Machine-readable progress | `ffmpeg -progress - -nostats -i input.mp4 output.mp4` |
| Detailed log file | `ffmpeg -report -i input.mp4 output.mp4` |
| Probe file | `ffprobe -v error -show_format -show_streams file` |

## Codec Reference

### Video Codecs (Software)

| Codec | Encoder | Use Case | Quality | Speed |
|-------|---------|----------|---------|-------|
| H.264/AVC | libx264 | Universal compatibility | Excellent | Medium |
| H.265/HEVC | libx265 | 4K, HDR, storage efficiency | Excellent | Slow |
| H.266/VVC | libvvenc | Next-gen, 8K | Best | Very Slow |
| AV1 | libsvtav1, libaom-av1 | Web streaming, royalty-free | Excellent | Slow-Medium |
| VP9 | libvpx-vp9 | WebM, YouTube | Very Good | Slow |
| ProRes | prores_ks | Professional editing | Visually lossless (lossy intra) | Fast |
| DNxHR | dnxhd | Avid/broadcast editing | Visually lossless (lossy intra) | Fast |
| FFV1 | ffv1 | Lossless archival | Lossless | Medium |

Quality defaults per encoder are in SKILL.md (Quality Quick Reference). Intermediate codecs (ProRes, DNxHR) are in `fundamentals-common-operations.md`.

### Hardware Encoders

| Platform | H.264 | H.265 | AV1 | VVC | FFv1 |
|----------|-------|-------|-----|-----|------|
| NVIDIA | h264_nvenc | hevc_nvenc | av1_nvenc | - | - |
| Intel | h264_qsv | hevc_qsv | av1_qsv | - | - |
| AMD | h264_amf | hevc_amf | av1_amf | - | - |
| Apple | h264_videotoolbox | hevc_videotoolbox | - | - | - |
| Vulkan | h264_vulkan | hevc_vulkan | av1_vulkan (8.0+) | - | ffv1_vulkan (8.0+) |

### Hardware Decoders (7.1 and 8.0 additions)

| Platform | VVC/H.266 | VP9 | ProRes RAW |
|----------|-----------|-----|------------|
| VAAPI | vvc (8.0+) | Yes | - |
| QSV | vvc_qsv (7.1+) | Yes | - |
| Vulkan | - | vp9 (8.0+) | Yes (8.0+) |

### Audio Codecs

| Codec | Encoder | Use Case | Bitrate Range |
|-------|---------|----------|---------------|
| AAC | aac, libfdk_aac | Universal, streaming | 96-320 kbps |
| MP3 | libmp3lame | Legacy compatibility | 128-320 kbps |
| Opus | libopus | VoIP, streaming, WebM | 32-256 kbps |
| FLAC | flac | Lossless archival | ~900 kbps |
| AC3 | ac3 | DVD, Blu-ray | 384-640 kbps |
| EAC3 | eac3 | Streaming, Dolby Digital+ | 192-768 kbps |

Recommended bitrates per use are in `audio.md` (Recommended Bitrates).

## Container Compatibility

| Container | Video | Audio | Subtitles | Notes |
|-----------|-------|-------|-----------|-------|
| MP4 / MOV | H.264, HEVC, AV1, VP9; ProRes in MOV only | AAC, MP3, AC-3, E-AC-3, Opus, FLAC, ALAC | `mov_text` only | Web needs `+faststart`; Apple HEVC needs `hvc1` |
| MKV | Almost any | Almost any | SRT, ASS, PGS, VobSub, WebVTT | Best for archival and remux; poor browser support |
| WebM | VP8, VP9, AV1 | Opus, Vorbis | WebVTT | Browser-native; FFmpeg refuses other codecs |
| MPEG-TS | H.264, HEVC, MPEG-2, AV1 | AAC, MP3, AC-3, E-AC-3, Opus | DVB, Teletext | Broadcast, HLS segments, survives truncation |
| MXF | MPEG-2, H.264, DNxHD/HR, ProRes | PCM only | - | Broadcast exchange; refuses non-broadcast frame rates (e.g. 10 fps) |

Browser playback in MP4: H.264 + AAC is universal. HEVC, AC-3 and E-AC-3 depend on browser and OS (Safari plays them; Chrome and Firefox vary). Use WebM or H.264 + AAC as the fallback. Bitmap subtitles (PGS, VobSub) cannot go into MP4; burn them in or keep MKV (see `captions.md`).

## Probing

```bash
# Get media info as JSON
ffprobe -v quiet -print_format json -show_format -show_streams input.mp4

# Get duration
ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp4

# Get resolution
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 input.mp4

# Get codec
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 input.mp4

# Pixel format, profile, color tags and field order of the first video stream
ffprobe -v error -select_streams v:0 \
  -show_entries stream=pix_fmt,profile,color_range,color_space,color_primaries,color_transfer,field_order \
  -of default=noprint_wrappers=1 input.mp4

# Validate headers (fast; does not decode frames, so corrupt video data passes)
ffprobe -v error input.mp4 && echo "Valid" || echo "Invalid"
```

For a full decode check (exit code stays 0 on concealed errors), see [Validate the File](troubleshooting.md#1-validate-the-file).

`scripts/analyze-video.sh <file>` runs a full probe and prints encoding recommendations.

## Capability Discovery

```bash
ffmpeg -encoders          # List encoders
ffmpeg -decoders          # List decoders
ffmpeg -formats           # List formats
ffmpeg -filters           # List filters
ffmpeg -hwaccels          # List hardware acceleration methods
ffmpeg -h encoder=libx264 # Encoder-specific options
ffmpeg -h filter=scale    # Filter options and their types
ffmpeg -h muxer=hls       # Muxer options
```

`scripts/check-codecs.sh` audits the whole build.

## Exit Codes

- 0: success
- non-zero: error (check stderr). The value varies: sometimes 1, often a negative AVERROR truncated to 8 bits (e.g. 234 for EINVAL, 254 for a missing input file; 8, 187 and 218 also occur), so test for non-zero rather than a specific number
- 255: interrupted with Ctrl+C (SIGINT)

The exit code reports fatal errors only. Concealed decode errors (corrupt frames) still exit 0, so scan stderr when validating files. FFmpeg also exits 0 when it declines to overwrite an existing output (`-n`), so check that the output exists.

## Related Files

- `fundamentals-common-operations.md` - Transcode checklist, conversion, scaling, trimming, concat, audio, image ops, device-targeted output, target-size encodes, intermediates
- `fundamentals-version-history.md` - FFmpeg 8.0 / 7.1 LTS feature lists, version-sensitive claims
- `fundamentals-vvc-h266-encoding.md` - VVC/H.266 encoding with libvvenc plus hardware decode
- `fundamentals-vulkan-compute-codecs.md` - Vulkan compute-based codecs (FFv1, ProRes RAW)
