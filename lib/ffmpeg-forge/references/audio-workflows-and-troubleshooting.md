# Professional Workflows & Troubleshooting

Self-contained processing chains for common production scenarios, plus quick fixes for typical post-processing issues.

## Professional Workflows

Deliverables use **two-pass** `loudnorm` (as in `audio.md`): pass 1 measures the processed signal with `print_format=json`, pass 2 applies the measured values with `linear=true`. Single-pass `loudnorm` runs in dynamic mode, which pumps and usually misses the target by a few LU on short material. The processing chain before `loudnorm` must be identical in both passes, so this helper takes it as one string:

```bash
# loudnorm2 INPUT "PRE_CHAIN" "LOUDNORM_TARGETS" OUTPUT [output options...]
loudnorm2() {
  local in="$1" pre="$2" tgt="$3" out="$4"; shift 4
  local j
  # Pass 1: measure (the JSON block is printed on stderr)
  j=$(ffmpeg -hide_banner -nostats -i "$in" \
        -af "${pre:+$pre,}loudnorm=$tgt:print_format=json" -f null - 2>&1 |
      sed -n '/^{/,/^}/p')
  g() { printf '%s\n' "$j" | sed -n "s/.*\"$1\" : \"\([^\"]*\)\".*/\1/p"; }
  # Pass 2: apply the measured values (linear=true keeps the dynamics;
  # loudnorm falls back to dynamic mode only if the TP/LRA targets demand it)
  ffmpeg -i "$in" \
    -af "${pre:+$pre,}loudnorm=$tgt:measured_I=$(g input_i):measured_TP=$(g input_tp):measured_LRA=$(g input_lra):measured_thresh=$(g input_thresh):offset=$(g target_offset):linear=true" \
    -ar 48000 "$@" "$out"
}
```

### Podcast Processing

```bash
# Complete podcast processing chain (silence trim before loudness so both
# passes measure the same audio)
loudnorm2 raw_podcast.wav \
  "highpass=f=80,acompressor=threshold=-20dB:ratio=4:attack=5:release=50,silenceremove=start_periods=1:start_silence=1:start_threshold=-50dB" \
  "I=-16:TP=-1.5:LRA=11" \
  podcast.m4a -c:a aac -b:a 96k
```

### Music Mastering Chain

```bash
# Mastering chain
loudnorm2 mix.wav \
  "equalizer=f=60:width_type=o:width=1:g=1,equalizer=f=12000:width_type=o:width=1:g=0.5,acompressor=threshold=-12dB:ratio=2:attack=20:release=200,alimiter=limit=0.95" \
  "I=-14:TP=-1:LRA=9" \
  master.flac -c:a flac
```

### Broadcast Normalization

```bash
# EBU R128 broadcast compliance (-23 LUFS, -1 dBTP)
loudnorm2 input.wav "" "I=-23:TP=-1:LRA=11:dual_mono=true" \
  broadcast.wav -c:a pcm_s24le

# Verify: Integrated should read -23.0 LUFS (+/-0.5 LU tolerance in R128).
# dualmono=true measures a mono file the way loudnorm's dual_mono did (+3 dB);
# drop it for stereo files.
ffmpeg -hide_banner -nostats -i broadcast.wav -af ebur128=peak=true:dualmono=true -f null - 2>&1 | sed -n '/Summary:/,/Peak:/p'
```

## Troubleshooting

### Common Issues

**"loudnorm resamples to 192kHz"**
```bash
# Force output sample rate
ffmpeg -i input.mp3 \
  -af loudnorm=I=-16:TP=-1.5:LRA=11 \
  -ar 48000 \
  output.mp3
```

**Audio/video sync after processing**
```bash
# Maintain sync with video
ffmpeg -i video.mp4 \
  -af "loudnorm=I=-16:TP=-1.5:LRA=11,aresample=async=1" \
  -ar 48000 -c:v copy \
  output.mp4
```

**Quality loss from re-encoding**
- Use lossless intermediate format (FLAC, WAV)
- Avoid multiple lossy conversions
- Use high bitrates for final lossy encode
