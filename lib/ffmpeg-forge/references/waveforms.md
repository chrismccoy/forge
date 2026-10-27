# FFmpeg Waveforms and Audio Visualization

Complete guide to generating audio waveforms, spectrum analyzers, and audio-reactive visualizations using FFmpeg.

## Contents

- [Quick Reference](#quick-reference)
- [Audio Visualization Filters](#audio-visualization-filters)
- [Waveform Generation (showwaves)](#waveform-generation-showwaves)
- [Static Waveform Images (showwavespic)](#static-waveform-images-showwavespic)
- [Spectrum Visualization (showspectrum)](#spectrum-visualization-showspectrum)
- [Static Spectrum Image (showspectrumpic)](#static-spectrum-image-showspectrumpic)
- [Frequency Bars (showfreqs)](#frequency-bars-showfreqs)
- [Constant-Q Transform (showcqt)](#constant-q-transform-showcqt)
- [Vector Scope (avectorscope)](#vector-scope-avectorscope)
- [Audio Histogram (ahistogram)](#audio-histogram-ahistogram)
- [Combining Visualizations](#combining-visualizations)
- [Podcast/Music Video Templates](#podcastmusic-video-templates)
- [Performance Optimization](#performance-optimization)
- [Troubleshooting](#troubleshooting)

## Quick Reference

| Visualization | Filter | Output | Command Snippet |
|---------------|--------|--------|-----------------|
| Animated waveform | `showwaves` | Video | `[0:a]showwaves=s=1280x720:mode=line[v]` |
| Static waveform | `showwavespic` | Image | `[0:a]showwavespic=s=1280x240:colors=0x00FF00` |
| Spectrum | `showspectrum` | Video | `[0:a]showspectrum=s=1280x720:color=fire:fps=30` |
| Frequency bars | `showfreqs` | Video | `[0:a]showfreqs=s=1280x720:mode=bar` |
| Vectorscope | `avectorscope` | Video | `[0:a]avectorscope=s=512x512:mode=lissajous` |

| Color Scheme | Effect |
|--------------|--------|
| `rainbow` | Full spectrum gradient |
| `fire` | Warm orange/red tones |
| `cool` | Blue tones |
| `viridis` | Scientific colormap |

Default colour is `channel`; the full list is under Spectrum Visualization.


> **Pixel format:** showwaves, showfreqs and avectorscope output RGBA, showspectrum outputs full-range `yuvj444p`, and ahistogram `yuva444p`. libx264 turns any of these into a High 4:4:4 stream that browsers and phones will not play. The MP4 recipes below add `-pix_fmt yuv420p`; keep it (or end the graph with `format=yuv420p`) when adapting them. Recipes that overlay the visualization onto a yuv420p video or background already come out 4:2:0.

## Audio Visualization Filters

### Filter Overview

| Filter | Output | Use Case |
|--------|--------|----------|
| showwaves | Video of animated waveform | Music videos, live vis |
| showwavespic | Static waveform image | Thumbnails, podcasts |
| showspectrum | Spectrum analyzer video | Frequency analysis |
| showspectrumpic | Static spectrum image | Audio fingerprinting |
| showfreqs | Frequency bars video | Equalizer visualization |
| avectorscope | Stereo phase visualization | Audio engineering |
| ahistogram | Audio level histogram | Loudness analysis |
| showcqt | Constant-Q transform | Musical note visualization |

## Waveform Generation (showwaves)

### Basic Animated Waveform

```bash
# Simple waveform video
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x720:mode=line[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  -c:v libx264 -c:a aac \
  waveform.mp4

# Waveform from video with audio
ffmpeg -i video.mp4 \
  -filter_complex "[0:a]showwaves=s=1920x200:mode=line[wave];[0:v][wave]overlay=0:H-200[v]" \
  -map "[v]" -map 0:a \
  -c:v libx264 -c:a copy \
  video_with_wave.mp4
```

### Waveform Modes

```bash
# Point mode (default) - one dot per sample (gaps on steep waveforms)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=point[v]" \
  -map "[v]" -pix_fmt yuv420p waveform_point.mp4

# Line mode - a vertical line from the centre to each sample (filled look)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line[v]" \
  -map "[v]" -pix_fmt yuv420p waveform_filled.mp4

# Point-to-point mode - thin connected line between samples (oscilloscope look)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=p2p[v]" \
  -map "[v]" -pix_fmt yuv420p waveform_p2p.mp4

# Centered line mode - filled, mirrored around the centre
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=cline[v]" \
  -map "[v]" -pix_fmt yuv420p waveform_centered.mp4
```

### Available Modes

| Mode | Description |
|------|-------------|
| point | Draw a point for each sample (default) |
| line | Draw a vertical line from the centre to each sample (filled) |
| p2p | Draw a line between consecutive samples (thin, connected) |
| cline | Draw a centered vertical line for each sample (filled, symmetric) |

### Colored Waveforms

```bash
# Single color waveform
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=cline:colors=0x00FF00[v]" \
  -map "[v]" -pix_fmt yuv420p green_wave.mp4

# Multi-channel colors (stereo)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:colors=red|blue:split_channels=1[v]" \
  -map "[v]" -pix_fmt yuv420p stereo_wave.mp4

# Single accent colour
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=cline:colors=0xFF6600[v]" \
  -map "[v]" -pix_fmt yuv420p orange_wave.mp4
```

### Rate, Speed and Scale

showwaves draws a fresh page per frame. Each frame shows `sample_rate / rate` samples spread over the width, so `rate` (default 25) and the width set how much audio a frame covers. `n` (samples per column) overrides `rate`: with `n` set, the frame rate becomes `sample_rate / (n * width)`, e.g. 44100 / (2 * 1280) = 17.2 fps for `n=2`. Avoid `n` for video and set `rate` instead.

```bash
# Normal video rate (30 fps); each frame covers 1/30 s of audio
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:rate=30[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p rate30_wave.mp4

# Adjust scale (amplitude)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:scale=lin[v]" \
  -map "[v]" -pix_fmt yuv420p linear_wave.mp4

# Logarithmic scale (better for quiet audio)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:scale=log[v]" \
  -map "[v]" -pix_fmt yuv420p log_wave.mp4

# Square root scale
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:scale=sqrt[v]" \
  -map "[v]" -pix_fmt yuv420p sqrt_wave.mp4

# Cube root scale (compressed dynamics)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:scale=cbrt[v]" \
  -map "[v]" -pix_fmt yuv420p cbrt_wave.mp4
```

### Scale Options

| Scale | Description | Best For |
|-------|-------------|----------|
| lin | Linear amplitude | General use |
| log | Logarithmic | Quiet audio, speech |
| sqrt | Square root | Moderate compression |
| cbrt | Cube root | Heavy compression |

## Static Waveform Images (showwavespic)

### Basic Waveform Image

```bash
# Generate waveform PNG
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwavespic=s=1280x240:colors=0x00FF00" \
  -frames:v 1 -update 1 \
  waveform.png

# High-resolution waveform
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwavespic=s=3840x480:colors=white" \
  -frames:v 1 -update 1 \
  waveform_hires.png
```

### Styled Waveform Images

```bash
# Split stereo channels
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwavespic=s=1280x480:split_channels=1:colors=0xFF0000|0x0000FF" \
  -frames:v 1 -update 1 \
  stereo_waveform.png

# Filled style
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwavespic=s=1280x240:colors=0x1E90FF:draw=full" \
  -frames:v 1 -update 1 \
  filled_waveform.png

# Scale adjustment
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwavespic=s=1280x240:scale=sqrt:colors=0xFFD700" \
  -frames:v 1 -update 1 \
  golden_waveform.png
```

### Waveform with Background

```bash
# Waveform on colored background
ffmpeg -i audio.mp3 \
  -filter_complex "color=c=0x1a1a2e:s=1280x240:d=1[bg];\
                   [0:a]showwavespic=s=1280x240:colors=0x00FF88[wave];\
                   [bg][wave]overlay[v]" \
  -map "[v]" -frames:v 1 -update 1 \
  waveform_bg.png

# Waveform on gradient background
ffmpeg -f lavfi \
  -i "gradients=s=1280x240:c0=0x000033:c1=0x003366:duration=1" \
  -i audio.mp3 \
  -filter_complex "[1:a]showwavespic=s=1280x240:colors=0x00FFFF[wave];\
                   [0:v][wave]overlay[v]" \
  -map "[v]" -frames:v 1 -update 1 \
  waveform_gradient.png
```

## Spectrum Visualization (showspectrum)

`showspectrum` defaults to `fps=auto`, a rate that depends on the output height (measured on 8.0.1 at 44.1 kHz: 61.25 fps at 360 px, 30.62 at 720, 20.42 at 1080). The recipes set `fps=30` for a predictable video rate.

### Basic Spectrum Analyzer

```bash
# Animated spectrum
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:mode=combined:color=rainbow:fps=30[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  -c:v libx264 -c:a aac \
  spectrum.mp4

# Vertical spectrum
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=720x1280:orientation=vertical:color=fire:fps=30[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  spectrum_vertical.mp4
```

### Spectrum Modes

```bash
# Combined channels
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:mode=combined:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_combined.mp4

# Separate channels
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:mode=separate:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_separate.mp4
```

### Color Schemes

```bash
# Rainbow spectrum
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:color=rainbow:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_rainbow.mp4

# Fire spectrum
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:color=fire:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_fire.mp4

# Cool spectrum
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:color=cool:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_cool.mp4

# Channel-based colors
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:color=channel:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_channel.mp4
```

### Available Color Schemes

| Color | Description |
|-------|-------------|
| channel | Use channel colors (default) |
| intensity | Brightness by intensity |
| rainbow | Rainbow gradient |
| moreland | Diverging color map |
| nebulae | Space-like colors |
| fire | Warm fire colors |
| fiery | Intense fire |
| fruit | Fruit-inspired |
| cool | Cool blue tones |
| magma | Volcanic colors |
| green | Green gradient |
| viridis | Scientific colormap |
| plasma | Plasma colormap |
| cividis | Colorblind-friendly |
| terrain | Terrain-like |

### Spectrum Scale and Window

```bash
# Logarithmic frequency scale
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:fscale=log:color=fire:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_log.mp4

# Different window functions
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x720:win_func=blackman:color=rainbow:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_blackman.mp4

# Higher frequency resolution (frequency bins follow the output height)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1280x1024:color=fire:fps=30[v]" \
  -map "[v]" -pix_fmt yuv420p spectrum_hires.mp4
```

## Static Spectrum Image (showspectrumpic)

```bash
# Full audio spectrogram
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrumpic=s=1920x480:color=fire:legend=0[v]" \
  -map "[v]" -update 1 \
  spectrogram.png

# With legend (legend=1 is the default; the axes and labels add margins, so
# the image is larger than s=, e.g. 960x240 -> 1242x368)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrumpic=s=1920x480:color=rainbow:legend=1[v]" \
  -map "[v]" -update 1 \
  spectrogram_legend.png

# Logarithmic frequency scale
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrumpic=s=1920x480:fscale=log:color=viridis:legend=0[v]" \
  -map "[v]" -update 1 \
  spectrogram_log.png
```

## Frequency Bars (showfreqs)

### Basic Frequency Display

```bash
# Bar-style equalizer
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showfreqs=s=1280x720:mode=bar:ascale=log:colors=green[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  freqs_bar.mp4

# Line-style frequency display
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showfreqs=s=1280x720:mode=line:colors=cyan[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  freqs_line.mp4

# Dot-style display
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showfreqs=s=1280x720:mode=dot:colors=0xFF00FF[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  freqs_dot.mp4
```

### Equalizer-Style Visualization

```bash
# Classic equalizer bars
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showfreqs=s=1280x720:mode=bar:fscale=log:ascale=log:win_size=1024:colors=0x00FF00[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  -c:v libx264 -c:a aac \
  equalizer.mp4
```

## Constant-Q Transform (showcqt)

### Musical Note Visualization

```bash
# Basic CQT visualization
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showcqt=s=1920x1080[v]" \
  -map "[v]" -map 0:a \
  cqt.mp4

# Axis and note labels are on by default (axis=1, text=1); fontfile only
# changes the label font, which should be monospace (showcqt warns otherwise)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showcqt=s=1920x1080:fontfile=/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf[v]" \
  -map "[v]" -map 0:a \
  cqt_labeled.mp4

# Contrast: sonogram and bar gamma (numbers 1-7)
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showcqt=s=1920x1080:sono_g=4:bar_g=2[v]" \
  -map "[v]" -map 0:a \
  cqt_custom.mp4
```

## Vector Scope (avectorscope)

### Stereo Phase Visualization

```bash
# Basic vectorscope
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]avectorscope=s=512x512:mode=lissajous[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  vectorscope.mp4

# Polar mode
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]avectorscope=s=512x512:mode=polar:zoom=1.5[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  vectorscope_polar.mp4

# With color coding
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]avectorscope=s=512x512:mode=lissajous:draw=line:scale=sqrt[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  vectorscope_color.mp4
```

## Audio Histogram (ahistogram)

### Level Distribution Visualization

```bash
# Basic audio histogram
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]ahistogram=s=1280x720:dmode=separate[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  histogram.mp4

# Single (combined channels) mode
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]ahistogram=s=1280x720:dmode=single:slide=scroll[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  histogram_combined.mp4
```

## Combining Visualizations

### Waveform Over Video

```bash
# Waveform overlay at bottom
ffmpeg -i video.mp4 \
  -filter_complex "[0:a]showwaves=s=1920x200:mode=cline:colors=white@0.7[wave];\
                   [0:v][wave]overlay=0:H-200[v]" \
  -map "[v]" -map 0:a \
  -c:v libx264 -c:a copy \
  video_waveform.mp4

# Semi-transparent full-frame waveform: overlay uses the waveform's alpha
# (blend would ignore alpha and, on YUV, add the background's chroma and
# tint the whole frame magenta)
ffmpeg -i video.mp4 \
  -filter_complex "[0:a]showwaves=s=1920x1080:mode=p2p:colors=0x00FF00@0.5:scale=sqrt[wave];\
                   [0:v][wave]overlay=format=auto,format=yuv420p[v]" \
  -map "[v]" -map 0:a -c:a copy \
  video_wave_overlay.mp4
```

### Multiple Visualizations

```bash
# Waveform + Spectrum side by side. Give every visualizer the same rate:
# hstack/vstack emit a frame whenever any input does, so 25 fps showwaves
# next to 30 fps showspectrum gives variable-rate output tagged 150 fps
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]asplit=2[a1][a2];\
                   [a1]showwaves=s=640x360:mode=cline:colors=green:rate=30[wave];\
                   [a2]showspectrum=s=640x360:color=fire:fps=30[spec];\
                   [wave][spec]hstack,scale=out_range=tv,format=yuv420p[v]" \
  -map "[v]" -map 0:a \
  combined_vis.mp4

# Full visualization dashboard
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]asplit=4[a1][a2][a3][a4];\
                   [a1]showwaves=s=640x240:mode=cline:colors=cyan:rate=30[wave];\
                   [a2]showspectrum=s=640x240:color=fire:scale=log:fps=30[spec];\
                   [a3]showfreqs=s=640x240:mode=bar:colors=lime:rate=30[freq];\
                   [a4]avectorscope=s=640x240:mode=lissajous:rate=30[vec];\
                   [wave][spec]hstack[top];\
                   [freq][vec]hstack[bottom];\
                   [top][bottom]vstack[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  dashboard.mp4
```

### Visualization with Progress Bar

```bash
# Waveform with animated progress indicator.
# showwavespic only emits ONE frame at end of stream, so render it to a PNG
# first, then loop that PNG under the live waveform and the moving playhead.
DUR=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 audio.mp3)

ffmpeg -i audio.mp3 \
  -filter_complex "showwavespic=s=1280x200:colors=0x333333" \
  -frames:v 1 -update 1 wave_bg.png

ffmpeg -loop 1 -i wave_bg.png -i audio.mp3 \
  -filter_complex "[1:a]showwaves=s=1280x200:mode=cline:colors=0x00FF00[wave];\
                   [0:v][wave]overlay=shortest=1[v];\
                   color=c=red:s=4x200[bar];\
                   [v][bar]overlay=x='t/${DUR}*W':shortest=1,format=yuv420p[out]" \
  -map "[out]" -map 1:a -shortest \
  waveform_progress.mp4
```

## Podcast/Music Video Templates

### SoundCloud-Style Waveform

```bash
# Static waveform for music thumbnail
ffmpeg -i audio.mp3 \
  -filter_complex "color=c=0x1a1a2e:s=1200x300:d=1[bg];\
                   [0:a]showwavespic=s=1200x200:colors=0xFF6B00:scale=sqrt[wave];\
                   [bg][wave]overlay=0:50[v]" \
  -map "[v]" -frames:v 1 -update 1 \
  soundcloud_wave.png
```

### Music Visualizer Video

```bash
# Full music visualizer
ffmpeg -i audio.mp3 -loop 1 -i album_art.jpg \
  -filter_complex "[1:v]scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,boxblur=30[bg];\
                   [0:a]showwaves=s=1920x300:mode=cline:colors=white:scale=sqrt[wave];\
                   [1:v]scale=400:400[art];\
                   [bg][wave]overlay=0:H-350:shortest=1[tmp];\
                   [tmp][art]overlay=(W-400)/2:(H-400)/2-100,scale=out_range=tv,format=yuv420p[v]" \
  -map "[v]" -map 0:a -shortest \
  -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 192k \
  music_video.mp4
```

### Podcast Waveform Video

```bash
# Podcast with waveform and title
ffmpeg -i podcast.mp3 \
  -filter_complex "color=c=0x2d3436:s=1920x1080:d=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 podcast.mp3)[bg];\
                   [0:a]showwaves=s=1920x400:mode=cline:colors=0x74b9ff:scale=sqrt[wave];\
                   [bg][wave]overlay=0:(H-400)/2[tmp];\
                   [tmp]drawtext=text='Episode Title':fontsize=72:fontcolor=white:x=(w-tw)/2:y=100[v]" \
  -map "[v]" -map 0:a \
  -c:v libx264 -c:a aac \
  podcast_video.mp4
```

## Performance Optimization

### Large Audio Files

Visualizers are single-threaded and cheap next to the encode. For long files, speed up the encode, not the visualizer, and keep `n` out of it (it would lower the frame rate):

```bash
ffmpeg -i long_audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:rate=25[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  -c:v libx264 -preset veryfast -c:a aac \
  output.mp4
```

### Hardware Acceleration

```bash
# NVENC encoding for visualization
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showspectrum=s=1920x1080:color=fire:fps=30[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  -c:v h264_nvenc -preset p4 -c:a aac \
  spectrum_nvenc.mp4
```

## Troubleshooting

### Common Issues

**Waveform appears silent/flat**
```bash
# Adjust scale for quiet audio
ffmpeg -i quiet_audio.mp3 \
  -filter_complex "[0:a]volume=10,showwaves=s=1280x360:mode=line:scale=log[v]" \
  -map "[v]" -pix_fmt yuv420p output.mp4
```

**Audio/video sync issues**
```bash
# Force frame rate
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:rate=30[v]" \
  -map "[v]" -map 0:a -pix_fmt yuv420p \
  -r 30 \
  output.mp4
```

**Waveform moves too fast/slow**
```bash
# Each frame covers sample_rate/rate samples. A higher rate shows less audio
# per frame (calmer, more detailed); a lower rate shows more (busier).
# Do not use n for this: it overrides rate and lowers the frame rate.
ffmpeg -i audio.mp3 \
  -filter_complex "[0:a]showwaves=s=1280x360:mode=line:rate=50[v]" \
  -map "[v]" -pix_fmt yuv420p output.mp4
```

This guide covers FFmpeg audio visualization. For video transitions and effects, see `transitions.md`.
