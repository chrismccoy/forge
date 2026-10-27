# FFmpeg Forge

The files named below live in `${CLAUDE_PLUGIN_ROOT}/lib/ffmpeg-forge/`.

Complete FFmpeg toolkit: encoding, filtergraphs, audio, subtitles, analysis, restoration, hardware acceleration, and creative effects. This file holds the core rules and a routing table. Details live in `references/`, and runnable helpers in `scripts/`.

**Version coverage:** Content targets FFmpeg 7.1 LTS and 8.x. As of 2026-10 the latest stable release is 9.0.2. 9.0-specific features are not documented here. Run `ffmpeg -version` first. Confirm uncertain filter or encoder options with `ffmpeg -h filter=NAME` or `ffmpeg -h encoder=NAME` on the installed build.

## Core Workflow

1. **Intent.** Decide the job: transcode, remux, stream, analyze, caption, composite, restore, or apply an effect.
2. **Probe the input.** `ffprobe -v error -show_format -show_streams -of json INPUT`. Note codec, container, resolution, frame rate, pixel format, color space, field order, and audio channel layout.
3. **Remux or transcode.** Use `-c copy` when only the container changes or when trimming at keyframes. Re-encode only what needs to change (e.g. `-c:v libx264 -c:a copy`).
4. **Check capabilities.** Before using an encoder, filter, or hwaccel, confirm it exists: `ffmpeg -hide_banner -encoders | grep NAME`, `-filters`, `-hwaccels`. `scripts/check-codecs.sh` audits the whole build.
5. **Build the command.** Place every option correctly (see rules below) and give explicit codecs and quality settings.
6. **Test on a short slice first.** Example: `-ss 60 -t 10` before `-i`.
7. **Verify the output.** Re-probe it. Check duration, A/V sync, and pixel format. Use PSNR/SSIM/VMAF when quality matters.

## Non-Negotiable Rules

**Option position.** Options apply to the *next* file named after them and reset between files.

```bash
ffmpeg [global] {[input opts] -i input}... {[output opts] output}...
```

- Global options go first: `-y`, `-n`, `-hide_banner`, `-v`, `-init_hw_device`, `-filter_complex`.
- Input options go directly before their `-i`: `-re`, `-stream_loop`, `-hwaccel`, `-hwaccel_output_format`, `-itsoffset`. `-ss`, `-t`, and `-to` work in either position, with different meaning.
- Output options go after all inputs and before their output file: `-c:v`, `-crf`, `-preset`, `-vf`, `-af`, `-map`, `-movflags`, `-shortest`.

**Seeking.** `-ss` before `-i` seeks the input. It is fast and, when re-encoding, frame-accurate. `-ss` after `-i` decodes and discards frames up to that point, which is slow. With `-c copy`, put `-ss` before `-i`: the cut starts at the keyframe before the requested time. `-ss` after `-i` with copy drops video up to the next keyframe, so the video starts late (blank or frozen at the start).

**Stream selection.** Once any `-map` is given, automatic stream selection stops. Map every stream wanted, e.g. `-map 0:v:0 -map 0:a?`. A trailing `?` makes the map optional.

**`-vf` vs `-filter_complex`.** Use `-vf`/`-af` for one input and one output chain. Use `-filter_complex` with named labels (`[0:v][1:v]overlay[v]`) and `-map "[v]"` for multiple inputs or outputs.

**Delivery defaults.**
- Web MP4: add `-movflags +faststart` and `-pix_fmt yuv420p`.
- HEVC for Apple devices: add `-tag:v hvc1`.
- Odd dimensions break 4:2:0 encoders. Scale with `scale=-2:720`, not `-1`.
- Color: keep source color metadata. To set or fix tags when re-encoding, use `-vf setparams=color_primaries=bt709:color_trc=bt709:colorspace=bt709` (FFmpeg 8.x overwrites the output options `-color_primaries`/`-color_trc` with the frame's values). With `-c copy`, use `-bsf:v h264_metadata` or `hevc_metadata`.

**GPU pipelines.**
- Keep frames on the GPU with `-hwaccel X -hwaccel_output_format X`. Omitting `-hwaccel_output_format` can halve throughput.
- Before any CPU filter, add `hwdownload,format=nv12` for 8-bit sources or `hwdownload,format=p010le` for 10-bit/HDR. The format must match the surface's sw_format.
- Before GPU filters on CPU frames, add `format=nv12,hwupload`. This needs a filter device: `-init_hw_device cuda=gpu -filter_hw_device gpu` (or `hwupload_cuda`). See `command-syntax-hardware-device-init.md`.
- A CPU filter cannot read GPU frames directly.

**Safety.**
- Never overwrite a user's input file. FFmpeg cannot read and write the same file.
- Use `-n` or ask before `-y` when the output path already exists.

## Quality Quick Reference

| Encoder | Quality knob | Sensible default | Notes |
|---|---|---|---|
| `libx264` | `-crf` 0–51 (8-bit) | `-crf 20-23 -preset medium/slow` | Most compatible |
| `libx265` | `-crf` | `-crf 24-28 -preset medium` | ~same quality as x264 at ~half the bitrate; `-tag:v hvc1` |
| `libsvtav1` | `-crf` 0–63 | `-crf 30-35 -preset 6-8` | Fast AV1; `-g` ~ 10s of frames |
| `libaom-av1` | `-crf` + `-b:v 0` | `-crf 30 -b:v 0 -cpu-used 4` | Slow, efficient |
| `libvpx-vp9` | `-crf` + `-b:v 0` | `-crf 31 -b:v 0 -row-mt 1` | WebM |
| `*_nvenc` | `-cq` / `-rc vbr` | `-preset p5 -tune hq -rc vbr -cq 23 -b:v 0` | `hwaccel-nvidia-nvenc.md` |
| `*_qsv` | `-global_quality` | `-global_quality 23` (+ `-look_ahead 1` on `h264_qsv`) | `hwaccel-intel-qsv.md` |
| `*_vaapi` | `-qp` / `-rc_mode` | `-rc_mode CQP -qp 23` | `hwaccel-amd-amf-vaapi-videotoolbox.md` |
| `aac` | `-b:a` | `-b:a 160k` (stereo) | `libfdk_aac` is higher quality if built |
| `libopus` | `-b:a` | `-b:a 96k-128k` | Best lossy audio |

Prefer CRF/CQ for files and capped VBR (`-maxrate`/`-bufsize`) for streaming. Use two-pass only for a hard size target.

## Routing Table

Load only the reference files the task needs. `workflow-*.md` files are step-by-step procedures (probe, ask, build, verify). Topic files hold recipes and parameter tables. Topic files such as `karaoke-text.md` and `animation-timing.md` list their own sub-references. Combine them for tasks that span topics. Example: "burn Whisper captions on a CUDA 4K encode" uses `captions.md`, `hwaccel.md`, and `filter-complex.md`.

### Core encoding and syntax

| Task | Read |
|---|---|
| Codec/container choice, basic recipes, probing, best practices | `references/fundamentals.md` |
| Convert, scale, trim, concat, image ops, device-targeted output | `references/fundamentals-common-operations.md` |
| `-vf`/`-af` basics; fps, setpts, select, thumbnails, tile, reverse, loop | `references/fundamentals-filter-essentials.md`, `references/fundamentals-frame-manipulation.md` |
| Release features, 7.1 vs 8.0 differences | `references/fundamentals-version-history.md` |
| VVC/H.266; Vulkan codecs (FFv1 compute encode; H.264/HEVC/AV1 via Vulkan Video) | `references/fundamentals-vvc-h266-encoding.md`, `references/fundamentals-vulkan-compute-codecs.md` |
| Option placement, input vs output options | `references/command-syntax.md` |
| Full option catalog; stream specifiers | `references/command-syntax-complete-option-reference.md`, `references/command-syntax-stream-specifiers.md` |
| HLS/DASH/segment/RTMP/movflags/MPEG-TS muxer options | `references/command-syntax-format-specific-options.md` |
| Timestamps, bitstream filters, metadata, disposition, attachments | `references/command-syntax-timestamps-bitstream-metadata.md` |
| Step-by-step transcode procedure | `references/workflow-transcode.md` |
| Errors, corrupt files, sync problems, failed encodes | `references/workflow-debug.md` |

### Filtergraphs and hardware

| Task | Read |
|---|---|
| `filter_complex`: PiP, grids, overlays, split, amix, ABR ladders | `references/filter-complex.md` |
| Hardware acceleration overview and platform choice | `references/hwaccel.md` |
| NVENC/NVDEC/CUDA filters | `references/hwaccel-nvidia-nvenc.md` |
| Intel QSV | `references/hwaccel-intel-qsv.md` |
| AMD AMF, VAAPI, VideoToolbox | `references/hwaccel-amd-amf-vaapi-videotoolbox.md` |
| Vulkan filters and codecs; OpenCL filters | `references/hwaccel-vulkan.md`, `references/hwaccel-opencl-filters.md` |
| hwupload/hwdownload, GPU memory, Docker GPU, troubleshooting | `references/hwaccel-gpu-memory-and-troubleshooting.md` |
| `-init_hw_device` syntax per backend | `references/command-syntax-hardware-device-init.md` |
| Long-form GPU + filter_complex research notes | `references/research-gpu-filter-complex.md` |

### Audio, subtitles, analysis, restoration

| Task | Read |
|---|---|
| Audio codecs, loudnorm (EBU R128), EQ, compression, channels, resampling | `references/audio.md` |
| Podcast/music/broadcast chains; audio troubleshooting | `references/audio-workflows-and-troubleshooting.md`, `references/workflow-audio.md` |
| Audio measurement: astats, ebur128, volumedetect, speechnorm | `references/audio-audio-analysis-measurement.md` |
| Burn/add/extract/convert subtitles, CEA-608, positioning | `references/captions.md` |
| drawtext overlays; Whisper subtitle generation | `references/captions-drawtext-and-whisper.md`, `references/fundamentals-whisper-transcription.md` |
| QC: black/freeze/blur/scene detect, cropdetect, PSNR/SSIM/VMAF, signalstats | `references/analysis.md` |
| Batch QC scripts and CI checks | `references/analysis-automation-patterns.md` |
| Denoise video (nlmeans, hqdn3d) or audio (afftdn) | `references/denoise.md` |
| Deinterlace, inverse telecine, field order | `references/deinterlace.md` |
| Stabilization (vidstab, deshake), v360, lens correction, zoompan | `references/stabilization-360.md` |

### Creative effects

| Task | Read |
|---|---|
| xfade transitions, fades, wipes, slideshows | `references/transitions.md` |
| Chromakey, LUTs, curves, color balance, HDR tonemap | `references/color-chromakey.md`, `references/workflow-color.md` |
| drawbox/drawgrid, shapes, watermarks, lower thirds, blend modes | `references/shapes-graphics.md` |
| Glitch, datamosh, VHS, chromatic aberration, trails, displacement | `references/glitch.md`, `references/workflow-effects.md` |
| ASS karaoke, scrolling credits, typewriter, animated drawtext | `references/karaoke-text.md` (+ `karaoke-text-*.md`) |
| Kinetic/viral captions: word-pop, word-grow, bounce, TikTok styles | `references/kinetic-captions.md`, `references/kinetic-captions-complete-generator.md`, `references/workflow-kinetic.md` |
| Waveforms, spectrum, showcqt, music/podcast visualizers | `references/waveforms.md` |
| Animation durations, easing, springs, caption readability, platform timing | `references/animation-timing.md` (+ `animation-timing-*.md`) |

For big reference files, grep the section instead of reading the whole file:

```bash
grep -n '^## ' references/hwaccel-nvidia-nvenc.md
```

## Scripts

Every script is a standalone bash file. Most print usage when run with no arguments. `check-codecs.sh` takes no arguments, and `benchmark-encoding.sh` generates a test source when given none.

| Script | Purpose |
|---|---|
| `scripts/analyze-video.sh <file>` | Probe a file and print encoding recommendations |
| `scripts/check-codecs.sh` | Audit the build's encoders, decoders, filters, muxers, and hwaccels |
| `scripts/benchmark-encoding.sh [file] [seconds]` | Compare encoder and preset speed and size on a slice (default 10 s) |
| `scripts/generate-whisper-subtitles.sh <video> [model] [language]` | Generate subtitles with the 8.0+ `whisper` filter |
| `scripts/apply-color-grade.sh <preset> <in> <out> [1-10]` | Presets: cinematic, vintage, noir, warm, cool, bleach, instagram, matrix |
| `scripts/apply-glitch-effects.sh <effect> <in> <out> [1-10]` | Effects: datamosh, vhs, chromatic, trails, wave, pixelate, combined |
| `scripts/generate-karaoke.sh <action> [options]` | Actions: create, apply, template, kinetic (ASS karaoke and kinetic captions) |

Reference scripts by absolute path when running them from the user's working directory.

## Anti-Patterns

- Adding a CPU `scale` after `hwupload`, or a GPU filter on CPU frames, without the matching `hwdownload`/`hwupload`.
- Re-encoding when `-c copy` would do. Re-encoding audio that already matches the target.
- Using `-ss` after `-i` on long files when input seeking would work.
- Combining `-crf` with a nonzero `-b:v` on `libaom-av1`/`libvpx-vp9`. That turns CRF into constrained quality capped at that bitrate. On FFmpeg 8.x `-crf` alone already gives constant quality; `-b:v 0` makes it explicit and is needed on older builds.
- Leaving out `-movflags +faststart` on web MP4s, or `-pix_fmt yuv420p` when the source is 10-bit or 4:4:4 and the target player is not.
- Running single-pass `loudnorm` for deliverables. Use two-pass with measured values (`audio.md`).
- Dropping or mislabeling color metadata, e.g. tagging a BT.2020 PQ source as BT.709.
- Using `-shortest` with filters that buffer, without checking the resulting duration.
- Animating `drawtext` `fontsize` with a time expression. It segfaults on some FFmpeg 8.0.1 builds (seen on Ubuntu's). Animate size with ASS `\t(\fscx…)` tags instead, or scale a fixed-size text layer.
- Passing expressions to options that take plain numbers (`rgbashift`, `blurdetect` thresholds are 0–1). Check `ffmpeg -h filter=NAME` for the type. Use `sendcmd` or `blend` with `T` to animate.
- Using `enable=` on `minterpolate` (no timeline support). Run it on a `split` branch and `overlay=enable=...` instead.
- Writing a filter's own output with a muxer: `whisper` writes via `destination=`, so the ffmpeg output is `-f null -`.
- Trusting ffmpeg's exit code alone: it exits 0 when it declines to overwrite, and on many decode errors. Check that the output exists, and check stderr for errors.
- Quoting file paths inside filter options. FFmpeg unescapes option values twice (option level, then graph level), so FFmpeg must receive `:` as `\\:` and `'` as `\\\'`. Inside single shell quotes, type exactly that: `-vf 'subtitles=./a\\:b.srt'`. Inside double quotes the shell eats one level, so type `\\\\:`. Prefix a relative path that contains `:` with `./`, or it is read as a protocol. In scripts, use the `filter_escape` function from `scripts/generate-karaoke.sh`. Windows `cmd` quoting differs.
- Letting a filter change the pixel format of a deliverable. Color filters (`curves`, `colorbalance`, `rgbashift`, `lut3d`), `xfade`, colored `fade`, audio visualizers (`showwaves`, `showspectrum`, ...), `zoompan` on images, and `fieldorder` can output RGB, 4:4:4 or 4:2:2. libx264 then writes High 4:4:4/4:2:2, which browsers and phones cannot play. End deliverable chains with `-pix_fmt yuv420p`. JPEG inputs give full-range `yuvj420p`; end those chains with `scale=out_range=tv,format=yuv420p`.

## Response Standards

- Show the full command with explicit `-c:v`, `-c:a`, quality settings, and container flags.
- Explain non-obvious flags in one line each.
- State codec and container compatibility limits for the target players.
- Before running a long encode, offer a short test slice first.
