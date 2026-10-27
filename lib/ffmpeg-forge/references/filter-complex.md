# FFmpeg filter_complex Reference

Complex filtergraphs: multi-input compositions, overlays, grids, transitions, audio mixing, color correction, and multi-output chains.

## Contents

- [Quick Reference](#quick-reference)
- [filter_complex Syntax](#filter_complex-syntax)
- [Common Composition Patterns](#common-composition-patterns) (PiP, grids, xfade, audio mixing, text, split to multiple outputs, concat, color correction, looping)
- [GPU-Accelerated Filtergraphs](#gpu-accelerated-filtergraphs)
- [Advanced Patterns](#advanced-patterns) (multi-layer, green screen, visualizers, timed effects)
- [Debugging Filtergraphs](#debugging-filtergraphs)
- [Best Practices](#best-practices)

## Quick Reference

| Task | Command Pattern |
|------|-----------------|
| Basic filter_complex | `-filter_complex "[0:v][1:v]overlay"` |
| Named labels | `[input]filter[output]` |
| Chain filters | `filter1,filter2,filter3` |
| Separate chains | `chain1;chain2` |
| Map output | `-map "[label]"` |

## filter_complex Syntax

### Basic Structure

```text
-filter_complex "filterchain1;filterchain2;..."
```

Each filterchain consists of:
- **Input labels**: `[input_label]`
- **Filter(s)**: `filter1,filter2,...` (comma-separated)
- **Output labels**: `[output_label]`

### Complete Syntax

```text
[input_label1][input_label2]filter=param1=value1:param2=value2[output_label]
```

### Syntax Components

| Component | Description | Example |
|-----------|-------------|---------|
| `[0:v]` | Video stream from input 0 | First input video |
| `[0:a]` | Audio stream from input 0 | First input audio |
| `[1:v]` | Video stream from input 1 | Second input video |
| `[label]` | Custom named label | User-defined |
| `,` | Chain filters sequentially | `scale,fps` |
| `;` | Separate independent chains | `chain1;chain2` |
| `=` | Parameter assignment | `scale=1280:720` |
| `:` | Parameter separator | `w=1280:h=720` |

### Stream References

| Reference | Meaning |
|-----------|---------|
| `[0]` | First input (all streams) |
| `[0:v]` | First input, video stream |
| `[0:a]` | First input, audio stream |
| `[0:s]` | First input, subtitle stream |
| `[0:v:0]` | First input, first video stream |
| `[1:a:1]` | Second input, second audio stream |

### Unlabeled Pads

- An unlabeled input pad (or a label that matches no stream and no other filter's output) binds to the first unused input stream of the matching type.
- An unlabeled output pad of the whole graph is mapped to the first output file automatically.
- Inside one chain, filters separated by `,` connect output to input in order.
- Use explicit labels plus `-map "[label]"` whenever there is more than one input or output; implicit binding is easy to get wrong.

### Escaping Rules

```bash
# Wrap filtergraph in double quotes
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]drawtext=text='Hello World':fontsize=24[out]" \
  -map "[out]" output.mp4

# Using shell variables
text="Dynamic Text"
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]drawtext=text='$text':fontsize=24[out]" \
  -map "[out]" output.mp4

# Escaping special characters (colons in timestamps)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]drawtext=text='Time\: %{pts\:hms}':fontsize=24[out]" \
  -map "[out]" output.mp4
```

---

## Common Composition Patterns

### 1. Picture-in-Picture (PiP)

```bash
# Basic PiP - small video in bottom-right corner
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "\
    [1:v]scale=320:240[pip];\
    [0:v][pip]overlay=W-w-10:H-h-10" \
  -c:v libx264 -c:a copy output.mp4

# PiP with border
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "\
    [1:v]scale=320:240,drawbox=x=0:y=0:w=iw:h=ih:c=white:t=3[pip];\
    [0:v][pip]overlay=W-w-10:H-h-10" \
  output.mp4

# Animated PiP (moving)
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "\
    [1:v]scale=320:240[pip];\
    [0:v][pip]overlay='W-w-10-sin(t)*20':'H-h-10-cos(t)*20'" \
  output.mp4

# PiP with fade-in
ffmpeg -i main.mp4 -i pip.mp4 \
  -filter_complex "\
    [1:v]scale=320:240,fade=in:st=2:d=1[pip];\
    [0:v][pip]overlay=W-w-10:H-h-10:enable='gte(t,2)'" \
  output.mp4
```

### 2. Video Grid Layouts

**Using hstack/vstack (fast, simple):**

```bash
# Side by side (hstack needs equal heights; scale first if they differ)
ffmpeg -i left.mp4 -i right.mp4 \
  -filter_complex "[0:v][1:v]hstack=inputs=2[out]" \
  -map "[out]" output.mp4

# 2x2 Grid
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 \
  -filter_complex "\
    [0:v]scale=640:360[v0];\
    [1:v]scale=640:360[v1];\
    [2:v]scale=640:360[v2];\
    [3:v]scale=640:360[v3];\
    [v0][v1]hstack=inputs=2[top];\
    [v2][v3]hstack=inputs=2[bottom];\
    [top][bottom]vstack=inputs=2[out]" \
  -map "[out]" output.mp4

# 3x2 Grid
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 -i 5.mp4 -i 6.mp4 \
  -filter_complex "\
    [0:v]scale=426:240[v0];\
    [1:v]scale=426:240[v1];\
    [2:v]scale=426:240[v2];\
    [3:v]scale=426:240[v3];\
    [4:v]scale=426:240[v4];\
    [5:v]scale=426:240[v5];\
    [v0][v1][v2]hstack=inputs=3[top];\
    [v3][v4][v5]hstack=inputs=3[bottom];\
    [top][bottom]vstack=inputs=2[out]" \
  -map "[out]" output.mp4
```

**Using xstack (more flexible positioning):**

```bash
# 2x2 Grid with xstack
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 -i 4.mp4 \
  -filter_complex "\
    [0:v]scale=640:360[v0];\
    [1:v]scale=640:360[v1];\
    [2:v]scale=640:360[v2];\
    [3:v]scale=640:360[v3];\
    [v0][v1][v2][v3]xstack=inputs=4:layout=0_0|640_0|0_360|640_360[out]" \
  -map "[out]" output.mp4

# L-shaped layout
ffmpeg -i main.mp4 -i side1.mp4 -i side2.mp4 \
  -filter_complex "\
    [0:v]scale=960:720[main];\
    [1:v]scale=320:360[s1];\
    [2:v]scale=320:360[s2];\
    [main][s1][s2]xstack=inputs=3:layout=0_0|960_0|960_360[out]" \
  -map "[out]" output.mp4
```

### 3. Video Transitions (xfade)

```bash
# Simple fade transition
ffmpeg -i first.mp4 -i second.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=fade:duration=1:offset=4[v];\
    [0:a][1:a]acrossfade=d=1[a]" \
  -map "[v]" -map "[a]" -pix_fmt yuv420p output.mp4

# Dissolve transition
ffmpeg -i first.mp4 -i second.mp4 \
  -filter_complex "\
    [0:v][1:v]xfade=transition=dissolve:duration=2:offset=3[v]" \
  -map "[v]" -pix_fmt yuv420p output.mp4

# Wipe transitions
ffmpeg -i first.mp4 -i second.mp4 \
  -filter_complex "[0:v][1:v]xfade=transition=wipeleft:duration=1:offset=4[v]" \
  -map "[v]" -pix_fmt yuv420p output.mp4

# Multiple transitions (3+ clips)
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 \
  -filter_complex "\
    [0:v]settb=AVTB,fps=30[v0];\
    [1:v]settb=AVTB,fps=30[v1];\
    [2:v]settb=AVTB,fps=30[v2];\
    [v0][v1]xfade=transition=fade:duration=1:offset=4[xf1];\
    [xf1][v2]xfade=transition=dissolve:duration=1:offset=8[out]" \
  -map "[out]" -pix_fmt yuv420p output.mp4
```

**Available xfade transitions:**
- `fade`, `fadeblack`, `fadewhite`
- `wipeleft`, `wiperight`, `wipeup`, `wipedown`
- `slideleft`, `slideright`, `slideup`, `slidedown`
- `circlecrop`, `rectcrop`, `distance`
- `radial`, `smoothleft`, `smoothright`
- `dissolve`, `pixelize`, `diagtl`, `diagtr`, `diagbl`, `diagbr`
- `hlslice`, `hrslice`, `vuslice`, `vdslice`
- `hblur`, `fadegrays`, `squeezev`, `squeezeh`

### 4. Audio Mixing

```bash
# Mix two audio tracks
ffmpeg -i video.mp4 -i music.mp3 \
  -filter_complex "\
    [0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2[aout]" \
  -map 0:v -map "[aout]" output.mp4

# Mix with volume control (duration=first keeps the mix as long as the video's
# own audio; the default duration=longest would run on if the music is longer)
ffmpeg -i vocals.mp4 -i music.mp3 \
  -filter_complex "\
    [0:a]volume=1.0[a0];\
    [1:a]volume=0.3[a1];\
    [a0][a1]amix=inputs=2:duration=first[aout]" \
  -map 0:v -map "[aout]" -c:v copy output.mp4

# Audio with delay (sound effect starts at 2 s; adelay takes ms per channel)
ffmpeg -i main.mp4 -i effect.mp3 \
  -filter_complex "\
    [1:a]adelay=2000|2000[delayed];\
    [0:a][delayed]amix=inputs=2:duration=first[aout]" \
  -map 0:v -map "[aout]" output.mp4

# Ducking: music drops whenever the voice is present (voice = sidechain key)
ffmpeg -i voice.mp4 -i music.mp3 \
  -filter_complex "\
    [0:a]asplit=2[vo][key];\
    [1:a][key]sidechaincompress=threshold=0.05:ratio=8:attack=20:release=400[ducked];\
    [vo][ducked]amix=inputs=2:duration=first:normalize=0[aout]" \
  -map 0:v -map "[aout]" -c:v copy output.mp4

# Merge channels (stereo from two mono)
ffmpeg -i left.wav -i right.wav \
  -filter_complex "[0:a][1:a]amerge=inputs=2[aout]" \
  -map "[aout]" stereo.wav

# Audio crossfade between tracks
ffmpeg -i track1.mp3 -i track2.mp3 \
  -filter_complex "[0:a][1:a]acrossfade=d=3:c1=tri:c2=tri[out]" \
  -map "[out]" mixed.mp3
```

### 5. Text and Watermark Overlays

```bash
# Static text overlay
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]drawtext=text='Watermark':\
    fontsize=48:fontcolor=white@0.8:\
    x=10:y=H-th-10[out]" \
  -map "[out]" output.mp4

# Fade-in text
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]drawtext=text='Hello':\
    fontsize=64:fontcolor=white:\
    x=(w-text_w)/2:y=(h-text_h)/2:\
    alpha='if(lt(t,1),t,1)'[out]" \
  -map "[out]" output.mp4

# Scrolling credits. On the 8.0.1 Ubuntu build a multi-line textfile draws a
# missing-glyph box at every line end: for real credits use the ASS recipe in
# drawtext-animation.md (Scrolling Credits)
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]drawtext=textfile=credits.txt:\
    fontsize=32:fontcolor=white:\
    x=(w-text_w)/2:y=h-t*50[out]" \
  -map "[out]" output.mp4

# Timed text (appear/disappear)
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]drawtext=text='Show at 2s':\
    fontsize=48:fontcolor=yellow:\
    x=100:y=100:\
    enable='between(t,2,5)'[out]" \
  -map "[out]" output.mp4

# Logo/image watermark
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "\
    [1:v]scale=150:-1[logo];\
    [0:v][logo]overlay=W-w-20:20[out]" \
  -map "[out]" -map 0:a output.mp4
```

### 6. Split to Multiple Outputs

One decode feeding several independent files. This is not an ABR ladder: the outputs have no aligned keyframes, bitrate caps or master playlist. HLS/DASH ladders are in [`streaming.md`](streaming.md#abr-ladder-master-playlist).

```bash
# Split for multiple resolutions
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split=3[v1][v2][v3];\
    [v1]scale=1920:1080[hd];\
    [v2]scale=1280:720[sd];\
    [v3]scale=640:360[mobile]" \
  -map "[hd]" hd.mp4 \
  -map "[sd]" sd.mp4 \
  -map "[mobile]" mobile.mp4

# Split video and audio separately
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split=2[v1][v2];\
    [0:a]asplit=2[a1][a2];\
    [v1]scale=1280:720[vout1];\
    [v2]scale=640:360[vout2]" \
  -map "[vout1]" -map "[a1]" output1.mp4 \
  -map "[vout2]" -map "[a2]" output2.mp4
```

### 7. Video Concatenation with Filters

```bash
# Concatenate with format normalization
ffmpeg -i 1.mp4 -i 2.mp4 -i 3.mp4 \
  -filter_complex "\
    [0:v]scale=1920:1080,fps=30,setpts=PTS-STARTPTS[v0];\
    [1:v]scale=1920:1080,fps=30,setpts=PTS-STARTPTS[v1];\
    [2:v]scale=1920:1080,fps=30,setpts=PTS-STARTPTS[v2];\
    [0:a]aformat=sample_rates=48000:channel_layouts=stereo[a0];\
    [1:a]aformat=sample_rates=48000:channel_layouts=stereo[a1];\
    [2:a]aformat=sample_rates=48000:channel_layouts=stereo[a2];\
    [v0][a0][v1][a1][v2][a2]concat=n=3:v=1:a=1[outv][outa]" \
  -map "[outv]" -map "[outa]" output.mp4
```

### 8. Color Correction

RGB-based filters (`lut3d`, `colorbalance`, `curves`) can change the pixel format, so end deliverable chains with `-pix_fmt yuv420p`.

```bash
# Basic EQ adjustment
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]eq=brightness=0.1:contrast=1.2:saturation=1.3[out]" \
  -map "[out]" -map 0:a? -c:a copy output.mp4

# Apply a 3D LUT (.cube)
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]lut3d=file=cinematic.cube[out]" \
  -map "[out]" -map 0:a? -c:a copy -pix_fmt yuv420p output.mp4

# Color balance (shadows / midtones / highlights)
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]colorbalance=\
    rs=0.1:gs=-0.05:bs=-0.1:\
    rm=0.05:gm=0:bm=-0.05:\
    rh=0.1:gh=0:bh=-0.1[out]" \
  -map "[out]" -map 0:a? -c:a copy -pix_fmt yuv420p output.mp4

# Curves preset
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]curves=preset=vintage[out]" \
  -map "[out]" -map 0:a? -c:a copy -pix_fmt yuv420p output.mp4
```

### 9. Looping an Input

```bash
# Play the input 4 times (-stream_loop 3 = 3 extra loops), capped at 60 s
ffmpeg -stream_loop 3 -i input.mp4 \
  -filter_complex "[0:v]setpts=N/FRAME_RATE/TB[out]" \
  -map "[out]" -t 60 output.mp4
```

---

## GPU-Accelerated Filtergraphs

### Full CUDA Pipeline

```bash
# GPU decode -> GPU filter -> GPU encode
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i main.mp4 \
  -hwaccel cuda -hwaccel_output_format cuda -i overlay.mp4 \
  -filter_complex "\
    [0:v]scale_cuda=1920:1080[main];\
    [1:v]scale_cuda=320:180[pip];\
    [main][pip]overlay_cuda=W-w-10:H-h-10[out]" \
  -map "[out]" -map 0:a \
  -c:v h264_nvenc -preset p4 output.mp4
```

### Hybrid Pipelines and GPU ABR Ladders

CPU-only filters (`drawtext`, `subtitles`) need `hwdownload,format=nv12` (8-bit) or `format=p010le` (10-bit) before them and `hwupload_cuda` after. The GPU-scale -> CPU-text -> GPU-encode graph and the 1:N CUDA ABR ladder (`split` + `scale_cuda` per rung) are in [`hwaccel-nvidia-nvenc.md`](hwaccel-nvidia-nvenc.md#hybrid-gpu--cpu-pipelines). Vulkan and OpenCL graphs are in [`hwaccel-vulkan.md`](hwaccel-vulkan.md) and [`hwaccel-opencl-filters.md`](hwaccel-opencl-filters.md).

---

## Advanced Patterns

### Multi-Layer Composition

```bash
# Video with lower third, logo, and timecode
ffmpeg -i main.mp4 -i logo.png -i lower_third.png \
  -filter_complex "\
    [1:v]scale=150:-1[logo];\
    [2:v]scale=400:-1[third];\
    [0:v][logo]overlay=W-w-20:20[step1];\
    [step1][third]overlay=50:H-h-80:enable='between(t,5,55)'[step2];\
    [step2]drawtext=text='%{pts\\:hms}':\
      fontsize=32:fontcolor=white:\
      x=W-tw-20:y=H-th-20[out]" \
  -map "[out]" -map 0:a output.mp4
```

### Green Screen Pipeline (CPU)

```bash
# Key, despill-ish green reduction, composite, then grade the composite
ffmpeg -i greenscreen.mp4 -i background.mp4 \
  -filter_complex "\
    [0:v]chromakey=0x00FF00:0.2:0.1,\
         colorbalance=gs=-0.15:gm=-0.1:gh=-0.05,\
         eq=saturation=1.1[fg];\
    [1:v]scale=1920:1080[bg];\
    [bg][fg]overlay=format=auto,\
         eq=contrast=1.1:saturation=1.1,\
         colorbalance=rs=0.1:bs=-0.1:rh=0.05:bh=-0.08,\
         curves=all='0/0.02 0.5/0.5 1/0.98'[out]" \
  -map "[out]" -map 0:a? \
  -c:v libx264 -crf 18 -pix_fmt yuv420p output.mp4
```

Scale the foreground first if it is not already the background size. For the GPU version see `chromakey_cuda` in [`hwaccel-nvidia-nvenc.md`](hwaccel-nvidia-nvenc.md#gpu-chromakey-green-screen).

### Audio Visualization Overlay

```bash
# Waveform overlay on video
ffmpeg -i video.mp4 -i audio.mp3 \
  -filter_complex "\
    [1:a]showwaves=s=1920x200:mode=cline:colors=white@0.8[wave];\
    [0:v][wave]overlay=0:H-h-50[out]" \
  -map "[out]" -map 1:a output.mp4

# Spectrum analyzer
ffmpeg -i video.mp4 \
  -filter_complex "\
    [0:a]showspectrum=s=1920x200:legend=0:color=rainbow:fps=30[spec];\
    [0:v][spec]overlay=0:H-h[out]" \
  -map "[out]" -map 0:a output.mp4
```

### Time-Based Effects

```bash
# Different effects at different times
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split=3[v1][v2][v3];\
    [v1]trim=0:5,setpts=PTS-STARTPTS[part1];\
    [v2]trim=5:10,setpts=PTS-STARTPTS,eq=brightness=0.2:saturation=2.0[part2];\
    [v3]trim=10,setpts=PTS-STARTPTS[part3];\
    [part1][part2][part3]concat=n=3:v=1:a=0[out]" \
  -map "[out]" -map 0:a output.mp4

# Glitch bursts: a motion-interpolated copy flashes in for 0.3 s every 4 s,
# plus an RGB split for 0.15 s every second (minterpolate has no timeline
# support, so it runs on a split branch and overlay's enable= gates it)
ffmpeg -i music_video.mp4 \
  -filter_complex "\
    [0:v]split[base][m];\
    [m]fps=10,minterpolate='fps=30:mi_mode=mci:mc_mode=aobmc:scd=none'[mosh];\
    [base][mosh]overlay=enable='lt(mod(t,4),0.3)',\
    rgbashift=rh=3:bh=-3:enable='lt(mod(t,1),0.15)'[out]" \
  -map "[out]" -map 0:a -pix_fmt yuv420p output.mp4
```

The `fps=30` in `minterpolate` assumes a 30 fps source; set it to the source rate.

---

## Debugging Filtergraphs

### Verbose Logging

```bash
# Enable debug logging
ffmpeg -loglevel debug -i input.mp4 -filter_complex "..." output.mp4

# Load a long filtergraph from a file (FFmpeg 7+: "-/option file" reads the
# option value from the file; replaces the deprecated -filter_complex_script)
ffmpeg -i input.mp4 -/filter_complex graph.txt -map "[out]" output.mp4

# Show how the graph was built, including auto-inserted conversions
ffmpeg -v verbose -i input.mp4 -filter_complex "..." -f null - 2>&1 | grep -iE 'Parsed_|auto_scale|auto_aresample'
```

### Validate Filtergraph

```bash
# Test filtergraph without encoding (null output)
ffmpeg -i input.mp4 -filter_complex "..." -f null -

# Check specific filter options
ffmpeg -h filter=overlay
ffmpeg -h filter=xfade
ffmpeg -h filter=amix
```

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Filter 'split' has output 1 (b) unconnected` | A filter output is neither mapped nor fed to another filter | Add `-map "[b]"`, connect it, or reduce `split=N` |
| `Stream specifier ':v' in filtergraph description ... matches no streams.` | The input has no stream of that type/index | Probe the input; fix `[N:v]`/`[N:a]` or add `?` to optional `-map`s |
| `No such filter: 'foo'` | Typo, or filter not compiled into this build | Check `ffmpeg -filters` |
| `Impossible to convert between the formats supported by the filter ...` | GPU frames fed to a CPU filter (or the reverse), or incompatible formats on a two-input filter | Add `hwdownload,format=...` / `hwupload`, or a `format=` before the filter |
| `Too many packets buffered for output stream` | One output stream waits on a slow filter branch | Add `-max_muxing_queue_size 1024` (output option) |

### Performance Tips

1. **Reduce work early** - Put `crop`, downscaling `scale`, `fps` and `trim` before expensive filters (denoise, minterpolate, overlays)
2. **Use GPU filters** when available (scale_cuda, overlay_cuda)
3. **Avoid unnecessary format conversions** - Keep the same pixel format through the chain
4. **Decode once, `split` for multiple outputs** - One graph with `split` beats several ffmpeg runs on the same input
5. **Buffering** - With several inputs, raise the demuxer queue with `-thread_queue_size 512` before each `-i`; for "Too many packets buffered" raise `-max_muxing_queue_size 1024` (this uses more memory, not less)

```bash
ffmpeg -thread_queue_size 512 -i input1.mp4 \
       -thread_queue_size 512 -i input2.mp4 \
  -filter_complex "[0:v][1:v]overlay" -max_muxing_queue_size 1024 output.mp4
```

---

## Best Practices

1. **Use meaningful labels** - `[scaled]` not `[v1]` for clarity
2. **Test on short clips** - Use `-t 5` to test first 5 seconds
3. **Check all streams** - Verify audio mapping with `-map`
4. **Normalize inputs** - Match fps, resolution before concat/transitions
5. **Quote the filtergraph** - Use double quotes around entire -filter_complex
6. **Handle audio separately** - Video and audio often need different processing

This file covers filter_complex patterns. For hardware acceleration details, see `hwaccel.md`. For basic filter syntax, see `fundamentals.md`.
