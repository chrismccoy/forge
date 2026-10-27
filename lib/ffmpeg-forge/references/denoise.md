# FFmpeg Noise Reduction

Comprehensive guide to video and audio denoising filters.

## Contents

- [Quick Reference](#quick-reference)
- [Video Denoising](#video-denoising)
- [Audio Denoising](#audio-denoising)
- [Combined Workflows](#combined-workflows)
- [Filter Comparison](#filter-comparison)
- [Parameter Tuning Tips](#parameter-tuning-tips)
- [Best Practices](#best-practices)

## Quick Reference

| Task | Filter | Command Pattern |
|------|--------|-----------------|
| Video denoising (best) | `nlmeans` | `-vf nlmeans=s=3:p=7:r=15` |
| Video denoising (fast) | `hqdn3d` | `-vf hqdn3d=4:3:6:4.5` |
| GPU video denoising | `nlmeans_vulkan` | `-vf nlmeans_vulkan` |
| Audio denoising | `afftdn` | `-af afftdn=nf=-25` |
| Adaptive temporal | `atadenoise` | `-vf atadenoise` |

---

## Video Denoising

### nlmeans - Non-Local Means (Best Quality)

The highest quality software denoiser, using non-local means algorithm.

```bash
# Basic denoising
ffmpeg -i noisy.mp4 -vf "nlmeans" output.mp4

# Medium denoising (good default)
ffmpeg -i noisy.mp4 -vf "nlmeans=s=3.0:p=7:r=15" output.mp4

# Strong denoising (very noisy footage)
ffmpeg -i noisy.mp4 -vf "nlmeans=s=5.0:p=7:r=15" output.mp4

# Light denoising (preserve detail)
ffmpeg -i noisy.mp4 -vf "nlmeans=s=1.5:p=5:r=9" output.mp4

# Denoise only chroma (preserve luma detail). hqdn3d treats 0 as "use the
# default" (luma 4), so 0 still denoises luma; a tiny non-zero luma strength
# leaves luma bit-exact (verified: luma PSNR = inf) while chroma is filtered
ffmpeg -i noisy.mp4 -vf "hqdn3d=luma_spatial=0.0001:chroma_spatial=6:luma_tmp=0.0001:chroma_tmp=6" output.mp4

# Same result, explicit: denoise a copy, then take Y from the original and
# U/V from the denoised copy (yuv420p input)
ffmpeg -i noisy.mp4 -filter_complex \
  "[0:v]split[orig][d];[d]hqdn3d=chroma_spatial=6:chroma_tmp=6[dn];\
   [orig][dn]mergeplanes=format=yuv420p:map1s=1:map1p=1:map2s=1:map2p=2" output.mp4

# nlmeans has one strength (s) for all planes; tune chroma separately via pc/rc
ffmpeg -i noisy.mp4 -vf "nlmeans=s=3.0:p=7:pc=5:r=15:rc=9" output.mp4
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `s` | Denoising strength (sigma) | 1.0 | 1-30 |
| `p` | Patch size (use odd values) | 7 | 0-99 |
| `pc` | Patch size for chroma | 0 (same as p) | 0-99 |
| `r` | Research window size (use odd values) | 15 | 0-99 |
| `rc` | Research window for chroma | 0 (same as r) | 0-99 |

**Strength guidelines:**
| s value | Use case |
|---------|----------|
| 1.0-2.0 | Light noise, preserve detail |
| 2.0-4.0 | Moderate noise (typical) |
| 4.0-6.0 | Heavy noise, low light |
| 6.0+ | Extreme noise (quality loss) |

### nlmeans_opencl - GPU-Accelerated NLMeans

OpenCL accelerated version, much faster.

```bash
# OpenCL denoising (hwupload needs an initialized OpenCL device)
ffmpeg -init_hw_device opencl=ocl -filter_hw_device ocl -i noisy.mp4 \
  -vf "format=yuv420p,hwupload,nlmeans_opencl=s=3:p=7:r=15,hwdownload,format=yuv420p" \
  output.mp4

# Strong denoising with OpenCL
ffmpeg -init_hw_device opencl=ocl -filter_hw_device ocl -i noisy.mp4 \
  -vf "format=yuv420p,hwupload,nlmeans_opencl=s=5:p=7:r=21,hwdownload,format=yuv420p" \
  output.mp4
```

### nlmeans_vulkan - Vulkan-Accelerated NLMeans (FFmpeg 6.1+)

Cross-platform GPU acceleration using Vulkan. Unlike CPU `nlmeans`, its `r` is a
research *radius* (the window is 2r+1), so `r=15` searches a 31x31 window and is
much slower than CPU `r=15`. Start with `r=7` to match CPU `nlmeans` r=15.
It also has per-plane strengths `s1`-`s4` and patch sizes `p1`-`p4`.

```bash
# Vulkan denoising
ffmpeg -init_hw_device vulkan \
  -i noisy.mp4 \
  -vf "hwupload,nlmeans_vulkan=s=3:p=7:r=7,hwdownload,format=yuv420p" \
  output.mp4

# Full Vulkan pipeline
ffmpeg -init_hw_device vulkan=vk \
  -filter_hw_device vk \
  -hwaccel vulkan -hwaccel_output_format vulkan \
  -i noisy.mp4 \
  -vf "nlmeans_vulkan=s=3:r=7" \
  -c:v h264_vulkan output.mp4
```

### hqdn3d - High Quality 3D Denoiser (Fast)

Faster than nlmeans with good results for moderate noise.

```bash
# Default settings
ffmpeg -i noisy.mp4 -vf "hqdn3d" output.mp4

# Custom settings (luma_spatial:chroma_spatial:luma_tmp:chroma_tmp)
ffmpeg -i noisy.mp4 -vf "hqdn3d=4:3:6:4.5" output.mp4

# Strong spatial denoising
ffmpeg -i noisy.mp4 -vf "hqdn3d=8:6:6:4" output.mp4

# Strong temporal denoising (for static scenes)
ffmpeg -i noisy.mp4 -vf "hqdn3d=4:3:12:9" output.mp4

# Light denoising
ffmpeg -i noisy.mp4 -vf "hqdn3d=2:1.5:3:2" output.mp4
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `luma_spatial` | Luma spatial strength | 4.0 | 0 and up (no upper limit) |
| `chroma_spatial` | Chroma spatial strength | 3.0 (derived from luma_spatial) | 0 and up |
| `luma_tmp` | Luma temporal strength | 6.0 (derived from luma_spatial) | 0 and up |
| `chroma_tmp` | Chroma temporal strength | 4.5 (derived) | 0 and up |

`ffmpeg -h filter=hqdn3d` shows every default as 0: a value of 0 means "derive it" (4 for luma_spatial, the others scaled from it), so 0 never turns a plane off.

### atadenoise - Adaptive Temporal Averaging

Temporal denoiser that preserves motion.

```bash
# Basic temporal denoising
ffmpeg -i noisy.mp4 -vf "atadenoise" output.mp4

# Stronger denoising
ffmpeg -i noisy.mp4 -vf "atadenoise=0a=0.1:0b=0.2:1a=0.1:1b=0.2:2a=0.1:2b=0.2" output.mp4

# Adjust threshold and planes
ffmpeg -i noisy.mp4 -vf "atadenoise=s=9:p=5" output.mp4
```

**Parameters:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `0a`, `1a`, `2a` | Threshold A for planes 0,1,2 | 0.02 |
| `0b`, `1b`, `2b` | Threshold B for planes 0,1,2 | 0.04 |
| `s` | Number of frames to average | 9 |
| `p` | Planes to process | 7 (all) |

### vaguedenoiser - Wavelet Denoiser

Uses wavelet transform for denoising.

```bash
# Basic wavelet denoising
ffmpeg -i noisy.mp4 -vf "vaguedenoiser" output.mp4

# Adjust threshold
ffmpeg -i noisy.mp4 -vf "vaguedenoiser=threshold=3:method=soft" output.mp4

# Stronger denoising
ffmpeg -i noisy.mp4 -vf "vaguedenoiser=threshold=6:nsteps=6" output.mp4
```

**Parameters:**
| Parameter | Description | Default | Values |
|-----------|-------------|---------|--------|
| `threshold` | Denoising threshold | 2 | 0-inf |
| `method` | Thresholding method | garrote | hard, soft, garrote |
| `nsteps` | Decomposition steps | 6 | 1-32 |
| `percent` | Percent of full denoising | 85 | 0-100 |

### fftdnoiz - FFT-Based Denoising

Frequency domain denoising.

```bash
# Basic FFT denoising
ffmpeg -i noisy.mp4 -vf "fftdnoiz" output.mp4

# Adjust sigma
ffmpeg -i noisy.mp4 -vf "fftdnoiz=sigma=8" output.mp4

# Strong denoising
ffmpeg -i noisy.mp4 -vf "fftdnoiz=sigma=15:block=32:overlap=0.8" output.mp4
```

### owdenoise - Overcomplete Wavelet Denoiser

Another wavelet-based option.

```bash
# Basic wavelet denoising
ffmpeg -i noisy.mp4 -vf "owdenoise" output.mp4

# Adjust depth and strength
ffmpeg -i noisy.mp4 -vf "owdenoise=depth=10:ls=3:cs=3" output.mp4
```

### removegrain - RemoveGrain

Classic grain/noise removal (from AviSynth).

```bash
# Mode 1 (basic)
ffmpeg -i noisy.mp4 -vf "removegrain=m0=1" output.mp4

# Different modes for different noise types
ffmpeg -i noisy.mp4 -vf "removegrain=m0=17:m1=17:m2=17" output.mp4
```

---

## Audio Denoising

### afftdn - FFT Denoiser (Recommended)

Powerful audio noise reduction using FFT.

```bash
# Basic audio denoising
ffmpeg -i noisy_audio.mp4 -af "afftdn" output.mp4

# Specify noise floor
ffmpeg -i noisy_audio.mp4 -af "afftdn=nf=-25" output.mp4

# Stronger noise reduction
ffmpeg -i noisy_audio.mp4 -af "afftdn=nf=-20:nt=w" output.mp4

# Gentler reduction with a higher noise floor
ffmpeg -i noisy_audio.mp4 -af "afftdn=nr=10:nf=-30:nt=w:om=o" output.mp4

# Learn the noise profile from a noise-only section (here 0-1 s) via sample_noise
ffmpeg -i noisy_audio.mp4 \
  -af "asendcmd=c='0.0 afftdn sn start; 1.0 afftdn sn stop',afftdn=nf=-40" output.mp4

# Adaptive noise floor (track the noise level over time)
ffmpeg -i noisy_audio.mp4 -af "afftdn=tn=1:om=o" output.mp4

# Custom noise profile: nt=c plus bn = 15 per-band noise levels in dB
ffmpeg -i noisy_audio.mp4 \
  -af "afftdn=nt=c:bn='-40 -40 -40 -40 -45 -45 -45 -50 -50 -50 -50 -50 -50 -50 -50':om=o" output.mp4
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `nr` | Noise reduction (dB) | 12 | 0.01-97 |
| `nf` | Noise floor (dB) | -50 | -80 to -20 |
| `nt` | Noise type | w | w=white, v=vinyl, s=shellac, c=custom |
| `bn` | Custom band noise: 15 space- or `\|`-separated dB values (with `nt=c`) | - | string |
| `tn` | Track noise (adaptive noise floor) | 0 | 0-1 |
| `sn` | Sample noise profile (`start`/`stop`, usually via `asendcmd`) | none | none, start, stop |
| `rf` | Residual floor (dB) | -38 | -80 to -20 |
| `om` | Output mode | o | i=input, o=output, n=noise |

### anlmdn - Non-Local Means Audio Denoiser

Audio equivalent of video nlmeans.

```bash
# Basic NLM audio denoising
ffmpeg -i noisy_audio.mp4 -af "anlmdn" output.mp4

# Adjust strength
ffmpeg -i noisy_audio.mp4 -af "anlmdn=s=0.0001" output.mp4

# Stronger denoising
ffmpeg -i noisy_audio.mp4 -af "anlmdn=s=0.001:p=0.01" output.mp4
```

**Parameters:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `s` | Denoising strength (0.00001-10000) | 0.00001 |
| `p` | Patch duration (seconds) | 0.002 |
| `r` | Research duration (seconds) | 0.006 |
| `o` | Output mode: `i` input, `o` output, `n` noise | o |
| `m` | Smooth factor (1-1000) | 11 |

### adeclick - Remove Clicks/Pops

Removes impulsive noise from audio.

```bash
# Remove clicks
ffmpeg -i clicked_audio.mp4 -af "adeclick" output.mp4

# Adjust parameters
ffmpeg -i clicked_audio.mp4 -af "adeclick=w=55:o=75" output.mp4
```

### adeclip - Remove Clipping

Repairs clipped audio.

```bash
# Fix clipping
ffmpeg -i clipped_audio.mp4 -af "adeclip" output.mp4
```

---

## Combined Workflows

### Low-Light Video Enhancement

```bash
# Denoise + brighten + contrast
ffmpeg -i dark_noisy.mp4 \
  -vf "nlmeans=s=4:p=7:r=15,eq=brightness=0.1:contrast=1.2:saturation=1.1" \
  -c:v libx264 -crf 18 \
  enhanced.mp4
```

### Interview Cleanup (Video + Audio)

```bash
# Clean both video and audio noise
ffmpeg -i interview.mp4 \
  -vf "hqdn3d=3:2:4:3" \
  -af "afftdn=nf=-30:nr=10,loudnorm" \
  -c:v libx264 -crf 20 \
  -ar 48000 -c:a aac -b:a 192k \
  interview_clean.mp4
```

### Film Grain Removal

```bash
# Strong nlmeans for film grain
ffmpeg -i grainy_film.mp4 \
  -vf "nlmeans=s=5:p=7:r=21" \
  -c:v libx264 -crf 18 -preset slow \
  degrained.mp4

# Preserve some grain (artistic choice)
ffmpeg -i grainy_film.mp4 \
  -vf "nlmeans=s=2.5:p=5:r=11" \
  -c:v libx264 -crf 18 \
  light_degrain.mp4
```

### Compression Artifact Removal

```bash
# Remove blocking artifacts from highly compressed video
ffmpeg -i compressed.mp4 \
  -vf "hqdn3d=2:1.5:3:2,unsharp=5:5:0.3:5:5:0" \
  -c:v libx264 -crf 18 \
  cleaner.mp4
```

### GPU-Accelerated Batch Processing

```bash
#!/bin/bash
# Process multiple noisy videos with GPU

for video in noisy_*.mp4; do
  output="clean_${video}"
  ffmpeg -init_hw_device vulkan \
    -i "$video" \
    -vf "hwupload,nlmeans_vulkan=s=3:r=7,hwdownload,format=yuv420p" \
    -c:v libx264 -crf 18 \
    "$output"
done
```

---

## Filter Comparison

### Video Denoising Speed vs Quality

| Filter | Quality | Speed | GPU Option | Best For |
|--------|---------|-------|------------|----------|
| `nlmeans` | Excellent | Slow | Yes (OpenCL/Vulkan) | Final output |
| `hqdn3d` | Good | Fast | No | Real-time, previews |
| `atadenoise` | Good | Medium | No | Static scenes |
| `vaguedenoiser` | Good | Medium | No | Mixed content |
| `fftdnoiz` | Good | Medium | No | Periodic noise |

### Audio Denoising Comparison

| Filter | Quality | Speed | Best For |
|--------|---------|-------|----------|
| `afftdn` | Excellent | Fast | All-purpose |
| `anlmdn` | Good | Medium | Speech |
| `adeclick` | Specialized | Fast | Clicks/pops |

---

## Parameter Tuning Tips

### Video Denoising
1. **Start conservative** - Begin with s=2-3, increase if needed
2. **Preserve edges** - Lower patch size (p=5) preserves more detail
3. **Test on samples** - Process 10-second clips first
4. **Consider GPU** - nlmeans_opencl/vulkan are 5-10x faster
5. **Match content** - Static scenes tolerate stronger temporal denoising

### Audio Denoising
1. **Find noise floor** - Listen to quiet sections
2. **Use appropriate type** - White noise vs vinyl vs custom
3. **Don't over-process** - Artifacts can be worse than noise
4. **Check residual** - Use om=n to hear what's being removed

---

## Best Practices

1. **Denoise before encoding** - Noise compresses poorly
2. **Preserve some texture** - Over-denoising looks artificial
3. **Match source quality** - Don't denoise clean footage
4. **Use GPU when available** - Massive speed improvement
5. **Combine filters carefully** - Multiple denoisers can cause artifacts
6. **Test different filters** - Content-dependent results

This guide covers noise reduction. For video analysis and detection, see `analysis.md`. For hardware acceleration, see `hwaccel.md`.
