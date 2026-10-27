# FFmpeg Audio Processing

## Purpose
Extract, convert, normalize, and process audio using FFmpeg with professional-grade settings.

## Workflow

### 1. Analyze Audio
```bash
# Get audio stream info
ffprobe -v error -select_streams a -show_entries stream=codec_name,sample_rate,channels,bit_rate -of default=noprint_wrappers=1 INPUT
```

### 2. Common Operations

#### Extract Audio
```bash
# Copy without re-encoding
ffmpeg -i video.mp4 -vn -c:a copy audio.m4a

# Convert to MP3
ffmpeg -i video.mp4 -vn -c:a libmp3lame -b:a 320k audio.mp3

# Convert to high-quality AAC
ffmpeg -i video.mp4 -vn -c:a aac -b:a 256k audio.m4a
```

#### Convert Formats
```bash
# FLAC to MP3
ffmpeg -i input.flac -c:a libmp3lame -b:a 320k output.mp3

# WAV to AAC
ffmpeg -i input.wav -c:a aac -b:a 256k output.m4a

# MP3 to Opus (for WebM)
ffmpeg -i input.mp3 -c:a libopus -b:a 128k output.opus
```

#### Normalize Audio (EBU R128)
```bash
# Single-pass (quick)
ffmpeg -i input.mp3 -af "loudnorm=I=-16:TP=-1.5:LRA=11" -ar 48000 output.mp3

# Two-pass (best quality) - see `audio.md` for script
```

### 3. Audio Filters

#### Volume Adjustment
```bash
# Increase by 50%
ffmpeg -i input.mp3 -af "volume=1.5" output.mp3

# Increase by 6dB
ffmpeg -i input.mp3 -af "volume=6dB" output.mp3
```

#### Fade Effects
```bash
# Fade in 3s, fade out 3s (60s audio)
ffmpeg -i input.mp3 -af "afade=t=in:d=3,afade=t=out:st=57:d=3" output.mp3
```

#### Noise Reduction
```bash
ffmpeg -i input.mp3 -af "afftdn=nf=-25" output.mp3
```

#### Compression
```bash
ffmpeg -i input.mp3 -af "acompressor=threshold=-20dB:ratio=4:attack=5:release=50" output.mp3
```

### 4. Bitrate Reference

| Codec | Speech | Music (Good) | Music (High) |
|-------|--------|--------------|--------------|
| AAC | 64-96k | 128-192k | 256-320k |
| MP3 | 96-128k | 192-256k | 320k |
| Opus | 32-64k | 96-128k | 160-256k |

### 5. Podcast Processing Chain
```bash
# Two-pass loudnorm via the loudnorm2 helper defined in
# `audio-workflows-and-troubleshooting.md` (it also sets -ar 48000)
loudnorm2 raw_podcast.wav \
  "highpass=f=80,acompressor=threshold=-20dB:ratio=4" \
  "I=-16:TP=-1.5:LRA=11" \
  podcast.m4a -c:a aac -b:a 96k
```

## Checklist

- The command runs on a short test (`-t 10`) before the full file.
- Codec and bitrate match the use case (see the bitrate table above).
- Re-encoding is avoided when `-c:a copy` would do; when re-encoding, the quality trade-off is known.
- Multiple files are handled with a shell loop rather than one command per file.
- The output is verified, e.g. `ffprobe -v error -show_entries stream=codec_name,sample_rate,channels,bit_rate OUTPUT` and, for loudness, `ebur128=framelog=quiet`.
