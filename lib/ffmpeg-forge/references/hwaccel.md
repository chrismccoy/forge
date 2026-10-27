# Hardware Acceleration

Platform choice, minimal per-backend commands, the full-GPU pipeline pattern, per-backend device initialization, a cross-vendor filter map, use-case recipes, and Docker. Backend details live in the files listed in the [Reference Map](#reference-map).

## Contents

- [Quick Reference](#quick-reference)
- [Hardware Acceleration Overview](#hardware-acceleration-overview)
- [Core Workflow](#core-workflow) and [Minimal Examples per Backend](#minimal-examples-per-backend)
- [Full GPU Pipeline Pattern](#full-gpu-pipeline-pattern-critical)
- [Hardware Device Initialization](#hardware-device-initialization) (per-backend `-init_hw_device` syntax)
- [Cross-Vendor Filter Quick Map](#cross-vendor-filter-quick-map)
- [Use-Case Quick Recipes](#use-case-quick-recipes) (live, VOD, batch, Docker)
- [Best Practices](#best-practices) and [Reference Map](#reference-map)

## Quick Reference

| Platform | Encoder | Decoder | Detect Command |
|----------|---------|---------|----------------|
| NVIDIA | `h264_nvenc`, `hevc_nvenc`, `av1_nvenc` | `h264_cuvid`, `hevc_cuvid` | `ffmpeg -encoders \| grep nvenc` |
| Intel QSV | `h264_qsv`, `hevc_qsv`, `av1_qsv` | `h264_qsv`, `hevc_qsv` | `ffmpeg -encoders \| grep qsv` |
| AMD AMF | `h264_amf`, `hevc_amf`, `av1_amf` | `-hwaccel d3d11va`/`dxva2` (Windows), `-hwaccel vaapi` (Linux) | `ffmpeg -encoders \| grep amf` |
| Apple | `h264_videotoolbox`, `hevc_videotoolbox` | `h264_videotoolbox` | macOS only |
| VAAPI | `h264_vaapi`, `hevc_vaapi`, `av1_vaapi` | with `-hwaccel vaapi` | Linux only |
| Vulkan | `h264_vulkan`, `hevc_vulkan`, `av1_vulkan` (8.0+), `ffv1_vulkan` (8.0+) | with `-hwaccel vulkan` (H.264, HEVC, AV1; VP9, FFv1, ProRes RAW 8.0+) | `ffmpeg -encoders \| grep vulkan` |

**Versions**: this content targets FFmpeg 7.1 LTS and 8.x; the latest stable release as of 2026-10 is 9.0.2 (see [`fundamentals-version-history.md`](fundamentals-version-history.md)). Check the installed build with `ffmpeg -version`.

## Hardware Acceleration Overview

Hardware acceleration uses dedicated GPU/SoC components for video processing:

- **NVENC/NVDEC** (NVIDIA): dedicated encode/decode engines
- **QSV** (Intel): Quick Sync Video on Intel CPUs with integrated graphics
- **AMF** (AMD): Advanced Media Framework for AMD GPUs
- **VideoToolbox** (Apple): macOS/iOS hardware acceleration
- **VAAPI** (Linux): Video Acceleration API (Intel, AMD on Linux)
- **Vulkan Video** (Cross-platform; decode 6.1+, H.264/HEVC encode 7.1+, AV1 encode and VP9 decode 8.0+): H.264/HEVC/AV1 encode and H.264/HEVC/AV1/VP9 decode use the GPU's fixed-function video engine through the `VK_KHR_video_*` extensions (the driver must expose them); FFv1 encode/decode and ProRes RAW decode (8.0+) are Vulkan compute shaders

### Performance Comparison (indicative)

Speed multipliers are rough, illustrative figures (unsourced, not benchmarks); they vary widely with GPU generation, preset and resolution.

| Method | Speed (rough) | Quality | Power | Use Case |
|--------|-------|---------|-------|----------|
| libx264 (CPU) | 1x | Best | High | Quality-critical |
| libx265 (CPU) | 0.3x | Best | Very High | Archival |
| h264_nvenc | 10-20x | Good | Low | Real-time, streaming |
| hevc_nvenc | 8-15x | Good | Low | 4K streaming |
| h264_qsv | 8-15x | Good | Very Low | Laptop, efficiency |
| h264_amf | 8-15x | Good | Low | AMD systems |

## Core Workflow

1. **Detect available backends**: `ffmpeg -hwaccels`, `ffmpeg -encoders | grep <api>`
2. **Pick a backend**: prefer the vendor-native one (NVENC on NVIDIA, QSV on Intel, AMF on AMD, VideoToolbox on Apple). Use Vulkan for cross-platform portability.
3. **Build a full-GPU pipeline** where possible:
   - Add `-hwaccel <api>` and `-hwaccel_output_format <api>` *before* `-i`
   - Use GPU-side filters (`scale_cuda`, `scale_vulkan`, `vpp_qsv`, ...)
   - Use the matching hardware encoder
4. **Tune quality**: `-preset` (NVENC `p1-p7`), `-cq`/`-qp`/`-global_quality`, lookahead, spatial/temporal AQ
5. **Verify**: benchmark with `ffmpeg -benchmark` and monitor GPU via `nvidia-smi dmon`, `intel_gpu_top`, etc.

## Minimal Examples per Backend

```bash
# NVIDIA NVENC
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -c:v h264_nvenc -preset p5 -tune hq -b:v 5M output.mp4

# Intel QSV
ffmpeg -hwaccel qsv -hwaccel_output_format qsv -i input.mp4 \
  -c:v h264_qsv -preset medium -b:v 5M output.mp4

# AMD AMF
ffmpeg -i input.mp4 -c:v h264_amf -quality balanced -b:v 5M output.mp4

# Apple VideoToolbox
ffmpeg -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4

# Linux VAAPI (h264_vaapi accepts only VAAPI frames, so keep them on the GPU;
# without -hwaccel_output_format this fails with
# "Impossible to convert between the formats ...")
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi -i input.mp4 \
  -c:v h264_vaapi -b:v 5M output.mp4

# Vulkan (cross-platform; *_vulkan encoders take only Vulkan frames, so upload)
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk -i input.mp4 \
  -vf format=nv12,hwupload -c:v h264_vulkan -b:v 5M output.mp4
```

## Full GPU Pipeline Pattern (Critical)

```bash
ffmpeg -y \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf scale_cuda=1280:720 \
  -fps_mode passthrough -c:v h264_nvenc -preset p5 -tune hq -b:v 5M \
  -c:a copy \
  output.mp4
```

Omitting `-hwaccel_output_format` can cut throughput by up to 50% because decoded frames silently round-trip through CPU memory. See [`hwaccel-gpu-memory-and-troubleshooting.md`](hwaccel-gpu-memory-and-troubleshooting.md) for memory flow diagrams and best practices.

## Hardware Device Initialization

Per-backend syntax for `-hwaccel`, `-init_hw_device`, and `-filter_hw_device`.

### General Syntax

```text
-init_hw_device TYPE[=NAME][:DEVICE[,KEY=VALUE...]]   create a device
-init_hw_device TYPE[=NAME]@SOURCE                    derive from an existing device
-filter_hw_device NAME                                device used by hwupload/hwmap
-hwaccel TYPE -hwaccel_device NAME|DEVICE             input option: decode device
-hwaccel_output_format TYPE                           input option: keep frames on the GPU
```

- `hwupload` uses `-filter_hw_device`; when exactly one device was initialised it is used automatically. `hwupload_cuda` ignores both and takes its own `device=N` index.
- Without `-hwaccel_output_format`, decoded frames are copied back to system memory. Encoders that accept only hardware frames (`*_vaapi`, `*_vulkan`) then need `format=nv12,hwupload` again.

### CUDA (NVIDIA)

```bash
# Basic CUDA
ffmpeg -hwaccel cuda -i input.mp4 -c:v h264_nvenc output.mp4

# Specify device
ffmpeg -hwaccel cuda -hwaccel_device 0 -i input.mp4 -c:v h264_nvenc output.mp4

# Full GPU pipeline (decode + filter + encode on GPU)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -vf "scale_cuda=1920:1080" -c:v h264_nvenc output.mp4

# Initialize named device for filters (hwupload honours -filter_hw_device;
# hwupload_cuda would ignore it and use device=0)
ffmpeg -init_hw_device cuda=gpu0:0 -filter_hw_device gpu0 \
  -i input.mp4 -vf "format=yuv420p,hwupload,scale_cuda=1920:1080,hwdownload,format=yuv420p" \
  -c:v libx264 output.mp4
```

### VAAPI (AMD/Intel Linux)

```bash
# VAAPI with output format
ffmpeg -hwaccel vaapi -hwaccel_output_format vaapi \
  -hwaccel_device /dev/dri/renderD128 -i input.mp4 \
  -vf "scale_vaapi=1920:1080" -c:v h264_vaapi output.mp4

# Using -vaapi_device shortcut
ffmpeg -vaapi_device /dev/dri/renderD128 -i input.mp4 \
  -vf "format=nv12,hwupload,scale_vaapi=1920:1080" -c:v h264_vaapi output.mp4
```

### QSV (Intel)

```bash
# Basic QSV
ffmpeg -hwaccel qsv -i input.mp4 -c:v h264_qsv output.mp4

# QSV with device specification
ffmpeg -qsv_device /dev/dri/renderD128 -hwaccel qsv \
  -i input.mp4 -c:v h264_qsv output.mp4

# Same via -init_hw_device: the render node goes in child_device
# (qsv=hw:/dev/dri/renderD129 would ignore the path)
ffmpeg -init_hw_device qsv=hw,child_device=/dev/dri/renderD129 -filter_hw_device hw \
  -hwaccel qsv -hwaccel_device hw -hwaccel_output_format qsv \
  -i input.mp4 -c:v h264_qsv output.mp4

# Full QSV pipeline
ffmpeg -hwaccel qsv -hwaccel_output_format qsv -i input.mp4 \
  -vf "scale_qsv=1920:1080" -c:v h264_qsv output.mp4
```

### Vulkan (Cross-platform FFmpeg 7.1+/8.0+)

```bash
# Vulkan hardware acceleration (hwdownload needs an explicit format=)
ffmpeg -init_hw_device vulkan=vk:0 -filter_hw_device vk \
  -i input.mp4 -vf "hwupload,scale_vulkan=1920:1080,hwdownload,format=yuv420p" \
  -c:v libx264 output.mp4

# Vulkan decode + encode (h264/hevc_vulkan 7.1+, av1_vulkan 8.0+;
# needs VK_KHR_video_decode/encode support in the driver)
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan -i input.mp4 \
  -c:v h264_vulkan output.mp4
```

### D3D11VA (Windows)

```bash
# D3D11 hardware acceleration
ffmpeg -hwaccel d3d11va -i input.mp4 -c:v h264_nvenc output.mp4

# With specific adapter
ffmpeg -hwaccel d3d11va -hwaccel_device 0 -i input.mp4 \
  -c:v hevc_amf output.mp4
```

### VideoToolbox (macOS)

```bash
# VideoToolbox decode + encode
ffmpeg -hwaccel videotoolbox -i input.mp4 \
  -c:v h264_videotoolbox output.mp4

# With ProRes
ffmpeg -i input.mov -c:v prores_videotoolbox output.mov
```

## Cross-Vendor Filter Quick Map

| Operation | NVIDIA (CUDA) | Intel (QSV) | VAAPI (Intel/AMD Linux) | Cross-platform |
|-----------|--------|-------|-----------|----------------|
| Scale | `scale_cuda`, `scale_npp` | `vpp_qsv`, `scale_qsv` | `scale_vaapi` | `scale_vulkan`, `libplacebo` |
| Overlay | `overlay_cuda` | `overlay_qsv` | `overlay_vaapi` | `overlay_vulkan`, `overlay_opencl` |
| Stack/grid | - | `hstack_qsv`, `vstack_qsv`, `xstack_qsv` | `hstack_vaapi`, `vstack_vaapi`, `xstack_vaapi` | - |
| Deinterlace | `bwdif_cuda`, `yadif_cuda` | `deinterlace_qsv`, `vpp_qsv=deinterlace=2` | `deinterlace_vaapi` | `bwdif_vulkan` |
| Denoise | `bilateral_cuda` | `vpp_qsv=denoise=N` | `denoise_vaapi` | `nlmeans_vulkan`, `nlmeans_opencl` |
| Chromakey | `chromakey_cuda` | - | - | `colorkey_opencl` |
| Tonemap (HDR->SDR) | - | `vpp_qsv=tonemap=1` | `tonemap_vaapi` | `libplacebo`, `tonemap_opencl` |
| Pad/letterbox | `pad_cuda` (8.0+) | - | `pad_vaapi` | `pad_opencl` |
| Draw box | - | - | `drawbox_vaapi` | - |

AMD AMF on Windows adds `vpp_amf` (scale/convert) and `sr_amf` (super resolution); see [`hwaccel-amd-amf-vaapi-videotoolbox.md`](hwaccel-amd-amf-vaapi-videotoolbox.md). On Linux, AMD GPUs use the VAAPI column. The Vulkan column runs on any Vulkan 1.3 compute device.

## Use-Case Quick Recipes

### Live streaming (low latency)

NVENC low-latency RTMP push and the platform settings (keyframe interval, CBR, bufsize): [`streaming.md`](streaming.md#hardware-encoding-for-live).

### VOD (quality target)

```bash
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc -preset p6 -tune hq \
  -rc vbr -cq 22 -b:v 0 \
  -rc-lookahead 32 -spatial-aq 1 \
  output.mp4
```

### Batch / parallel encoding

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input1.mp4 -c:v h264_nvenc output1.mp4 &
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input2.mp4 -c:v h264_nvenc output2.mp4 &
wait
```

### Docker (GPU passthrough)

Use an image whose FFmpeg was built with the needed backend (check `ffmpeg -hwaccels` and `-encoders` inside the container); image names and tags change, so substitute a current one for `FFMPEG_IMAGE`.

```bash
# NVIDIA: needs the NVIDIA Container Toolkit on the host; the "video"
# capability mounts libnvidia-encode/libnvcuvid into the container
docker run --rm --gpus all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility \
  -v "$(pwd)":/data FFMPEG_IMAGE \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i /data/input.mp4 -c:v h264_nvenc /data/output.mp4

# Intel QSV / VAAPI: pass the render node through (image needs libvpl or
# libva plus the Intel media driver)
docker run --rm --device /dev/dri:/dev/dri \
  -v "$(pwd)":/data FFMPEG_IMAGE \
  -hwaccel qsv -hwaccel_output_format qsv \
  -i /data/input.mp4 -c:v h264_qsv /data/output.mp4
```

## Best Practices

1. Use full GPU pipelines when possible to avoid CPU/GPU memory transfers
2. Match decode and encode hardware for best performance
3. Pick presets deliberately - faster is not always better for quality
4. Enable lookahead and AQ for quality-critical encodes
5. Test on target hardware - quality varies by GPU generation
6. Monitor GPU memory and engine load for high-resolution content (`nvidia-smi dmon`, `intel_gpu_top`)
7. Consider power efficiency for laptops and servers
8. Update drivers regularly for performance and feature improvements

## Reference Map

For deep dives on each backend, see:

- **NVIDIA NVENC/NVDEC** (presets, CUDA filters, scale_npp, hybrid pipelines, two-pass, multi-GPU, 1:N ABR): [`hwaccel-nvidia-nvenc.md`](hwaccel-nvidia-nvenc.md)
- **Intel QSV** (requirements, full pipeline, vpp_qsv scale/deinterlace/denoise, lookahead, multi-GPU, VVC decoding): [`hwaccel-intel-qsv.md`](hwaccel-intel-qsv.md)
- **AMD AMF, VAAPI, Apple VideoToolbox** (AMF encoders and D3D11 decode, VAAPI scaling/deinterlace/rate control, VVC VAAPI decode 8.0+, VideoToolbox): [`hwaccel-amd-amf-vaapi-videotoolbox.md`](hwaccel-amd-amf-vaapi-videotoolbox.md)
- **Vulkan encode/decode pipelines and Vulkan filters** (h264/hevc/av1_vulkan, scale/overlay/blur/transitions/libplacebo): [`hwaccel-vulkan.md`](hwaccel-vulkan.md)
- **Vulkan codec versions, FFv1 and ProRes RAW, Vulkan device selection**: [`fundamentals-vulkan-compute-codecs.md`](fundamentals-vulkan-compute-codecs.md)
- **OpenCL filters** (overlay, pad, colorkey, nlmeans, deshake, unsharp, tonemap, transpose, xfade; there is no scale_opencl): [`hwaccel-opencl-filters.md`](hwaccel-opencl-filters.md)
- **GPU memory (hwupload/hwdownload, surface formats), driver and device errors**: [`hwaccel-gpu-memory-and-troubleshooting.md`](hwaccel-gpu-memory-and-troubleshooting.md)
