# Whisper AI Transcription with FFmpeg 8.0

FFmpeg 8.0 added the `whisper` audio filter, which runs whisper.cpp speech recognition inside a filtergraph. This is the canonical Whisper reference; `captions-drawtext-and-whisper.md` and `fundamentals-common-operations.md` show the same pattern in context.

## How the Filter Works

- The filter **writes the transcript itself** to the file named by `destination=` (or to stdout with `destination=-`).
- The audio stream passes through unchanged. Discard it with `-f null -`, or keep encoding it to a normal output.
- Do **not** use `-f srt out.srt` as the output: the srt muxer accepts no audio stream, and ffmpeg fails with `Output file does not contain any stream`.
- The filter converts input to 16 kHz mono float internally, so no manual resampling is needed.
- It also attaches `lavfi.whisper.text` and `lavfi.whisper.duration` metadata to **audio** frames (readable with `ametadata=print`).

## Requirements

- FFmpeg 8.0 or later **built with whisper.cpp** (`--enable-whisper`). Many distribution builds, including Ubuntu's, omit it.
- A GGML model file.

```bash
ffmpeg -hide_banner -filters | grep whisper   # must print a line
```

## Filter Options

All options as defined in `libavfilter/af_whisper.c` (8.0):

| Option | Type | Default | Description |
|---|---|---|---|
| `model` | string | (required) | Path to the whisper.cpp GGML model |
| `language` | string | `auto` | Language code (`en`, `de`, ...) or `auto` |
| `queue` | duration | `3` (s) | Audio buffered before each transcription run. Longer gives better context and more latency |
| `use_gpu` | bool | `1` | Use the GPU if whisper.cpp was built with GPU support |
| `gpu_device` | int | `0` | GPU index |
| `destination` | string | `""` | Output file, URL, or `-` for stdout. Empty means metadata only |
| `format` | string | `text` | `text`, `srt`, or `json` (no `vtt`) |
| `vad_model` | string | — | Silero VAD model; enables voice-activity segmentation |
| `vad_threshold` | float | `0.5` | VAD speech probability threshold (0–1) |
| `vad_min_speech_duration` | duration | `0.1` (s) | Shortest speech segment kept |
| `vad_min_silence_duration` | duration | `0.5` (s) | Silence needed to split segments |

There is **no translate option** in the 8.0 filter. For translation to English, run the whisper.cpp CLI (`whisper-cli --translate`) instead.

## Download Models

```bash
mkdir -p ~/.cache/whisper && cd ~/.cache/whisper
BASE=https://huggingface.co/ggerganov/whisper.cpp/resolve/main

curl -fLO $BASE/ggml-base.bin            # 142 MiB, good default
curl -fLO $BASE/ggml-base.en.bin         # English-only, more accurate for English
curl -fLO $BASE/ggml-medium.bin          # 1.5 GiB, better accuracy
curl -fLO $BASE/ggml-large-v3-turbo.bin  # 1.5 GiB, near large-v3 quality, much faster
curl -fLO $BASE/ggml-large-v3.bin        # 2.9 GiB, best accuracy

# Quantized (smaller, faster): e.g. ggml-base-q5_1.bin, ggml-medium-q5_0.bin
curl -fLO $BASE/ggml-medium-q5_0.bin

# Silero VAD model
curl -fLO https://huggingface.co/ggml-org/whisper-vad/resolve/main/ggml-silero-v5.1.2.bin
```

`curl -f` makes a 404 fail instead of saving the error page as a "model". There is no plain `ggml-large.bin`; use `large-v3` or `large-v3-turbo`.

| Model | Disk | Notes |
|---|---|---|
| tiny / tiny.en | 75 MiB | Fastest, lowest accuracy |
| base / base.en | 142 MiB | Good default for clean speech |
| small / small.en | 466 MiB | Noticeably better on accents and noise |
| medium / medium.en | 1.5 GiB | High accuracy |
| large-v3-turbo | 1.5 GiB | Close to large-v3, several times faster |
| large-v3 | 2.9 GiB | Best accuracy, slowest |

`.en` models are English-only and more accurate for English at the same size.

## Basic Usage

```bash
# SRT subtitles
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:destination=output.srt:format=srt" \
  -f null -

# Known language (faster and more accurate than auto)
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.en.bin:language=en:destination=output.srt:format=srt" \
  -f null -

# JSON with segment timestamps
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:destination=output.json:format=json" \
  -f null -

# Plain text to stdout
ffmpeg -v warning -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=en:destination=-:format=text" \
  -f null -
```

### WebVTT

The filter has no VTT format. Generate SRT, then convert:

```bash
ffmpeg -i output.srt output.vtt
```

## Advanced Examples

### Voice Activity Detection

VAD splits on real pauses, which gives better-timed segments and skips silence:

```bash
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-medium.bin:language=en:queue=20:vad_model=ggml-silero-v5.1.2.bin:vad_threshold=0.5:destination=output.srt:format=srt" \
  -f null -
```

With VAD, a larger `queue` (10–20 s) is recommended, because VAD decides where segments end within the queue.

### Live Transcription from a Microphone

```bash
# Linux (PulseAudio/PipeWire)
ffmpeg -loglevel warning -f pulse -i default \
  -af "highpass=f=200,lowpass=f=3000,whisper=model=ggml-base.en.bin:language=en:queue=3:destination=-:format=text" \
  -f null -

# macOS (AVFoundation)
ffmpeg -loglevel warning -f avfoundation -i ":0" \
  -af "whisper=model=ggml-base.en.bin:language=en:destination=-:format=text" \
  -f null -
```

### Transcribe, then Burn In

```bash
# 1. Generate SRT
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=auto:destination=subs.srt:format=srt" \
  -f null -

# 2. Burn into the video
ffmpeg -i input.mp4 -vf "subtitles=subs.srt" \
  -c:v libx264 -crf 20 -c:a copy output_with_subs.mp4
```

### Inspect the Per-Frame Metadata

```bash
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.en.bin:language=en,ametadata=mode=print:key=lavfi.whisper.text" \
  -f null -
```

The text is attached to audio frames, so `drawtext` on the video stream cannot read it directly. For on-screen captions, generate SRT and burn it in as above.

## Performance

```bash
# CPU only (e.g. when GPU memory is busy)
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-base.bin:language=en:use_gpu=0:destination=output.srt:format=srt" \
  -f null -

# Quantized model: smaller download and faster on CPU
ffmpeg -i input.mp4 -vn \
  -af "whisper=model=ggml-medium-q5_0.bin:language=en:destination=output.srt:format=srt" \
  -f null -
```

- Set `language` explicitly when known. `auto` re-detects the language and is slower.
- Use `-vn` so the video is not decoded.
- For several transcriptions of one file, extract audio once (`-vn -c:a pcm_s16le -ar 16000 -ac 1 audio.wav`) and run whisper on the WAV.

## Audio Preprocessing

Cleaner audio improves accuracy noticeably:

```bash
# Noise reduction + loudness normalization before recognition
ffmpeg -i input.mp4 -vn \
  -af "afftdn=nf=-25,loudnorm=I=-16:TP=-1.5:LRA=11,whisper=model=ggml-base.bin:language=en:destination=output.srt:format=srt" \
  -f null -

# Band-limit to the speech range
ffmpeg -i input.mp4 -vn \
  -af "highpass=f=200,lowpass=f=3000,whisper=model=ggml-base.bin:language=en:destination=output.srt:format=srt" \
  -f null -
```

## Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| `No such filter: 'whisper'` | Build lacks whisper.cpp. Use a build configured with `--enable-whisper` |
| `Output file does not contain any stream` | Used `-f srt file.srt` as the output. Use `destination=` + `-f null -` |
| `No option name near ...` or `Protocol not found` on paths | A `:` in a path needs two escape levels: FFmpeg must receive `\\:` (type `\\:` inside single shell quotes, `\\\\:` inside double quotes). Prefix a relative path that contains `:` with `./` (`destination=./a\\:b.srt`), or it is read as a protocol. Simplest: avoid `:` and `'` in file names |
| Empty or garbage output | Model file is a failed download (check its size), or wrong `language` |
| Poor accuracy | Larger model, explicit `language`, VAD, and the preprocessing chains above |
| Timing drifts on long files | Use VAD and a larger `queue` |

The helper `scripts/generate-whisper-subtitles.sh <video> [model] [language]` wraps this workflow, including model download.
