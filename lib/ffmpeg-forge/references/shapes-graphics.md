# FFmpeg Shapes and Graphics

Shapes, boxes, grids, image overlays, progress bars, blend modes, safe-area guides, masks and generated patterns. Text overlays are in `drawtext.md`.

## Contents

- [Quick Reference](#quick-reference)
- [Shape Drawing Filters](#shape-drawing-filters)
- [Drawing Boxes (drawbox)](#drawing-boxes-drawbox)
- [Drawing Grids (drawgrid)](#drawing-grids-drawgrid)
- [Drawing Circles and Ellipses (geq)](#drawing-circles-and-ellipses-geq)
- [Image Overlays](#image-overlays)
- [Text Graphics (drawtext)](#text-graphics-drawtext)
- [Progress Bars and Indicators](#progress-bars-and-indicators)
- [Color Correction Overlays](#color-correction-overlays)
- [Blend Modes](#blend-modes)
- [Safe Areas and Guides](#safe-areas-and-guides)
- [Masking](#masking)
- [Generating Graphics Programmatically](#generating-graphics-programmatically)
- [Performance Tips](#performance-tips)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

## Quick Reference

| Shape | Filter | Command Example |
|-------|--------|-----------------|
| Rectangle | `drawbox` | `-vf "drawbox=x=100:y=100:w=200:h=150:color=red:t=fill"` |
| Grid | `drawgrid` | `-vf "drawgrid=w=iw/3:h=ih/3:t=2:color=white"` |
| Text | `drawtext` | `-vf "drawtext=text='Hello':x=10:y=10:fontsize=24:fontcolor=white"` (see `drawtext.md`) |
| Watermark | `overlay` | `[0:v][1:v]overlay=W-w-10:10` |

| Position | Expression |
|----------|------------|
| Centered | `x=(iw-200)/2:y=(ih-150)/2` |
| Bottom-right | `x=iw-w-10:y=ih-h-10` |
| Full-width bar | `x=0:y=0:w=iw:h=80` |

---

## Shape Drawing Filters

### Available Drawing Filters

| Filter | Purpose | Shapes |
|--------|---------|--------|
| drawbox | Draw rectangles/boxes | Rectangles, squares |
| drawgrid | Draw grid patterns | Lines, grids |
| drawtext | Draw text | Text, numbers |
| geq | Geometric equation | Any (via expressions) |
| overlay | Composite images | Any image/shape |
| blend | Blend layers | Composite effects |

## Drawing Boxes (drawbox)

### Basic Rectangle

```bash
# Draw red box
ffmpeg -i video.mp4 \
  -vf "drawbox=x=100:y=100:w=200:h=150:color=red:t=3" \
  output.mp4

# Filled rectangle
ffmpeg -i video.mp4 \
  -vf "drawbox=x=100:y=100:w=200:h=150:color=red:t=fill" \
  output.mp4

# Semi-transparent rectangle
ffmpeg -i video.mp4 \
  -vf "drawbox=x=100:y=100:w=200:h=150:color=red@0.5:t=fill" \
  output.mp4
```

### Position Options

```bash
# Centered box
ffmpeg -i video.mp4 \
  -vf "drawbox=x=(iw-200)/2:y=(ih-150)/2:w=200:h=150:color=blue:t=fill" \
  output.mp4

# Box at bottom right
ffmpeg -i video.mp4 \
  -vf "drawbox=x=iw-210:y=ih-160:w=200:h=150:color=green:t=3" \
  output.mp4

# Full-width bar at top
ffmpeg -i video.mp4 \
  -vf "drawbox=x=0:y=0:w=iw:h=80:color=black@0.7:t=fill" \
  output.mp4

# Full-width bar at bottom
ffmpeg -i video.mp4 \
  -vf "drawbox=x=0:y=ih-80:w=iw:h=80:color=black@0.7:t=fill" \
  output.mp4
```

### Letterbox/Pillarbox

```bash
# Add letterbox bars (16:9 to 2.35:1)
ffmpeg -i video_16x9.mp4 \
  -vf "drawbox=x=0:y=0:w=iw:h=ih*0.12:color=black:t=fill,\
       drawbox=x=0:y=ih-ih*0.12:w=iw:h=ih*0.12:color=black:t=fill" \
  letterbox.mp4

# Add pillarbox bars (4:3 in 16:9 frame)
ffmpeg -i video_4x3.mp4 \
  -vf "scale=-2:1080,pad=1920:1080:(ow-iw)/2:0:black" \
  pillarbox.mp4
```

### Animated Boxes

```bash
# drawbox has no time variable (its `t` option is the border thickness), and its
# x/y/w/h expressions are evaluated once, not per frame. To animate a box,
# overlay a solid `color` source instead: overlay x/y are evaluated per frame,
# and `scale` with eval=frame can change the size over time.

# Growing box (scale the box per frame, then overlay it)
ffmpeg -i video.mp4 \
  -filter_complex "color=c=red:s=16x16[c];\
    [c]scale=w='max(2,min(t*50,300))':h='max(2,min(t*30,200))':eval=frame[bx];\
    [0:v][bx]overlay=100:100:shortest=1" \
  growing_box.mp4

# Moving box
ffmpeg -i video.mp4 \
  -filter_complex "color=c=blue:s=100x100[bx];\
    [0:v][bx]overlay=x='mod(t*100,W)':y=100:shortest=1" \
  moving_box.mp4

# Pulsing opacity. drawbox color/alpha cannot be an expression, so draw an
# opaque box on a copy and blend it in with a time-varying weight
ffmpeg -i video.mp4 \
  -filter_complex "[0:v]split[a][b];[b]drawbox=x=100:y=100:w=200:h=150:color=red:t=fill[bx];\
    [a][bx]blend=all_expr='A+(B-A)*(0.3+0.3*sin(T*3))'" \
  pulsing_box.mp4

# Box appears at specific time
ffmpeg -i video.mp4 \
  -vf "drawbox=x=100:y=100:w=200:h=150:color=yellow:t=fill:enable='between(t,2,5)'" \
  timed_box.mp4
```

### Multiple Boxes

```bash
# Border/frame effect
ffmpeg -i video.mp4 \
  -vf "drawbox=x=0:y=0:w=iw:h=20:color=white:t=fill,\
       drawbox=x=0:y=ih-20:w=iw:h=20:color=white:t=fill,\
       drawbox=x=0:y=0:w=20:h=ih:color=white:t=fill,\
       drawbox=x=iw-20:y=0:w=20:h=ih:color=white:t=fill" \
  bordered.mp4

# Grid of boxes
ffmpeg -i video.mp4 \
  -vf "drawbox=x=0:y=0:w=iw/3:h=ih/3:color=red@0.3:t=fill,\
       drawbox=x=iw/3:y=0:w=iw/3:h=ih/3:color=green@0.3:t=fill,\
       drawbox=x=2*iw/3:y=0:w=iw/3:h=ih/3:color=blue@0.3:t=fill" \
  color_grid.mp4
```

## Drawing Grids (drawgrid)

### Basic Grid

```bash
# Simple grid overlay
ffmpeg -i video.mp4 \
  -vf "drawgrid=w=100:h=100:t=1:color=white@0.5" \
  grid.mp4

# Rule of thirds grid
ffmpeg -i video.mp4 \
  -vf "drawgrid=w=iw/3:h=ih/3:t=2:color=white@0.7" \
  thirds.mp4

# Fine grid
ffmpeg -i video.mp4 \
  -vf "drawgrid=w=50:h=50:t=1:color=cyan@0.3" \
  fine_grid.mp4
```

### Crosshair/Center Marker

```bash
# Center crosshair
ffmpeg -i video.mp4 \
  -vf "drawbox=x=iw/2-1:y=0:w=2:h=ih:color=red:t=fill,\
       drawbox=x=0:y=ih/2-1:w=iw:h=2:color=red:t=fill" \
  crosshair.mp4

# Center square marker
ffmpeg -i video.mp4 \
  -vf "drawbox=x=iw/2-5:y=ih/2-5:w=10:h=10:color=red:t=2" \
  center_marker.mp4
```

## Drawing Circles and Ellipses (geq)

### Using geq Filter for Circles

```bash
# Draw circle outline
ffmpeg -i video.mp4 \
  -vf "geq=lum='if(between(sqrt(pow(X-W/2,2)+pow(Y-H/2,2)),100,105),255,lum(X,Y))':cb='cb(X,Y)':cr='cr(X,Y)'" \
  circle_outline.mp4

# Filled circle (white). Build one RGBA frame whose alpha is 255 inside the
# circle and 0 outside (r=1:d=1 = a single frame, so geq runs once); overlay
# keeps showing that last frame and ends with the main video.
# Set s= to the video size.
ffmpeg -i video.mp4 \
  -filter_complex "\
    color=c=white:s=1920x1080:r=1:d=1,format=rgba,\
    geq=r=255:g=255:b=255:a='if(lt(hypot(X-W/2,Y-H/2),200),255,0)'[circle];\
    [0:v][circle]overlay[v]" \
  -map "[v]" \
  filled_circle.mp4
```

### Using Overlay with Circle Images

```bash
# More practical: overlay a circle image
# First create circle image
ffmpeg -f lavfi \
  -i "color=c=red:s=200x200" \
  -vf "format=rgba,geq=r=255:g=0:b=0:a='if(lt(hypot(X-100,Y-100),100),255,0)'" \
  -frames:v 1 -update 1 \
  circle.png

# Overlay circle on video
ffmpeg -i video.mp4 -i circle.png \
  -filter_complex "[0:v][1:v]overlay=100:100" \
  video_with_circle.mp4
```

### Generate Shape Patterns

```bash
# Radial gradient
ffmpeg -f lavfi \
  -i "color=c=black:s=500x500,geq=lum='255*sqrt(pow(X-W/2,2)+pow(Y-H/2,2))/(W/2)':cb=128:cr=128" \
  -frames:v 1 -update 1 \
  radial_gradient.png

# Checkerboard pattern
ffmpeg -f lavfi \
  -i "color=c=white:s=800x800,geq=lum='if(mod(floor(X/100)+floor(Y/100),2),255,0)':cb=128:cr=128" \
  -frames:v 1 -update 1 \
  checkerboard.png

# Diagonal stripes
ffmpeg -f lavfi \
  -i "color=c=black:s=800x600,geq=lum='if(lt(mod(X+Y,100),50),255,0)':cb=128:cr=128" \
  -frames:v 1 -update 1 \
  stripes.png
```

## Image Overlays

### Basic Overlay

```bash
# Overlay logo at top-right corner
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[0:v][1:v]overlay=W-w-10:10" \
  watermarked.mp4

# Overlay at bottom-left
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[0:v][1:v]overlay=10:H-h-10" \
  watermarked.mp4

# Centered overlay
ffmpeg -i video.mp4 -i overlay.png \
  -filter_complex "[0:v][1:v]overlay=(W-w)/2:(H-h)/2" \
  centered.mp4
```

### Overlay with Transparency

```bash
# Scale and position logo with transparency
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "\
    [1:v]format=rgba,colorchannelmixer=aa=0.5[logo];\
    [0:v][logo]overlay=W-w-20:H-h-20" \
  watermark_50.mp4

# Fade in logo (-loop 1 turns the still into a stream so fade has frames to
# work on; shortest=1 ends the output with the video)
ffmpeg -i video.mp4 -loop 1 -i logo.png \
  -filter_complex "\
    [1:v]format=rgba,fade=t=in:st=0:d=1:alpha=1[logo];\
    [0:v][logo]overlay=W-w-10:10:shortest=1" \
  fade_logo.mp4
```

### Animated Overlays

```bash
# Moving logo across screen
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "\
    [0:v][1:v]overlay=x='mod(t*100,W+w)-w':y=10" \
  scrolling_logo.mp4

# Bouncing logo
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "\
    [0:v][1:v]overlay=x='abs(mod(t*100,2*(W-w))-(W-w))':y='abs(mod(t*80,2*(H-h))-(H-h))'" \
  bouncing_logo.mp4

# Rotating overlay (using rotate filter; -loop 1 so the still has a frame
# for every time step, shortest=1 to stop with the video)
ffmpeg -i video.mp4 -loop 1 -i logo.png \
  -filter_complex "\
    [1:v]rotate=t*PI/4:c=none:ow=200:oh=200[rot];\
    [0:v][rot]overlay=(W-200)/2:(H-200)/2:shortest=1" \
  rotating_logo.mp4
```

### Multiple Overlays

```bash
# Multiple logos/watermarks
ffmpeg -i video.mp4 -i logo1.png -i logo2.png \
  -filter_complex "\
    [0:v][1:v]overlay=10:10[tmp];\
    [tmp][2:v]overlay=W-w-10:10" \
  multi_logo.mp4

# Grid of thumbnails
ffmpeg -i main.mp4 -i thumb1.png -i thumb2.png -i thumb3.png -i thumb4.png \
  -filter_complex "\
    [1:v]scale=200:150[t1];[2:v]scale=200:150[t2];\
    [3:v]scale=200:150[t3];[4:v]scale=200:150[t4];\
    [0:v][t1]overlay=10:10[a];\
    [a][t2]overlay=220:10[b];\
    [b][t3]overlay=10:170[c];\
    [c][t4]overlay=220:170" \
  thumbnail_grid.mp4
```

## Text Graphics (drawtext)

Text overlays (styled text, badges, lower thirds, timecode, frame counters) are in `drawtext.md`; animated text (sliding lower thirds, tickers, credits) is in `drawtext-animation.md`.

## Progress Bars and Indicators

### Progress Bar

```bash
# Horizontal progress bar for a 1920-wide, 10-second video. The gray track is
# a static drawbox; the red fill is a color source scaled per frame
# (scale eval=frame knows t, but not the main video width, so 1820 = 1920-100).
ffmpeg -i video.mp4 \
  -filter_complex "color=c=red:s=16x10[p];\
       [p]scale=w='max(1,1820*t/10)':h=10:eval=frame[fill];\
       [0:v]drawbox=x=50:y=ih-30:w=iw-100:h=10:color=gray@0.5:t=fill[track];\
       [track][fill]overlay=x=50:y=H-30:shortest=1" \
  progress_bar.mp4

# Circular progress (approximate with boxes)
# Note: True circular progress requires more complex expressions
```

### Loading Spinner (Approximation)

```bash
# Rotating indicator: a small color square overlaid on a circular path
ffmpeg -i video.mp4 \
  -filter_complex "color=c=white:s=10x10[dot];\
       [0:v][dot]overlay=x='W/2+50*cos(t*3)':y='H/2+50*sin(t*3)':shortest=1" \
  spinner.mp4
```

## Color Correction Overlays

### Vignette Effect

```bash
# Dark vignette
ffmpeg -i video.mp4 \
  -vf "vignette=PI/4" \
  vignette.mp4

# Softer vignette: a smaller angle darkens the corners less
# (mid-grey 1920x1080 yuv420p frame, corner vs centre: PI/4 -> ~12%,
# PI/6 -> ~48%; RGB input darkens less: ~25% and ~56%).
# mode=backward inverts the effect (brightens the corners), so keep forward.
ffmpeg -i video.mp4 \
  -vf "vignette=angle=PI/6" \
  soft_vignette.mp4
```

### Color Tint Overlay

```bash
# Warm tint using blend (the color source is endless and must match the video
# size; shortest=1 ends the output with the video). Blend modes run per plane,
# so blend in planar RGB (gbrp) and convert back to yuv420p afterwards.
ffmpeg -i video.mp4 \
  -f lavfi -i "color=c=0xFF8800:s=1920x1080" \
  -filter_complex "[0:v]format=gbrp[v];[1:v]format=gbrp[c];\
    [v][c]blend=all_mode=softlight:all_opacity=0.3:shortest=1,format=yuv420p" \
  warm_tint.mp4

# Cool tint
ffmpeg -i video.mp4 \
  -f lavfi -i "color=c=0x0088FF:s=1920x1080" \
  -filter_complex "[0:v]format=gbrp[v];[1:v]format=gbrp[c];\
    [v][c]blend=all_mode=softlight:all_opacity=0.2:shortest=1,format=yuv420p" \
  cool_tint.mp4
```

## Blend Modes

### Available Blend Modes

| Mode | Effect |
|------|--------|
| addition | Add pixel values |
| multiply | Multiply (darken) |
| screen | Screen (lighten) |
| overlay | Overlay blend |
| softlight | Soft light |
| hardlight | Hard light |
| difference | Difference |
| exclusion | Exclusion |
| darken | Darken only |
| lighten | Lighten only |

### Blend Mode Examples

```bash
# blend works plane by plane. On yuv420p video the U/V planes are blended too,
# which tints the result (multiply turns the frame green, screen pink). Convert
# both inputs to planar RGB (gbrp), blend, then go back to yuv420p.
# Both inputs must be the same size: scale with a reference input (rw/rh =
# the reference's size, FFmpeg 7.1+) matches the texture to the video. A single
# still image is repeated for every video frame.

# Multiply blend (darken)
ffmpeg -i video.mp4 -i texture.png \
  -filter_complex "[0:v]split[v][ref];[1:v][ref]scale=rw:rh,format=gbrp[b];[v]format=gbrp[a];\
    [a][b]blend=all_mode=multiply,format=yuv420p" \
  multiply.mp4

# Screen blend (lighten)
ffmpeg -i video.mp4 -i light_leak.png \
  -filter_complex "[0:v]split[v][ref];[1:v][ref]scale=rw:rh,format=gbrp[b];[v]format=gbrp[a];\
    [a][b]blend=all_mode=screen,format=yuv420p" \
  light_leak.mp4

# Overlay blend
ffmpeg -i video.mp4 -i texture.png \
  -filter_complex "[0:v]split[v][ref];[1:v][ref]scale=rw:rh,format=gbrp[b];[v]format=gbrp[a];\
    [a][b]blend=all_mode=overlay:all_opacity=0.5,format=yuv420p" \
  textured.mp4
```

## Safe Areas and Guides

### Broadcast Safe Areas

```bash
# Action safe (outer, 90%, red) and title safe (inner, 80%, yellow) guides
ffmpeg -i video.mp4 \
  -vf "drawbox=x=iw*0.05:y=ih*0.05:w=iw*0.9:h=ih*0.9:color=red:t=1,\
       drawbox=x=iw*0.1:y=ih*0.1:w=iw*0.8:h=ih*0.8:color=yellow:t=1" \
  safe_areas.mp4
```

### Aspect Ratio Guides

```bash
# 16:9 guide on 4:3 content (full width, 3/4 of the height: 4/3 / 0.75 = 16/9)
ffmpeg -i video_4x3.mp4 \
  -vf "drawbox=x=0:y=ih*0.125:w=iw:h=ih*0.75:color=green:t=1" \
  aspect_guide.mp4

# 2.35:1 cinematic guide
ffmpeg -i video.mp4 \
  -vf "drawbox=x=0:y=ih*0.12:w=iw:h=ih*0.76:color=red:t=1" \
  cinematic_guide.mp4
```

## Masking

### Rectangle Mask

```bash
# Blur outside rectangle
ffmpeg -i video.mp4 \
  -filter_complex "\
    [0:v]split[a][b];\
    [a]boxblur=20[blur];\
    [b]crop=400:300:100:100[crop];\
    [blur][crop]overlay=100:100" \
  spotlight.mp4
```

### Using Alpha Mask

```bash
# Apply effect only to masked area (mask.png: grayscale, same size as the
# video, white = effect). Use the mask as the alpha of the processed copy and
# overlay it. (maskedmerge forces all three inputs to one pixel format, so a
# gray mask on yuv420p video also blends the chroma planes at 50%.)
ffmpeg -i video.mp4 -i mask.png \
  -filter_complex "\
    [0:v]split[a][b];\
    [a]curves=preset=lighter[light];\
    [1:v]format=gray[mask];\
    [light][mask]alphamerge[fx];\
    [b][fx]overlay=format=auto" \
  -pix_fmt yuv420p masked_effect.mp4
```

## Generating Graphics Programmatically

### Color Bars and Test Patterns

```bash
# SMPTE color bars
ffmpeg -f lavfi -i "smptebars=size=1920x1080:duration=10" \
  -c:v libx264 -pix_fmt yuv420p \
  colorbars.mp4

# Test pattern with grid
ffmpeg -f lavfi -i "testsrc=size=1920x1080:duration=10" \
  -c:v libx264 -pix_fmt yuv420p \
  testpattern.mp4

# Solid color
ffmpeg -f lavfi -i "color=c=red:s=1920x1080:d=5" \
  -c:v libx264 -pix_fmt yuv420p \
  red.mp4
```

### Gradient Backgrounds

```bash
# Horizontal gradient
ffmpeg -f lavfi -i "gradients=s=1920x1080:c0=0x000033:c1=0x003366:duration=5" \
  -c:v libx264 -pix_fmt yuv420p \
  gradient.mp4

# Radial gradient (using geq)
ffmpeg -f lavfi \
  -i "color=c=black:s=1920x1080:d=5,geq=lum='255-255*sqrt(pow(X-W/2,2)+pow(Y-H/2,2))/sqrt(pow(W/2,2)+pow(H/2,2))':cb=128:cr=128" \
  -c:v libx264 -pix_fmt yuv420p \
  radial.mp4
```

### Noise and Texture

```bash
# Noise overlay
ffmpeg -f lavfi -i "nullsrc=size=1920x1080:duration=5,geq=lum='random(1)*255':cb=128:cr=128" \
  -c:v libx264 -pix_fmt yuv420p \
  noise.mp4

# Film grain effect (temporal + uniform luma noise from the noise filter)
ffmpeg -i video.mp4 \
  -vf "noise=c0s=20:c0f=t+u" \
  grainy.mp4
```

## Performance Tips

### Optimize Drawing Operations

```bash
# Use enable parameter to limit processing
ffmpeg -i video.mp4 \
  -vf "drawbox=x=100:y=100:w=200:h=150:color=red:t=fill:enable='between(t,5,10)'" \
  optimized.mp4

# Pre-render static graphics
# Instead of complex real-time drawing, overlay pre-made images
ffmpeg -i video.mp4 -i prerendered_graphic.png \
  -filter_complex "[0:v][1:v]overlay=10:10" \
  faster.mp4
```

### Hardware Acceleration

```bash
# Use hardware encoding for graphics-heavy output
ffmpeg -i video.mp4 \
  -vf "drawbox=x=100:y=100:w=200:h=150:color=red:t=fill" \
  -c:v h264_nvenc -preset p4 \
  output.mp4
```

## Troubleshooting

### Common Issues

**"Expression syntax error"**
```bash
# Escape special characters properly
# Use single quotes around expression values
ffmpeg -i video.mp4 \
  -vf "drawbox=x='iw/2':y='ih/2':w=100:h=100:color=red:t=fill" \
  output.mp4
```

**Overlay not visible**
```bash
# Check PNG has alpha channel
ffprobe -v error -select_streams v -show_entries stream=pix_fmt overlay.png

# Convert to RGBA if needed
ffmpeg -i overlay.png -pix_fmt rgba -update 1 overlay_rgba.png
```

**Text not rendering**: `fontcolor` defaults to black, and a missing font falls back silently; see Troubleshooting in `drawtext.md`.

**Performance issues with complex filters**
```bash
# Reduce filter chain complexity
# Pre-render graphics
# Use lower resolution for preview
ffmpeg -i video.mp4 \
  -vf "scale=640:360,drawbox=x=20:y=20:w=200:h=100:color=red:t=fill" \
  -preset ultrafast \
  preview.mp4
```

## Best Practices

### Design
1. Use transparency (RGBA) for overlays
2. Match overlay resolution to video
3. Use appropriate colors for visibility
4. Test on various backgrounds

### Performance
1. Pre-render complex graphics as images
2. Use enable parameter for timed effects
3. Limit filter chain length
4. Use hardware encoding for final output

### Accessibility
1. Ensure sufficient contrast for text
2. Avoid flashing/blinking elements
3. Keep important content within safe areas
4. Test at multiple resolutions

For text overlays see `drawtext.md`; for subtitle files and burn-in see `captions.md`.
