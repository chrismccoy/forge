# Audio Analysis & Measurement

Audio measurement with FFmpeg: astats, ebur128, volumedetect, chromaprint, and a complete analysis script. Processing filters (speechnorm, dialoguenhance, sofalizer) are in `audio-chains.md`, loudness normalization in `audio.md`.

## Contents

- [Audio Statistics (astats)](#audio-statistics-astats)
- [EBU R128 Loudness Measurement (ebur128)](#ebu-r128-loudness-measurement-ebur128)
- [Volume Detection](#volume-detection)
- [Audio Fingerprinting (chromaprint)](#audio-fingerprinting-chromaprint)
- [Complete Analysis Workflow](#complete-analysis-workflow)

## Audio Statistics (astats)

Measure audio statistics: RMS, peak levels, crest factor, bit depth, and DC offset. astats prints a per-channel block and an `Overall` block when the stream ends.

```bash
# Whole-file statistics (per channel + overall)
ffmpeg -i input.mp3 -af astats -f null -

# Only selected overall metrics
ffmpeg -i input.mp3 -af "astats=measure_overall=RMS_level+Peak_level:measure_perchannel=none" -f null -

# Only selected per-channel metrics
ffmpeg -i input.mp3 -af "astats=measure_perchannel=Crest_factor+Dynamic_range:measure_overall=none" -f null -
```

Do not add `reset=1` for a whole-file summary. `reset=N` restarts the statistics every N frames, so the summary printed at the end covers only the last frame or frames. Measured: Peak -15.9 dB with `reset=1` against -9.9 dB without it. `reset` is for per-frame (or per-window) values exported as metadata:

```bash
# Per-frame RMS level as metadata, logged to a file
ffmpeg -i input.mp3 \
  -af "astats=metadata=1:reset=1,ametadata=mode=print:key=lavfi.astats.Overall.RMS_level:file=rms.txt" \
  -f null -
```

**astats Metrics** (names as used in `measure_overall` / `measure_perchannel` and in `lavfi.astats.*` keys):

| Metric | Description |
|--------|-------------|
| `DC_offset` | DC bias in signal |
| `Min_level` | Minimum sample value |
| `Max_level` | Maximum sample value |
| `Min_difference` | Minimum sample-to-sample difference |
| `Max_difference` | Maximum sample-to-sample difference |
| `Mean_difference` | Average sample-to-sample difference |
| `RMS_level` | Root Mean Square level (dB) |
| `Peak_level` | Peak level (dB) |
| `RMS_peak` | RMS peak level |
| `RMS_trough` | RMS trough level |
| `Crest_factor` | Peak to RMS ratio (per channel only) |
| `Flat_factor` | Flatness measure |
| `Peak_count` | Number of samples at peak |
| `Bit_depth` | Actual bit depth used |
| `Dynamic_range` | Dynamic range in dB (per channel only) |
| `Noise_floor`, `Entropy`, `Zero_crossings` | Further metrics; full list: `ffmpeg -h filter=astats` |

## EBU R128 Loudness Measurement (ebur128)

Loudness measurement per EBU R128 / ITU-R BS.1770.

```bash
# Basic loudness measurement: summary only
ffmpeg -hide_banner -nostats -i input.mp3 -af "ebur128=peak=true:framelog=quiet" -f null - 2>&1 |
  sed -n '/Summary:/,$p'

# Summary includes:
# - Integrated loudness (I) and its gating threshold
# - Loudness Range (LRA), LRA low/high
# - True peak (printed as dBFS; with peak=true it is the true peak)

# Frame-by-frame log: momentary (M), short-term (S), integrated (I), LRA
# every 100 ms, then the summary
ffmpeg -hide_banner -nostats -i input.mp3 -af "ebur128=framelog=info:peak=true" -f null - 2>&1 |
  grep -E 'M:|Summary:|^ +(I|LRA|Peak):'

# Generate loudness graph (PNG). With video=1, ebur128 has a video AND an
# audio output; discard the audio with anullsink. -update 1 keeps overwriting
# the PNG, so it ends up holding the final, complete graph.
ffmpeg -i input.mp3 \
  -filter_complex "[0:a]ebur128=video=1:meter=18:gauge=shortterm[v][a];[a]anullsink;[v]scale=1280:720[out]" \
  -map "[out]" -update 1 \
  loudness_graph.png

# Create loudness monitoring video (default 640x480 at 10 fps)
ffmpeg -i input.mp3 \
  -filter_complex "[0:a]ebur128=video=1:meter=18:gauge=shortterm:scale=absolute[v][a]" \
  -map "[v]" -map "[a]" \
  -c:v libx264 -pix_fmt yuv420p -c:a aac \
  loudness_monitor.mp4

# Measure a mono file as dual mono (mono played on two speakers, +3 dB vs. single-speaker mono)
ffmpeg -i input.mp3 -af "ebur128=dualmono=1:peak=true" -f null -
```

**ebur128 Parameters:**
| Parameter | Description | Values |
|-----------|-------------|--------|
| `video` | Generate video output | 0 or 1 |
| `meter` | Meter scale range (+9 to +18 LU) | 9-18 (default 9) |
| `gauge` | Which loudness the video gauge shows (not an on/off switch) | `momentary`/`m` (default), `shortterm`/`s` |
| `scale` | Scale type | `absolute`, `relative` |
| `peak` | Peak mode (flags, combinable: `sample+true`) | `none`, `sample`, `true` |
| `dualmono` | Dual mono mode | 0 or 1 |
| `framelog` | Per-frame log level (`verbose` lines only show with `-v verbose`) | `quiet`, `info`, `verbose` |

## Volume Detection

```bash
# Detect volume levels
ffmpeg -i input.mp3 -af "volumedetect" -f null -

# Output includes (sample peak, 0.1 dB resolution):
# [Parsed_volumedetect_0 @ ...] mean_volume: -19.0 dB
# [Parsed_volumedetect_0 @ ...] max_volume: -9.9 dB
# [Parsed_volumedetect_0 @ ...] histogram_9db: 12
```

## Audio Fingerprinting (chromaprint)

Generate audio fingerprints for identification (needs `--enable-chromaprint`).

```bash
# Raw fingerprint: binary 32-bit integers, not text
ffmpeg -i input.mp3 -f chromaprint -fp_format raw fingerprint.bin

# Base64 fingerprint (text)
# (the fingerprint is written to stdout; -v error keeps the log off the terminal)
ffmpeg -v error -i input.mp3 -f chromaprint -fp_format base64 -
```

## Complete Analysis Workflow

```bash
#!/bin/bash
# audio-analysis.sh - Complete audio analysis
INPUT="$1"
[ -f "$INPUT" ] || { echo "usage: $0 FILE" >&2; exit 1; }
ff() { ffmpeg -hide_banner -nostdin -nostats -i "$INPUT" -vn "$@" -f null - 2>&1; }

# Fail early on unreadable input
ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$INPUT" |
  grep -q . || { echo "No audio stream in $INPUT" >&2; exit 1; }

echo "=== Audio Analysis Report ==="
echo "File: $INPUT"

echo "--- Basic Statistics (overall) ---"
ff -af "astats=measure_perchannel=none" | sed -n '/Overall/,/Number of samples/p' | sed 's/^\[[^]]*\] //'

echo "--- Loudness (EBU R128) ---"
ff -af "ebur128=peak=true:framelog=quiet" | grep -E '^ +(I|LRA|Peak):'

echo "--- Volume Detection ---"
ff -af volumedetect | grep -oE '(mean|max)_volume: .*'

echo "--- Silence Detection (below -50 dB for 0.5 s+) ---"
# grep exits 1 when it finds nothing; a file without silence is not an error
SIL=$(ff -af "silencedetect=noise=-50dB:d=0.5" | grep -oE 'silence_(start|end).*' || true)
echo "${SIL:-No silence found}"
exit 0
```
