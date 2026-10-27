# Streaming

Streaming output (HLS, DASH, RTMP/RTMPS, SRT, WHIP), muxer options (segment, movflags, MPEG-TS, Matroska), and receiving and recording streams. Screen, camera and audio capture, raw video input, and testing a push without a server are in `capture.md`.

## Contents

- [Muxer, Demuxer and Protocol Options](#muxer-demuxer-and-protocol-options)
- [Keyframe Alignment](#keyframe-alignment)
- [HLS](#hls)
- [DASH](#dash)
- [RTMP / RTMPS Push (Twitch, YouTube)](#rtmp--rtmps-push-twitch-youtube)
- [Hardware Encoding for Live](#hardware-encoding-for-live)
- [SRT](#srt)
- [WHIP (WebRTC, 8.0+)](#whip-webrtc-80)
- [Receiving and Recording Streams](#receiving-and-recording-streams)
- [Segment Muxer](#segment-muxer)
- [MP4/MOV Muxer Flags (-movflags)](#mp4mov-muxer-flags--movflags)
- [MPEG-TS Muxer](#mpeg-ts-muxer)
- [Matroska/WebM Muxer](#matroskawebm-muxer)
- [Verification Status](#verification-status)

## Muxer, Demuxer and Protocol Options

These options belong to **specific muxers/demuxers/protocols**, not the main FFmpeg options. They are passed using `-option value` syntax and follow the same position rule as other per-file options: muxer options go after the inputs, with the output they apply to; demuxer and protocol options go before the `-i` they apply to. A muxer option placed before `-i` fails (`Option hls_time not found.`). A muxer option given to a different muxer (for example `-hls_time` on an `.mp4` output) is silently ignored, so check the output.

List a component's options on the installed build:

```bash
ffmpeg -h muxer=hls        # also: muxer=dash, muxer=flv, muxer=mpegts, muxer=segment
ffmpeg -h demuxer=x11grab  # also: demuxer=v4l2, demuxer=pulse
ffmpeg -h protocol=srt     # also: protocol=rtmp
```

## Keyframe Alignment

Segmented formats (HLS, DASH) can only cut at keyframes, and ABR players switch renditions at segment boundaries, so every rendition needs keyframes at the same times. Live platforms ask for a fixed keyframe interval (usually 2 s) for the same reason.

```bash
# Fixed GOP: keyframe every 2 s at 30 fps (-g = 2 x fps), no extra keyframes at
# scene cuts (-sc_threshold 0), no shorter GOPs (-keyint_min = -g)
-g 60 -keyint_min 60 -sc_threshold 0

# Frame-rate independent: force a keyframe every 2 s of timestamp
-force_key_frames "expr:gte(t,n_forced*2)"
```

`-sc_threshold` is an x264/x265 option. Other encoders: use `-force_key_frames`, or check `ffmpeg -h encoder=NAME` for their GOP options (NVENC honours `-g`; SVT-AV1 takes `-g` and `-svtav1-params keyint=...`). Make the segment duration (`-hls_time`, `-seg_duration`) a multiple of the keyframe interval, or segments come out longer than requested.

## HLS

### VOD

```bash
# Single-rendition VOD: 4 s segments, playlist marked complete (vod)
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 21 -preset medium -pix_fmt yuv420p \
  -force_key_frames "expr:gte(t,n_forced*2)" \
  -c:a aac -b:a 128k -ac 2 \
  -f hls -hls_time 4 -hls_playlist_type vod \
  -hls_segment_filename "seg_%03d.ts" \
  index.m3u8
```

`-hls_playlist_type vod` lists every segment and ends with `#EXT-X-ENDLIST`; `event` keeps all segments but leaves the playlist open (growing live event). The default `-hls_time` is 2 s.

### Live (sliding window)

```bash
ffmpeg -i input.mp4 -c copy \
  -hls_time 10 \
  -hls_list_size 6 \
  -hls_segment_filename "seg_%03d.ts" \
  -hls_flags delete_segments \
  playlist.m3u8
```

`-hls_list_size 6` keeps the last 6 segments in the playlist (0 = keep all); `delete_segments` removes older files from disk. Add `-re` before `-i` when the input is a file that should be sent at real-time speed. `-c copy` only works when the source keyframes already fit the segment length.

### fMP4 Segments (CMAF)

```bash
# Fragmented MP4 segments instead of MPEG-TS (needed for HEVC in HLS on Apple
# devices, and shareable with DASH)
ffmpeg -i input.mp4 \
  -c:v libx264 -crf 21 -pix_fmt yuv420p -force_key_frames "expr:gte(t,n_forced*2)" \
  -c:a aac -b:a 128k \
  -f hls -hls_time 4 -hls_playlist_type vod \
  -hls_segment_type fmp4 -hls_fmp4_init_filename init.mp4 \
  -hls_segment_filename "seg_%03d.m4s" \
  index.m3u8
```

For HEVC in fMP4 HLS add `-tag:v hvc1`.

### ABR Ladder (master playlist)

One command encodes four renditions and writes a master playlist that points at one media playlist per rendition. `-var_stream_map` groups the output streams into variants; `%v` in the paths is replaced by the variant index. The HLS muxer creates the `v0`...`v3` directories.

```bash
ffmpeg -i input.mp4 \
  -filter_complex "\
    [0:v]split=4[v1][v2][v3][v4];\
    [v1]scale=-2:1080[1080p];\
    [v2]scale=-2:720[720p];\
    [v3]scale=-2:480[480p];\
    [v4]scale=-2:360[360p]" \
  -map "[1080p]" -map "[720p]" -map "[480p]" -map "[360p]" \
  -map 0:a:0 -map 0:a:0 -map 0:a:0 -map 0:a:0 \
  -c:v libx264 -preset medium -pix_fmt yuv420p \
  -g 48 -keyint_min 48 -sc_threshold 0 \
  -b:v:0 5M    -maxrate:v:0 5.5M -bufsize:v:0 10M \
  -b:v:1 2.5M  -maxrate:v:1 2.8M -bufsize:v:1 5M \
  -b:v:2 1M    -maxrate:v:2 1.2M -bufsize:v:2 2M \
  -b:v:3 500k  -maxrate:v:3 600k -bufsize:v:3 1M \
  -c:a aac -ac 2 \
  -b:a:0 192k -b:a:1 128k -b:a:2 96k -b:a:3 64k \
  -f hls -hls_time 4 -hls_playlist_type vod \
  -hls_segment_filename "v%v/seg_%03d.ts" \
  -master_pl_name master.m3u8 \
  -var_stream_map "v:0,a:0 v:1,a:1 v:2,a:2 v:3,a:3" \
  "v%v/index.m3u8"
```

- `-g 48` gives a 2 s GOP at 24 fps; use 2 x fps for other rates, or `-force_key_frames "expr:gte(t,n_forced*2)"`.
- `scale=-2:1080` keeps the aspect ratio and an even width. Drop rungs above the source height instead of upscaling.
- `-maxrate` about 1.1 x and `-bufsize` 2 x the target bitrate keep each rendition near its advertised bandwidth.
- Name the variants with `name:` in the map, e.g. `"v:0,a:0,name:1080p v:1,a:1,name:720p ..."`; `%v` then expands to the name (`v1080p/index.m3u8`).
- A shared audio-only rendition: map one audio stream and use `agroup:` (see `ffmpeg -h muxer=hls` and the FFmpeg formats documentation for `var_stream_map`).

The same ladder as separate MP4 files (no HLS packaging) and GPU versions: `filter-complex.md` (Stream Splitting) and `hwaccel-nvidia-nvenc.md`.

## DASH

```bash
# Copy into DASH (keyframes must already be regular)
ffmpeg -i input.mp4 -c copy \
  -f dash \
  -seg_duration 4 \
  -init_seg_name 'init_$RepresentationID$.m4s' \
  manifest.mpd

# Two video renditions + one audio, grouped into adaptation sets
ffmpeg -i input.mp4 \
  -filter_complex "[0:v]split=2[a][b];[a]scale=-2:720[v720];[b]scale=-2:480[v480]" \
  -map "[v720]" -map "[v480]" -map 0:a:0 \
  -c:v libx264 -pix_fmt yuv420p -force_key_frames "expr:gte(t,n_forced*2)" \
  -b:v:0 2.5M -b:v:1 1M -c:a aac -b:a 128k \
  -f dash -seg_duration 4 \
  -adaptation_sets "id=0,streams=v id=1,streams=a" \
  manifest.mpd
```

`-adaptation_sets` groups output streams by index (`streams=0,1`) or by type (`streams=v`, `streams=a`). `-hls_playlist 1` writes HLS playlists next to the MPD from the same segments. Live DASH: add `-window_size` (segments kept in the manifest), `-extra_window_size` and `-remove_at_exit 1`; `-ldash 1 -streaming 1` enables low-latency DASH.

## RTMP / RTMPS Push (Twitch, YouTube)

```bash
# Server URL and stream key from the platform dashboard, kept out of the
# command line history, e.g.:
#   export RTMP_URL="rtmp://ingest.example.com/app"   (rtmps://... for TLS)
#   export STREAM_KEY="..."
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p \
  -b:v 6000k -maxrate 6000k -bufsize 12000k \
  -g 60 -keyint_min 60 -sc_threshold 0 \
  -c:a aac -b:a 160k -ar 48000 -ac 2 \
  -f flv "$RTMP_URL/$STREAM_KEY"
```

- **CBR-like rate:** `-b:v` equal to `-maxrate`, `-bufsize` 2 x. Live platforms want a steady bitrate.
- **Keyframes every 2 s:** `-g` = 2 x fps (60 at 30 fps, 120 at 60 fps).
- **Preset:** `veryfast` or `faster` so the encoder keeps up in real time. Watch the `speed=` value in the log: below 1.0x the stream stalls. Use a faster preset or lower resolution if it drops.
- **Audio:** AAC, 160k, 44.1 or 48 kHz, stereo.
- **Container:** `-f flv` for `rtmp://` and `rtmps://` URLs (RTMPS needs a TLS-enabled build; check `ffmpeg -protocols | grep rtmps`).
- `-re` reads a file at its native rate. Leave it out for live sources (capture devices are real-time already).
- Test the command against a local file first: [Testing Without a Server or Device](capture.md#testing-without-a-server-or-device).
- Platforms publish current recommended bitrates and resolutions per tier (e.g. 1080p60 at 6000 kb/s is a common cap). Check the platform's current guide before choosing.

### Push to Several Platforms at Once

```bash
# Encode once, send to two RTMP servers. onfail=ignore keeps one going if the other drops
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p \
  -b:v 6000k -maxrate 6000k -bufsize 12000k -g 60 -keyint_min 60 -sc_threshold 0 \
  -c:a aac -b:a 160k -ar 48000 \
  -map 0:v -map 0:a -flags +global_header \
  -f tee "[f=flv:onfail=ignore]$RTMP_URL_1/$KEY_1|[f=flv:onfail=ignore]$RTMP_URL_2/$KEY_2"
```

## Hardware Encoding for Live

```bash
# NVENC low-latency RTMP push (keeps decode and encode on the GPU)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda \
  -i input \
  -c:v h264_nvenc -preset p3 -tune ll -zerolatency 1 \
  -rc cbr -b:v 6M -maxrate 6M -bufsize 12M \
  -g 120 -keyint_min 120 \
  -c:a aac -b:a 160k \
  -f flv "$RTMP_URL/$STREAM_KEY"
```

- `-tune ll` (low latency) or `ull` (ultra low latency) and `-zerolatency 1` (no reordering delay) cut encoder latency; `-preset p3` trades some quality for speed.
- `-g 120` is a 2 s GOP at 60 fps.
- Other vendors: `h264_qsv`, `h264_vaapi`, `h264_amf`, `h264_videotoolbox` take the same `-b:v`/`-maxrate`/`-bufsize`/`-g` options; see `hwaccel.md`.

## SRT

SRT (Secure Reliable Transport) carries MPEG-TS over UDP with retransmission. Options go in the URL query or as protocol options before the URL. `latency` is in **microseconds** in FFmpeg (200000 = 200 ms).

```bash
# Push (caller) to an SRT server or receiver
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p -b:v 4M -maxrate 4M -bufsize 8M -g 60 \
  -c:a aac -b:a 128k \
  -f mpegts "srt://receiver.example.com:9000?mode=caller&latency=200000&pkt_size=1316"

# Listen for one caller and record what it sends
ffmpeg -i "srt://0.0.0.0:9000?mode=listener" -c copy recording.ts

# Serve as listener: wait for a receiver to connect, then send
ffmpeg -re -i input.mp4 -c copy -f mpegts "srt://0.0.0.0:9000?mode=listener"

# Encrypted: both ends use the same passphrase (at least 10 characters)
ffmpeg -re -i input.mp4 -c copy -f mpegts \
  "srt://receiver.example.com:9000?passphrase=$SRT_PASSPHRASE&pbkeylen=16"
```

`pkt_size=1316` fits seven 188-byte TS packets per datagram. `streamid=` passes a stream identifier that some servers (SRT Live Server, MediaMTX) use for routing.

## WHIP (WebRTC, 8.0+)

FFmpeg 8.0 added a WHIP muxer (`-f whip`) that publishes to a WebRTC server over HTTP signalling. It needs a build with the muxer and a TLS library that supports DTLS (OpenSSL). Check with `ffmpeg -muxers | grep whip`. WebRTC allows no B-frames, so set `-bf 0`, and send Opus audio.

```bash
ffmpeg -re -i input.mp4 \
  -c:v libx264 -preset veryfast -tune zerolatency -bf 0 -g 60 -pix_fmt yuv420p -b:v 2500k \
  -c:a libopus -b:a 128k -ar 48000 -ac 2 \
  -f whip "https://whip.example.com/publish/STREAM"

# NVENC variant (frames stay on the GPU)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input \
  -c:v h264_nvenc -preset p4 -tune ll -bf 0 \
  -c:a libopus -b:a 128k -ar 48000 \
  -f whip "https://whip.example.com/publish/STREAM"
```

Authentication tokens and other options: `ffmpeg -h muxer=whip` on a build that has it.

## Receiving and Recording Streams

```bash
# RTSP camera over TCP (UDP drops packets on lossy links)
ffmpeg -rtsp_transport tcp -i "rtsp://server/stream" -c copy output.mkv

# RTMP input with a larger client buffer (ms)
ffmpeg -rtmp_buffer 1000 -i "rtmp://server/live/stream" -c copy output.mkv

# Download an HLS stream without re-encoding
ffmpeg -i "https://example.com/stream/index.m3u8" -c copy output.mkv

# Re-stream an RTSP camera to an RTMP server without re-encoding
# (works when the camera sends H.264 + AAC; otherwise re-encode the audio)
ffmpeg -rtsp_transport tcp -i "rtsp://camera/stream" -c copy -f flv "$RTMP_URL/$STREAM_KEY"
```

Record live input to MKV or MPEG-TS rather than MP4: an interrupted MP4 has no index (`moov atom not found`), while MKV and TS stay playable up to the cut. Remux to MP4 afterwards with `-c copy`.

## Segment Muxer

```bash
# -reset_timestamps 1 makes every segment start at 0 (otherwise segment N
# starts at about N*60 s)
ffmpeg -i input.mp4 -c copy \
  -f segment \
  -segment_time 60 \
  -reset_timestamps 1 \
  -segment_list playlist.txt \
  -segment_format mp4 \
  output_%03d.mp4

# Hourly files from a live source, named by wall-clock time
ffmpeg -rtsp_transport tcp -i "rtsp://camera/stream" -c copy \
  -f segment -segment_time 3600 -segment_atclocktime 1 -strftime 1 \
  -reset_timestamps 1 "cam_%Y-%m-%d_%H-%M-%S.mkv"
```

With `-c copy`, segments split at the first keyframe after each `-segment_time`, so lengths vary with the source GOP.

## MP4/MOV Muxer Flags (-movflags)

```bash
# Fast start (move moov atom to beginning for web)
ffmpeg -i input.mp4 -c copy -movflags +faststart output.mp4

# Fragmented MP4 (for DASH/streaming)
ffmpeg -i input.mp4 -c copy -movflags +frag_keyframe+empty_moov output.mp4

# Fragmented, with a separate moof/mdat pair per track in each fragment
ffmpeg -i input.mp4 -c copy -movflags +frag_keyframe+separate_moof output.mp4

# Fragmented MP4 for DASH/MSE players (faststart is not needed: with
# empty_moov the moov is already at the front, and faststart is ignored)
ffmpeg -i input.mp4 -c copy \
  -movflags +frag_keyframe+empty_moov+default_base_moof \
  output.mp4
```

| Flag | Description |
|------|-------------|
| `faststart` | Move moov before mdat (web streaming) |
| `frag_keyframe` | Fragment at each keyframe |
| `empty_moov` | Empty initial moov (DASH) |
| `separate_moof` | Write separate moof/mdat atoms for each track |
| `default_base_moof` | Base offset at moof (DASH) |
| `negative_cts_offsets` | Allow negative CTS offsets |
| `isml` | IIS Smooth Streaming |
| `omit_tfhd_offset` | Omit offset in tfhd |
| `disable_chpl` | Disable the Nero chapter atom (`chpl`); QuickTime-style chapters are still written |
| `write_colr` | Write colr atom |
| `write_gama` | Write gama atom |

A fragmented MP4 also survives an interrupted recording (each fragment is self-contained), which makes it a safer MP4 choice for live capture.

## MPEG-TS Muxer

```bash
# Keep the input timestamps (no initial offset added; default shifts start ~1.4 s)
ffmpeg -i input.mp4 -c copy -mpegts_copyts 1 output.ts

# PCR is always written; -pcr_period sets its interval in ms (default -1 = auto)
ffmpeg -i input.mp4 -c copy -pcr_period 20 output.ts

# Set service info
ffmpeg -i input.mp4 -c copy \
  -mpegts_service_id 1 \
  -mpegts_service_type digital_tv \
  output.ts
```

## Matroska/WebM Muxer

```bash
# Move the Cues (seek index) to the front of the file (better for web seeking)
ffmpeg -i input.mp4 -c:v libvpx-vp9 -cues_to_front 1 output.webm

# Set cluster size
ffmpeg -i input.mp4 -c copy -cluster_size_limit 2M output.mkv
```

## Verification Status

Checked on FFmpeg 8.0.1 (Linux, no NVIDIA GPU, no VAAPI driver):

- **Run:** HLS VOD, live, fMP4 and the ABR ladder (smaller rungs; master playlist and four variant playlists checked), both DASH commands, the RTMP push settings, tee and SRT encoding written to local files, keyframe interval check, segment and movflags examples.
- **Help-checked only** (`ffmpeg -h`): SRT URL options (no second process to connect to), NVENC live options, MPEG-TS and Matroska options.
- **Not verifiable here:** WHIP (muxer absent from this build).
