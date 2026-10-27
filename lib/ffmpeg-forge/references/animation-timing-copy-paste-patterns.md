# Quick Copy-Paste Timing Patterns

Battle-tested FFmpeg and ASS timing snippets ready to drop into commands.

## FFmpeg Common Timing Patterns

```bash
# 2-second fade in:
-vf "fade=t=in:d=2"

# Text visible from 1s to 5s:
-vf "drawtext=text='Hello':enable='between(t,1,5)':..."

# 1.5s xfade starting at 4s:
-filter_complex "[0:v][1:v]xfade=duration=1.5:offset=4"

# 2-second zoom at 30fps on a STILL image (single image input, 60 output frames).
# The scale+crop first matches the source to the 9:16 output; zoompan's s= would
# otherwise stretch a differently shaped source. A PNG input gives yuv444p, hence -pix_fmt.
ffmpeg -i still.png -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,zoompan=z='min(zoom+0.005,1.5)':d=60:s=1080x1920:fps=30" -pix_fmt yuv420p out.mp4

# 2-second zoom on VIDEO (d=1: one output frame per input frame, zoom driven by `it` seconds):
-vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,zoompan=z='1+0.5*min(it/2,1)':d=1:s=1080x1920:fps=30"

# Fade text in over 0.5s, hold, fade out over 0.3s (5s total):
-vf "drawtext=text='Hello':alpha='if(lt(t,0.5),t/0.5,if(lt(t,4.7),1,(5-t)/0.3))':enable='lt(t,5)':..."
```

## ASS Common Timing Patterns

```ass
; Word karaoke (centiseconds): 0.5s + 0.4s + 0.6s + 0.5s
{\k50}This {\k40}is {\k60}the {\k50}test

; 200ms pop animation (milliseconds):
{\fscx80\fscy80\t(0,200,\fscx100\fscy100)}Pop

; 500ms slide + 300ms fade:
{\move(0,1920,540,960,0,500)\fad(300,0)}Slide in

; Bounce: 150ms up, 100ms overshoot, 150ms settle (total 400ms)
{\fscx90\fscy90\t(0,150,\fscx110\fscy110)\t(150,250,\fscx95\fscy95)\t(250,400,\fscx100\fscy100)}Bounce
```

## Frame Rate Conversion Reference

| Frame Rate | 1 Frame Duration | 30 Frames | 60 Frames |
|------------|------------------|-----------|-----------|
| 24 fps | 41.67 ms | 1.25 s | 2.5 s |
| 25 fps | 40 ms | 1.2 s | 2.4 s |
| 30 fps | 33.33 ms | 1 s | 2 s |
| 50 fps | 20 ms | 0.6 s | 1.2 s |
| 60 fps | 16.67 ms | 0.5 s | 1 s |

### Zoompan Duration Calculation

```bash
# zoompan d= parameter is in FRAMES, not seconds, and it is the number of
# output frames produced PER INPUT FRAME. Use d>1 only with a single still
# image (no -loop). On video, d=60 turns every input frame into 60 frames
# (a 4 s 25 fps clip becomes 6000 frames = 4 minutes). zoompan's own output
# rate is fps= (default 25), not the input rate, so always set it.

# For 2-second zoom at 30fps (still image):
ffmpeg -i still.png -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,zoompan=z='min(zoom+0.005,1.5)':d=60:s=1080x1920:fps=30" -pix_fmt yuv420p output.mp4
# d=60 frames / fps=30 = 2 seconds

# For 2-second zoom at 60fps (still image):
ffmpeg -i still.png -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,zoompan=z='min(zoom+0.0025,1.5)':d=120:s=1080x1920:fps=60" -pix_fmt yuv420p output.mp4
# d=120 frames / fps=60 = 2 seconds

# Zoom over 2 seconds of a VIDEO: d=1, time from the input timestamp `it`
ffmpeg -i input.mp4 -vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,fps=30,zoompan=z='1+0.2*min(it/2,1)':d=1:s=1080x1920:fps=30" output.mp4
# duration stays equal to the input; zoom reaches 1.2 at t=2 s and holds

# Formula: frames = seconds * fps
```
