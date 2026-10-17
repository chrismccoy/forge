# Python Video Pipeline

Use this reference for end-to-end Python video pipelines that combine decoding, OpenCV/PyAV/frame processing, FFmpeg encoding, serverless execution, GPU acceleration, HLS output, and large-file orchestration.

## Core Workflow

1. Start by selecting the pipeline architecture: simple OpenCV, FFmpeg plus OpenCV pipes, PyAV frame processing, ffmpegcv/Decord/VidGear, or Modal for scalable execution.
2. Normalize color and shape conventions at every library boundary: OpenCV BGR/HWC, PIL RGB, PyAV RGB, FFmpeg pixel formats, and ML CHW tensors.
3. Probe media metadata before processing so FPS, resolution, frame count, audio presence, and codec assumptions are explicit.
4. Process long videos as streams, batches, or chunks; avoid accumulating all frames unless inputs are small and bounded.
5. Re-mux or preserve audio after frame-level processing, since OpenCV-only workflows usually produce video-only outputs.
6. On Modal or GPU infrastructure, tune batch size, pixel format, decode/encode acceleration, volume usage, and timeout boundaries.

## Key Gotchas

- BGR/RGB mismatches silently produce wrong colors across OpenCV, FFmpeg, PyAV, PIL, and ML frameworks.
- Frame dimensions are usually HWC in NumPy/OpenCV but may need CHW for deep learning frameworks.
- OpenCV `VideoWriter` output may not preserve the source audio; plan an explicit FFmpeg audio re-mux step.
- Parallel frame processing must restore original frame order before reconstruction.
- Chunked processing needs timestamp and concat handling; audio is usually handled after chunk recombination.

## Reference Map

This file is an index; for any code task, load the matching deep-dive reference.

- [video-pipeline-complete-patterns.md](video-pipeline-complete-patterns.md) - Full pipeline guide covering library selection, integration gotchas, FFmpeg/OpenCV pipes, ffmpegcv, VidGear, Decord, Modal GPU workflows, chunking, transcoding, HLS, end-to-end workflows, and optimization tips.
- [modal-video-patterns.md](modal-video-patterns.md) - Modal.com video recipes: container images (standard FFmpeg, NVENC/NVDEC GPU, ffmpegcv, Decord), storage with Volumes and S3/R2 bucket mounts, frame-level `map()`, video-level `starmap()`, and chunk-based parallelism, upload-and-process and streaming-response web endpoints, cost optimization (GPU selection by task, CPU-only jobs, preemption-tolerant batch jobs with checkpoints), robust error handling, and progress tracking/logging.

