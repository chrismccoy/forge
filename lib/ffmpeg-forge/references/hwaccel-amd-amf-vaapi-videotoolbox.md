# AMD AMF, VAAPI, and Apple VideoToolbox

Encoding, decoding and GPU filters on AMD (AMF on Windows), VAAPI (Linux AMD and Intel) and Apple VideoToolbox (macOS): requirements, device setup, rate control and full GPU pipelines. Backend choice and the cross-vendor filter map are in `hwaccel.md`.

## AMD AMF

### Requirements
- AMD GPU (GCN or newer)
- AMD drivers with AMF support
- FFmpeg built with `--enable-amf`

### Detection

```bash
ffmpeg -encoders | grep amf
```

### Basic AMF Encoding

```bash
# H.264 AMF
ffmpeg -i input.mp4 -c:v h264_amf -quality balanced -b:v 5M output.mp4

# H.265/HEVC AMF
ffmpeg -i input.mp4 -c:v hevc_amf -quality balanced -b:v 4M output.mp4

# AV1 AMF (RDNA3+)
ffmpeg -i input.mp4 -c:v av1_amf -quality balanced -b:v 3M output.mp4
```

### AMF Quality Presets

| Preset | Description |
|--------|-------------|
| speed | Fastest encoding |
| balanced | **Recommended** |
| quality | Best quality |

### AMF with Hardware Decode (Windows)

AMF encoders accept D3D11 (and DXVA2) surfaces directly, so decode on the GPU and keep frames there:

```bash
# D3D11VA decode -> AMF encode
ffmpeg -hwaccel d3d11va -hwaccel_output_format d3d11 \
  -i input.mp4 -c:v hevc_amf -quality balanced output.mp4

# DXVA2 decode (older Windows systems)
ffmpeg -hwaccel dxva2 -hwaccel_output_format dxva2_vld \
  -i input.mp4 -c:v h264_amf output.mp4
```

### AMD Hardware Upscaling (FFmpeg 8.0+)

```bash
# Super resolution
ffmpeg -i input.mp4 \
  -vf "sr_amf=4096:2160:algorithm=sr1-1" \
  -c:v hevc_amf output.mp4
```

## VAAPI (Linux)

### Requirements
- Intel or AMD GPU on Linux. NVIDIA works only through the third-party `nvidia-vaapi-driver`, which is decode-only; encode on NVIDIA with NVENC (`hwaccel-nvidia-nvenc.md`)
- VAAPI drivers (intel-media-driver, mesa-va-drivers)
- FFmpeg built with `--enable-vaapi`

### Detection

```bash
vainfo
ffmpeg -encoders | grep vaapi
ffmpeg -hide_banner -hwaccels   # VAAPI decode is a hwaccel, not a separate decoder: look for "vaapi"
```

### Basic VAAPI Encoding

```bash
# H.264 VAAPI (upload from CPU)
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 -vf 'format=nv12,hwupload' \
  -c:v h264_vaapi -b:v 5M output.mp4

# H.265/HEVC VAAPI
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 -vf 'format=nv12,hwupload' \
  -c:v hevc_vaapi -b:v 4M output.mp4
```

### Full VAAPI Pipeline

```bash
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mp4 -c:v h264_vaapi -b:v 5M output.mp4
```

### VAAPI Scaling

```bash
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mp4 -vf 'scale_vaapi=w=1280:h=720' \
  -c:v h264_vaapi output.mp4
```

### VAAPI Deinterlacing

```bash
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i interlaced.mp4 -vf 'deinterlace_vaapi' \
  -c:v h264_vaapi output.mp4
```

Other VAAPI filters: `denoise_vaapi`, `sharpness_vaapi`, `procamp_vaapi`, `tonemap_vaapi`, `transpose_vaapi`, `overlay_vaapi`, `pad_vaapi`, `drawbox_vaapi`, `hstack_vaapi`/`vstack_vaapi`/`xstack_vaapi`.

### VAAPI Rate Control

`-rc_mode` takes `auto`, `CQP`, `CBR`, `VBR`, `ICQ`, `QVBR`, `AVBR`; which ones work depends on the driver and GPU.

```bash
# Constant QP (SKILL.md default for *_vaapi)
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 -vf 'format=nv12,hwupload' \
  -c:v hevc_vaapi -rc_mode CQP -qp 23 output.mp4

# Capped VBR
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mp4 -vf 'format=nv12,hwupload' \
  -c:v h264_vaapi -rc_mode VBR -b:v 5M -maxrate 7M output.mp4
```

### VVC VAAPI Decoding (FFmpeg 8.0+)

FFmpeg 8.0 adds VVC/H.266 hardware decoding via VAAPI. Support depends on the GPU and driver: Intel Xe2 (Lunar Lake) or newer with the Intel media driver; on AMD it depends on driver/hardware (Mesa/radeonsi VVC support required). Check that `vainfo` lists a VVC profile.

```bash
# Hardware VVC decoding
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.vvc -c:v h264_vaapi output.mp4

# VVC decode + transcode to H.265
ffmpeg -hwaccel vaapi \
  -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i input.mkv -c:v hevc_vaapi -b:v 4M output.mp4

# VVC with Screen Content Coding (SCC)
# FFmpeg 8.0's full SCC support (IBC, Palette Mode, ACT) is in the native
# software VVC decoder, not in VAAPI; decode SCC streams without -hwaccel
ffmpeg -i screen_recording.vvc output.mp4
```

**VVC VAAPI Requirements:**
- Intel Xe2 graphics (Lunar Lake) or newer for full VVC support
- FFmpeg 8.0 or later
- Intel media driver with VVC support

## Apple VideoToolbox

### Requirements
- macOS 10.8+ or iOS 8+
- FFmpeg built with `--enable-videotoolbox`

### Detection

```bash
ffmpeg -encoders | grep videotoolbox
ffmpeg -hide_banner -hwaccels   # VideoToolbox decode is a hwaccel: look for "videotoolbox"
```

### Basic VideoToolbox Encoding

```bash
# H.264 VideoToolbox
ffmpeg -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4

# H.265/HEVC VideoToolbox (Apple-compatible tag)
ffmpeg -i input.mp4 -c:v hevc_videotoolbox -b:v 4M -tag:v hvc1 output.mp4

# ProRes VideoToolbox
ffmpeg -i input.mp4 -c:v prores_videotoolbox -profile:v 3 output.mov
```

### VideoToolbox Quality Settings

```bash
# Quality-based
ffmpeg -i input.mp4 -c:v h264_videotoolbox -q:v 65 output.mp4

# Hardware decode + encode
ffmpeg -hwaccel videotoolbox \
  -i input.mp4 -c:v h264_videotoolbox -b:v 5M output.mp4
```
