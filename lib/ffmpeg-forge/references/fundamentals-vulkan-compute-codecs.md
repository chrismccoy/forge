# Vulkan Video and Vulkan Compute Codecs in FFmpeg 8.0

FFmpeg 8.0 extended its Vulkan codec support, giving cross-platform GPU acceleration without vendor-specific APIs. Only some of these codecs are compute-based:

| Codec | Mechanism | Runs on |
|-------|-----------|---------|
| FFv1 encode/decode (8.0) | Vulkan compute shaders | Any Vulkan 1.3 compute-capable device |
| ProRes RAW decode (8.0) | Vulkan compute shaders | Any Vulkan 1.3 compute-capable device |
| AV1 encode (8.0), H.264/HEVC encode (7.1) | Fixed-function video engine via `VK_KHR_video_encode_queue` + per-codec extension | Only drivers/GPUs exposing those extensions |
| VP9 decode (8.0), H.264/HEVC/AV1 decode (earlier) | Fixed-function video engine via `VK_KHR_video_decode_queue` + per-codec extension | Only drivers/GPUs exposing those extensions |

## What's New in FFmpeg 8.0

- **FFv1 Vulkan**: Encode and decode via Vulkan compute shaders
- **ProRes RAW Vulkan**: Decode via Vulkan compute shaders
- **AV1 Vulkan Encoder**: Fixed-function AV1 encoding (`VK_KHR_video_encode_av1`)
- **VP9 Vulkan Decoder**: Fixed-function VP9 decode (`VK_KHR_video_decode_vp9`)

## Requirements

- Vulkan 1.3 compatible GPU and drivers (enough for FFv1, ProRes RAW and the `*_vulkan` filters)
- For H.264/HEVC/AV1 encode and hardware decode: a driver exposing `VK_KHR_video_queue` and the matching `VK_KHR_video_encode_*` / `VK_KHR_video_decode_*` extensions (check with `vulkaninfo | grep VK_KHR_video`)
- FFmpeg 8.0+ built with Vulkan support

## Check Vulkan Support

```bash
# Check for Vulkan hardware acceleration
ffmpeg -hwaccels | grep vulkan

# List Vulkan devices
ffmpeg -init_hw_device vulkan -v verbose 2>&1 | grep -i vulkan

# Check Vulkan encoders
ffmpeg -encoders | grep vulkan

# Check Vulkan decode: it is a hwaccel, not a separate decoder, so
# `ffmpeg -decoders | grep vulkan` never matches
ffmpeg -hwaccels | grep vulkan
# Does this GPU/driver actually decode? An error such as "Failed setup for
# format vulkan" or "does not support the VK_KHR_video_decode_queue
# extension" means no (FFmpeg silently falls back to software, exit code 0)
ffmpeg -v error -init_hw_device vulkan=vk -hwaccel vulkan -hwaccel_device vk \
  -i input.mp4 -t 1 -f null -
```

## FFv1 Vulkan Codec

FFv1 is a lossless video codec, now with Vulkan acceleration.

### Encoding

```bash
# FFv1 Vulkan encoding (the encoder takes only Vulkan frames: upload them;
# 4:2:0 needs FFv1 version 4, i.e. -level 4, which is still experimental)
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -vf format=yuv420p,hwupload \
  -c:v ffv1_vulkan -level 4 -strict experimental \
  output.mkv

# With specific GPU selection
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk:0 -filter_hw_device vk \
  -vf format=yuv420p,hwupload \
  -c:v ffv1_vulkan -level 4 -strict experimental \
  output.mkv
```

### Decoding

```bash
# FFv1 Vulkan decoding
ffmpeg -hwaccel vulkan \
  -i input_ffv1.mkv \
  -c:v libx264 -crf 18 \
  output.mp4
```

## AV1 Vulkan Encoder

```bash
# AV1 Vulkan encoding (needs VK_KHR_video_encode_av1 in the driver)
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -vf format=nv12,hwupload \
  -c:v av1_vulkan \
  output.webm

# With quality settings
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -vf format=nv12,hwupload \
  -c:v av1_vulkan -b:v 5M \
  output.webm
```

## VP9 Vulkan Decoder

```bash
# VP9 Vulkan decoding to H.264
ffmpeg -hwaccel vulkan \
  -i input.webm \
  -c:v libx264 -crf 20 \
  output.mp4

# Keep in GPU for further processing
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.webm \
  -vf "scale_vulkan=w=1920:h=1080" \
  -c:v av1_vulkan \
  output.mp4
```

## ProRes RAW Vulkan Decoder

```bash
# ProRes RAW Vulkan decoding (ProRes RAW lives in .mov; .braw is Blackmagic RAW, a different format)
ffmpeg -hwaccel vulkan \
  -i input.mov \
  -c:v libx264 -crf 18 \
  output.mp4
```

## Hardware Device Initialization

### Auto-select GPU

```bash
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -i input.mp4 ...
```

### Select Specific GPU

```bash
# First GPU (index 0)
ffmpeg -init_hw_device vulkan=vk:0 -filter_hw_device vk \
  -i input.mp4 ...

# Second GPU (index 1)
ffmpeg -init_hw_device vulkan=vk:1 -filter_hw_device vk \
  -i input.mp4 ...
```

### List Available GPUs

```bash
# Show Vulkan device info
ffmpeg -init_hw_device vulkan=vk -v verbose 2>&1 | grep -E "device|GPU"
```

## Vulkan Filters

FFmpeg includes Vulkan-based video filters:

```bash
# Vulkan scale filter
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 \
  -vf "scale_vulkan=w=1920:h=1080" \
  -c:v av1_vulkan \
  output.mp4

# Vulkan pixel-format conversion (8-bit -> 10-bit P010). scale_vulkan's format=
# only converts RGB input to 8-bit YUV (nv12/yuv420p/yuv444p); use libplacebo here
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 \
  -vf "libplacebo=format=p010" \
  -c:v av1_vulkan \
  output.mp4
```

## Cross-Platform Compatibility

Vulkan works on:

| Platform | AMD | NVIDIA | Intel |
|----------|-----|--------|-------|
| Linux | Yes | Yes | Yes |
| Windows | Yes | Yes | Yes |
| macOS | Via MoltenVK (no Vulkan Video, so no H.264/HEVC/AV1 `*_vulkan` encode/decode) | N/A | N/A |

## Performance Comparison

Rough, illustrative ratios only (unsourced, not benchmarks); real speed depends heavily on GPU, driver, preset and content. Measure on your own hardware with `-benchmark`.

| Codec | API | Relative Speed (rough) |
|-------|-----|----------------|
| H.264 | NVENC | 1x |
| H.264 | Vulkan | 0.8-0.9x |
| FFv1 | CPU | 1x |
| FFv1 | Vulkan | 3-5x |
| AV1 | libaom (CPU) | 1x |
| AV1 | Vulkan | 10-15x |

## Best Practices

1. **Use Vulkan when**:
   - You need cross-platform GPU acceleration
   - Vendor-specific APIs (NVENC, QSV) aren't available
   - Working with FFv1 lossless compression

2. **Prefer vendor APIs when**:
   - Maximum performance is critical
   - You're on a single platform
   - Using established codecs (H.264, H.265)

3. **Memory considerations**:
   ```bash
   # Keep processing on GPU to avoid transfers
   ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
     -i input.mp4 \
     -vf "scale_vulkan=1920:1080" \
     -c:v av1_vulkan \
     output.mp4
   ```

## Troubleshooting

### "Vulkan not available"
- Install/update GPU drivers
- Ensure Vulkan 1.3 support
- Check FFmpeg was built with `--enable-vulkan`

### "Device does not support the VK_KHR_video_encode_queue extension!"
- The device has Vulkan compute but no Vulkan Video encode. H.264/HEVC/AV1 `*_vulkan` encoding cannot run there; FFv1 and the Vulkan filters still work. Use the vendor encoder (NVENC, QSV, VAAPI, AMF) or a newer driver.

### "Impossible to convert between the formats ..." with a `*_vulkan` encoder
- The encoder got software frames. Add `-init_hw_device vulkan=vk -filter_hw_device vk -vf format=nv12,hwupload`, or decode with `-hwaccel vulkan -hwaccel_output_format vulkan`.

### Poor performance
- Ensure `hwaccel_output_format vulkan` to keep data on GPU
- Use Vulkan filters instead of CPU filters
- Try different GPU if multiple available

### Encoding errors
- Check input pixel format compatibility
- Try adding explicit format conversion
- Verify GPU memory availability

## Example Pipelines

### Lossless Archival with FFv1

```bash
# Fast lossless encoding for archival
ffmpeg -i source.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -vf format=yuv420p,hwupload \
  -c:v ffv1_vulkan -level 4 -strict experimental \
  -c:a flac \
  archive.mkv
```

### Web Delivery with AV1

```bash
# AV1 encoding for web
ffmpeg -i source.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -vf format=nv12,hwupload \
  -c:v av1_vulkan -b:v 3M \
  -c:a libopus -b:a 128k \
  output.webm
```

### Transcode VP9 to AV1

```bash
# VP9 decode + AV1 encode (all on GPU)
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.webm \
  -c:v av1_vulkan -b:v 3M \
  -c:a copy \
  output.mp4
```
