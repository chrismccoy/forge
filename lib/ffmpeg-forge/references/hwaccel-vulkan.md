# Vulkan Video and Vulkan Filters

Vulkan encode/decode pipelines and the `*_vulkan` / `libplacebo` filters. Compute codecs (FFv1, ProRes RAW), the per-version feature table, device selection and troubleshooting are in [`fundamentals-vulkan-compute-codecs.md`](fundamentals-vulkan-compute-codecs.md).

## Contents

- [Mechanisms](#mechanisms)
- [Basic Vulkan Encoding](#basic-vulkan-encoding) and [Full Vulkan Pipeline](#full-vulkan-pipeline)
- [Vulkan Filters Reference](#vulkan-filters-reference)
- [Scaling](#vulkan-scaling), [Compositing](#vulkan-compositing), [Rotation and Flip](#rotation-and-flip), [Blur](#blur-effects), [Chromatic Aberration](#chromatic-aberration)
- [Denoising](#vulkan-denoising-nlmeans_vulkan), [Deinterlacing](#vulkan-deinterlacing-bwdif_vulkan), [Transitions](#vulkan-transitions-xfade_vulkan)
- [Libplacebo Processing](#libplacebo-processing-advanced)

## Mechanisms

Cross-platform GPU acceleration via Vulkan (AMD, Intel, NVIDIA) uses two different mechanisms:

- **Vulkan Video (fixed-function)**: H.264/HEVC/AV1 encode and H.264/HEVC/AV1/VP9 decode drive the GPU's hardware video engine through the `VK_KHR_video_queue`, `VK_KHR_video_encode_queue` / `VK_KHR_video_decode_queue` and per-codec extensions. A Vulkan 1.3 driver is not enough: the driver and GPU must expose these extensions, otherwise the encoder fails with `Device does not support the VK_KHR_video_encode_queue extension!`.
- **Vulkan compute**: FFv1 encode/decode, ProRes RAW decode (8.0+) and all `*_vulkan` filters run as compute shaders and work on any Vulkan 1.3 compute-capable device.

To list the video extensions a device exposes, run `vulkaninfo | grep VK_KHR_video`.

Version support (6.1 decode, 7.1 H.264/HEVC encode, 8.0 AV1 encode, VP9 decode, FFv1 and ProRes RAW) is tabulated in [`fundamentals-vulkan-compute-codecs.md`](fundamentals-vulkan-compute-codecs.md#codec-support-by-version).

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
```

FFv1 Vulkan (lossless, compute shaders, 8.0+) is covered in [`fundamentals-vulkan-compute-codecs.md`](fundamentals-vulkan-compute-codecs.md#ffv1-vulkan-codec).

## Full Vulkan Pipeline

```bash
ffmpeg -init_hw_device vulkan=vk \
  -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.mp4 \
  -vf "scale_vulkan=1280:720" \
  -c:v h264_vulkan output.mp4
```

## Hardware Decode to Vulkan Encode

```bash
# Any codec the driver decodes (H.264/HEVC/AV1; VP9 needs VK_KHR_video_decode_vp9, 8.0+)
# -> H.264 Vulkan encode, frames stay on the GPU
ffmpeg -hwaccel vulkan -hwaccel_output_format vulkan \
  -i input.webm -c:v h264_vulkan output.mp4
```

If the driver cannot decode the stream, FFmpeg prints `Failed setup for format vulkan` and silently decodes in software (exit code 0); the `h264_vulkan` encoder then fails because it gets software frames. ProRes RAW decode and FFv1 are in [`fundamentals-vulkan-compute-codecs.md`](fundamentals-vulkan-compute-codecs.md).

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
| `nlmeans_vulkan` | NLMeans denoising | `s`, `p`, `r` (radius) | 6.1 |
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
# overlay_vulkan x/y are integers, not expressions: compute W-w-10 by hand
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
# Basic. r is a RADIUS here (window = 2r+1 pixels), unlike CPU nlmeans where
# r is the window size: r=7 matches CPU nlmeans r=15 (15x15). The default r=15
# searches 31x31 and ran about 4x slower in a test (8.3 s vs 2.1 s, 320x180, 3 s)
ffmpeg -init_hw_device vulkan -i noisy.mp4 \
  -vf "hwupload,nlmeans_vulkan=s=3:p=7:r=7,hwdownload,format=yuv420p" output.mp4

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
