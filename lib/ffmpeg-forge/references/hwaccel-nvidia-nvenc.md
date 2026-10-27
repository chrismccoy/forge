# NVIDIA NVENC/NVDEC

Detailed encoding, GPU pipeline, CUDA filter, scale_npp, chromakey, quality tuning, two-pass, B-frames, and multi-GPU patterns for NVIDIA hardware.

## Contents

- [Requirements](#requirements) and [Detection](#detection)
- [Basic NVENC Encoding](#basic-nvenc-encoding), [Presets](#nvenc-presets-p1-p7), [Tune Options](#nvenc-tune-options)
- [Full GPU Pipeline](#full-gpu-pipeline-decode--encode), [Decoder-Side Resize](#decoder-side-resize-and-crop-cuvid)
- [GPU Scaling and Filtering](#gpu-scaling-and-filtering), [CUDA Filters Reference](#cuda-filters-reference), [scale_npp](#scale_npp-nvidia-performance-primitives)
- [overlay_cuda Formats and PNG Logos](#overlay_cuda-pixel-formats-and-png-logos), [GPU Chromakey](#gpu-chromakey-green-screen)
- [Hybrid GPU + CPU Pipelines](#hybrid-gpu--cpu-pipelines)
- [Quality Optimization](#nvenc-quality-optimization), [Quality Parameters](#nvenc-quality-parameters), [Two-Pass](#nvenc-two-pass-encoding), [B-Frames and GOP](#nvenc-b-frames-and-gop)
- [Multi-GPU](#nvidia-multi-gpu), [1:N ABR Ladder](#1n-abr-ladder-single-input-multiple-outputs), [Parallel Throughput](#parallel-throughput)

## Requirements

- NVIDIA GPU with NVENC. Current drivers support Maxwell (GTX 900) and newer; Kepler (GTX 600/700) is limited to the legacy R470 driver, which FFmpeg 8.x's NVENC cannot use.
- An NVIDIA driver at least as new as the nv-codec-headers version FFmpeg was built with requires (headers 12.1: 530+, 12.2: 550+, 13.0: 570+ on Linux). An older driver fails with `Driver does not support the required nvenc API version`.
- FFmpeg built with `--enable-nvenc --enable-nvdec --enable-cuvid` (autodetected when nv-codec-headers is installed). The CUDA filters (`scale_cuda`, `overlay_cuda`, `pad_cuda`, ...) also need `--enable-cuda-nvcc` or `--enable-cuda-llvm`; `scale_npp` needs `--enable-libnpp --enable-nonfree`.
- No CUDA toolkit is needed at runtime. `libcuda.so.1` and `libnvidia-encode.so.1` come with the driver.

## Detection

```bash
ffmpeg -encoders | grep nvenc
ffmpeg -decoders | grep cuvid
nvidia-smi
ffmpeg -hwaccels
```

## Basic NVENC Encoding

```bash
# H.264 NVENC
ffmpeg -i input.mp4 -c:v h264_nvenc -preset p4 -b:v 5M output.mp4

# H.265/HEVC NVENC
ffmpeg -i input.mp4 -c:v hevc_nvenc -preset p4 -b:v 4M output.mp4

# AV1 NVENC (encode needs RTX 40 series+; AV1 decode works from RTX 30)
ffmpeg -i input.mp4 -c:v av1_nvenc -preset p4 -b:v 3M output.mp4
```

## NVENC Presets (p1-p7)

`p4` is the encoder default. For file encodes the recommended starting point is `-preset p5 -tune hq -rc vbr -cq 23 -b:v 0` (the SKILL.md quality table).

| Preset | Speed | Quality | Use Case |
|--------|-------|---------|----------|
| p1 | Fastest | Lowest | Real-time capture |
| p2 | Faster | Low | Screen recording |
| p3 | Fast | Medium | General streaming |
| p4 | Medium | Good | Default |
| p5 | Slow | Better | **Recommended** for files, high-quality streaming |
| p6 | Slower | Best | Offline encoding |
| p7 | Slowest | Highest | Maximum quality |

The legacy names (`slow`, `medium`, `fast`, `hq`, `ll`, ...) are still accepted but map to old behaviour; use `p1`-`p7`.

## NVENC Tune Options

| Tune | Use Case |
|------|----------|
| `hq` | High quality encoding (default) |
| `ll` | Low latency (streaming) |
| `ull` | Ultra low latency |
| `lossless` | Lossless encoding |

## Full GPU Pipeline (Decode + Encode)

```bash
ffmpeg -y \
  -hwaccel cuda \
  -hwaccel_output_format cuda \
  -i input.mp4 \
  -fps_mode passthrough -c:v h264_nvenc \
  -preset p4 \
  -b:v 5M \
  -c:a copy \
  output.mp4
```

### Decoder-Side Resize and Crop (cuvid)

`-resize` and `-crop` are options of the `*_cuvid` decoders, so select the decoder explicitly; they have no effect with `-hwaccel cuda` alone.

```bash
# Resize in the NVDEC decoder (no separate scale filter)
ffmpeg -y \
  -c:v h264_cuvid -resize 1280x720 \
  -i input.mp4 \
  -fps_mode passthrough -c:v h264_nvenc \
  output.mp4

# Crop (top)x(bottom)x(left)x(right) pixels in the decoder
ffmpeg -c:v h264_cuvid -crop 0x0x240x240 -i input.mp4 -c:v h264_nvenc output.mp4
```

## GPU Scaling and Filtering

```bash
# scale_cuda
ffmpeg -y \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf scale_cuda=1280:720 \
  -fps_mode passthrough -c:v h264_nvenc -preset p4 output.mp4

# scale_cuda with pixel-format conversion (e.g. NV12 -> YUV420P for overlay_cuda)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_cuda=1920:1080:format=yuv420p" \
  -c:v h264_nvenc output.mp4

# Keep aspect ratio (-2 = even height computed from width)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "scale_cuda=1280:-2" \
  -c:v h264_nvenc output.mp4

# overlay_cuda (x/y accept expressions)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i main.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i overlay.mp4 \
  -filter_complex "[0:v][1:v]overlay_cuda=10:10" \
  -c:v h264_nvenc output.mp4

# pad_cuda (FFmpeg 8.0+)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -vf "pad_cuda=1920:1080:(ow-iw)/2:(oh-ih)/2:black" \
  -c:v h264_nvenc output.mp4

# Letterbox via pad_cuda
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -vf "scale_cuda=1920:-2,pad_cuda=1920:1080:(ow-iw)/2:(oh-ih)/2" \
  -c:v h264_nvenc output.mp4
```

## CUDA Filters Reference

As of FFmpeg 8.0; `pad_cuda` needs 8.0+.

| Filter | Description | Key Parameters |
|--------|-------------|----------------|
| `scale_cuda` | GPU video scaling | `w`, `h`, `format`, `interp_algo` |
| `scale_npp` | NPP-based scaling (higher quality) | `w`, `h`, `interp_algo` |
| `overlay_cuda` | GPU overlay/compositing | `x`, `y`, `eof_action` |
| `pad_cuda` | GPU padding (8.0+) | `w`, `h`, `x`, `y`, `color` |
| `chromakey_cuda` | GPU chroma keying | `color`, `similarity`, `blend` |
| `colorspace_cuda` | Color range conversion (TV/PC) only | `range` (`tv`/`mpeg`, `pc`/`jpeg`) |
| `bilateral_cuda` | Bilateral filter | `sigmaS`, `sigmaR`, `window_size` |
| `bwdif_cuda` | Deinterlacing | `mode`, `parity`, `deint` |
| `hwupload_cuda` | Upload to GPU | `device` (index; ignores `-filter_hw_device`) |
| `hwdownload` | Download from GPU | - |

## scale_npp (NVIDIA Performance Primitives)

```bash
# Super-sampling downscale
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 -vf "scale_npp=1280:720:interp_algo=super" \
  -c:v h264_nvenc output.mp4

# Lanczos upscale
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 -vf "scale_npp=1920:1080:interp_algo=lanczos" \
  -c:v h264_nvenc output.mp4
```

| Algorithm | Quality | Speed | Best For |
|-----------|---------|-------|----------|
| `nn` | Low | Fastest | Pixel art, nearest neighbor |
| `linear` | Medium | Fast | General use |
| `cubic` | Good | Medium | Smooth scaling |
| `lanczos` | High | Slow | High quality upscaling |
| `super` | Best | Slowest | Downscaling only |

## overlay_cuda Pixel Formats and PNG Logos

- Main input: NV12 or YUV420P.
- Overlay input: NV12, YUV420P, or YUVA420P.
- Formats must pair up: an NV12 main needs an NV12 overlay; a YUV420P main takes a YUV420P or YUVA420P (alpha) overlay. NVDEC outputs NV12, so convert the main with `scale_cuda=format=yuv420p` before blending an alpha overlay.

```bash
# PNG logo with alpha: decoded on the CPU, so convert to YUVA420P and upload.
# hwupload uses the -filter_hw_device; the decoder shares the same device.
ffmpeg -init_hw_device cuda=cu -filter_hw_device cu \
  -hwaccel cuda -hwaccel_device cu -hwaccel_output_format cuda -i main.mp4 \
  -i logo.png \
  -filter_complex "[0:v]scale_cuda=format=yuv420p[main];[1:v]scale=200:-2,format=yuva420p,hwupload[logo];[main][logo]overlay_cuda=W-w-10:H-h-10" \
  -c:v h264_nvenc output.mp4
```

## GPU Chromakey (Green Screen)

`chromakey_cuda` outputs YUVA420P and `overlay_cuda` only blends a YUVA420P overlay onto a YUV420P main, so convert NVDEC's NV12 with `scale_cuda=format=yuv420p` first.

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i greenscreen.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i background.mp4 \
  -filter_complex "[0:v]scale_cuda=format=yuv420p,chromakey_cuda=0x00FF00:0.3:0.1[fg];[1:v]scale_cuda=format=yuv420p[bg];[bg][fg]overlay_cuda" \
  -c:v h264_nvenc output.mp4
```

## Hybrid GPU + CPU Pipelines

Download with `hwdownload,format=nv12` (8-bit) or `format=p010le` (10-bit/HDR) before CPU filters, and re-upload with `hwupload_cuda` after them.

```bash
# CPU decode -> CPU filter -> GPU encode
ffmpeg -i input.mp4 \
  -vf "fade=in:0:30,hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# GPU decode -> CPU drawtext -> GPU encode
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "hwdownload,format=nv12,drawtext=text='Hello':fontsize=48,hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# Full hybrid: GPU scale -> CPU text -> GPU encode
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
  -filter_complex "\
    [0:v]scale_cuda=1920:1080[scaled];\
    [scaled]hwdownload,format=nv12[cpu];\
    [cpu]drawtext=text='Watermark':fontsize=48:x=10:y=10[text];\
    [text]hwupload_cuda[gpu]" \
  -map "[gpu]" \
  -c:v h264_nvenc output.mp4
```

## NVENC Quality Optimization

```bash
# Recommended file encode (SKILL.md default) with lookahead and AQ
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc -preset p5 -tune hq \
  -rc vbr -cq 23 -b:v 0 \
  -rc-lookahead 32 -spatial-aq 1 -temporal-aq 1 \
  -c:a copy output.mp4

# Constant QP (CQP)
ffmpeg -i input.mp4 \
  -c:v h264_nvenc -preset p4 -rc constqp -qp 23 \
  -c:a copy output.mp4
```

## NVENC Quality Parameters

| Parameter | Description | Recommended |
|-----------|-------------|-------------|
| `-rc-lookahead` | Frames to look ahead for rate control (default 0 = off) | 20-32 |
| `-spatial-aq` | Spatial adaptive quantization | 1 (enabled) |
| `-temporal-aq` | Temporal adaptive quantization | 1 (enabled) |
| `-aq-strength` | Spatial AQ strength, 1 (low) - 15 (aggressive) | 8 (default) |
| `-bf` | Number of B-frames | 3-4 |
| `-b_ref_mode` | B-frames as references: `disabled`, `each`, `middle` | `middle` (HEVC needs Turing+) |
| `-cq` | Target quality for `-rc vbr` (0 = automatic) | 18-28 |

## NVENC Two-Pass Encoding

`-multipass` replaces the older boolean `-2pass` (still accepted by h264/hevc_nvenc, absent from av1_nvenc). `qres` runs the first pass at quarter resolution, `fullres` at full resolution.

```bash
ffmpeg -i input.mp4 \
  -c:v h264_nvenc -preset p5 -multipass fullres -b:v 5M \
  -c:a copy output.mp4
```

## NVENC B-Frames and GOP

```bash
ffmpeg -i input.mp4 \
  -c:v hevc_nvenc -preset p4 -bf 4 -b_ref_mode middle -g 250 \
  -c:a copy output.mp4
```

## NVIDIA Multi-GPU

```bash
# Parallel jobs on different GPUs
ffmpeg -hwaccel cuda -hwaccel_device 0 -hwaccel_output_format cuda \
  -i input1.mp4 -c:v h264_nvenc output1.mp4 &

ffmpeg -hwaccel cuda -hwaccel_device 1 -hwaccel_output_format cuda \
  -i input2.mp4 -c:v h264_nvenc output2.mp4 &

wait

# Named device for decode + filters + encode (all on GPU 1)
ffmpeg -init_hw_device cuda=gpu1:1 -filter_hw_device gpu1 \
  -hwaccel cuda -hwaccel_device gpu1 -hwaccel_output_format cuda -i input.mp4 \
  -filter_complex "[0:v]scale_cuda=1280:720[scaled]" \
  -map "[scaled]" -c:v h264_nvenc output.mp4
```

## 1:N ABR Ladder (Single Input, Multiple Outputs)

One process decodes once and shares the CUDA context across all rungs, which is cheaper than separate processes.

```bash
ffmpeg -y \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -filter_complex "[0:v]split=3[v1][v2][v3];\
    [v1]scale_cuda=1920:1080[hd];\
    [v2]scale_cuda=1280:720[sd];\
    [v3]scale_cuda=640:360[mobile]" \
  -map "[hd]" -fps_mode passthrough -c:v h264_nvenc -b:v 5M output_1080p.mp4 \
  -map "[sd]" -fps_mode passthrough -c:v h264_nvenc -b:v 2M output_720p.mp4 \
  -map "[mobile]" -fps_mode passthrough -c:v h264_nvenc -b:v 500k output_360p.mp4
```

## Parallel Throughput

Several concurrent sessions usually raise aggregate fps. GeForce drivers cap simultaneous NVENC sessions per system (the limit has changed between driver releases), so measure aggregate fps across all jobs.

```bash
export CUDA_VISIBLE_DEVICES=0   # pin all jobs to GPU 0

for i in {1..4}; do
  ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
    -i input_$i.mp4 -c:v h264_nvenc output_$i.mp4 &
done
wait
```

### Splitting One Long File

```bash
# 1. Split at keyframes into ~60 s pieces (stream copy, no re-encode)
ffmpeg -i input.mp4 -map 0 -c copy -f segment -segment_time 60 \
  -reset_timestamps 1 segment_%03d.mp4

# 2. Encode the pieces in parallel
for seg in segment_*.mp4; do
  ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
    -i "$seg" -c:v h264_nvenc -c:a copy "processed_$seg" &
done
wait

# 3. Join with the concat demuxer
printf "file '%s'\n" processed_segment_*.mp4 > concat.txt
ffmpeg -f concat -safe 0 -i concat.txt -c copy final.mp4
```

Segments cut only at keyframes, so piece lengths vary. Check the joined file's duration and A/V sync.
