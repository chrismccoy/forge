# Capture

Screen, camera and audio capture on Linux, Windows and macOS, raw video input, and testing streaming commands with generated sources instead of a device or server. Streaming output (HLS, DASH, RTMP, SRT, WHIP) and muxer options are in `streaming.md`.

## Contents

- [Raw Video Input](#raw-video-input)
- [Capture Sources](#capture-sources)
- [Testing Without a Server or Device](#testing-without-a-server-or-device)
- [Verification Status](#verification-status)

## Raw Video Input

```bash
ffmpeg -f rawvideo -video_size 1920x1080 -pix_fmt yuv420p -framerate 30 \
  -i input.yuv output.mp4
```

## Capture Sources

Capture inputs are real-time, so the encoder must keep up: use `-preset ultrafast`/`veryfast` (or a hardware encoder) and watch `speed=` in the log. Give each live input `-thread_queue_size 1024` (before its `-i`) when combining screen and audio, or FFmpeg warns `Thread message queue blocking` and drops data. Press `q` to stop cleanly so the file is finalized.

### Linux: Screen (X11)

```bash
# Full screen of display :0, 30 fps, with the mouse pointer
ffmpeg -f x11grab -video_size 1920x1080 -framerate 30 -draw_mouse 1 -i :0.0 \
  -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p screen.mkv

# A 1280x720 region starting at x=100, y=200
ffmpeg -f x11grab -video_size 1280x720 -framerate 30 -i :0.0+100,200 \
  -c:v libx264 -preset ultrafast -crf 18 -pix_fmt yuv420p region.mkv

# Screen plus desktop audio (a PulseAudio/PipeWire monitor source)
ffmpeg -thread_queue_size 1024 -f x11grab -video_size 1920x1080 -framerate 30 -i :0.0 \
  -thread_queue_size 1024 -f pulse -i default \
  -c:v libx264 -preset veryfast -crf 20 -pix_fmt yuv420p -c:a aac -b:a 160k screen.mkv
```

`-video_size` must fit inside the screen; leave it out to capture the whole screen. Other x11grab options: `-follow_mouse centered`, `-show_region 1`, `-select_region 1` (pick with the pointer), `-window_id`. List them with `ffmpeg -h demuxer=x11grab`.

### Linux: Screen (KMS, Wayland)

On a Wayland session, x11grab sees only XWayland windows; native Wayland windows come out black or missing. Wayland screen capture goes through the xdg-desktop-portal and PipeWire, which this FFmpeg has no input device for. Options:

- **kmsgrab** reads the DRM framebuffer directly (any session, also the console). It needs `CAP_SYS_ADMIN` (run as root or `setcap cap_sys_admin+ep` on the binary) and gives hardware frames, so map them to VAAPI:

  ```bash
  # Zero-copy capture and VAAPI encode
  ffmpeg -device /dev/dri/card0 -framerate 30 -f kmsgrab -i - \
    -vf 'hwmap=derive_device=vaapi,scale_vaapi=w=1920:h=1080:format=nv12' \
    -c:v h264_vaapi capture.mkv

  # Download to the CPU for a software encoder
  ffmpeg -device /dev/dri/card0 -framerate 30 -f kmsgrab -i - \
    -vf 'hwmap=derive_device=vaapi,hwdownload,format=bgr0' \
    -c:v libx264 -preset ultrafast -pix_fmt yuv420p capture.mkv
  ```

- A PipeWire-aware recorder (OBS, `wf-recorder` on wlroots compositors, `gpu-screen-recorder`), then FFmpeg for the post-processing.

### Linux: Webcam (V4L2)

```bash
# List the formats, sizes and frame rates the camera offers
ffmpeg -f v4l2 -list_formats all -i /dev/video0

# Capture MJPEG 1280x720 at 30 fps (most USB cameras deliver higher frame rates
# as MJPEG than as raw YUYV) and encode to H.264
ffmpeg -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 30 -i /dev/video0 \
  -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p webcam.mkv
```

`v4l2-ctl --list-devices` (v4l-utils) names the devices; one camera often exposes two nodes, and only one of them delivers video.

### Linux: Audio (PulseAudio/PipeWire, ALSA)

```bash
# List PulseAudio/PipeWire sources (".monitor" sources capture what plays on an output)
ffmpeg -sources pulse

# Record the default input (microphone)
ffmpeg -f pulse -i default -c:a flac mic.flac

# Record a specific source by name from the list above
ffmpeg -f pulse -i alsa_output.pci-0000_00_1f.3.analog-stereo.monitor -c:a flac desktop.flac

# ALSA directly (card/device from arecord -l)
ffmpeg -f alsa -i hw:0,0 -c:a flac mic.flac
```

### Windows

```bash
# Desktop with GDI (works everywhere, CPU-heavy at high resolution)
ffmpeg -f gdigrab -framerate 30 -i desktop -c:v libx264 -preset ultrafast -pix_fmt yuv420p screen.mkv

# One window by title, or a region of the desktop
ffmpeg -f gdigrab -framerate 30 -i title="Untitled - Notepad" window.mkv
ffmpeg -f gdigrab -framerate 30 -offset_x 100 -offset_y 200 -video_size 1280x720 -i desktop region.mkv

# Desktop Duplication API (ddagrab filter, Windows 8+): frames stay on the GPU
# as D3D11 surfaces, so a hardware encoder takes them directly
ffmpeg -f lavfi -i ddagrab=framerate=60 -c:v h264_nvenc -cq 18 screen.mkv

# ddagrab with a software encoder: download and set the format explicitly
ffmpeg -filter_complex "ddagrab=output_idx=0:framerate=60,hwdownload,format=bgra" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p screen.mkv

# DirectShow: list devices, list one device's modes, then capture camera + mic
ffmpeg -list_devices true -f dshow -i dummy
ffmpeg -list_options true -f dshow -i video="Integrated Camera"
ffmpeg -f dshow -i video="Integrated Camera":audio="Microphone (Realtek Audio)" \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac webcam.mkv
```

Device names come from the `-list_devices` output; quote them exactly. ddagrab takes `video_size`, `offset_x` and `offset_y` for a region and `draw_mouse`; check `ffmpeg -h filter=ddagrab`.

### macOS (AVFoundation)

```bash
# List video devices (cameras and "Capture screen N") and audio devices
ffmpeg -f avfoundation -list_devices true -i ""

# Screen 1 with audio device 0 ("video:audio" indices from the list)
ffmpeg -f avfoundation -framerate 30 -capture_cursor 1 -i "1:0" \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac screen.mkv

# Camera 0 without audio ("none" for the audio side)
ffmpeg -f avfoundation -framerate 30 -video_size 1280x720 -i "0:none" \
  -c:v h264_videotoolbox -b:v 5M camera.mov
```

macOS asks for screen-recording and camera/microphone permission for the terminal app on first use; until it is granted, capture fails or records black frames. If the device rejects the default pixel format, add `-pixel_format uyvy422` (or `nv12`) before `-i`.

## Testing Without a Server or Device

Use `lavfi` sources in place of a camera or a file, and a local file in place of the server, to check a streaming command before going live:

```bash
# 5 s test pattern + tone, encoded exactly like the RTMP push, written to a file
ffmpeg -re -f lavfi -i testsrc2=size=1280x720:rate=30 -f lavfi -i sine=frequency=440:sample_rate=48000 -t 5 \
  -c:v libx264 -preset veryfast -pix_fmt yuv420p \
  -b:v 3000k -maxrate 3000k -bufsize 6000k -g 60 -keyint_min 60 -sc_threshold 0 \
  -c:a aac -b:a 160k -ar 48000 -ac 2 \
  -f flv test.flv

# Check the keyframe interval (prints the time of every keyframe)
ffprobe -v error -select_streams v:0 -skip_frame nokey -show_entries frame=pts_time \
  -of csv=p=0 test.flv
```

A local MediaMTX or nginx-rtmp server accepts RTMP, SRT and WHIP pushes for an end-to-end test. List a device's options without opening it: `ffmpeg -h demuxer=x11grab` (or `v4l2`, `pulse`, `alsa`, `dshow`, `avfoundation`, `gdigrab` on their platforms).

## Verification Status

Checked on FFmpeg 8.0.1 (Linux, no NVIDIA GPU, no VAAPI driver):

- **Run:** x11grab region capture on XWayland, pulse source listing, v4l2 format listing, the lavfi test-pattern push written to a file and its keyframe check.
- **Help-checked only** (`ffmpeg -h`): kmsgrab (needs root and VAAPI).
- **Not verifiable here:** gdigrab, ddagrab, dshow, avfoundation (other platforms).
