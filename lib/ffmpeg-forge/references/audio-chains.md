# Audio Processing Chains

Ready-made audio chains: podcast, music mastering and broadcast loudness chains, speech levelling (speechnorm), dialogue enhancement (dialoguenhance) and binaural rendering (sofalizer). Codecs, loudness normalization, single filters and channel operations are in `audio.md`; measurement is in `audio-measurement.md`.

## Contents

- [Processing Chains](#processing-chains) (podcast, music mastering, broadcast)
  - [Podcast Processing](#podcast-processing)
  - [Music Mastering Chain](#music-mastering-chain)
  - [Broadcast Normalization](#broadcast-normalization)
- [Speech, Dialogue and Binaural Processing](#speech-dialogue-and-binaural-processing)
  - [Speech Normalization (speechnorm)](#speech-normalization-speechnorm)
  - [Dialogue Enhancement (dialoguenhance, FFmpeg 5.1+)](#dialogue-enhancement-dialoguenhance-ffmpeg-51)
  - [3D Audio / Binaural (sofalizer)](#3d-audio--binaural-sofalizer)

## Processing Chains

Deliverables use two-pass loudness through `scripts/loudnorm-2pass.sh`. Single-pass `loudnorm` runs in dynamic mode, which pumps and usually misses the target by a few LU on short material.

### Podcast Processing

This is the canonical podcast chain.

```bash
# High-pass, compression, leading-silence trim, then two-pass loudness
# (the silence trim sits before loudnorm so both passes measure the same audio)
scripts/loudnorm-2pass.sh \
  --pre "highpass=f=80,acompressor=threshold=-20dB:ratio=4:attack=5:release=50,silenceremove=start_periods=1:start_silence=1:start_threshold=-50dB" \
  raw_podcast.wav podcast.m4a -16 -1.5 11 -- -c:a aac -b:a 96k
```

Speech-optimized variant: put `speechnorm=p=0.95:e=12.5:r=0.0005` after `highpass` in the `--pre` chain (see [speechnorm](#speech-normalization-speechnorm)).

### Music Mastering Chain

```bash
scripts/loudnorm-2pass.sh \
  --pre "equalizer=f=60:width_type=o:width=1:g=1,equalizer=f=12000:width_type=o:width=1:g=0.5,acompressor=threshold=-12dB:ratio=2:attack=20:release=200,alimiter=limit=0.95" \
  mix.wav master.flac -14 -1 9 -- -c:a flac
```

### Broadcast Normalization

```bash
# EBU R128 broadcast compliance (-23 LUFS, -1 dBTP). LRA=20 because broadcast
# programmes often measure 10-20 LU; with a lower target than the input's LRA
# loudnorm drops to dynamic mode (measured: LRA=11 on a 14.6 LU input gave
# -24.6 LUFS instead of -23). The script also raises it automatically.
# --dual-mono is for MONO files only: it measures them as played on two
# speakers (+3 dB). Drop it for stereo.
scripts/loudnorm-2pass.sh --dual-mono input_mono.wav broadcast.wav -23 -1 20 -- -c:a pcm_s24le

# Verify: Integrated should read -23.0 LUFS (+/-0.5 LU tolerance in R128).
# dualmono=true matches --dual-mono for a mono file; drop it for stereo.
ffmpeg -hide_banner -nostats -i broadcast.wav -af ebur128=peak=true:dualmono=true -f null - 2>&1 | sed -n '/Summary:/,/Peak:/p'
```

## Speech, Dialogue and Binaural Processing

### Speech Normalization (speechnorm)

Normalizer for speech that raises quiet passages and limits loud ones, adapting per half-cycle. It does not target a LUFS value; for deliverables, run it in the `--pre` chain of `scripts/loudnorm-2pass.sh`.

```bash
# Basic speech normalization
ffmpeg -i speech.mp3 -af "speechnorm" output.mp3

# Speech normalization with custom parameters
ffmpeg -i speech.mp3 \
  -af "speechnorm=p=0.95:e=6:r=0.0005:l=1" \
  output.mp3

# Aggressive speech normalization
ffmpeg -i speech.mp3 \
  -af "speechnorm=p=0.9:e=15:r=0.001:l=1" \
  output.mp3

# Podcast deliverable: speechnorm before two-pass loudness
scripts/loudnorm-2pass.sh --pre "highpass=f=80,speechnorm=p=0.95:e=12.5:r=0.0005" \
  podcast.wav podcast.m4a -16 -1.5 11 -- -c:a aac -b:a 96k
```

**speechnorm Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `p` | Peak value target | 0.95 | 0-1 |
| `e` | Max expansion factor | 2 | 1-50 |
| `c` | Max compression factor | 2 | 1-50 |
| `t` | Threshold below which half-cycles are not expanded | 0 | 0-1 |
| `r` | Expansion raising amount per half-cycle | 0.001 | 0-1 |
| `f` | Compression (fall) amount per half-cycle | 0.001 | 0-1 |
| `m` | RMS target (0 = off) | 0 | 0-1 |
| `i` | Invert filtering | 0 | 0 or 1 |
| `l` | Link channels | 0 | 0 or 1 |

### Dialogue Enhancement (dialoguenhance, FFmpeg 5.1+)

Enhances dialogue by extracting the centre (voice) component of a **stereo** input. The output is **3.0** (FL+FR+FC), not stereo: mono input is upmixed first, and an `-c:v copy output.mp4` recipe without a downmix writes a 3-channel track. Downmix back to stereo for normal delivery:

```bash
# Basic dialogue enhancement, folded back to stereo (FC at -3 dB into both sides)
ffmpeg -i input.mp4 \
  -af "dialoguenhance,pan=stereo|FL=FL+0.707*FC|FR=FR+0.707*FC" \
  -c:v copy -c:a aac output.mp4

# Custom dialogue enhancement; -ac 2 lets FFmpeg choose the downmix
ffmpeg -i input.mp4 \
  -af "dialoguenhance=original=0.3:enhance=1.5:voice=16" -ac 2 \
  -c:v copy -c:a aac output.mp4

# Heavy enhancement for poor recordings (less original centre, more enhanced voice)
ffmpeg -i input.mp4 \
  -af "dialoguenhance=original=0.2:enhance=2.5" -ac 2 \
  -c:v copy -c:a aac output.mp4

# Keep the 3.0 layout (e.g. for a surround mix)
ffmpeg -i input.mp4 -af dialoguenhance -c:v copy -c:a aac output_3ch.mp4
```

**dialoguenhance Parameters:**
| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `original` | Original center-channel factor | 1 | 0-1 |
| `enhance` | Dialogue enhance factor | 1 | 0-3 |
| `voice` | Voice detection factor | 2 | 2-32 |

### 3D Audio / Binaural (sofalizer)

Apply HRTF (Head-Related Transfer Function) for 3D audio and binaural processing using SOFA files. Needs a build with `--enable-libmysofa`. The commands below were checked against `ffmpeg -h filter=sofalizer` only, because no SOFA file was available.

```bash
# Basic binaural conversion (requires SOFA file)
ffmpeg -i surround.ac3 \
  -af "sofalizer=sofa=/path/to/hrtf.sofa" \
  binaural.mp3

# With custom gain and rotation
ffmpeg -i surround.ac3 \
  -af "sofalizer=sofa=/path/to/hrtf.sofa:gain=0:rotation=0" \
  binaural.mp3

# Binaural conversion with elevation
ffmpeg -i surround.ac3 \
  -af "sofalizer=sofa=/path/to/hrtf.sofa:elevation=0:radius=1" \
  binaural.mp3
```

A path containing `:`, `'` or `,` must be escaped for the filtergraph (see SKILL.md and `scripts/lib/filter-escape.sh`).

**SOFA Files:**
- Download HRTF databases from: https://sofacoustics.org/data/database/
- Common formats: CIPIC, MIT KEMAR, LISTEN databases

**sofalizer Parameters:**
| Parameter | Description | Range |
|-----------|-------------|-------|
| `sofa` | Path to SOFA file | - |
| `gain` | Additional gain (dB) | -20 to 40 |
| `rotation` | Head rotation (degrees) | -360 to 360 |
| `elevation` | Head elevation (degrees) | -90 to 90 |
| `radius` | Distance scaling | 0 to 5 |
| `type` | Processing domain | `time`, `freq` (default) |
