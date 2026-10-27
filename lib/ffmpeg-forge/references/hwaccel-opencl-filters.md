# OpenCL Filters

OpenCL GPU filters, which work across vendors (NVIDIA, AMD, Intel): device setup, compositing, keying, denoising, stabilization, sharpening, tonemapping, blur and convolution. OpenCL has no encoders; pair these filters with a CPU or vendor encoder.

## OpenCL Filter Reference

| Filter | Description | Key Parameters |
|--------|-------------|----------------|
| `overlay_opencl` | Compositing | `x`, `y` |
| `pad_opencl` | Padding | `w`, `h`, `x`, `y`, `color` |
| `colorkey_opencl` | Chroma keying | `color`, `similarity`, `blend` |
| `unsharp_opencl` | Sharpening | `lx`, `ly`, `la`, `cx`, `cy`, `ca` |
| `nlmeans_opencl` | NLMeans denoising | `s`, `p`, `r` |
| `deshake_opencl` | Stabilization | `tripod`, `smooth_strength`, `smooth_window_multiplier`, `adaptive_crop`, `debug` |
| `tonemap_opencl` | HDR tonemapping | `tonemap`, `transfer`, `matrix`, `primaries`, `format`, `peak`, `desat` |
| `avgblur_opencl` | Box blur | `sizeX`, `sizeY` |
| `convolution_opencl` | Custom kernel | `0m`, `1m`, etc. |

## OpenCL Initialization

```bash
# Quick device probe
ffmpeg -init_hw_device opencl=gpu:0.0 -filter_hw_device gpu \
  -f lavfi -i nullsrc -vf "hwupload,avgblur_opencl=2" -t 1 -f null -

# General pattern
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i input.mp4 -vf "hwupload,<filter_opencl>,hwdownload,format=yuv420p" \
  output.mp4
```

## Scaling

There is no `scale_opencl` filter. Scale on the CPU before `hwupload`, or use `scale_vulkan` / `libplacebo` (`hwaccel-vulkan.md`) for GPU scaling.

## Compositing (PiP)

```bash
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i main.mp4 -i overlay.mp4 \
  -filter_complex "\
    [0:v]format=nv12,hwupload[main];\
    [1:v]scale=320:180,format=nv12,hwupload[pip];\
    [main][pip]overlay_opencl=x=10:y=10,hwdownload,format=nv12[out]" \
  -map "[out]" output.mp4
```

## Chroma Keying (colorkey_opencl)

`colorkey_opencl` works on RGB and writes the key into the alpha channel. `overlay_opencl` does not blend that alpha when main and overlay have the same layout (both `rgba` selects its no-alpha kernel, so the foreground simply covers the background). Download the keyed foreground and composite on the CPU:

```bash
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i greenscreen.mp4 -i background.mp4 \
  -filter_complex "\
    [0:v]format=rgba,hwupload,colorkey_opencl=0x00FF00:0.3:0.1,hwdownload,format=rgba[fg];\
    [1:v][fg]overlay=format=auto,format=yuv420p[out]" \
  -map "[out]" output.mp4
```

## Denoising (nlmeans_opencl)

```bash
# Basic
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i noisy.mp4 \
  -vf "hwupload,nlmeans_opencl=s=3:p=7:r=15,hwdownload,format=yuv420p" \
  output.mp4

# Strong
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i noisy.mp4 \
  -vf "hwupload,nlmeans_opencl=s=5:p=7:r=21,hwdownload,format=yuv420p" \
  output.mp4
```

## Stabilization (deshake_opencl)

```bash
# General
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i shaky.mp4 \
  -vf "hwupload,deshake_opencl,hwdownload,format=yuv420p" output.mp4

# Tripod
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i shaky.mp4 \
  -vf "hwupload,deshake_opencl=tripod=1,hwdownload,format=yuv420p" output.mp4
```

## Sharpening (unsharp_opencl)

```bash
# Basic
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i input.mp4 \
  -vf "hwupload,unsharp_opencl=lx=5:ly=5:la=1.0,hwdownload,format=yuv420p" \
  output.mp4

# Subtle
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i input.mp4 \
  -vf "hwupload,unsharp_opencl=lx=3:ly=3:la=0.5,hwdownload,format=yuv420p" \
  output.mp4
```

## HDR Tonemapping (tonemap_opencl)

`tonemap_opencl` accepts only P010 or NV12 input and outputs the input format unless `format=` is set, so upload P010 and request `format=nv12` to match the `hwdownload` format.

```bash
# Hable
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i hdr_input.mp4 \
  -vf "format=p010,hwupload,tonemap_opencl=tonemap=hable:transfer=bt709:matrix=bt709:primaries=bt709:format=nv12,hwdownload,format=nv12" \
  sdr_output.mp4

# Reinhard
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i hdr_input.mp4 \
  -vf "format=p010,hwupload,tonemap_opencl=tonemap=reinhard:param=0.5:format=nv12,hwdownload,format=nv12" \
  sdr_output.mp4
```

| Algorithm | Description |
|-----------|-------------|
| `none` | No tonemapping |
| `clip` | Simple clipping |
| `linear` | Linear scaling |
| `gamma` | Gamma-based |
| `reinhard` | Reinhard operator |
| `hable` | Hable/Filmic (most popular) |
| `mobius` | Mobius (preserves blacks) |

`tonemap_opencl` has no `bt2390` mode; for BT.2390 use `libplacebo=tonemapping=bt.2390` (Vulkan, see `hwaccel-vulkan.md`).

## Blur

```bash
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i input.mp4 \
  -vf "hwupload,avgblur_opencl=sizeX=5:sizeY=5,hwdownload,format=yuv420p" \
  output.mp4
```

## Custom Convolution

```bash
# Edge detection
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i input.mp4 \
  -vf "hwupload,convolution_opencl=0m='-1 -1 -1 -1 8 -1 -1 -1 -1':0rdiv=1:0bias=128,hwdownload,format=yuv420p" \
  output.mp4

# Sharpen
ffmpeg -init_hw_device opencl=gpu -filter_hw_device gpu \
  -i input.mp4 \
  -vf "hwupload,convolution_opencl=0m='0 -1 0 -1 5 -1 0 -1 0':0rdiv=1:0bias=0,hwdownload,format=yuv420p" \
  output.mp4
```
