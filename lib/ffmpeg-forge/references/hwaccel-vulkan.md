# Vulkan Video and Vulkan Filters (FFmpeg 7.1+/8.0)

Cross-platform GPU acceleration via Vulkan (AMD, Intel, NVIDIA). Two different mechanisms are involved:

- **Vulkan Video (fixed-function)**: H.264/HEVC/AV1 encode and H.264/HEVC/AV1/VP9 decode drive the GPU's hardware video engine through the `VK_KHR_video_queue`, `VK_KHR_video_encode_queue` / `VK_KHR_video_decode_queue` and per-codec extensions. A Vulkan 1.3 driver is not enough: the driver and GPU must expose these extensions, otherwise the encoder fails with `Device does not support the VK_KHR_video_encode_queue extension!`.
- **Vulkan compute**: FFv1 encode/decode, ProRes RAW decode (8.0+) and all `*_vulkan` filters run as compute shaders and work on any Vulkan 1.3 compute-capable device.

Check what your device exposes with `vulkaninfo | grep VK_KHR_video`.

## Vulkan Codecs Overview

### FFmpeg 7.1 Vulkan Features
- H.264 Vulkan encoding
- H.265/HEVC Vulkan encoding

### FFmpeg 8.0 Vulkan Features (New)
- **AV1 Vulkan encoding** - fixed-function AV1 encode via `VK_KHR_video_encode_av1`
- **VP9 Vulkan decoding** - fixed-function VP9 decode via `VK_KHR_video_decode_vp9`
- **FFv1 Vulkan encode/decode** - lossless codec, compute shaders (archival/capture)
- **ProRes RAW Vulkan decode** - Apple ProRes RAW, compute shaders

**Benefits:**
- Cross-platform: same command line on AMD/Intel/NVIDIA (given driver support for the needed extensions)
- No vendor lock-in
- Ideal for lossless screen capture, high-throughput archival, professional workflows

## Basic Vulkan Encoding

The `*_vulkan` encoders accept only Vulkan frames (`Supported pixel formats: vulkan`). Software-decoded input must be uploaded with `hwupload`; without it FFmpeg fails with `Impossible to convert between the formats ...`.

```bash
# H.264 Vulkan
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk -i input.mp4 \
  -vf format=nv12,hwupload -c:v h264_vulkan -b:v 5M output.mp4

# H.265/HEVC Vulkan
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk -i input.mp4 \
  -vf format=nv12,hwupload -c:v hevc_vulkan -b:v 4M output.mp4

# AV1 Vulkan (FFmpeg 8.0+)
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk -i input.mp4 \
  -vf format=nv12,hwupload -c:v av1_vulkan -b:v 3M output.mp4

# FFv1 Vulkan Lossless (FFmpeg 8.0+, experimental)
# 4:2:0 input needs FFv1 version 4 (-level 4), which needs -strict experimental;
# without it: "Encoding frames with subsampling and unaligned dimensions is only supported in version 4"
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk -i input.mp4 \
  -vf format=yuv420p,hwupload -c:v ffv1_vulkan -level 4 -strict experimental output.mkv
```

## Full Vulkan Pipeline

```bash
ffmpeg -init_hw_device vulkan=vk \
  -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 \
  -vf "scale_vulkan=1280:720" \
  -c:v h264_vulkan output.mp4
```

## VP9 / ProRes RAW Vulkan Decoding (FFmpeg 8.0+)

```bash
# VP9 decode (needs VK_KHR_video_decode_vp9) -> H.264 Vulkan encode, frames stay on GPU
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.webm -c:v h264_vulkan output.mp4

# ProRes RAW decode (compute shaders) -> CPU encode
ffmpeg -hwaccel vulkan \
  -i input.mov -c:v libx264 output.mp4
```

## Lossless Screen Capture with FFv1 Vulkan

```bash
# Linux X11 (yuv444p keeps full chroma; check the result decodes cleanly, see note below)
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -f x11grab -framerate 60 -i :0.0 \
  -vf format=yuv444p,hwupload -c:v ffv1_vulkan -level 4 -strict experimental screen_capture.mkv

# Windows
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -f gdigrab -framerate 60 -i desktop \
  -vf format=yuv444p,hwupload -c:v ffv1_vulkan -level 4 -strict experimental screen_capture.mkv
```

FFv1 Vulkan is still experimental. On FFmpeg 8.0.1 with an Intel iGPU, yuv420p/yuv444p output decoded bit-exact with the software `ffv1` decoder, while RGB (`bgr0`) input produced files the software decoder flagged with `bytestream end mismatching`. Verify archival output with `ffmpeg -i out.mkv -f framemd5 -` against the source before relying on it.

More Vulkan compute codecs (ProRes, VC-2) were announced as following 8.0; check `ffmpeg -encoders | grep vulkan` and `ffmpeg -hwaccels` on newer builds (Vulkan decode is a hwaccel, so `ffmpeg -decoders` never lists it).

---

## Vulkan Filters Reference

| Filter | Description | Key Parameters | Since |
|--------|-------------|----------------|-------|
| `scale_vulkan` | GPU scaling | `w`, `h`, `scaler` (`bilinear`, `nearest`), `format` (RGB input to 8-bit YUV only) | 4.3 |
| `overlay_vulkan` | Compositing | `x`, `y` (plain integers, no expressions) | 4.3 |
| `transpose_vulkan` | Rotate/transpose | `dir`, `passthrough` | 5.0 |
| `hflip_vulkan` / `vflip_vulkan` | Horizontal / vertical flip | - | 5.0 |
| `flip_vulkan` | Flip both axes (180° rotation) | - | 5.0 |
| `avgblur_vulkan` | Box blur | `sizeX`, `sizeY` | 4.3 |
| `gblur_vulkan` | Gaussian blur | `sigma`, `sigmaV`, `planes` | 5.0 |
| `chromaber_vulkan` | Chromatic aberration | `dist_x`, `dist_y` | 4.3 |
| `nlmeans_vulkan` | NLMeans denoising | `s`, `p`, `r` | 6.1 |
| `bwdif_vulkan` | Deinterlacing | `mode`, `parity`, `deint` | 6.1 |
| `xfade_vulkan` | Transitions | `transition`, `duration`, `offset` | 6.1 |
| `libplacebo` | Libplacebo processing | `w`, `h`, `format`, `colorspace`, `tonemapping`, `upscaler` | 5.0 |

## Vulkan Scaling

```bash
# CPU-to-GPU-to-CPU scaling
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -i input.mp4 \
  -vf "hwupload,scale_vulkan=1920:1080,hwdownload,format=yuv420p" \
  output.mp4

# Full GPU pipeline
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 -vf "scale_vulkan=1280:720" \
  -c:v h264_vulkan output.mp4

# Specific scaler (scale_vulkan offers only bilinear and nearest;
# for lanczos/ewa_lanczos use libplacebo upscaler=/downscaler=)
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,scale_vulkan=w=1920:h=1080:scaler=nearest,hwdownload,format=yuv420p" \
  output.mp4
```

## Vulkan Compositing

```bash
# Picture-in-picture
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -i main.mp4 -i overlay.mp4 \
  -filter_complex "\
    [0:v]hwupload[main];\
    [1:v]hwupload,scale_vulkan=320:180[pip];\
    [main][pip]overlay_vulkan=x=10:y=10,hwdownload,format=yuv420p[out]" \
  -map "[out]" output.mp4

# Full Vulkan overlay pipeline
# overlay_vulkan x/y are integers, not expressions: compute W-w-10 yourself
# (here 1920x1080 main, 320x180 overlay -> x=1590)
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan -i main.mp4 \
  -hwaccel vulkan -hwaccel_output_format vulkan -i overlay.mp4 \
  -filter_complex "[1:v]scale_vulkan=320:180[pip];[0:v][pip]overlay_vulkan=x=1590:y=10" \
  -c:v h264_vulkan output.mp4
```

## Rotation and Flip

```bash
# 90° clockwise
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,transpose_vulkan=dir=clock,hwdownload,format=yuv420p" \
  output.mp4

# Horizontal flip (vflip_vulkan = vertical, flip_vulkan = both axes)
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,hflip_vulkan,hwdownload,format=yuv420p" output.mp4
```

| dir | Rotation |
|-----|----------|
| `cclock_flip` | 90° counter-clockwise + vertical flip |
| `clock` | 90° clockwise |
| `cclock` | 90° counter-clockwise |
| `clock_flip` | 90° clockwise + vertical flip |

## Blur Effects

```bash
# Gaussian
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,gblur_vulkan=sigma=5,hwdownload,format=yuv420p" output.mp4

# Box
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,avgblur_vulkan=sizeX=5:sizeY=5,hwdownload,format=yuv420p" output.mp4
```

## Chromatic Aberration

```bash
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,chromaber_vulkan=dist_x=-0.002:dist_y=0.002,hwdownload,format=yuv420p" \
  output.mp4
```

## Vulkan Denoising (nlmeans_vulkan)

```bash
# Basic
ffmpeg -init_hw_device vulkan -i noisy.mp4 \
  -vf "hwupload,nlmeans_vulkan=s=3:p=7:r=15,hwdownload,format=yuv420p" output.mp4

# Full pipeline
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i noisy.mp4 -vf "nlmeans_vulkan=s=4" \
  -c:v h264_vulkan output.mp4
```

## Vulkan Deinterlacing (bwdif_vulkan)

```bash
# Bob-Weaver
ffmpeg -init_hw_device vulkan -i interlaced.mp4 \
  -vf "hwupload,bwdif_vulkan=mode=send_frame,hwdownload,format=yuv420p" output.mp4

# Full pipeline
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i interlaced.mp4 -vf "bwdif_vulkan=1" \
  -c:v h264_vulkan output.mp4
```

## Vulkan Transitions (xfade_vulkan)

```bash
ffmpeg -init_hw_device vulkan=vk -filter_hw_device vk \
  -i clip1.mp4 -i clip2.mp4 \
  -filter_complex "\
    [0:v]hwupload[v1];\
    [1:v]hwupload[v2];\
    [v1][v2]xfade_vulkan=transition=fade:duration=1:offset=4,hwdownload,format=yuv420p[out]" \
  -map "[out]" output.mp4
```

Two-input Vulkan filters (`xfade_vulkan`, `overlay_vulkan`) need both uploaded inputs to share pixel format and colour tags. Mixing an untagged clip with one tagged `bt470bg`/`tv` made negotiation fail with `Impossible to convert between the formats supported by the filter 'Parsed_hwupload_...'`; normalise first (e.g. `format=yuv420p,setparams=colorspace=bt709:range=tv` on both before `hwupload`).

Transitions include: `fade`, `dissolve`, `wipeleft`, `wiperight`, `wipeup`, `wipedown`, `slideleft`, `slideright`, `slideup`, `slidedown`, etc.

## Libplacebo Processing (Advanced)

```bash
# HDR tonemapping (libplacebo keeps the input pixel format unless format= is set;
# a 10-bit HDR source would otherwise fail at hwdownload,format=yuv420p)
ffmpeg -init_hw_device vulkan -i hdr_input.mp4 \
  -vf "hwupload,libplacebo=tonemapping=hable:colorspace=bt709:color_primaries=bt709:color_trc=bt709:format=yuv420p,hwdownload,format=yuv420p" \
  sdr_output.mp4

# High-quality upscale (format= must match the hwdownload format)
ffmpeg -init_hw_device vulkan -i input.mp4 \
  -vf "hwupload,libplacebo=w=3840:h=2160:upscaler=ewa_lanczos:format=yuv420p10le,hwdownload,format=yuv420p10le" \
  output.mp4
```
