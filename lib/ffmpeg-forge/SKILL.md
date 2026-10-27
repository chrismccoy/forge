# FFmpeg Forge

The files named below live in `${CLAUDE_PLUGIN_ROOT}/lib/ffmpeg-forge/`.

Complete FFmpeg toolkit: encoding, filtergraphs, audio, subtitles, streaming and capture, analysis, restoration, hardware acceleration, and creative effects. This file holds the core rules, the most common recipes, and a routing table. Details live in `references/`, and runnable helpers in `scripts/`.

**Version coverage:** Content targets FFmpeg 7.1 LTS and 8.0, verified on 8.0.1. Changes in 8.1 and later have not been reviewed; `references/fundamentals-version-history.md` lists the claims that depend on version. Run `ffmpeg -version` first. On any other build, confirm uncertain options with `ffmpeg -h filter=NAME` or `ffmpeg -h encoder=NAME`.

## Core Workflow

1. **Intent.** Decide the job: transcode, remux, stream, capture, analyze, caption, composite, restore, or apply an effect.
2. **Probe the input.** `ffprobe -v error -show_format -show_streams -of json INPUT`. Note codec, container, resolution, frame rate, pixel format, color space, field order, and audio channel layout.
3. **Remux or transcode.** Use `-c copy` when only the container changes or when trimming at keyframes. Re-encode only what needs to change (e.g. `-c:v libx264 -c:a copy`).
4. **Check capabilities.** Before using an encoder, filter, or hwaccel, confirm it exists: `ffmpeg -hide_banner -encoders | grep NAME`, `-filters`, `-hwaccels`. `scripts/check-codecs.sh` audits the whole build.
5. **Build the command.** Place every option correctly (see rules below) and give explicit codecs and quality settings.
6. **Test on a short slice first.** Example: `-ss 60 -t 10` before `-i`. Offer this before any long encode.
7. **Verify the output.** Re-probe it. Check duration, A/V sync, and pixel format. Use PSNR/SSIM/VMAF when quality matters.

## Non-Negotiable Rules

**Option position.** Options apply to the *next* file named after them and reset between files.

```bash
ffmpeg [global] {[input opts] -i input}... {[output opts] output}...
```

- Global options go first: `-y`, `-n`, `-hide_banner`, `-v`, `-init_hw_device`, `-filter_complex`.
- Input options go directly before their `-i`: `-re`, `-stream_loop`, `-hwaccel`, `-hwaccel_output_format`, `-itsoffset`. `-ss`, `-t`, and `-to` work in either position, with different meaning.
- Output options go after all inputs and before their output file: `-c:v`, `-crf`, `-preset`, `-vf`, `-af`, `-map`, `-movflags`, `-shortest`. Muxer options (`-hls_time`, `-movflags`) belong to one output; on the wrong output they are ignored without a warning.

**Seeking.** `-ss` before `-i` seeks the input. It is fast and, when re-encoding, frame-accurate. `-ss` after `-i` decodes and discards frames up to that point, which is slow. With `-c copy`, put `-ss` before `-i`: the cut starts at the keyframe before the requested time. `-ss` after `-i` with copy drops video up to the next keyframe, so the video starts late (blank or frozen at the start).

**Stream selection.** Once any `-map` is given, automatic stream selection stops. Map every stream wanted, e.g. `-map 0:v:0 -map 0:a?`. A trailing `?` makes the map optional. Without `-map`, ffmpeg picks one video and one audio stream: adding a second audio file keeps the first file's audio unless both are mapped, and remuxing a multi-track MKV drops the extra tracks unless `-map 0` is given.

**Timing filters change only their own stream.** `setpts`, `select`+`setpts`, `trim`, `tpad`, `loop` and `-itsscale:v` change video length or start time but leave audio untouched, so the streams drift apart. Drop the audio (`-an`) or apply the matching audio filter (`atempo`, `atrim`+`asetpts`, `adelay`). `reverse` keeps the length but needs `areverse` for the audio to match.

**`-vf` vs `-filter_complex`.** Use `-vf`/`-af` for one input and one output chain. Use `-filter_complex` with named labels (`[0:v][1:v]overlay[v]`) and `-map "[v]"` for multiple inputs or outputs. An overlay input that never ends (`-stream_loop -1`, `-loop 1`) needs `overlay=shortest=1` or `-t`, or the encode never stops.

**Delivery defaults.**
- Web MP4: add `-movflags +faststart` and `-pix_fmt yuv420p`. WebM/VP9 for browsers: `-pix_fmt yuv420p` too.
- HEVC for Apple devices: add `-tag:v hvc1` (MP4/MOV only).
- Odd dimensions break 4:2:0 encoders. Scale with `scale=-2:720`, not `-1`. Do not upscale smaller sources: `scale=-2:'min(720,ih)'`.
- Color: keep source color metadata. To set or fix tags when re-encoding, use `-vf setparams=color_primaries=bt709:color_trc=bt709:colorspace=bt709` (FFmpeg 8.x overwrites the output options `-color_primaries`/`-color_trc` with the frame's values). With `-c copy`, use `-bsf:v h264_metadata` or `hevc_metadata`.

**GPU pipelines.**
- Keep frames on the GPU with `-hwaccel X -hwaccel_output_format X`. Without `-hwaccel_output_format`, frames come back to system memory, which costs throughput and makes `*_vaapi`/`*_qsv` encoders fail ("Impossible to convert between the formats").
- Before any CPU filter, add `hwdownload,format=nv12` for 8-bit sources or `hwdownload,format=p010le` for 10-bit/HDR. The format must match the surface's sw_format, or the picture comes out green or garbled.
- Before GPU filters on CPU frames, add `format=nv12,hwupload`. This needs a filter device: `-init_hw_device cuda=gpu -filter_hw_device gpu`. `hwupload` honours `-filter_hw_device`; `hwupload_cuda` ignores it and takes `device=N`. See `references/hwaccel.md`.
- A CPU filter cannot read GPU frames directly.

**Safety.**
- Never overwrite a user's input file. FFmpeg cannot read and write the same file.
- Use `-n` or ask before `-y` when the output path already exists.

## Quality Quick Reference

| Encoder | Quality knob | Sensible default | Notes |
|---|---|---|---|
| `libx264` | `-crf` 0–51 (8-bit) | `-crf 20-23 -preset medium/slow` | Most compatible |
| `libx265` | `-crf` | `-crf 24-28 -preset medium` | ~25–50% smaller than x264 at similar quality; `-tag:v hvc1` |
| `libsvtav1` | `-crf` 0–63 | `-crf 30-35 -preset 6-8` | Fast AV1; `-g` ~ 10s of frames |
| `libaom-av1` | `-crf` + `-b:v 0` | `-crf 30 -b:v 0 -cpu-used 4` | Slow, efficient |
| `libvpx-vp9` | `-crf` + `-b:v 0` | `-crf 31 -b:v 0 -row-mt 1` | WebM. A nonzero `-b:v` turns CRF into a bitrate cap |
| `*_nvenc` | `-cq` / `-rc vbr` | `-preset p5 -tune hq -rc vbr -cq 23 -b:v 0` | p4 is the default preset; `hwaccel-nvidia-nvenc.md` |
| `*_qsv` | `-global_quality` | `-global_quality 23` (+ `-look_ahead 1` on `h264_qsv`) | `hwaccel-intel-qsv.md` |
| `*_vaapi` | `-qp` / `-rc_mode` | `-rc_mode CQP -qp 23` | `hwaccel-amd-amf-vaapi-videotoolbox.md` |
| `aac` | `-b:a` | `-b:a 160k` (stereo) | `libfdk_aac` is higher quality if built |
| `libopus` | `-b:a` | `-b:a 96k-128k` | Best lossy audio |

Prefer CRF/CQ for files and capped VBR (`-maxrate`/`-bufsize`) for streaming. Use two-pass only for a hard size target.

## Top Recipes

```bash
# Remux MKV to MP4 without re-encoding (text subs become mov_text;
# PGS/VobSub subs and font attachments do not fit MP4: add -sn or keep MKV)
ffmpeg -i in.mkv -map 0:v -map 0:a -map 0:s? -c copy -c:s mov_text -movflags +faststart out.mp4

# Extract audio: copy (AAC source into .m4a), or convert to MP3 (VBR ~190 kbps)
ffmpeg -i in.mp4 -vn -c:a copy out.m4a
ffmpeg -i in.mp4 -vn -c:a libmp3lame -q:a 2 out.mp3

# GIF with a generated palette
ffmpeg -i in.mp4 -vf "fps=15,scale=480:-2:flags=lanczos,split[a][b];[a]palettegen[p];[b][p]paletteuse" out.gif

# Burn SRT subtitles (escape : and ' in the path; see Anti-Patterns)
ffmpeg -i in.mp4 -vf "subtitles=subs.srt" -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a copy out.mp4
```

- **Fit a size limit** (Discord, email): run `scripts/encode-to-size.sh in.mp4 out.mp4 <MB>`. It computes the bitrate, encodes two-pass and checks the result. If the user gives no limit, state the assumed limit and proceed; platform limits change, so do not present one as fact.
- **Loudness for a deliverable:** `scripts/loudnorm-2pass.sh in out [I] [TP] [LRA]`.

## Routing Table

Load only the reference files the task needs, and combine them for tasks that span topics. Example: "burn Whisper captions on a CUDA 4K encode" uses `whisper.md`, `captions.md`, and `hwaccel-nvidia-nvenc.md`. For big files, list the sections first: `grep -n '^## ' references/FILE.md`.

### Core encoding, syntax and delivery

| Task | Read |
|---|---|
| Codec/container choice, probing, exit codes | `references/fundamentals.md` |
| Transcode procedure, CRF/preset tables, convert, scale, trim, concat, target size, ProRes/DNxHR, image ops, device presets | `references/fundamentals-common-operations.md` |
| `-vf`/`-af` basics; crop, rotate/transpose/flip, speed (setpts+atempo), fps, select, thumbnails, tile, reverse, loop, freeze | `references/filters-basics.md` |
| Option placement, input vs output options, stream specifiers | `references/command-syntax.md` |
| Full option catalog | `references/command-syntax-complete-option-reference.md` |
| Timestamps, bitstream filters, metadata, chapters, disposition, attachments | `references/command-syntax-timestamps-bitstream-metadata.md` |
| HLS/DASH (ABR ladders), RTMP/SRT push, WHIP, receiving streams, segment/movflags/MPEG-TS options | `references/streaming.md` |
| Screen, webcam and audio capture, raw video input, testing a push without a server | `references/capture.md` |
| Errors and symptoms: won't play on phone/browser/smart TV, green GPU output, A/V drift, "Unknown encoder", corrupt files, failed encodes | `references/troubleshooting.md` |
| VVC/H.266 encoding and decoding | `references/fundamentals-vvc-h266-encoding.md` |
| Release features, version-sensitive claims | `references/fundamentals-version-history.md` |

### Filtergraphs and hardware

| Task | Read |
|---|---|
| `filter_complex`: PiP, grids, overlays, split to multiple outputs, amix, filtergraph errors | `references/filter-complex.md` |
| Hardware acceleration overview, platform choice, cross-vendor filter map, `-init_hw_device` syntax, Docker | `references/hwaccel.md` |
| NVENC/NVDEC/CUDA filters | `references/hwaccel-nvidia-nvenc.md` |
| Intel QSV | `references/hwaccel-intel-qsv.md` |
| AMD AMF, VAAPI, VideoToolbox | `references/hwaccel-amd-amf-vaapi-videotoolbox.md` |
| Vulkan encode/decode pipelines and filters | `references/hwaccel-vulkan.md` |
| Vulkan version support, FFv1 compute codec, ProRes RAW, device selection | `references/fundamentals-vulkan-compute-codecs.md` |
| OpenCL filters | `references/hwaccel-opencl-filters.md` |
| GPU memory, hwupload/hwdownload, driver and device errors | `references/hwaccel-gpu-memory-and-troubleshooting.md` |

### Audio, subtitles, analysis, restoration

| Task | Read |
|---|---|
| Audio codecs, two-pass loudnorm, EQ, compression, channels, resampling | `references/audio.md` |
| Podcast/music/broadcast chains, speechnorm, dialogue enhance, binaural (sofalizer) | `references/audio-chains.md` |
| Audio measurement: astats, ebur128, volumedetect, silence, fingerprints | `references/audio-measurement.md` |
| Burn/add/extract/convert subtitles, CEA-608, positioning, batch burn | `references/captions.md` |
| Whisper speech-to-text subtitles (8.0+) | `references/whisper.md` |
| QC: black/freeze/blur/scene detect, cropdetect, PSNR/SSIM/VMAF, signalstats, batch QC | `references/analysis.md` |
| Denoise video (nlmeans, hqdn3d) or audio (afftdn, anlmdn) | `references/denoise.md` |
| Deinterlace, inverse telecine, field order | `references/deinterlace.md` |
| Stabilization (vidstab, deshake), v360, lens correction, zoompan (Ken Burns, timing, hook zooms) | `references/stabilization-360.md` |

### Text and creative effects

| Task | Read |
|---|---|
| drawtext overlays: fonts, escaping, boxes, timecode, clock, frame metadata | `references/drawtext.md` |
| Animated drawtext: fades, motion, typewriter, credits, tickers, countdowns, size via a scaled layer | `references/drawtext-animation.md` |
| ASS karaoke (`\k`/`\kf`/`\ko`), karaoke styles, tempo timing | `references/karaoke-text.md` |
| Kinetic/viral captions (word-pop, grow, bounce, elastic; TikTok/Shorts/Reels), caption generators | `references/kinetic-captions.md` |
| Timing units, durations, caption readability, platform timing, sync tolerances | `references/animation-timing.md` |
| Easing curves, spring physics, oscillation formulas | `references/easing-and-springs.md` |
| xfade transitions, fades, wipes, slideshows | `references/transitions.md` |
| Chromakey, LUTs, curves, color balance, HDR tonemap (workflow included) | `references/color-chromakey.md` |
| Glitch, datamosh, VHS, chromatic aberration, trails, displacement (workflow included) | `references/glitch.md` |
| Watermarks and logos, drawbox/drawgrid, shapes, progress bars, blend modes, masks | `references/shapes-graphics.md` |
| Waveforms, spectrum, showcqt, music/podcast visualizers | `references/waveforms.md` |

## Scripts

The bash helpers share `scripts/lib/filter-escape.sh` and need bash 4.3+ (macOS: Homebrew bash); `kinetic_captions.py` needs Python 3. All refuse to overwrite outputs and print usage with no arguments or `-h`. `check-codecs.sh` takes no arguments, and `benchmark-encoding.sh` generates a test source when given none. Run them by absolute path, using the skill's base directory shown when the skill loads.

| Script | Purpose |
|---|---|
| `scripts/analyze-video.sh <file>` | Probe a file and print recommendations (remux when already compatible, deinterlace when interlaced) |
| `scripts/check-codecs.sh` | Audit the build's encoders, decoders, filters, muxers, protocols, and hwaccels |
| `scripts/benchmark-encoding.sh [file] [seconds]` | Compare encoder and preset speed and size on a slice (default 10 s) |
| `scripts/encode-to-size.sh <in> <out> <MB> [x264\|x265] [audio_kbps]` | Two-pass encode to a target file size |
| `scripts/loudnorm-2pass.sh [opts] <in> <out> [I] [TP] [LRA] [-- ffmpeg opts]` | Two-pass EBU R128 loudness normalization, verified with ebur128 |
| `scripts/generate-whisper-subtitles.sh <video> [model] [language]` | Generate subtitles with the 8.0+ `whisper` filter; writes `<name>.srt`/`.vtt` to the current directory |
| `scripts/apply-color-grade.sh <preset> <in> <out> [1-10]` | Presets: cinematic, vintage, noir, warm, cool, bleach, instagram, matrix |
| `scripts/apply-glitch-effects.sh <effect> <in> <out> [1-10]` | Effects: datamosh, vhs, chromatic, trails, wave, pixelate, combined |
| `scripts/generate-karaoke.sh <action> [options]` | Actions: create, apply, template, kinetic (ASS karaoke and kinetic captions; `--res WxH`/`--video FILE` set the canvas) |
| `python3 scripts/kinetic_captions.py <transcript.json> <out.ass> [style] [platform]` | Kinetic ASS captions from word-level timestamps |
| `scripts/slideshow.sh [--dur S] [--trans S] [--fps N] [--size WxH] <out.mp4> <transition\|cycle> <img>...` | xfade slideshow from N images |

## Anti-Patterns

- Running single-pass `loudnorm` for deliverables. Use two-pass (`scripts/loudnorm-2pass.sh`). Measure with `ebur128`: after a compressor, loudnorm's own pass-1 `input_i` can be ~2 LU off. Keep the LRA target at or above the input LRA, or loudnorm silently switches to dynamic mode and misses the target.
- Using `-shortest` with filters that buffer, without checking the resulting duration.
- Animating `drawtext` `fontsize` per frame (`t`, `n`, ...): segfaults on 8.0.1. Use ASS `\t(\fscx\fscy)` or a scaled text layer (`drawtext-animation.md`).
- Running `blend` modes (screen, multiply, overlay, softlight, addition) or `displace` on YUV frames. They work per plane, so chroma gets blended too and the picture turns magenta or green. Convert every input with `format=gbrp` first, and add `format=yuv420p` after.
- Encoding `chromakey`/`colorkey` output straight to yuv420p H.264. The alpha is dropped and nothing looks keyed. Overlay the result on a background, or write an alpha format (VP9 `yuva420p`, ProRes 4444, PNG).
- Using a still image as the main input of `overlay`. Its frame rate (25 fps for a JPEG) becomes the output rate. Use `-loop 1 -framerate <fps>` and `overlay=shortest=1`.
- Trusting ffmpeg's exit code alone. It exits 0 when `-n` declines to overwrite, and on many decode errors. Check whether the output existed beforehand, check that it exists and is non-empty afterwards, and check stderr for errors.
- Passing unescaped paths to filter options. FFmpeg unescapes option values twice (option level, then graph level), so FFmpeg must receive `:` as `\\:` and `'` as `\\\'`. Inside single shell quotes, type exactly that: `-vf 'subtitles=./a\\:b.srt'`. Inside double quotes the shell eats one level, so type `\\\\:`. Prefix a relative path that contains `:` with `./`, or it is read as a protocol. In scripts, source `scripts/lib/filter-escape.sh` and use `filter_escape` (handles `\ ' : = , ; [ ]` and spaces). Windows `cmd` quoting differs.
- Letting a filter change the pixel format of a deliverable. Color filters (`curves`, `colorbalance`, `rgbashift`, `lut3d`, `despill`), `xfade`, colored `fade`, audio visualizers (`showwaves`, `showspectrum`, ...), `zoompan` on images, and `fieldorder` can output RGB, 4:4:4 or 4:2:2. libx264 then writes High 4:4:4/4:2:2, which browsers and phones cannot play. End deliverable chains with `-pix_fmt yuv420p`. JPEG inputs give full-range `yuvj420p`; end those chains with `scale=out_range=tv,format=yuv420p`.

## Response Standards

- Show the full command with explicit `-c:v`, `-c:a`, quality settings, and container flags.
- Explain non-obvious flags in one line each.
- State codec and container compatibility limits for the target players.
- For long encodes, offer a short test slice first (Core Workflow step 6).
