# Vulkan Video and Vulkan Compute Codecs

Which Vulkan codecs FFmpeg has, which are compute-based and which need Vulkan Video hardware, plus FFv1 and ProRes RAW usage, device selection, and troubleshooting. Encode/decode pipelines and the `*_vulkan` filters are in [`hwaccel-vulkan.md`](hwaccel-vulkan.md).

## Contents

- [Codec Support by Version](#codec-support-by-version)
- [Requirements](#requirements) and [Check Vulkan Support](#check-vulkan-support)
- [FFv1 Vulkan Codec](#ffv1-vulkan-codec) (encode, decode, lossless screen capture)
- [ProRes RAW Vulkan Decoder](#prores-raw-vulkan-decoder)
- [Hardware Device Initialization](#hardware-device-initialization)
- [Cross-Platform Compatibility](#cross-platform-compatibility) and [Performance](#performance-comparison)
- [Best Practices](#best-practices) and [Troubleshooting](#troubleshooting)

## Codec Support by Version

Only some Vulkan codecs are compute-based:

| Codec | Since | Mechanism | Runs on |
|-------|-------|-----------|---------|
| H.264/HEVC decode | 6.1 | Fixed-function video engine via `VK_KHR_video_decode_queue` + per-codec extension | Only drivers/GPUs exposing those extensions |
| AV1 decode | 6.1 | Same (`VK_KHR_video_decode_av1`) | Same |
| H.264/HEVC encode | 7.1 | Fixed-function via `VK_KHR_video_encode_queue` + per-codec extension | Same |
| AV1 encode | 8.0 | Fixed-function (`VK_KHR_video_encode_av1`) | Same |
| VP9 decode | 8.0 | Fixed-function (`VK_KHR_video_decode_vp9`) | Same |
| FFv1 encode/decode | 8.0 | Vulkan compute shaders | Any Vulkan 1.3 compute-capable device |
| ProRes RAW decode | 8.0 | Vulkan compute shaders | Any Vulkan 1.3 compute-capable device |

More Vulkan compute codecs (ProRes, VC-2) were announced as following 8.0; check `ffmpeg -encoders | grep vulkan` and `ffmpeg -hwaccels` on newer builds. Vulkan decode is a hwaccel, so `ffmpeg -decoders` never lists it.

H.264/HEVC/AV1 encode commands, hardware decode, and full Vulkan pipelines are in [`hwaccel-vulkan.md`](hwaccel-vulkan.md#basic-vulkan-encoding).

## Requirements

- Vulkan 1.3 compatible GPU and drivers (enough for FFv1, ProRes RAW and the `*_vulkan` filters)
- For H.264/HEVC/AV1 encode and hardware decode: a driver exposing `VK_KHR_video_queue` and the matching `VK_KHR_video_encode_*` / `VK_KHR_video_decode_*` extensions (check with `vulkaninfo | grep VK_KHR_video`)
- FFmpeg built with Vulkan support (`--enable-vulkan`): 6.1+ for hardware decode, 7.1+ for H.264/HEVC encode, 8.0+ for AV1 encode, VP9 decode, FFv1 and ProRes RAW

## Check Vulkan Support

```bash
# Is the Vulkan hwaccel compiled in?
ffmpeg -hwaccels | grep vulkan

# Vulkan encoders in this build
ffmpeg -encoders | grep vulkan

# List Vulkan devices and the one selected (needs a dummy input/output to run)
ffmpeg -v verbose -init_hw_device vulkan -f lavfi -i nullsrc -frames:v 1 -f null - 2>&1 \
  | grep -A4 'GPU listing'

# Does this GPU/driver actually decode? An error such as "Failed setup for
# format vulkan" or "does not support the VK_KHR_video_decode_queue
# extension" means no (FFmpeg silently falls back to software, exit code 0)
ffmpeg -v error -init_hw_device vulkan=vk -hwaccel vulkan -hwaccel_device vk \
  -i input.mp4 -t 1 -f null -
```

## FFv1 Vulkan Codec

FFv1 is a lossless video codec; FFmpeg 8.0 adds Vulkan compute encode and decode.

### Encoding

```bash
# FFv1 Vulkan encoding (the encoder takes only Vulkan frames: upload them;
# 4:2:0 needs FFv1 version 4, i.e. -level 4, which is still experimental;
# without it: "Encoding frames with subsampling and unaligned dimensions is
# only supported in version 4 (-level 4)")
ffmpeg -i input.mp4 \
  -init_hw_device vulkan=vk -filter_hw_device vk \
  -vf format=yuv420p,hwupload \
  -c:v ffv1_vulkan -level 4 -strict experimental \
  output.mkv

# Archival copy with lossless audio, on the second GPU (index 1)
ffmpeg -i source.mp4 \
  -init_hw_device vulkan=vk:1 -filter_hw_device vk \
  -vf format=yuv420p,hwupload \
  -c:v ffv1_vulkan -level 4 -strict experimental \
  -c:a flac \
  archive.mkv
```

### Decoding

```bash
# FFv1 Vulkan decoding
ffmpeg -hwaccel vulkan \
  -i input_ffv1.mkv \
  -c:v libx264 -crf 18 \
  output.mp4
```

### Lossless Screen Capture

```bash
# Linux X11 (yuv444p keeps full chroma)
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -f x11grab -framerate 60 -i :0.0 \
  -vf format=yuv444p,hwupload -c:v ffv1_vulkan -level 4 -strict experimental screen_capture.mkv

# Windows
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -f gdigrab -framerate 60 -i desktop \
  -vf format=yuv444p,hwupload -c:v ffv1_vulkan -level 4 -strict experimental screen_capture.mkv
```

FFv1 Vulkan is still experimental. On FFmpeg 8.0.1 with an Intel iGPU, yuv420p/yuv444p output decoded bit-exact with the software `ffv1` decoder, while RGB (`bgr0`) input produced files the software decoder flagged with `bytestream end mismatching`. Verify archival output against the source before relying on it:

```bash
ffmpeg -v error -i output.mkv -map 0:v -f framemd5 - | grep -v '^#' | md5sum
ffmpeg -v error -i input.mp4 -map 0:v -vf format=yuv420p -f framemd5 - | grep -v '^#' | md5sum
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

```bash
# Auto-select GPU (the first discrete/integrated device; software llvmpipe is last)
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk -i input.mp4 ...

# Select by index from the GPU listing (0 = first, 1 = second)
ffmpeg -init_hw_device vulkan=vk:1 -filter_hw_device vk -i input.mp4 ...
```

When only one hardware device is initialised, filters such as `hwupload` use it even without `-filter_hw_device`.

## Cross-Platform Compatibility

| Platform | Vulkan compute (FFv1, ProRes RAW, filters) | Vulkan Video (H.264/HEVC/AV1 encode, hardware decode) |
|----------|-----|-----|
| Linux (AMD, Intel, NVIDIA) | Yes | Depends on driver: Mesa RADV/ANV and the NVIDIA driver expose it on recent GPUs |
| Windows (AMD, Intel, NVIDIA) | Yes | Depends on driver |
| macOS (any GPU) | Via MoltenVK | No: MoltenVK has no Vulkan Video; use VideoToolbox |

## Performance Comparison

Rough, illustrative ratios only (unsourced, not benchmarks); real speed depends heavily on GPU, driver, preset and content. Measure on the target hardware with `-benchmark`.

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
   - Cross-platform GPU acceleration is needed
   - Vendor-specific APIs (NVENC, QSV) aren't available
   - Working with FFv1 lossless compression
2. **Prefer vendor APIs when**:
   - Maximum performance is critical
   - The deployment targets one platform
   - Encoding established codecs (H.264, H.265)
3. **Keep frames on the GPU** with `-hwaccel vulkan -hwaccel_output_format vulkan` and Vulkan filters (see [`hwaccel-vulkan.md`](hwaccel-vulkan.md#full-vulkan-pipeline)).

## Troubleshooting

### "Vulkan not available" / device creation fails
- Install/update GPU drivers
- Ensure Vulkan 1.3 support
- Check FFmpeg was built with `--enable-vulkan`

### "Device does not support the VK_KHR_video_encode_queue extension!"
- The device has Vulkan compute but no Vulkan Video encode. H.264/HEVC/AV1 `*_vulkan` encoding cannot run there; FFv1 and the Vulkan filters still work. Use the vendor encoder (NVENC, QSV, VAAPI, AMF) or a newer driver.

### "Impossible to convert between the formats ..." with a `*_vulkan` encoder
- The encoder got software frames. Add `-init_hw_device vulkan=vk -filter_hw_device vk -vf format=nv12,hwupload`, or decode with `-hwaccel vulkan -hwaccel_output_format vulkan`.

### Poor performance
- Ensure `-hwaccel_output_format vulkan` to keep data on GPU
- Use Vulkan filters instead of CPU filters
- Check the selected device in the GPU listing: `llvmpipe` is a software rasterizer

### Encoding errors
- Check input pixel format compatibility
- Try adding explicit format conversion
- Verify GPU memory availability
