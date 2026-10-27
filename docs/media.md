# Media

[← Back to the README](../README.md)

## `ffmpeg-forge`

FFmpeg and ffprobe work for FFmpeg 7.1 LTS and 8.x: encoding and codec choice, trimming and concatenation, filtergraphs, audio and loudness, subtitles and captions, quality control, restoration, hardware acceleration, and creative effects from transitions and color grades to glitch art, karaoke, and kinetic captions.

```
/ffmpeg-forge
```

It writes FFmpeg commands that work the first time and produce files that play everywhere. Before it answers, it probes the input with `ffprobe` (codecs, resolution, frame rate, pixel format, color tags, audio layout) and checks what your build supports, so it does not suggest an encoder, filter, or GPU path you do not have. `SKILL.md` holds the core rules and a routing table, and Claude loads only the reference file the task needs.

The rules come from testing, not only from the manual. Deliverables end in `yuv420p` so browsers and phones can play them, color tags are set in a way FFmpeg 8 actually keeps, loudness targets use two-pass `loudnorm`, filter paths are escaped at both levels, and seeking uses the fast, accurate option position. Commands are checked against the output they produce, not just their exit code.

**Targets:** FFmpeg 7.1 LTS and 8.0, verified on 8.0.1. Changes in 8.1 and later have not been reviewed.

**Requirements:**

- `ffmpeg` and `ffprobe` on `PATH` (`ffmpeg -version`).
- Bash 4.3+ for the helper scripts. On macOS, install a newer bash (e.g. Homebrew), since `/bin/bash` there is 3.2.
- `bc` for `analyze-video.sh`, `benchmark-encoding.sh`, `apply-color-grade.sh` and the glitch `trails` effect (`bc` is missing on some minimal systems).
- Python 3, only for `scripts/kinetic_captions.py`.
- Optional features depend on how your FFmpeg was built. Run `scripts/check-codecs.sh` to see what yours has:
  - `whisper` filter for speech-to-text subtitles (FFmpeg 8.0+ built with whisper.cpp)
  - `libvmaf` for VMAF scores, `libvvenc` for VVC/H.266 encoding
  - NVENC/CUDA, Quick Sync, VAAPI, AMF, VideoToolbox, or Vulkan, each with matching hardware and drivers

## Technical Overview

One slash command plus its procedure folder: one operating guide, 40 topic references, and 11 scripts.

```
lib/ffmpeg-forge/
├── SKILL.md                     # workflow, non-negotiable rules, quality table, routing table, anti-patterns
├── references/                  # loaded on demand through the routing table (40 files)
│   ├── fundamentals*.md         # codecs, common operations, version history, VVC, Vulkan compute codecs
│   ├── command-syntax*.md       # option order, every option, stream specifiers, timestamps, bitstream filters, metadata
│   ├── filters-basics.md, filter-complex.md   # single chains; multi-input graphs, PiP, grids, ABR ladders
│   ├── audio.md, audio-chains.md, audio-measurement.md   # codecs, loudness, EQ, dynamics, channels, measurement
│   ├── captions.md, whisper.md  # burn-in, soft subtitles, conversion, CEA-608/708, Whisper transcription
│   ├── drawtext.md, drawtext-animation.md     # text overlays, tickers, countdowns, credits
│   ├── analysis.md              # ffprobe, detection filters, PSNR/SSIM/VMAF, QC automation
│   ├── streaming.md, capture.md # HLS/DASH, RTMP/SRT push, WHIP; screen, webcam, and audio capture
│   ├── troubleshooting.md       # symptom table, common errors, smart-TV playback
│   ├── deinterlace.md, denoise.md, stabilization-360.md      # restoration, vidstab, v360, zoompan
│   ├── hwaccel*.md              # NVENC, Quick Sync, AMF/VAAPI/VideoToolbox, Vulkan, OpenCL, GPU memory
│   ├── transitions.md, color-chromakey.md, shapes-graphics.md, glitch.md, waveforms.md
│   └── karaoke-text.md, kinetic-captions.md, animation-timing.md, easing-and-springs.md   # animated text and timing
└── scripts/
    ├── check-codecs.sh                 # which encoders, decoders, filters, muxers, protocols and hwaccels your build has
    ├── analyze-video.sh                # probe a file and print encoding recommendations
    ├── benchmark-encoding.sh           # compare encoder and preset speed and file size
    ├── encode-to-size.sh               # two-pass encode to a target file size (upload limits)
    ├── loudnorm-2pass.sh               # two-pass EBU R128 loudness normalization, verified after encoding
    ├── apply-color-grade.sh            # 8 color-grade presets, intensity 1-10
    ├── apply-glitch-effects.sh         # 7 glitch effects, intensity 1-10
    ├── slideshow.sh                    # xfade slideshow from any number of images
    ├── generate-karaoke.sh             # karaoke and kinetic captions from timed lyrics, burned into video
    ├── kinetic_captions.py             # kinetic ASS captions from word-level timestamps
    ├── generate-whisper-subtitles.sh   # subtitles with the whisper filter, including model download
    └── lib/filter-escape.sh            # shared helpers: filter-path escaping, bash and bc checks, stream selection
```

`SKILL.md` holds the seven-step workflow, the most common recipes, the rules for option order, seeking, `-vf` versus `-filter_complex`, delivery defaults and GPU pipelines, the per-encoder quality table, the routing table, and the anti-patterns. The command pre-approves only `Read` and `ffprobe`, which reads files and never writes them. Every `ffmpeg` command and script asks for permission first.

The scripts refuse to overwrite an existing output, remove partial output when ffmpeg fails, skip cover-art streams, keep the source frame count and duration, and handle paths containing spaces, `:`, `'`, `,`, `;`, `[` and `]`. The bash scripts share `scripts/lib/filter-escape.sh`. Most print their usage when run with no arguments or `-h`. `check-codecs.sh` takes none, and `benchmark-encoding.sh` with none benchmarks a generated test clip.

## Features

### Encoding and conversion

- Codec choice for H.264, H.265/HEVC, H.266/VVC, AV1 (SVT-AV1, libaom), VP9, ProRes and DNxHR intermediates, and FFv1, with per-encoder quality defaults
- CRF/CQ, bitrate, two-pass target size (`encode-to-size.sh`), and capped VBR
- Remuxing without re-encoding, trimming, splitting, and concatenation, with fast versus frame-accurate seeking
- Scaling, cropping, rotation, padding, frame rate, speed changes, reverse, loop, and freeze frame
- Frames, thumbnails, contact sheets, and GIFs with palettes
- Web, iOS, Android, and smart-TV presets
- Streaming: HLS and DASH (including ABR ladders), RTMP/RTMPS and SRT push, receiving streams, segment output, and WHIP (WebRTC) on 8.0+ builds that include it
- Capture: screen (x11grab, kmsgrab, gdigrab, ddagrab, avfoundation), webcam (v4l2, dshow), and audio devices
- Color tags that FFmpeg 8 keeps (`setparams`, `h264_metadata`), chapters, attachments, and disposition flags

### Filtergraphs and hardware

- `filter_complex` with named labels: picture-in-picture, grids, overlays, watermarks, ABR ladders, and audio mixing
- NVIDIA NVENC/CUDA, Intel Quick Sync, AMD AMF, VAAPI, VideoToolbox, Vulkan Video, and OpenCL filters
- Full-GPU pipelines, `hwupload`/`hwdownload` rules, `-init_hw_device` for every backend, and Docker GPU containers

### Audio

- AAC, MP3, Opus, FLAC, Vorbis, and AC3/EAC3 extraction and conversion
- EBU R128 two-pass `loudnorm` helper, `dynaudnorm`, `speechnorm`, and peak and RMS normalization
- EQ, compression, limiting, de-essing, noise reduction, silence detection and removal, fades, and crossfades
- Mono, stereo, and 5.1 channel work, high-quality resampling, pitch shift, and binaural audio
- Podcast, music mastering, and broadcast chains

### Subtitles and captions

- Burn-in of SRT, Advanced SubStation Alpha (`.ass`), and WebVTT, with forced styling
- Soft subtitle tracks for MP4, MKV, and WebM with languages and default and forced flags; conversion between formats; CEA-608/708 extraction and passthrough (FFmpeg cannot author new 608/708 data)
- `drawtext` overlays, countdowns, tickers, and scrolling credits
- Whisper speech-to-text (FFmpeg 8.0+): models, languages, voice activity detection, and GPU

### Analysis and restoration

- `ffprobe` recipes, and detection of black or frozen frames, blur, crop borders, scene changes, and interlacing
- PSNR, SSIM, and VMAF, `signalstats`, and batch QC with CI-style thresholds
- Denoising, deinterlacing, inverse telecine, `vidstab` stabilization, 360/VR projections, and Ken Burns zoom and pan

### Creative effects

- `xfade` transitions (every built-in type plus custom expressions), luma-matte wipes, and slideshows
- LUTs, curves, color balance, looks (teal and orange, vintage, noir, bleach bypass), HDR tone mapping, and green screen
- Glitch art: datamosh, VHS, chromatic aberration, scan lines, pixelation, wave, and trails
- Karaoke with Advanced SubStation Alpha `\k`/`\kf`/`\ko` tags, and kinetic captions for TikTok, Shorts, and Reels
- Audio visualizers: `showwaves`, `showspectrum`, `showcqt`, `avectorscope`, and more
- Animation timing: easing and spring formulas, caption readability, platform pacing, and A/V sync tolerances

## How it works

1. **Intake.** Take the task from the arguments. With none, ask whether you want to convert or compress, edit, work on audio and subtitles, or apply effects and analysis, then ask for the input file.
2. **Probe.** Run `ffprobe` on the input for codec, container, resolution, frame rate, pixel format, color space, field order, and channel layout.
3. **Remux or transcode.** Use `-c copy` when only the container changes, and re-encode only the streams that must change.
4. **Check capabilities.** Confirm the encoder, filter, or hwaccel exists in the installed build before using it.
5. **Build the command.** Put each option in the right position, load the reference for the task, and set explicit codecs and quality.
6. **Test a short slice.** Run the command on a few seconds of input before the full file.
7. **Verify.** Re-probe the output for duration, A/V sync, and pixel format, and use PSNR, SSIM, or VMAF when quality matters.

## How to use it

```
/ffmpeg-forge                                          ← asks what you want to do
/ffmpeg-forge compress input.mov for the web           ← H.264 MP4 with faststart and yuv420p
/ffmpeg-forge make a GIF from 0:12 to 0:18 of clip.mp4 ← palette-based GIF
/ffmpeg-forge normalize podcast.wav to -16 LUFS        ← two-pass loudnorm
/ffmpeg-forge burn subs.srt into video.mp4             ← subtitles filter with escaped paths
/ffmpeg-forge why does this fail: <command>            ← diagnosis and a fixed command
```

**Typical asks:** *"convert this to MP4"*, *"trim the first 10 seconds"*, *"speed this up 2x"*, *"make a picture-in-picture"*, *"create HLS for this video"*, *"add a crossfade between these clips"*, *"generate subtitles with Whisper"*, *"use NVENC"*, *"make karaoke captions"*, *"fix this ffmpeg error"*

## Testing

Tested on Ubuntu with FFmpeg 8.0.1 on CPU, plus Vulkan compute on an Intel iGPU:

- **Scripts:** every glitch effect and color grade at intensity 1, 5, and 10 on `.mp4`, `.ts`, raw `.h264` and `.hevc` (24, 25, 30, and 60 fps), rotated, odd-size (321x241), audio-only, cover-art, and truncated input, with frame counts, durations, and `yuv420p` output checked. Every karaoke mode, including LRC input, CRLF files, and text containing `{}` and `\N`, with colors checked on rendered frames.
- **References:** six independent review passes. The largest ran 1,410 command invocations from the reference files. Each confirmed error was fixed and re-run, including commands that exited 0 but gave wrong results (pixel format, color tags and range, duration, frame rate, sample rate, aspect ratio), checked by probing the output and sampling pixels.
- **2026-10-27 review:** seven reviewers ran about 1,230 commands from the references and scripts. About 100 broken recipes and 36 failing script cases were fixed and re-run, including silent failures: `blend`/`tblend`/`displace` on YUV tinting the frame, chromakey output losing alpha, video-only timing filters desyncing audio, unclamped easing, and wrong interlaced field-order tags. A separate verification pass confirmed the fixes.
\1 `drawtext` with an animated `fontsize` expression segfaults on the Ubuntu build. Each affected recipe is marked, with a crash-free alternative (Advanced SubStation Alpha `\t` scaling).
- **Not tested** (no hardware or library on the test machine): NVENC/CUDA, Quick Sync, VAAPI, AMF, VideoToolbox, OpenCL, Vulkan Video encode and decode, `whisper`, `libvmaf`, `libvvenc`, and `lensfun`. These recipes were checked against `ffmpeg -h` option listings and the FFmpeg 8.0 sources.

