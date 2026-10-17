# Python FFmpeg

Use this reference for Python-driven FFmpeg work: encoding, filtering, audio processing, metadata probing, streaming, thumbnails, PyAV frame access, subprocess integration, and production troubleshooting.

## Core Workflow

1. Choose the integration layer first: ffmpeg-python for readable filter graphs, subprocess for full CLI parity, PyAV for frame-level access, and moviepy only for simple edits.
2. Probe inputs before processing so codec, duration, resolution, FPS, audio streams, and metadata are known.
3. Preserve audio explicitly whenever a video filter is applied; filtered video streams do not automatically carry audio.
4. Select the output codec and acceleration path based on compatibility, compression, and deployment hardware.
5. Use overwrite/error-handling patterns consistently: `overwrite_output()` with ffmpeg-python or `-y` with subprocess, plus captured stderr for diagnostics.
6. For large media, stream frames or use temp files instead of reading all stdout or frames into memory.

## Key Gotchas

- Video filters commonly drop audio unless the audio stream is passed to `ffmpeg.output(...)` or copied explicitly.
- Subprocess pipes can deadlock if stdout/stderr are not drained or frame reads are not sized correctly.
- Windows paths are safest as `Path(...).as_posix()` or as subprocess argument-list entries, not hand-quoted command strings.
- CRF values are codec-specific: H.265 CRF 28 is roughly comparable to H.264 CRF 23.
- Hardware encoders trade compression efficiency for speed; validate availability before choosing NVENC, QSV, AMF, or VAAPI.

## Reference Map

This file is an index; for any code task, load the matching deep-dive reference.

- [ffmpeg-complete-recipes.md](ffmpeg-complete-recipes.md) - Full recipe guide covering encoding, hardware acceleration, audio/audio filters, video filters, trimming, concatenation, streaming, probing, thumbnails, PyAV, subprocess patterns, common transformations, errors, and performance tips.
- [ffmpeg-advanced-patterns.md](ffmpeg-advanced-patterns.md) - Complex filter graphs (multi-output splits, side-by-side and grid stacking, xfade crossfades, animated picture-in-picture), advanced audio (multi-track mixing, sidechain ducking, waveform/spectrum visualization), video effects (stabilization, deinterlacing, denoising, chroma key, motion blur, interpolated slow motion, time lapse), batch processing with progress reporting, live RTMP desktop/webcam streaming, subtitle burn-in/extraction/muxing, HDR-to-SDR tone mapping, color space conversion and LUTs, CUDA GPU pipelines, broken-file repair and validation, FFmpeg/OpenCV frame piping, and memory-efficient and parallel encoding.

