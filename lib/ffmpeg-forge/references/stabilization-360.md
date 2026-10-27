# FFmpeg Stabilization & 360 Video

Comprehensive guide to video stabilization, VR processing, and motion effects.

## Contents

- [Quick Reference](#quick-reference)
- [Video Stabilization](#video-stabilization)
- [360/VR Video Processing](#360vr-video-processing)
- [Ken Burns and Zoom Effects](#ken-burns-and-zoom-effects)
- [Lens Correction](#lens-correction)
- [Common Workflows](#common-workflows)
- [Best Practices](#best-practices)

## Quick Reference

| Task | Filter | Command Pattern |
|------|--------|-----------------|
| Basic stabilization | `deshake` | `-vf deshake` |
| VidStab (2-pass) | `vidstab` | See two-pass workflow |
| OpenCL stabilization | `deshake_opencl` | `-vf deshake_opencl` |
| 360 projection | `v360` | `-vf v360=e:c3x2` |
| Ken Burns effect | `zoompan` | `-vf zoompan=z='...'` |
| Lens correction | `lenscorrection` | `-vf lenscorrection=k1=...` |

---

## Video Stabilization

### deshake - Basic Stabilization

Built-in single-pass stabilization filter.

```bash
# Basic stabilization
ffmpeg -i shaky.mp4 -vf "deshake" stable.mp4

# With custom parameters
ffmpeg -i shaky.mp4 -vf "deshake=x=-1:y=-1:w=-1:h=-1:rx=16:ry=16" stable.mp4

# Strong stabilization
ffmpeg -i shaky.mp4 -vf "deshake=rx=64:ry=64:edge=mirror" stable.mp4
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `x`, `y` | Motion search start | -1 (auto) | 0-width/height |
| `w`, `h` | Motion search size | -1 (auto) | 0-width/height |
| `rx`, `ry` | Maximum shift | 16 | 0-64 |
| `edge` | Edge handling | mirror | blank, original, clamp, mirror |
| `blocksize` | Block size for motion search | 8 | 4-128 |
| `contrast` | Contrast threshold | 125 | 1-255 |
| `search` | Search method | exhaustive | exhaustive, less |

**Edge modes:**
- `blank` - Fill edges with black
- `original` - Keep original edge pixels
- `clamp` - Clamp to edge values
- `mirror` - Mirror edge pixels (usually best)

### deshake_opencl - GPU-Accelerated Stabilization

Faster stabilization using OpenCL.

```bash
# OpenCL stabilization (hwupload needs an OpenCL device set up first)
ffmpeg -init_hw_device opencl=ocl -filter_hw_device ocl -i shaky.mp4 \
  -vf "format=yuv420p,hwupload,deshake_opencl,hwdownload,format=yuv420p" \
  stable.mp4

# With custom parameters (smooth_strength 0-1, 0 = adaptive;
# smooth_window_multiplier 0.1-10 scales the motion buffer, default 2)
ffmpeg -init_hw_device opencl=ocl -filter_hw_device ocl -i shaky.mp4 \
  -vf "format=yuv420p,hwupload,deshake_opencl=tripod=0:smooth_strength=0.5:smooth_window_multiplier=3:adaptive_crop=1,hwdownload,format=yuv420p" \
  stable.mp4
```

### VidStab - Professional Two-Pass Stabilization

VidStab provides the highest quality stabilization using a two-pass approach.

**Pass 1: Analyze motion**
```bash
# Analyze video and save transform data
ffmpeg -i shaky.mp4 \
  -vf "vidstabdetect=stepsize=6:shakiness=8:accuracy=9:result=transforms.trf" \
  -f null -
```

**Pass 2: Apply transforms**
```bash
# Apply stabilization with transforms
ffmpeg -i shaky.mp4 \
  -vf "vidstabtransform=input=transforms.trf:zoom=1:smoothing=30" \
  stable.mp4
```

**vidstabdetect Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `stepsize` | Step size for motion estimation | 6 | 1-32 |
| `shakiness` | Shakiness amount (higher = more analysis) | 5 | 1-10 |
| `accuracy` | Detection accuracy | 15 | 1-15 |
| `result` | Output transform file | transforms.trf | filename |
| `show` | Visualize detection | 0 | 0-2 |

**vidstabtransform Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `input` | Transform file | transforms.trf | filename |
| `smoothing` | Smoothing window (2*n+1 frames; higher = smoother) | 15 | 0-1000 |
| `zoom` | Zoom percentage | 0 | -100 to 100 |
| `optzoom` | Optimal zoom calculation | 1 | 0-2 |
| `zoomspeed` | Max zoom change per frame | 0.25 | 0-5 |
| `crop` | Cropping mode | keep | keep, black |
| `relative` | Transform type | 1 | 0-1 |
| `tripod` | Tripod mode (fixed position) | 0 | 0-1 |

**Complete VidStab workflow:**
```bash
#!/bin/bash
# Professional stabilization workflow

INPUT="$1"
OUTPUT="${1%.*}_stabilized.mp4"

echo "Pass 1: Analyzing motion..."
ffmpeg -i "$INPUT" \
  -vf "vidstabdetect=stepsize=6:shakiness=8:accuracy=15:result=transforms.trf" \
  -f null -

echo "Pass 2: Applying stabilization..."
ffmpeg -i "$INPUT" \
  -vf "vidstabtransform=input=transforms.trf:smoothing=30:zoom=2:optzoom=1" \
  -c:v libx264 -crf 18 -preset slow \
  -c:a copy \
  "$OUTPUT"

rm transforms.trf
echo "Stabilized: $OUTPUT"
```

### Stabilization Comparison

| Method | Quality | Speed | GPU | Use Case |
|--------|---------|-------|-----|----------|
| `deshake` | Good | Fast | No | Quick fixes |
| `deshake_opencl` | Good | Very Fast | Yes | Quick fixes with GPU |
| `vidstab` (2-pass) | Best | Slow | No | Professional work |

---

## 360/VR Video Processing

### v360 - 360 Video Projection Conversion

Converts between various 360 video projections.

```bash
# Equirectangular to Cubemap 3x2
ffmpeg -i equirect.mp4 -vf "v360=e:c3x2" cubemap.mp4

# Equirectangular to Cubemap 6x1
ffmpeg -i equirect.mp4 -vf "v360=e:c6x1" cubemap_6x1.mp4

# Cubemap to Equirectangular
ffmpeg -i cubemap.mp4 -vf "v360=c3x2:e" equirect.mp4

# Equirectangular to EAC (YouTube format)
ffmpeg -i equirect.mp4 -vf "v360=e:eac" youtube_360.mp4

# Dual fisheye to Equirectangular
ffmpeg -i dual_fisheye.mp4 -vf "v360=dfisheye:e:ih_fov=190:iv_fov=190" equirect.mp4
```

**Input/Output Projections:**
| Code | Projection | Description |
|------|------------|-------------|
| `e` | Equirectangular | Standard 360 format (2:1 ratio) |
| `c3x2` | Cubemap 3x2 | 3 faces wide, 2 high |
| `c6x1` | Cubemap 6x1 | 6 faces in a row |
| `c1x6` | Cubemap 1x6 | 6 faces in a column |
| `eac` | Equi-Angular Cubemap | YouTube 360 format |
| `dfisheye` | Dual Fisheye | Two circular fisheye images |
| `sg` | Stereographic | Low distortion projection |
| `flat` | Flat/Rectilinear | Normal perspective view |
| `barrel` / `fb` | Barrel | Facebook 360 barrel layout (`fb` is an alias) |
| `barrelsplit` | Barrel split | Facebook 360 barrel split layout |

**Parameters:**
| Parameter | Description | Example |
|-----------|-------------|---------|
| `id_fov` | Input diagonal FOV | `id_fov=195` |
| `ih_fov`, `iv_fov` | Input H/V FOV | `ih_fov=190:iv_fov=190` |
| `yaw`, `pitch`, `roll` | Rotation angles | `yaw=90:pitch=0` |
| `w`, `h` | Output size | `w=4096:h=2048` |
| `interp` | Interpolation | `nearest`, `linear`, `cubic`, `lanczos` |

### 360 Video Rotation and Reframing

```bash
# Rotate 360 video 90 degrees
ffmpeg -i input_360.mp4 -vf "v360=e:e:yaw=90" rotated.mp4

# Tilt view up
ffmpeg -i input_360.mp4 -vf "v360=e:e:pitch=-30" tilted.mp4

# Extract flat view from 360
ffmpeg -i 360_video.mp4 \
  -vf "v360=e:flat:h_fov=120:v_fov=90:yaw=45:pitch=-10:w=1920:h=1080" \
  flat_extract.mp4
```

### Stereoscopic 360 Processing

```bash
# Split top-bottom stereo to left eye only
ffmpeg -i stereo_tb.mp4 -vf "v360=e:e:in_stereo=tb:out_stereo=2d" left_eye.mp4

# Convert side-by-side to top-bottom
ffmpeg -i stereo_sbs.mp4 -vf "v360=e:e:in_stereo=sbs:out_stereo=tb" stereo_tb.mp4
```

---

## Ken Burns and Zoom Effects

### zoompan - Pan and Zoom Animation

Creates Ken Burns style effects on still images or video.

```bash
# Basic zoom in on center (5 s: one still image, d=125 frames at the default fps=25;
# no -loop 1, see the slideshow note below). Every recipe here starts with
# scale+crop to 1920x1080 so a 4:3 or portrait photo is cropped, not stretched,
# and ends with scale=out_range=tv,format=yuv420p (JPEGs are full range).
ffmpeg -i image.jpg \
  -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z='min(zoom+0.001,1.5)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=125:s=1920x1080,scale=out_range=tv,format=yuv420p" \
  -c:v libx264 zoom_in.mp4

# Zoom into the top-left corner (x/y omitted: zoompan defaults to x=0:y=0)
ffmpeg -i image.jpg \
  -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z='min(zoom+0.001,1.5)':d=125:s=1920x1080,scale=out_range=tv,format=yuv420p" \
  ken_burns_topleft.mp4

# Pan across image
ffmpeg -loop 1 -i image.jpg -t 10 \
  -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z=1.3:x='if(gte(px,iw-iw/zoom),0,px+1)':y='ih/2-(ih/zoom/2)':d=1:s=1920x1080,scale=out_range=tv,format=yuv420p" \
  pan.mp4

# Zoom out on center
ffmpeg -i image.jpg \
  -vf "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z='if(lte(zoom,1.0),1.5,max(1.001,zoom-0.002))':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=125:s=1920x1080,scale=out_range=tv,format=yuv420p" \
  zoom_out.mp4
```

**Parameters:**
| Parameter | Description | Example |
|-----------|-------------|---------|
| `z` | Zoom factor expression | `z='min(zoom+0.001,1.5)'` |
| `x`, `y` | Pan position expression | `x='iw/2'` |
| `d` | Output frames per input frame | `d=125` |
| `s` | Output size | `s=1920x1080` |
| `fps` | Output frame rate (default 25, not the input rate) | `fps=30` |

**Useful expressions:**
- `zoom` - Current zoom value
- `pzoom` - Previous zoom value
- `iw`, `ih` - Input width/height
- `in`, `on` - Input and output frame number
- `it` / `in_time`, `ot` / `time` - Input and output time in seconds (there is no `t`: `z='...t...'` fails with "Undefined constant")

### Zoompan Timing

`d=` is the number of output frames produced **per input frame**, and the output rate is `fps=` (default 25), so set both.

- **Still image:** `d` > 1 makes a clip from one picture. Frames = seconds x fps: `d=60:fps=30` is 2 s, `d=120:fps=60` is 2 s.
- **Video:** use `d=1` (one output frame per input frame) and drive the zoom from the input time `it`. `d=60` on a video turns every input frame into 60 frames (a 4 s 25 fps clip becomes 6000 frames = 4 minutes).
- Without `x`/`y`, zoompan zooms into the top-left corner; `x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2'` keeps it centred.
- `scale+crop` to the `s=` size first, so a source with another aspect ratio is cropped, not stretched.

```bash
# 2-second zoom on a vertical STILL at 30 fps: d=60 frames / fps=30 = 2 s
ffmpeg -i photo.jpg -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,zoompan=z='min(zoom+0.0015,1.2)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=60:s=1080x1920:fps=30,scale=out_range=tv,format=yuv420p" output.mp4

# Zoom over the first 2 seconds of a VIDEO: d=1, zoom from the input time;
# duration stays equal to the input, zoom reaches 1.2 at t=2 s and holds
ffmpeg -i input.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,zoompan=z='1+0.2*min(it/2,1)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1080x1920:fps=30" -pix_fmt yuv420p output.mp4
```

### Hook Zooms for Short-Form Video

Hook animations should finish within ~0.5 s to fit the first ~1.3 s attention window with room for text. Gate them with a time conditional such as `if(lt(it,0.5),effect,1)`, not with `d=`.

| Effect Type | FPS | Effect Duration | Frame Count | `d=` Parameter |
|-------------|-----|-----------------|-------------|----------------|
| Hook zoom punch | 60 | 0.4-0.5s | 24-30 frames | `d=1` (use time conditional) |
| Hook flash | 60 | 0.2-0.3s | 12-18 frames | `d=1` (use time conditional) |
| Continuous zoom | 30 | Entire video | N/A | `d=1` (recalc per frame) |
| Text animations | 60 | 0.3-0.5s | 18-30 frames | `d=1` (use time conditional) |

| Platform | Hook Zoom | Hook Duration | Continuous Zoom | Recommended FPS |
|----------|-----------|---------------|-----------------|-----------------|
| TikTok | 1.5x (50%) | 0.4-0.5s | +0.2%/sec | 60fps for hooks |
| YouTube Shorts | 1.5x (50%) | 0.5-0.6s | +0.15%/sec | 60fps throughout |
| Instagram Reels | 1.4x (40%) | 0.5-0.6s | +0.18%/sec | 60fps for hooks |

```bash
# Each formula starts with scale+crop to 1080x1920 so a 16:9 (or any non-9:16)
# source is cropped, not stretched, by zoompan's s=1080x1920.
# 1.5x zoom punch over 0.5s at 60fps: starts at 1.5x and eases back to 1x (a
# punch-out). For a punch-in that ends zoomed, use z='if(lt(it,0.5),1+it,1.5)':
scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=60,zoompan=z='if(lt(it,0.5),1.5-it,1)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1080x1920:fps=60

# 8% zoom pulse at ~2Hz for 1.5s (abs(sin(it*6)) peaks every pi/6 = 0.52s, ~1.9 Hz;
# abs() because zoompan clamps zoom values below 1):
scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=60,zoompan=z='if(lt(it,1.5),1+0.08*abs(sin(it*6)),1)':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1080x1920:fps=60

# Subtle continuous zoom for TikTok (0.2%/sec):
scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,zoompan=z='1+0.002*it':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1080x1920:fps=30

# Subtle continuous zoom for YouTube Shorts (0.15%/sec):
scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,zoompan=z='1+0.0015*it':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1080x1920:fps=30
```

### Animated Slideshow Example

```bash
# Create slideshow with Ken Burns (about 13 s: 3 x 5 s minus two 1 s fades).
# JPEGs are full range; scale=out_range=tv avoids a full-range yuvj420p output.
# Do NOT add -loop 1 here: zoompan already emits d=150 frames for EACH input
# frame, so a looped 5 s input (125 frames) would become 125 x 150 frames.
ffmpeg -i img1.jpg \
       -i img2.jpg \
       -i img3.jpg \
  -filter_complex "\
    [0:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z='min(zoom+0.001,1.3)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=150:s=1920x1080:fps=30[v0];\
    [1:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z=1.3:x='if(gte(x,iw-iw/zoom),0,x+2)':y='ih/2-(ih/zoom/2)':d=150:s=1920x1080:fps=30[v1];\
    [2:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,zoompan=z='1.3-0.002*on':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=150:s=1920x1080:fps=30[v2];\
    [v0][v1]xfade=transition=fade:duration=1:offset=4[x1];\
    [x1][v2]xfade=transition=fade:duration=1:offset=8,scale=out_range=tv,format=yuv420p[out]" \
  -map "[out]" slideshow.mp4
```

---

## Lens Correction

### lenscorrection - Barrel/Pincushion Correction

Corrects lens distortion mathematically.

```bash
# Correct barrel distortion
ffmpeg -i distorted.mp4 -vf "lenscorrection=k1=-0.2:k2=-0.05" corrected.mp4

# Correct pincushion distortion
ffmpeg -i distorted.mp4 -vf "lenscorrection=k1=0.2:k2=0.05" corrected.mp4

# With the optical centre moved off the frame centre (cx/cy are 0-1, default 0.5)
ffmpeg -i distorted.mp4 -vf "lenscorrection=cx=0.45:cy=0.55:k1=-0.2:k2=-0.05" corrected.mp4
```

**Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `cx`, `cy` | Center position | 0.5 | 0-1 |
| `k1` | Primary coefficient | 0 | -1 to 1 |
| `k2` | Secondary coefficient | 0 | -1 to 1 |
| `i` | Interpolation | nearest | nearest, bilinear |

**Tips for finding coefficients:**
- Barrel distortion (fisheye): negative k1 (-0.1 to -0.5)
- Pincushion distortion: positive k1 (0.1 to 0.5)
- Start with k2=0, adjust k1 first

### lensfun - Database-Driven Lens Correction

Uses the lensfun database for automatic lens correction.

```bash
# The filter does not read EXIF: give make, model and lens_model exactly as they
# appear in the lensfun database, plus focal_length (default 18) for zoom lenses
ffmpeg -i photo.jpg -vf "lensfun=make=Canon:model=EOS 5D Mark II:lens_model=Canon EF 24-70mm:focal_length=24" -update 1 corrected.jpg

# With specific parameters
ffmpeg -i video.mp4 -vf "lensfun=make=GoPro:model=HERO10:mode=geometry" corrected.mp4
```

**Requires**: lensfun library and database installed

### perspective - Perspective Correction

Corrects keystone/perspective distortion.

```bash
# Correct perspective with four corner points
# Map corners: (x0,y0)-(x1,y1)-(x2,y2)-(x3,y3) to rectangle
ffmpeg -i skewed.mp4 \
  -vf "perspective=x0=100:y0=50:x1=1820:y1=80:x2=0:y2=1030:x3=1920:y3=1000:interpolation=linear" \
  corrected.mp4

# Interactive: find coordinates with test overlay first
ffmpeg -i skewed.mp4 -vf "drawgrid=w=100:h=100:c=red" grid_overlay.mp4
```

---

## Common Workflows

### Action Camera Processing

```bash
# GoPro footage: stabilize + lens correct + encode
ffmpeg -i GOPR0001.MP4 \
  -vf "lenscorrection=k1=-0.2:k2=-0.05,vidstabdetect=shakiness=8:result=gopro.trf" \
  -f null -

ffmpeg -i GOPR0001.MP4 \
  -vf "lenscorrection=k1=-0.2:k2=-0.05,vidstabtransform=input=gopro.trf:smoothing=20:zoom=5" \
  -c:v libx264 -crf 18 \
  gopro_processed.mp4
```

### Drone Footage Processing

```bash
# DJI footage: stabilize and enhance
ffmpeg -i DJI_0001.MP4 \
  -vf "vidstabdetect=shakiness=5:stepsize=6:result=drone.trf" -f null -

ffmpeg -i DJI_0001.MP4 \
  -vf "vidstabtransform=input=drone.trf:smoothing=40:zoom=2,eq=contrast=1.1:saturation=1.2" \
  -c:v libx264 -crf 18 -preset slow \
  drone_processed.mp4
```

### 360 Camera to Flat Video

```bash
# Extract interesting view from 360 footage
ffmpeg -i insta360.mp4 \
  -vf "v360=e:flat:h_fov=110:v_fov=70:yaw=45:pitch=-15:w=1920:h=1080,deshake" \
  flat_view.mp4
```

---

## Best Practices

1. **VidStab for quality** - Two-pass is slower but much better than deshake
2. **Allow zoom headroom** - Stabilization needs room to crop
3. **Match frame rates** - Ensure consistent fps before and after
4. **GPU when available** - Use deshake_opencl for speed
5. **Test coefficients** - Lens correction needs experimentation
6. **Check 360 metadata** - Spherical (VR) projection info is stream side data, not a
   metadata tag, so `-map_metadata` does not control it. Check the output with
   `ffprobe -show_streams` (side data "Spherical Mapping"); if it is missing, re-inject
   it with Google's spatial-media tool. After `v360` changes the projection, the
   source's spherical data no longer applies.

This guide covers stabilization and 360 processing. For hardware acceleration, see `hwaccel.md`. For filters and effects, see `filter-complex.md`.
