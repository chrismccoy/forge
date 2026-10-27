# FFmpeg Audio Processing

Audio encoding, loudness normalization, filters, channel operations, resampling, speed and pitch, and audio troubleshooting with FFmpeg. Podcast, mastering and broadcast chains, speechnorm, dialogue enhancement and binaural rendering are in `audio-chains.md`.

## Contents

- [Quick Reference](#quick-reference)
- [Workflow](#workflow)
- [Audio Codec Reference](#audio-codec-reference)
- [Basic Audio Operations](#basic-audio-operations)
- [Audio Normalization](#audio-normalization) (loudness standards, two-pass script, peak, dynaudnorm, ffmpeg-normalize)
- [Audio Filters](#audio-filters)
- [Channel Operations](#channel-operations)
- [Sample Rate & Bit Depth](#sample-rate--bit-depth)
- [Speed & Pitch](#speed--pitch)
- [Trimming & Concatenation](#trimming--concatenation)
- [Troubleshooting](#troubleshooting)
- [Related References](#related-references)

## Quick Reference

| Task | Command |
|------|---------|
| Extract audio | `ffmpeg -i video.mp4 -vn -c:a copy audio.m4a` |
| Convert to MP3 | `ffmpeg -i input.flac -c:a libmp3lame -q:a 2 output.mp3` |
| Normalize (deliverable) | Two-pass: `scripts/loudnorm-2pass.sh in.wav out.wav -23 -1 20` ([script](#two-pass-script-loudnorm-2passsh)) |
| Normalize (preview/live only) | `-af loudnorm=I=-16:TP=-1.5:LRA=11 -ar 48000` |
| Adjust volume | `-af "volume=1.5"` or `-af "volume=6dB"` |
| Mono to stereo | `-ac 2` |

Bitrates: see [Recommended Bitrates](#recommended-bitrates). Loudness targets: see [Loudness Standards](#loudness-standards).

## Workflow

1. **Analyze the audio.**

   ```bash
   # Codec, rate, channels, bitrate
   ffprobe -v error -select_streams a -show_entries stream=codec_name,sample_rate,channels,bit_rate -of default=noprint_wrappers=1 INPUT

   # Loudness and true peak (needed before normalizing)
   ffmpeg -hide_banner -nostats -i INPUT -af ebur128=peak=true -f null - 2>&1 | sed -n '/Summary:/,$p'
   ```

2. **Choose the operation.**

   | Job | Section |
   |---|---|
   | Extract (copy or re-encode) | [Extract Audio](#extract-audio) |
   | Convert formats, batch convert | [Convert Audio Formats](#convert-audio-formats) |
   | Volume, fades, EQ, noise reduction, compression | [Audio Filters](#audio-filters) |
   | Speech levelling, dialogue, binaural | [Speech, Dialogue and Binaural Processing](audio-chains.md#speech-dialogue-and-binaural-processing) |
   | Channels, downmix | [Channel Operations](#channel-operations) |
   | Normalize a deliverable | [Two-Pass Script](#two-pass-script-loudnorm-2passsh), [Processing Chains](audio-chains.md#processing-chains) |

   Pick the codec and bitrate from [Recommended Bitrates](#recommended-bitrates). Prefer `-c:a copy` when the audio already matches the target.

3. **Test** the command on a short slice (`-t 10`) before the full file.

4. **Verify** the output.

   ```bash
   # Codec, rate, channels, bitrate
   ffprobe -v error -show_entries stream=codec_name,sample_rate,channels,bit_rate OUTPUT

   # Loudness (Integrated within 0.5 LU of the target)
   ffmpeg -hide_banner -nostats -i OUTPUT -af ebur128=peak=true:framelog=quiet -f null - 2>&1 |
     sed -n '/Summary:/,$p' | grep -E ' I:|LRA:|Peak:'
   ```

Checklist:

- Codec and bitrate match the use case ([Recommended Bitrates](#recommended-bitrates)).
- Re-encoding is avoided when `-c:a copy` would do; when re-encoding, the quality trade-off is known.
- Deliverables are normalized with two-pass `scripts/loudnorm-2pass.sh`, and its return code is checked.
- Multiple files are handled with a shell loop that reports failures ([Convert Audio Formats](#convert-audio-formats)).
- The output exists and is verified with ffprobe and `ebur128`.

## Audio Codec Reference

### Codec Comparison

| Codec | Encoder | Bitrate Range | Quality | Compatibility | Use Case |
|-------|---------|---------------|---------|---------------|----------|
| AAC | aac, libfdk_aac | 64-320 kbps | Excellent | Universal | Streaming, mobile |
| MP3 | libmp3lame | 96-320 kbps | Good | Universal | Legacy, podcasts |
| Opus | libopus | 32-256 kbps | Best | Modern | VoIP, WebM |
| FLAC | flac | ~900 kbps | Lossless | Wide | Archival |
| ALAC | alac | ~900 kbps | Lossless | Apple | Apple ecosystem |
| Vorbis | libvorbis | 64-500 kbps | Very Good | Wide | WebM, games |
| AC3 | ac3 | 192-640 kbps | Good | Universal | DVD, Blu-ray |
| EAC3 | eac3 | 192-768 kbps | Very Good | Wide | Streaming |
| xHE-AAC | - (decode only) | 12-64 kbps | Excellent | Emerging | Ultra-low bitrate |

### Recommended Bitrates

This is the canonical bitrate table for the audio references.

| Use Case | AAC | MP3 | Opus |
|----------|-----|-----|------|
| Podcast/Speech | 64-96k | 96-128k | 32-64k |
| Music (Standard) | 128-192k | 192-256k | 96-128k |
| Music (High Quality) | 256-320k | 320k | 160-256k |
| Transparent Quality | 256k+ | 320k | 192k+ |

## Basic Audio Operations

### Extract Audio

```bash
# Extract to original format (no re-encode)
ffmpeg -i video.mp4 -vn -c:a copy audio.m4a

# Extract to MP3
ffmpeg -i video.mp4 -vn -c:a libmp3lame -b:a 320k audio.mp3

# Extract to AAC
ffmpeg -i video.mp4 -vn -c:a aac -b:a 256k audio.m4a

# Extract to FLAC (lossless)
ffmpeg -i video.mp4 -vn -c:a flac audio.flac

# Extract to WAV (uncompressed)
ffmpeg -i video.mp4 -vn -c:a pcm_s16le audio.wav
```

### Convert Audio Formats

```bash
# MP3 to AAC
ffmpeg -i input.mp3 -c:a aac -b:a 256k output.m4a

# WAV to MP3
ffmpeg -i input.wav -c:a libmp3lame -b:a 320k output.mp3

# FLAC to MP3
ffmpeg -i input.flac -c:a libmp3lame -b:a 320k output.mp3

# MP3 to Opus (for WebM)
ffmpeg -i input.mp3 -c:a libopus -b:a 128k output.opus

# Multiple files (batch); report failures instead of ignoring them
# (-n never overwrites; a failed decode can leave an empty .mp3 behind)
for f in *.flac; do
  ffmpeg -nostdin -n -i "$f" -c:a libmp3lame -b:a 320k "${f%.flac}.mp3" ||
    echo "FAILED: $f" >&2
done
```

### Quality Settings

```bash
# Native AAC encoder VBR: -q:a roughly 0.1-2 (higher = better). This mode is
# experimental; constant bitrate (-b:a 128k-256k) is usually the safer choice.
# (The 1-5 scale is libfdk_aac's -vbr option, not native aac's -q:a.)
ffmpeg -i input.wav -c:a aac -q:a 2 output.m4a

# MP3 VBR quality (0-9, lower = better)
ffmpeg -i input.wav -c:a libmp3lame -q:a 0 output.mp3

# Opus with target bitrate
ffmpeg -i input.wav -c:a libopus -b:a 128k output.opus
```

## Audio Normalization

### Loudness Standards

| Standard | Target | Max True Peak | Use Case |
|----------|--------|----------------|----------|
| EBU R128 | -23 LUFS (±0.5 LU) | -1 dBTP | European broadcast |
| ATSC A/85 | -24 LKFS | -2 dBTP | US broadcast |
| Spotify | -14 LUFS | -1 dBTP | Streaming |
| YouTube | -14 LUFS | -1 dBTP | Video platform |
| Apple Music | -16 LUFS | -1 dBTP | Music streaming |
| Podcast | -16 to -19 LUFS | -1 dBTP | Podcast |

`loudnorm` options: `I` -70 to -5 (default -24), `LRA` 1 to 50 (default 7), `TP` -9 to 0 (default -2).

### Single-Pass loudnorm (preview and live only)

Single-pass `loudnorm` runs in dynamic mode: it pumps and usually misses the target by a few LU on short material. Use it for live streams and quick previews, never for deliverables.

```bash
# loudnorm upsamples to 192 kHz internally; -ar 48000 sets the output rate
ffmpeg -i input.mp3 \
  -af loudnorm=I=-16:TP=-1.5:LRA=11 \
  -ar 48000 preview.mp3
```

### Two-Pass loudnorm (deliverables)

Pass 1 measures with `print_format=json`. Pass 2 feeds the measured values back with `linear=true`, which applies one fixed gain and keeps the dynamics. For deliverables use `scripts/loudnorm-2pass.sh` ([below](#two-pass-script-loudnorm-2passsh)), which avoids the traps listed after the manual steps. The manual steps are the inline fallback when the script is not available.

```bash
# Pass 1: analyze (the JSON block is printed on stderr)
ffmpeg -hide_banner -nostats -i input.wav \
  -af loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json \
  -f null - 2>&1 | sed -n '/^{/,/^}/p'

# Output (FFmpeg 8.0.1):
# {
# 	"input_i" : "-30.89",
# 	"input_tp" : "-23.88",
# 	"input_lra" : "1.20",
# 	"input_thresh" : "-40.89",
# 	...
# 	"normalization_type" : "dynamic",   <- describes pass 1, ignore
# 	"target_offset" : "0.16"
# }

# Pass 2: normalize with the measured values. print_format=summary prints
# "Normalization Type: Linear" when the fixed-gain mode was used.
ffmpeg -i input.wav \
  -af loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=-30.89:measured_TP=-23.88:measured_LRA=1.20:measured_thresh=-40.89:offset=0.16:linear=true:print_format=summary \
  -ar 48000 output.wav
```

`loudnorm` uses linear mode only when all of these hold. Otherwise it silently falls back to dynamic mode, which can miss the target by 1-2 LU:

- The measured LRA is not above the target `LRA`. The default target is 7 LU, and much real content measures 10-20 LU. Measured: an input with LRA 14.6 LU and target `LRA=11` came out at -24.6 LUFS for a -23 target; with `LRA=20` it came out at -22.8 LUFS.
- The measured true peak plus the gain stays at or below `TP`. When it does not, `offset=` (from `target_offset`) keeps the dynamic-mode result close to the target (measured: -16.1 LUFS for -16).
- `measured_LRA` is not 0. loudnorm reads `0` as "not measured", so a perfectly flat input (LRA 0.00) needs a small value such as `0.1`.

A second trap: after a compressor in the pre-chain, loudnorm's own pass-1 `input_i` can be wrong. Measured on FFmpeg 8.0.1: `acompressor,...,loudnorm` reported `input_i` -16.8 LUFS, while `ebur128` on the same chain read -18.6 LUFS. The "two-pass" result then landed at -15.8 LUFS for a -14 target, in linear mode and with no warning. The script measures with `ebur128` placed just before `loudnorm` and checks the written file. For a manual run with a pre-chain, take `I`, `Threshold`, `LRA` and `Peak` from an `ebur128=peak=true` summary placed where `loudnorm` will be, instead of from loudnorm's JSON.

#### Two-Pass Script (loudnorm-2pass.sh)

`scripts/loudnorm-2pass.sh` handles all of these cases. The pre-loudnorm chain (`--pre`) runs identically in both passes. The script refuses to overwrite and stops when pass 1 fails or the input is silent. It raises the LRA target to cover the input so linear mode can apply (unless `--keep-lra`). It reports the normalization type, measures the output with `ebur128`, and returns 2 when the result is more than 0.5 LU from the target.

```text
scripts/loudnorm-2pass.sh [--pre CHAIN] [--dual-mono] [--keep-lra] <input> <output> [I] [TP] [LRA] [-- extra ffmpeg output options]
  I / TP / LRA   targets (defaults -16 LUFS, -1.5 dBTP, 11 LU)
  --pre CHAIN    filters before loudnorm, identical in both passes
  --dual-mono    measure a MONO file as played on two speakers (+3 dB)
  --keep-lra     keep the LRA target (dynamic mode; may miss). LOUDNORM2_KEEP_LRA=1 does the same
Output: 48 kHz, video copied unless the extra options say otherwise.
Return codes: 0 = on target, 1 = failed, 2 = written but more than 0.5 LU off.
```

Usage:

```bash
# EBU R128 broadcast (-23 LUFS, -1 dBTP)
scripts/loudnorm-2pass.sh input.wav broadcast.wav -23 -1 20 -- -c:a pcm_s24le

# Podcast, with a processing chain before loudnorm
scripts/loudnorm-2pass.sh --pre "highpass=f=80" raw.wav podcast.m4a -16 -1.5 11 -- -c:a aac -b:a 96k

# Video: normalize the audio, copy the video (the default)
scripts/loudnorm-2pass.sh video.mp4 output.mp4 -16 -1.5 11 -- -c:a aac -b:a 160k

# Check the return code in scripts: 0 = on target, 1 = failed, 2 = written but off target
scripts/loudnorm-2pass.sh in.wav out.wav || echo "loudnorm-2pass failed or missed ($?)" >&2

# Independent check (Integrated should be within 0.5 LU of the target)
ffmpeg -hide_banner -nostats -i broadcast.wav -af ebur128=peak=true -f null - 2>&1 |
  sed -n '/Summary:/,$p'
```

To keep a fixed LRA target, for example to compress dynamics on purpose, add `--keep-lra`. The script then reports dynamic mode and warns if the result misses.

Podcast, music-mastering and broadcast chains built on this script: [Processing Chains](audio-chains.md#processing-chains).

### Peak Normalization

```bash
# Peak normalization to -1 dBFS: measure the sample peak, then apply the difference.
# volumedetect reports the sample peak to 0.1 dB; lossy encoding can move the
# peak by a few tenths of a dB.
peak=$(ffmpeg -nostdin -i input.wav -af volumedetect -f null - 2>&1 |
  sed -n 's/.*max_volume: \(-\{0,1\}[0-9.]*\) dB/\1/p')
[ -n "$peak" ] || { echo "volumedetect failed" >&2; exit 1; }
gain=$(echo "-1 - ($peak)" | bc)
ffmpeg -i input.wav -af "volume=${gain}dB" output.wav

# Apply stored ReplayGain tags instead (values: track, album, ignore, drop)
ffmpeg -i input.mp3 -af "volume=replaygain=track" output.mp3
```

### Dynamic Normalization (dynaudnorm)

`dynaudnorm` evens out level changes over time (quiet and loud passages, distant and close speakers) by applying a smoothly varying gain per frame. It does not target a LUFS value, so for deliverables run it as the `--pre` chain of `scripts/loudnorm-2pass.sh`.

```bash
# Default: 500 ms frames, 31-frame Gaussian window, peak 0.95, max gain 10x
ffmpeg -i input.mp3 -af dynaudnorm output.mp3

# Faster-reacting, for speech with big level jumps
# (f = frame length ms, g = window size in frames (odd), m = max gain, p = peak)
ffmpeg -i lecture.wav -af "dynaudnorm=f=250:g=15:m=20:p=0.9" -c:a aac -b:a 128k lecture.m4a

# Gentler, music-friendly (longer window keeps more of the dynamics)
ffmpeg -i music.wav -af "dynaudnorm=f=500:g=101:m=5" music_norm.flac

# Deliverable: dynaudnorm, then two-pass loudnorm
scripts/loudnorm-2pass.sh --pre "dynaudnorm=f=250:g=15:m=20:p=0.9" lecture.wav lecture.m4a -16 -1.5 11 -- -c:a aac -b:a 96k
```

`dynaudnorm` buffers `f*g` ms of audio (500*31 = 15.5 s by default), so in live use the output starts after that delay. `speechnorm` reacts faster.

### ffmpeg-normalize Tool

The `ffmpeg-normalize` Python utility wraps two-pass loudnorm (not tested on this build; flags taken from its README):

```bash
# Install
pip install ffmpeg-normalize

# Basic usage (EBU R128, default target -23 LUFS)
ffmpeg-normalize input.mp3 -o output.mp3

# Custom target
ffmpeg-normalize input.mp3 -o output.mp3 -t -14

# Batch/album mode: preserves relative loudness between files (v1.35.0+)
ffmpeg-normalize *.mp3 --batch -o normalized/

# Built-in presets: podcast, music, streaming-video (v1.36.0+)
ffmpeg-normalize input.mp3 --preset podcast -o output.mp3
ffmpeg-normalize *.mp3 --preset music --batch -o normalized/
```

## Audio Filters

### Volume Control

```bash
# Increase volume by 50%
ffmpeg -i input.mp3 -af "volume=1.5" output.mp3

# Increase by 6dB
ffmpeg -i input.mp3 -af "volume=6dB" output.mp3

# Decrease by 3dB
ffmpeg -i input.mp3 -af "volume=-3dB" output.mp3
```

### Fade In/Out

```bash
# Fade in 3 seconds, fade out the last 3 seconds of a 60 s file
# (st = start time in seconds; ss would be a start *sample*)
ffmpeg -i input.mp3 \
  -af "afade=t=in:st=0:d=3,afade=t=out:st=57:d=3" \
  output.mp3

# Calculate the fade-out start automatically
duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 input.mp3)
fadeout_start=$(echo "$duration - 3" | bc)
ffmpeg -i input.mp3 \
  -af "afade=t=in:st=0:d=3,afade=t=out:st=${fadeout_start}:d=3" \
  output.mp3
```

### Equalization

```bash
# Bass boost
ffmpeg -i input.mp3 \
  -af "equalizer=f=100:width_type=o:width=2:g=5" \
  output.mp3

# Treble reduction
ffmpeg -i input.mp3 \
  -af "equalizer=f=8000:width_type=o:width=2:g=-3" \
  output.mp3

# Multi-band EQ
ffmpeg -i input.mp3 \
  -af "equalizer=f=100:width_type=o:width=2:g=3,equalizer=f=1000:width_type=o:width=2:g=-2,equalizer=f=8000:width_type=o:width=2:g=2" \
  output.mp3
```

### High-Pass / Low-Pass Filters

```bash
# High-pass filter (remove below 80Hz)
ffmpeg -i input.mp3 -af "highpass=f=80" output.mp3

# Low-pass filter (remove above 8kHz)
ffmpeg -i input.mp3 -af "lowpass=f=8000" output.mp3

# Band-pass filter
ffmpeg -i input.mp3 -af "highpass=f=80,lowpass=f=12000" output.mp3
```

### Noise Reduction

```bash
# FFT-based noise reduction (nf = noise floor in dB, -80 to -20, default -50)
ffmpeg -i input.mp3 \
  -af "afftdn=nf=-25" \
  output.mp3

# With noise tracking (tn=1 adapts the noise floor over time)
ffmpeg -i input.mp3 \
  -af "afftdn=nf=-20:tn=1" \
  output.mp3
```

More options and profiles: `denoise.md`.

### Compressor / Limiter

```bash
# Dynamic range compression
ffmpeg -i input.mp3 \
  -af "acompressor=threshold=-20dB:ratio=4:attack=5:release=50" \
  output.mp3

# Limiter
ffmpeg -i input.mp3 \
  -af "alimiter=limit=0.9:attack=5:release=50" \
  output.mp3

# De-esser
ffmpeg -i input.mp3 \
  -af "deesser=i=0.4:m=0.5:f=0.5" \
  output.mp3
```

### Silence Detection/Removal

```bash
# Detect silence
ffmpeg -i input.mp3 \
  -af silencedetect=noise=-30dB:d=0.5 \
  -f null -

# Remove silence
ffmpeg -i input.mp3 \
  -af "silenceremove=start_periods=1:start_silence=0.5:start_threshold=-50dB:stop_periods=1:stop_silence=0.5:stop_threshold=-50dB" \
  output.mp3
```

## Channel Operations

### Stereo to Mono

```bash
# Average both channels
ffmpeg -i stereo.mp3 \
  -af "pan=mono|c0=0.5*c0+0.5*c1" \
  mono.mp3

# Use only left channel
ffmpeg -i stereo.mp3 -af "pan=mono|c0=c0" mono.mp3

# Downmix stereo to mono
ffmpeg -i stereo.mp3 -ac 1 mono.mp3
```

### Mono to Stereo

```bash
# Duplicate mono to both channels
ffmpeg -i mono.mp3 -af "pan=stereo|c0=c0|c1=c0" stereo.mp3

# Simple conversion
ffmpeg -i mono.mp3 -ac 2 stereo.mp3
```

### Extract Specific Channels

```bash
# Extract left channel
ffmpeg -i stereo.mp3 \
  -filter_complex "[0:a]channelsplit=channel_layout=stereo:channels=FL[left]" \
  -map "[left]" left.mp3

# Extract right channel
ffmpeg -i stereo.mp3 \
  -filter_complex "[0:a]channelsplit=channel_layout=stereo:channels=FR[right]" \
  -map "[right]" right.mp3
```

### 5.1 Surround Operations

```bash
# Downmix 5.1 to stereo
# AC-3/E-AC-3/DTS/AAC decoders usually output 5.1(side) (SL/SR surrounds);
# check with: ffprobe -v error -show_entries stream=channel_layout surround.ac3
# pan silently treats channels missing from the input as silence, so using
# BL/BR on a 5.1(side) source drops the surrounds. For 5.1(side):
ffmpeg -i surround.ac3 \
  -af "pan=stereo|FL=0.5*FC+0.707*FL+0.707*SL+0.5*LFE|FR=0.5*FC+0.707*FR+0.707*SR+0.5*LFE" \
  stereo.mp3
# For a 5.1 (back) source, use BL/BR in place of SL/SR.
# Or let FFmpeg pick the matrix for whatever layout it gets:
ffmpeg -i surround.ac3 -ac 2 stereo.mp3

# Extract center channel
ffmpeg -i surround.ac3 \
  -filter_complex "[0:a]channelsplit=channel_layout=5.1:channels=FC[center]" \
  -map "[center]" center.mp3
```

## Sample Rate & Bit Depth

### Sample Rate Conversion

```bash
# Convert to 44.1kHz
ffmpeg -i input.wav -ar 44100 output.wav

# Convert to 48kHz
ffmpeg -i input.wav -ar 48000 output.wav

# High-quality resampling (needs a build with --enable-libsoxr)
ffmpeg -i input.wav \
  -af "aresample=resampler=soxr:precision=33:cheby=1" \
  -ar 44100 output.wav
```

### Bit Depth Conversion

```bash
# Convert to 16-bit
ffmpeg -i input.wav -c:a pcm_s16le output.wav

# Convert to 24-bit
ffmpeg -i input.wav -c:a pcm_s24le output.wav

# Convert to 32-bit float
ffmpeg -i input.wav -c:a pcm_f32le output.wav
```

## Speed & Pitch

### Speed Change (atempo keeps the pitch)

```bash
# 2x speed, same pitch
ffmpeg -i input.mp3 -af "atempo=2.0" output.mp3

# 0.5x speed (slow motion), same pitch
ffmpeg -i input.mp3 -af "atempo=0.5" output.mp3

# atempo accepts 0.5-100 in one instance (no chaining needed for >2x)
ffmpeg -i input.mp3 -af "atempo=4.0" output.mp3  # 4x
# Below 0.5x, chain instances: atempo=0.5,atempo=0.5 = 0.25x

# Speed AND pitch together (tape/chipmunk effect): reinterpret the sample
# rate, then resample back. 44100 must be the input's sample rate
# (check with ffprobe -show_entries stream=sample_rate); with a wrong value
# the speed factor is off.
ffmpeg -i input.mp3 -af "asetrate=44100*2,aresample=44100" output.mp3  # 2x, +1 octave
```

### Pitch Change (Preserves Speed)

```bash
# Pitch shift using rubberband (pitch is a frequency ratio: 1.5 = +7 semitones)
ffmpeg -i input.mp3 \
  -af "rubberband=pitch=1.5" \
  output.mp3

# Pitch shift by semitones without rubberband: asetrate raises pitch AND
# speed, so atempo slows it back to the original duration
# (+2 semitones; 48000 must be the input's sample rate, or the duration changes:
# a 44100 Hz value on a 48 kHz file turned 10.0 s into 10.87 s)
ffmpeg -i input.wav \
  -af "asetrate=48000*2^(2/12),aresample=48000,atempo=1/2^(2/12)" \
  output.wav
```

## Trimming & Concatenation

### Trim Audio

```bash
# Extract 30 seconds starting at 1 minute
ffmpeg -ss 00:01:00 -i input.mp3 -t 00:00:30 -c copy output.mp3

# Extract from 1:00 to 2:30
ffmpeg -ss 00:01:00 -to 00:02:30 -i input.mp3 -c copy output.mp3
```

### Concatenate Audio

```bash
# Create file list
echo "file 'part1.mp3'" > list.txt
echo "file 'part2.mp3'" >> list.txt

# Concatenate (same format)
ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp3

# Concatenate with re-encode
ffmpeg -f concat -safe 0 -i list.txt -c:a aac -b:a 256k output.m4a
```

### Crossfade

```bash
# Crossfade two files (3 second overlap)
ffmpeg -i part1.mp3 -i part2.mp3 \
  -filter_complex "acrossfade=d=3:c1=tri:c2=tri" \
  output.mp3
```

## Troubleshooting

**loudnorm output is 192 kHz.** loudnorm upsamples internally for true-peak detection and outputs 192 kHz unless an output rate is set:

```bash
# Preview / live: force the output sample rate
ffmpeg -i input.mp3 \
  -af loudnorm=I=-16:TP=-1.5:LRA=11 \
  -ar 48000 \
  preview.mp3
# Deliverables: scripts/loudnorm-2pass.sh already adds -ar 48000
```

**Audio/video sync after processing.**

```bash
# Two-pass loudness on a video's audio, video copied, timestamps kept aligned
scripts/loudnorm-2pass.sh --pre "aresample=async=1" video.mp4 output.mp4 -16 -1.5 11 -- -c:v copy -c:a aac -b:a 160k
```

More A/V drift causes (cuts, speed changes, variable frame rate): `troubleshooting.md`.

**Quality loss from re-encoding.**

- Use a lossless intermediate format (FLAC, WAV) between processing steps.
- Avoid chaining several lossy conversions.
- Use the [Recommended Bitrates](#recommended-bitrates) for the final lossy encode.

## Related References

- `audio-chains.md`: podcast, music mastering and broadcast chains; speechnorm, dialoguenhance, sofalizer.
- `audio-measurement.md`: astats, ebur128, volumedetect, chromaprint, and an analysis script.
- `denoise.md`: noise reduction in depth (afftdn, anlmdn, arnndn).
- `waveforms.md`: audio visualizers (showwaves, showspectrum, showcqt).
- `fundamentals-common-operations.md`: video operations and the transcode procedure.
