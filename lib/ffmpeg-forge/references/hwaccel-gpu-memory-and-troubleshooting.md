# GPU Memory and Hardware Troubleshooting

How frames move between CPU and GPU memory (hwupload, hwdownload, surface formats), and fixes for hardware pipeline errors: device and driver failures, format mismatches, and silent software fallback. Backend choice, device setup, the cross-vendor filter map and Docker are in `hwaccel.md`.

## GPU Memory Management

### Critical Concepts

PCIe transfers between CPU and GPU memory are the primary bottleneck. Keeping frames in GPU memory throughout the pipeline is critical for performance.

### Memory Flow Patterns

```text
Pattern 1: Full GPU Pipeline (OPTIMAL)
Input File -> GPU Decode -> GPU Filter -> GPU Encode -> Output File
                    |          |           |
                    v          v           v
                  [GPU Memory - No PCIe Transfer]

Pattern 2: CPU Filter Insertion (SUBOPTIMAL)
Input -> GPU Decode -> hwdownload -> CPU Filter -> hwupload -> GPU Encode -> Output
                           |                           |
                           v                           v
                     [PCIe Transfer]             [PCIe Transfer]

Pattern 3: Software Decode + GPU Encode
Input -> CPU Decode -> hwupload -> GPU Encode -> Output
                          |
                          v
                    [PCIe Transfer]
```

### Command Patterns Comparison

```bash
# OPTIMAL: full GPU pipeline - no CPU-GPU transfers
ffmpeg -y \
  -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 -vf scale_cuda=1280:720 \
  -fps_mode passthrough -c:v h264_nvenc output.mp4

# SUBOPTIMAL: GPU decode, CPU filter, GPU encode - 2 transfers
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input.mp4 \
  -vf "hwdownload,format=nv12,drawtext=text='Hello',hwupload_cuda" \
  -c:v h264_nvenc output.mp4

# AVOID: Missing -hwaccel_output_format -> frames copy to CPU after decode
ffmpeg -hwaccel cuda -i input.mp4 \
  -vf scale=1280:720 \
  -c:v h264_nvenc output.mp4
```

**Why `-hwaccel_output_format cuda` matters:** Without it, decoded frames transfer from GPU to CPU via PCIe, get processed, then transfer back to GPU for encoding. This can reduce throughput by up to 50%.

### Memory Monitoring

```bash
# NVIDIA memory and utilization
nvidia-smi dmon -s m

# Watch GPU utilization
watch -n 1 nvidia-smi

# Intel GPU
intel_gpu_top
```

### Best Practices

1. Use `-hwaccel_output_format` to keep decoded frames in GPU memory
2. Use GPU filters when available (scale_cuda, overlay_cuda, pad_cuda)
3. Batch similar operations to minimize filter graph complexity
4. Monitor GPU memory for high-resolution content
5. Use `-fps_mode passthrough` (output option) to prevent frame duplication overhead

---

## Troubleshooting

### "No NVENC capable devices found" / "OpenEncodeSessionEx failed"

```bash
nvidia-smi                                            # GPU visible, driver loaded?
nvidia-smi --query-gpu=name,driver_version --format=csv
ffmpeg -hide_banner -encoders | grep nvenc            # encoder compiled in?
```

The GPU must have NVENC (most GeForce/RTX/Quadro do; some datacenter parts such as A100 do not). Too many concurrent sessions on a GeForce card also fail with `OpenEncodeSessionEx failed: incompatible client key (21)` or `out of memory (10)`.

### "Driver does not support the required nvenc API version"

The driver is older than the nv-codec-headers FFmpeg was built against. Update the driver, or use an FFmpeg build made with older headers. See [`hwaccel-nvidia-nvenc.md`](hwaccel-nvidia-nvenc.md#requirements).

### "Cannot load libcuda.so.1" / "Cannot load libnvidia-encode.so.1"

These libraries ship with the NVIDIA driver, not the CUDA toolkit; no toolkit is needed for NVENC/NVDEC. Install or repair the driver (`nvidia-smi` must work). In Docker, run with `--gpus all -e NVIDIA_DRIVER_CAPABILITIES=compute,video,utility` so the container toolkit mounts the video libraries.

### VAAPI/QSV: "va_openDriver() returns -1" / "Failed to initialise VAAPI connection"

libva found no usable driver for the GPU. Install the driver (`intel-media-va-driver` / `intel-media-va-driver-non-free` for Intel Broadwell and newer, `mesa-va-drivers` for AMD) and check with `vainfo`. QSV on Linux sits on top of VAAPI, so it fails the same way.

### VAAPI permission denied

```bash
sudo usermod -aG video $USER
sudo usermod -aG render $USER
# Re-login or use newgrp
```

### QSV "Unsupported format"

QSV encoders take `nv12` (8-bit) or `p010le` (10-bit) system-memory frames, or `qsv` frames:

```bash
ffmpeg -i input.mp4 -vf "format=nv12" -c:v h264_qsv output.mp4
```

### "Impossible to convert between the formats supported by the filter ..."

A filter or encoder got frames in the wrong memory. `*_vaapi` and `*_vulkan` encoders accept only hardware frames: add `-hwaccel_output_format vaapi|vulkan` to the decode, or `format=nv12,hwupload` (with a filter device) before the encoder. CPU filters after GPU decode need `hwdownload,format=nv12` (8-bit) or `format=p010le` (10-bit) first.

### "Failed setup for format vaapi|vulkan|cuda: hwaccel initialisation returned error"

The hardware decoder could not handle this stream (unsupported codec/profile, or no device). FFmpeg then decodes in software and still exits 0, so check stderr, not the exit code.

### Performance Debugging

```bash
# Benchmark encode speed
ffmpeg -benchmark -i input.mp4 -c:v h264_nvenc -f null -

# Hardware decode stats
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -benchmark -i input.mp4 -f null -

# NVIDIA monitoring
nvidia-smi dmon -s u

# Intel monitoring
intel_gpu_top
```
