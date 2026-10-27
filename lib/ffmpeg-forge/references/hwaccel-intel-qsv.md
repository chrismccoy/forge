# Intel Quick Sync Video (QSV)

Intel QSV encoding, decoding and `vpp_qsv` processing: runtime requirements, detection, quality settings, full GPU pipelines, multi-GPU selection and VVC decoding. Backend choice and the cross-vendor filter map are in `hwaccel.md`.

## Requirements
- Intel integrated graphics or an Intel Arc GPU
- Runtime library matching the build:
  - `--enable-libvpl` (oneVPL; Ubuntu/Debian and most current builds): Gen12 / Tiger Lake and newer, plus Arc. Older iGPUs are not supported by the oneVPL GPU runtime.
  - `--enable-libmfx` (legacy Intel Media SDK): Broadwell through Ice Lake/Tiger Lake. Media SDK is discontinued.
- On Linux, a working VAAPI driver (`intel-media-va-driver`), because QSV runs on top of VAAPI; `vainfo` must succeed

## Detection

```bash
ffmpeg -encoders | grep qsv
ffmpeg -decoders | grep qsv
ls /dev/dri/
vainfo
```

## Basic QSV Encoding

```bash
# H.264 QSV
ffmpeg -init_hw_device qsv=hw -filter_hw_device hw \
  -i input.mp4 -c:v h264_qsv -preset medium -b:v 5M output.mp4

# H.265/HEVC QSV
ffmpeg -init_hw_device qsv=hw -filter_hw_device hw \
  -i input.mp4 -c:v hevc_qsv -preset medium -b:v 4M output.mp4

# AV1 QSV encode (Intel Arc, or Core Ultra / Meteor Lake and newer;
# 11th-14th gen Core iGPUs decode AV1 but cannot encode it)
ffmpeg -init_hw_device qsv=hw -filter_hw_device hw \
  -i input.mp4 -c:v av1_qsv -preset medium -b:v 3M output.mp4
```

## Full QSV Pipeline

```bash
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -c:v h264_qsv -preset medium -b:v 5M output.mp4
```

## QSV Quality Settings

```bash
# Constant quality (recommended)
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -c:v hevc_qsv -preset slow \
  -global_quality 22 -extbrc 1 -look_ahead_depth 40 output.mp4

# VBR with lookahead
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -c:v h264_qsv -preset medium \
  -b:v 5M -maxrate 7M -bufsize 10M \
  -look_ahead 1 -look_ahead_depth 40 output.mp4
```

| Parameter | Description | Range |
|-----------|-------------|-------|
| `-global_quality` | Quality level (like CRF) | 1-51 (lower = better) |
| `-preset` | Encoding speed/quality | `veryfast`, `faster`, `fast`, `medium`, `slow`, `slower`, `veryslow` |
| `-look_ahead` | Enable lookahead (`h264_qsv` only; HEVC/AV1 use `-extbrc 1 -look_ahead_depth N`) | 0 or 1 |
| `-look_ahead_depth` | Lookahead frames (`hevc_qsv`/`av1_qsv`: only with `-extbrc 1`) | 0-100 (0 = driver default) |

## Multi-GPU QSV (Linux)

`-init_hw_device qsv=hw:/dev/dri/renderD129` does **not** select that GPU: the QSV device string is an MFX implementation name, so the path is ignored and the first render node is used. Derive QSV from a VAAPI device on the wanted node, or pass `child_device`:

```bash
# Derive from a VAAPI device on the second GPU
ffmpeg -init_hw_device vaapi=va:/dev/dri/renderD129 \
  -init_hw_device qsv=hw@va -filter_hw_device hw \
  -i input.mp4 -c:v h264_qsv output.mp4

# Equivalent: child_device option
ffmpeg -init_hw_device qsv=hw,child_device=/dev/dri/renderD129 \
  -filter_hw_device hw \
  -i input.mp4 -c:v h264_qsv output.mp4
```

## QSV Video Processing (vpp_qsv)

`vpp_qsv` combines scaling, format conversion, deinterlacing (`deinterlace=1` bob, `2` advanced), denoise (`denoise=0-100`), detail enhancement, ProcAmp and HDR tonemapping (`tonemap=1`) in one GPU pass. `scale_qsv` and `deinterlace_qsv` are single-purpose alternatives; `overlay_qsv` and `hstack_qsv`/`vstack_qsv`/`xstack_qsv` composite on the GPU.

```bash
# Scaling
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -vf "vpp_qsv=w=1280:h=720" \
  -c:v h264_qsv -preset medium output.mp4

# Deinterlacing (advanced)
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i interlaced.mp4 -vf "vpp_qsv=deinterlace=2" \
  -c:v h264_qsv output.mp4

# Scale + deinterlace + denoise in one pass
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -i input.mp4 -vf "vpp_qsv=w=1920:h=1080:deinterlace=2:denoise=50" \
  -c:v hevc_qsv output.mp4
```

## VVC/H.266 QSV Decoding (FFmpeg 7.1+)

```bash
ffmpeg -hwaccel qsv -hwaccel_output_format qsv \
  -c:v vvc_qsv -i input.vvc \
  -c:v h264_qsv output.mp4
```
