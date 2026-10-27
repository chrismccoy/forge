# FFmpeg Troubleshooting

Symptoms, error messages and their fixes: playback failures, GPU output problems, A/V drift, wrong durations, corrupt files, and a diagnostic procedure.

## Contents

- [Symptom Table](#symptom-table)
- [Diagnostic Procedure](#diagnostic-procedure)
- [Error Messages](#error-messages)
- [A/V Sync and Duration Problems](#av-sync-and-duration-problems)
- [GPU Output Problems](#gpu-output-problems)
- [Playback on Phones, Browsers and TVs](#playback-on-phones-browsers-and-tvs)
- [Checklist](#checklist)

## Symptom Table

| Symptom | Likely cause | Fix | More |
|---|---|---|---|
| Green, garbled or purple picture from a GPU pipeline | `hwdownload` format does not match the surface's sw_format (`format=nv12` on a 10-bit `p010` surface), or a GPU filter fed CPU frames | `hwdownload,format=p010le` for 10-bit/HDR, `format=nv12` for 8-bit; `format=nv12,hwupload` before GPU filters | [GPU Output Problems](#gpu-output-problems), `hwaccel-gpu-memory-and-troubleshooting.md` |
| Plays on desktop, not on phone or browser | High 4:4:4 / 4:2:2 or 10-bit profile; HEVC without the `hvc1` tag (Apple); no faststart (long wait or no start over HTTP); AC-3/E-AC-3 or Opus audio in MP4 for a browser | `-pix_fmt yuv420p`; `-tag:v hvc1`; `-movflags +faststart` (remux is enough); `-c:a aac` | [Playback on Phones, Browsers and TVs](#playback-on-phones-browsers-and-tvs) |
| Smart TV, console or media player: no sound, no picture, "unsupported file", or missing subtitles | DTS/TrueHD/Opus audio; 10-bit HEVC/AV1 on an older TV; level too high (4K or 1080p60 at level 5.x); PGS/ASS subtitles; interlaced or variable-frame-rate source; MKV not accepted | Audio to AC-3 or AAC; video to 8-bit H.264 High at level 4.1; subtitles to SRT or burned in; deinterlace / constant frame rate; remux to MP4 | [Smart TV and Media Players](#smart-tv-and-media-players) |
| Audio drifts or starts out of sync after cutting or a speed change | `-c copy` cut starts video at an earlier keyframe; `setpts` without matching `atempo`; variable-frame-rate source; concatenated parts with unequal audio lengths | Re-encode the cut with `-ss` before `-i`; pair `setpts=PTS/N` with `atempo=N`; `-fps_mode cfr`; `aresample=async=1` | [A/V Sync and Duration Problems](#av-sync-and-duration-problems) |
| `Unknown encoder 'libfdk_aac'` / `Encoder not found` / decoder fails to open | Encoder not in this build (licence or build flags), or hardware library missing (`Cannot load libnvcuvid.so.1`) | `ffmpeg -encoders \| grep NAME`; use a built-in alternative (`aac`, `libx264`) or a build with the library | [Error Messages](#error-messages) |
| `Could not find tag for codec X ..., codec not currently supported in container` / `Only VP8 or VP9 or AV1 video and Vorbis or Opus audio ... are supported for WebM` | Codec not allowed in the chosen container | Change the container (MKV takes almost anything) or re-encode to a codec it accepts | `fundamentals.md` (Container Compatibility) |
| `Impossible to convert between the formats supported by the filter ...` | Usually a hardware/software boundary without `hwdownload`/`hwupload` | See the error entry | ["Impossible to convert ..."](#impossible-to-convert-between-the-formats-supported-by-the-filter) |
| Output shorter or longer than expected | `-shortest` with buffering filters; image input looped without `-t`; `amix` default `duration=longest`; `-t` placed before `-i` (limits input) vs after (limits output); stream durations differ | Set `-t` on the output; `amix=...:duration=first`; check each stream's duration with ffprobe | [A/V Sync and Duration Problems](#av-sync-and-duration-problems) |
| `Too many packets buffered for output stream 0:1.` | One stream is delayed (slow filter, sparse subtitles, late audio start), so the muxer queue overflows | `-max_muxing_queue_size 9999` (output option) | [Error Messages](#error-messages) |

## Diagnostic Procedure

### 1. Validate the File

```bash
# Check that the container/headers parse (does not decode any frames)
ffprobe -v error INPUT && echo "Headers OK" || echo "Invalid/Corrupt"

# Get detailed error info
ffprobe -v verbose INPUT 2>&1 | head -50

# Full validation (slow but thorough). Decode errors do NOT change the exit
# code (ffmpeg conceals them and exits 0), so test that stderr is empty:
errs=$(ffmpeg -v error -i INPUT -f null - 2>&1)
[ -z "$errs" ] && echo "Playable" || { echo "Has errors:"; printf '%s\n' "$errs" | head -20; }
```

### 2. Get Detailed File Info

```bash
# Comprehensive JSON info
ffprobe -v quiet -print_format json -show_format -show_streams INPUT

# Summary info
ffprobe -v error -show_entries format=duration,size,bit_rate:stream=codec_name,width,height,r_frame_rate -of default=noprint_wrappers=1 INPUT
```

### 3. Generate a Debug Log

```bash
# Create detailed report
ffmpeg -report -i INPUT -c copy OUTPUT

# Or set log level
ffmpeg -v verbose -i INPUT OUTPUT 2>&1 | tee ffmpeg.log
```

### 4. Check FFmpeg Capabilities

```bash
ffmpeg -version              # Version and build flags
ffmpeg -encoders             # All encoders
ffmpeg -decoders             # All decoders
ffmpeg -formats              # All formats
ffmpeg -filters              # All filters
ffmpeg -h encoder=libx264    # Specific encoder options
```

`scripts/check-codecs.sh` audits the whole build.

### 5. Test Commands

```bash
# Test reading the first 5 s without writing a file (null muxer)
ffmpeg -i INPUT -t 5 -c copy -f null -

# Generate test pattern
# (testsrc is RGB: without -pix_fmt yuv420p libx264 writes High 4:4:4,
# which phones and browsers cannot play)
ffmpeg -f lavfi -i testsrc=size=1280x720:rate=30 -t 10 -pix_fmt yuv420p test.mp4

# Test encoding speed
ffmpeg -benchmark -i INPUT -c:v libx264 -f null -
```

## Error Messages

### "Invalid data found when processing input"

```bash
# Try with error recovery (-err_detect is a decoder option: it only acts
# when the stream is decoded, i.e. re-encoded, not with -c copy)
ffmpeg -err_detect ignore_err -i INPUT -c:v libx264 -c:a aac OUTPUT

# Remux-only salvage: drop corrupt packets and regenerate missing PTS
ffmpeg -fflags +discardcorrupt+genpts -i INPUT -c copy OUTPUT

# Force format detection
ffmpeg -f FORMAT -i INPUT -c copy OUTPUT
```

### "No such file or directory"

```bash
# Check path (Windows Git Bash issue)
MSYS_NO_PATHCONV=1 ffmpeg -i INPUT OUTPUT

# Use quotes for paths with spaces
ffmpeg -i "path with spaces/file.mp4" output.mp4
```

A relative name containing `:` (e.g. `clip:1.mp4`) is read as a protocol; prefix it with `./`.

### "Unknown encoder" / Encoder or Decoder Not Found

FFmpeg 8.0 prints `Unknown encoder 'NAME'` when the encoder is not in the build. Non-free encoders such as `libfdk_aac` are missing from most distribution builds.

```bash
# Check available codecs
ffmpeg -encoders | grep -i CODEC_NAME
ffmpeg -decoders | grep -i CODEC_NAME

# Install missing codec or use alternative
ffmpeg -i INPUT -c:v libx264 OUTPUT.mp4
```

### "Hardware acceleration failed"

Typical lines: `Cannot load libnvcuvid.so.1` (no NVIDIA driver library), `va_openDriver() returns -1` (no VAAPI driver), `Failed setup for format ...` (decode silently falls back to software).

```bash
# Check available hardware accelerators
ffmpeg -hwaccels

# Check GPU encoders
ffmpeg -encoders | grep nvenc
ffmpeg -encoders | grep qsv
ffmpeg -encoders | grep vaapi

# Fallback to software
ffmpeg -i INPUT -c:v libx264 OUTPUT.mp4
```

Per-backend fixes: `hwaccel-gpu-memory-and-troubleshooting.md`.

### "Codec not currently supported in container"

`Could not find tag for codec rawvideo in stream #0, codec not currently supported in container` means the muxer cannot store that codec. WebM is strict and says so directly (`Only VP8 or VP9 or AV1 video and Vorbis or Opus audio and WebVTT subtitles are supported for WebM.`). Either pick a container that takes the codec (MKV, MOV) or re-encode. Bitmap subtitles (PGS, VobSub) cannot go into MP4: burn them in or keep MKV.

### "Impossible to convert between the formats supported by the filter"

```text
Impossible to convert between the formats supported by the filter 'Parsed_hwupload_0' and the filter 'auto_scale_0'
```

A filter's output format cannot be converted to what the next filter or the encoder accepts. Almost always this is a hardware/software boundary:

- GPU frames going to a CPU encoder or filter: add `hwdownload,format=nv12` (`format=p010le` for 10-bit surfaces).
- CPU frames going to a GPU filter or a GPU-only encoder such as `h264_vaapi`: add `format=nv12,hwupload` (with `-filter_hw_device`), or keep `-hwaccel_output_format vaapi` so decoded frames stay on the GPU.
- Keep `-hwaccel_output_format` consistent with the encoder's device type.
- Rarely, a software filter cannot output the pixel format the next stage needs: insert an explicit `format=` between them.

See [GPU Output Problems](#gpu-output-problems) and `hwaccel-gpu-memory-and-troubleshooting.md`.

### "Thread message queue blocking" / "Too many packets buffered" / Buffer Overruns

```bash
# Input side: "Thread message queue blocking; consider raising the
# thread_queue_size option" -> raise the demuxer queue (input option)
ffmpeg -thread_queue_size 1024 -i INPUT OUTPUT

# Output side: "Too many packets buffered for output stream" -> raise the
# muxing queue (output option)
ffmpeg -i INPUT -max_muxing_queue_size 9999 OUTPUT

# Live UDP input dropping data ("Circular buffer overrun"): enlarge the
# protocol FIFO and keep going on overrun
ffmpeg -i "udp://0.0.0.0:1234?fifo_size=1000000&overrun_nonfatal=1" OUTPUT
```

`-bufsize` is not a fix for these errors: it is the encoder's rate-control (VBV) buffer and does nothing without `-maxrate`.

### "moov atom not found"

The MP4/MOV index is missing, usually because the recording or upload was cut off. `+faststart` cannot help (it only moves an existing moov). Re-export the file, or try a recovery tool such as untrunc with a good reference file. Record live sources to MKV, MPEG-TS or fragmented MP4 to avoid this ([MP4/MOV Muxer Flags](streaming.md#mp4mov-muxer-flags--movflags)).

## A/V Sync and Duration Problems

### Measure First

```bash
# Start time and duration of every stream: a gap between video and audio
# start_time is a constant offset; equal starts with drifting playback is drift
ffprobe -v error -show_entries stream=index,codec_type,start_time,duration \
  -of compact=p=0 INPUT
```

### Constant Offset

```bash
# Audio is 0.3 s early: delay it by opening the file twice and offsetting the
# audio input (-itsoffset is an input option and applies to the next -i)
ffmpeg -i INPUT -itsoffset 0.3 -i INPUT -map 0:v -map 1:a -c copy OUTPUT.mkv

# Audio is 0.3 s late: offset the video input instead
ffmpeg -itsoffset 0.3 -i INPUT -i INPUT -map 0:v -map 1:a -c copy OUTPUT.mkv
```

### Drift After Cutting

With `-c copy`, video can only start at a keyframe, while audio starts at the requested time. MP4 hides the extra lead-in with an edit list, but players and later processing steps that ignore it show the audio early. Re-encode the cut (`-ss` before `-i` is fast and exact when re-encoding):

```bash
ffmpeg -ss 00:01:00 -i INPUT -t 30 -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac OUTPUT.mp4
```

### Drift After a Speed Change

`setpts` changes only the video. Change the audio by the same factor with `atempo` (or drop it with `-an`):

```bash
# 1.5x faster: video timestamps / 1.5, audio tempo x 1.5
ffmpeg -i INPUT -vf "setpts=PTS/1.5" -af "atempo=1.5" OUTPUT.mp4
```

### Variable Frame Rate and Gaps

Phone and screen recordings are often variable frame rate, and some editors and filters assume constant rate. Audio with gaps or timestamp jumps drifts gradually.

```bash
# Constant 30 fps video, audio stretched/padded to match its timestamps
ffmpeg -i INPUT -fps_mode cfr -r 30 -af "aresample=async=1" \
  -c:v libx264 -crf 20 -pix_fmt yuv420p -c:a aac OUTPUT.mp4
```

### Concatenated Parts Drift

The concat demuxer joins parts end to end by stream; when a part's audio is shorter or longer than its video, the error adds up over the following parts. Re-encode the parts with matching durations first (`-shortest` or `apad` per part), or join them with the `concat` filter, which keeps each segment's audio and video together (`filter-complex.md`).

### Output Shorter or Longer Than Expected

- **Runs forever or too long:** an image input with `-loop 1`, `-stream_loop -1` or a `lavfi` source has no end; set `-t` on the output. `amix` defaults to `duration=longest`; use `duration=first` to follow the main audio.
- **Too short:** `-t` before `-i` limits how much is read; `-shortest` stops at the shortest stream, and with buffering filters it can cut early or late. Check each stream's duration after the encode.
- **Audio longer than video (or the reverse):** filters that change only one stream (`select`, `setpts`, `trim`, `tpad`, `loop`, `reverse`) need the matching audio filter (`aselect`/`atrim`, `atempo`, `adelay`, `aloop`, `areverse`) or `-an`. See `filters-basics.md`.

## GPU Output Problems

- **Green or purple frames, garbled colours:** the format after `hwdownload` must match the surface's sw_format. 8-bit sources decode to `nv12`, 10-bit/HDR to `p010le`: use `hwdownload,format=p010le` for those (then convert with `format=yuv420p10le` or tonemap). Run with `-v verbose` to see the negotiated formats.
- **`Impossible to convert between the formats ...`:** see ["Impossible to convert ..."](#impossible-to-convert-between-the-formats-supported-by-the-filter).
- **Works but slow:** `-hwaccel X` without `-hwaccel_output_format X` copies every frame back to system memory; a silent software fallback (`Failed setup for format ...` in the log) looks the same.

Per-backend details and memory flow: `hwaccel-gpu-memory-and-troubleshooting.md`, `hwaccel.md`.

## Playback on Phones, Browsers and TVs

Diagnose "plays on the computer but not on a phone, browser or TV". The phone and browser recipes (universal mobile, iOS Safari, Android, low-bandwidth) are in `fundamentals-common-operations.md` ([Output Optimization](fundamentals-common-operations.md#output-optimization)); TVs, consoles and media players are under [Smart TV and Media Players](#smart-tv-and-media-players).

### Check Codec Profile and Level

```bash
# Show video stream profile and level
ffprobe -v error -select_streams v:0 \
  -show_entries stream=codec_name,profile,level,pix_fmt,width,height \
  -of default=noprint_wrappers=1 INPUT

# Common output for mobile-incompatible video:
# profile=High 4:4:4 Predictive  <- FAILS on mobile
# level=51                        <- Too high for most mobile
# pix_fmt=yuv444p                 <- Not supported on mobile
```

### Mobile Compatibility Check

```bash
# Run this diagnostic function to check mobile compatibility
check_mobile_compat() {
    local file="$1"
    echo "=== Mobile Compatibility Check: $file ==="

    # Get stream info
    # default=nw=1:nk=1 prints one bare value; csv=p=0 appends a trailing
    # comma when side data (e.g. a display rotation matrix) is present
    PROFILE=$(ffprobe -v error -select_streams v:0 -show_entries stream=profile -of default=nw=1:nk=1 "$file")
    LEVEL=$(ffprobe -v error -select_streams v:0 -show_entries stream=level -of default=nw=1:nk=1 "$file")
    PIX_FMT=$(ffprobe -v error -select_streams v:0 -show_entries stream=pix_fmt -of default=nw=1:nk=1 "$file")
    CODEC=$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$file")
    AUDIO_CODEC=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name -of default=nw=1:nk=1 "$file")

    echo "Video Codec: $CODEC"
    echo "Profile: $PROFILE"
    echo "Level: $LEVEL"
    echo "Pixel Format: $PIX_FMT"
    echo "Audio Codec: $AUDIO_CODEC"

    # Check for common mobile issues
    [[ "$PIX_FMT" != "yuv420p" ]] && echo "WARNING: Pixel format $PIX_FMT not supported on mobile (need yuv420p)"
    # level_idc scales differ: H.264 uses 10x the level (41 = 4.1), HEVC 30x (123 = 4.1)
    if [[ "$CODEC" == "h264" && "$LEVEL" -gt 41 ]] || [[ "$CODEC" == "hevc" && "$LEVEL" -gt 123 ]]; then
        echo "WARNING: Level $LEVEL may not play on older mobile devices (max 4.1 recommended)"
    fi
    [[ "$CODEC" == "hevc" ]] && echo "WARNING: HEVC/H.265 not universally supported on Android browsers"
    [[ -n "$AUDIO_CODEC" && "$AUDIO_CODEC" != "aac" ]] && echo "WARNING: Audio codec $AUDIO_CODEC may not be supported (use AAC)"

    # Check moov atom placement
    echo ""
    echo "Checking moov atom placement..."
    ffprobe -v trace "$file" 2>&1 | grep -E "type:'(moov|mdat)'" | head -2
    echo "(moov should appear BEFORE mdat for mobile streaming)"
}

check_mobile_compat INPUT
```

### Common Mobile Incompatibilities

| Issue | Symptom | Diagnosis | Fix |
|-------|---------|-----------|-----|
| H.264 High profile on old Android | Black screen, no playback | `profile=High`, `level=51` | Re-encode with `-profile:v main -level 4.0` |
| Missing faststart | Long delay before playback | moov after mdat in trace | Add `-movflags +faststart` |
| Wrong pixel format | Green/purple video or no playback | `pix_fmt=yuv444p` or `yuv422p` | Add `-pix_fmt yuv420p` |
| HEVC on Android Chrome | Audio plays, no video | `codec_name=hevc` | Re-encode with `-c:v libx264` |
| HEVC on Apple devices | Not recognized, or QuickTime refuses the file | `codec_tag_string=hev1` | Remux with `-c copy -tag:v hvc1` |
| High AAC profile | No audio on some devices | HE-AAC v2 | Use `-c:a aac -profile:a aac_low` |
| No moov atom (truncated file) | Will not open anywhere: `moov atom not found` | Recording or upload was cut off | See ["moov atom not found"](#moov-atom-not-found) |

### Verify Moov Atom Placement

```bash
# Check if moov atom is at the start (required for mobile streaming)
ffprobe -v trace INPUT 2>&1 | grep -E "type:'(moov|mdat)'" | head -4

# If moov appears AFTER mdat, fix it without re-encoding:
ffmpeg -i INPUT -c copy -movflags +faststart OUTPUT.mp4
```

### Platform Requirements

- **iOS Safari:** H.264 Baseline/Main/High (no High 4:4:4 Predictive), `yuv420p`, AAC-LC audio (Opus/Vorbis support varies by iOS version), faststart. Inline playback needs the `playsinline` attribute and autoplay needs `muted` in the HTML (not an FFmpeg issue).
- **Android WebView:** more limited than Chrome; H.264 Main at level 3.1 with AAC-LC stereo is the safe choice.
- **Audio on mobile browsers:** AAC-LC is the only universally safe codec. These may fail: HE-AAC v2, Opus or Vorbis in MP4, AC-3/E-AC-3 (Apple devices generally decode these; many Android browsers do not).

```bash
# Check audio codec compatibility
ffprobe -v error -select_streams a:0 \
  -show_entries stream=codec_name,profile,sample_rate,channels \
  -of default=noprint_wrappers=1 INPUT

# Fix only the audio for universal mobile playback
ffmpeg -i INPUT -c:v copy \
  -c:a aac -profile:a aac_low -b:a 128k -ar 44100 -ac 2 \
  OUTPUT_fixed_audio.mp4
```

The fixing encodes are in `fundamentals-common-operations.md`: [Universal Mobile / iOS Safari](fundamentals-common-operations.md#universal-mobile--ios-safari), [Android Compatibility](fundamentals-common-operations.md#android-compatibility), and, for Android WebView (H.264 Main 3.1, up to 720p30), [Low-Bandwidth Mobile](fundamentals-common-operations.md#low-bandwidth-mobile) (its audio is 64k mono; use `-b:a 128k -ac 2` for stereo).

### Smart TV and Media Players

TVs, consoles and streaming sticks play files from USB or a DLNA/Plex server with a fixed set of hardware decoders, and many skip whatever they cannot decode (no sound, black picture, missing subtitles) instead of reporting an error. Probe every stream first:

```bash
ffprobe -v error \
  -show_entries stream=index,codec_type,codec_name,profile,level,pix_fmt,field_order,channels:format=format_name \
  -of compact=p=0 INPUT
```

| Problem in the probe | Typical TV result | Fix |
|---|---|---|
| Audio `dts`, `truehd`, `opus`, `flac` | Picture, no sound | AC-3 (keeps 5.1) or AAC stereo |
| `pix_fmt` ending in `10le`, or `hevc`/`av1` on a TV older than ~2016 | Black screen, stutter, or "unsupported" | 8-bit H.264 High, `yuv420p` |
| `level` above 41 for H.264 (4K, or 1080p60 at 4.2+) | Refuses the file or stutters | Scale to 1080p and cap at 30 fps, `-level 4.1` |
| Subtitle `hdmv_pgs_subtitle` (bitmap) or `ass` | Subtitles missing, or styling lost | Text subtitles to SRT; bitmap or styled ones burned in |
| `field_order` `tt`/`bb`/`tb`/`bt`, or a phone video with variable frame rate | Combing, judder, A/V drift | Deinterlace; force a constant frame rate |
| Container MKV on a player that wants MP4 (or the reverse) | File not listed or "unsupported" | Remux with `-c copy` |

```bash
# Audio only: copy video and subtitles, convert every audio track to AC-3
# (640k is AC-3's maximum; 5.1 stays 5.1). MKV keeps all tracks.
ffmpeg -i INPUT.mkv -map 0 -c copy -c:a ac3 -b:a 640k OUTPUT.mkv

# Stereo TV or soundbar-less setup: first audio track to AAC stereo
ffmpeg -i INPUT.mkv -map 0:v:0 -map 0:a:0 -c:v copy \
  -c:a aac -b:a 192k -ac 2 -movflags +faststart OUTPUT.mp4

# Full compatibility encode: 8-bit H.264 High at level 4.1 (1080p30 at most;
# smaller sources are not upscaled), AC-3 audio, text subtitles as SRT
# (bitmap PGS cannot convert to SRT: drop -map 0:s? and burn them in instead).
# For 1080p60 use -level 4.2 and drop the fps cap if the TV supports 4.2.
# 10-bit HDR sources need tone mapping first or they look washed out
# (color-chromakey.md, HDR to SDR Tone Mapping).
ffmpeg -i INPUT.mkv -map 0:v:0 -map 0:a:0 -map 0:s? \
  -vf "scale=-2:'min(1080,ih)',fps='min(30,source_fps)',format=yuv420p" \
  -c:v libx264 -preset slow -crf 20 -profile:v high -level 4.1 \
  -c:a ac3 -b:a 640k -c:s srt OUTPUT.mkv

# ASS/SSA subtitles to plain SRT (styling and positioning are dropped)
ffmpeg -i INPUT.mkv -map 0 -c copy -c:s srt OUTPUT.mkv

# Or a sidecar SRT next to the video (same base name; most TVs pick it up)
ffmpeg -i INPUT.mkv -map 0:s:0 OUTPUT.srt

# Burn styled ASS subtitles into the picture (si = subtitle stream index)
ffmpeg -i INPUT.mkv -map 0:v:0 -map 0:a:0 \
  -vf "subtitles=INPUT.mkv:si=0,scale=-2:'min(1080,ih)',fps='min(30,source_fps)',format=yuv420p" \
  -c:v libx264 -crf 20 -profile:v high -level 4.1 -c:a ac3 -b:a 640k OUTPUT.mkv

# Burn PGS (bitmap) subtitles: they cannot become text without OCR, so overlay
# them (the PGS canvas normally matches the video size)
ffmpeg -i INPUT.mkv -filter_complex "[0:v:0][0:s:0]overlay,format=yuv420p[v]" \
  -map "[v]" -map 0:a:0 -c:v libx264 -crf 20 -profile:v high -level 4.1 \
  -c:a ac3 -b:a 640k OUTPUT.mkv

# Interlaced source: one frame per frame (send_frame keeps 25/30 fps, inside
# level 4.1 at 1080p); see deinterlace.md for field order and telecine
ffmpeg -i INPUT -vf "bwdif=mode=send_frame,format=yuv420p" \
  -c:v libx264 -crf 20 -profile:v high -level 4.1 -c:a ac3 -b:a 640k OUTPUT.mkv

# Variable frame rate (phone or screen recording): constant 30 fps
# (use the source's nominal rate, e.g. 30000/1001, when it is not 30)
ffmpeg -i INPUT.mp4 -vf "fps=30,format=yuv420p" \
  -c:v libx264 -crf 20 -profile:v high -level 4.1 -c:a aac -b:a 192k \
  -movflags +faststart OUTPUT.mp4

# MKV to MP4 for a player that only lists MP4 (text subtitles become mov_text;
# PGS cannot go into MP4, so burn it in or drop it with -sn). This copies the
# audio: convert DTS/TrueHD first (above) or add -c:a aac -b:a 192k -ac 2.
ffmpeg -i INPUT.mkv -map 0:v -map 0:a -map 0:s? -c copy -c:s mov_text \
  -movflags +faststart OUTPUT.mp4
```

- **MKV or MP4:** most TVs since about 2014 play MKV from USB and show its SRT tracks; some players, game consoles and DLNA renderers list only MP4. MP4 cannot hold PGS, and many TVs ignore `mov_text` tracks, so a sidecar `.srt` is the safest subtitle choice there.
- **Check the TV's manual** for its codec list: "HEVC 4K" support often means 8-bit only, or HEVC only from its own apps, not from USB.

## Checklist

- The exact error line is identified (re-run with `-v error`, or `-v verbose` for context).
- The root cause is confirmed with `ffprobe` before changing the command.
- The fix is tested on a short slice (`-t 10`) first.
- The output is re-probed and, for corruption fixes, decoded end to end (`-v error -f null -`) with no errors printed.
- If the first fix fails, an alternative is tried (re-encode instead of copy, a different container, or `-fflags +genpts`).
