# FFmpeg drawtext Animation

Animated `drawtext` recipes: fades, motion, wobble, pulses, wipes, typewriter, sequential words, lower thirds, scrolling credits, tickers, countdowns, and size animation with a scaled text layer. Static text (fonts, escaping, boxes, timecode) is in `drawtext.md`. The math behind the easing and spring curves is in `easing-and-springs.md`. ASS-based word animation is in `kinetic-captions.md`.

A per-frame `fontsize` (using `t` or `n`) segfaults FFmpeg 8.0.1; size animations here scale a fixed-size text layer instead.

## Contents

- [Scaled Text Layer (Size Animation)](#scaled-text-layer-size-animation)
- [Fades and Blinking](#fades-and-blinking)
- [Moving Text](#moving-text)
- [Bounce, Wobble and Shake](#bounce-wobble-and-shake)
- [Pulses](#pulses)
- [Wipe Reveals](#wipe-reveals)
- [Typewriter](#typewriter)
- [Sequential Words](#sequential-words)
- [Animated Lower Third](#animated-lower-third)
- [Scrolling Credits](#scrolling-credits)
- [News Tickers](#news-tickers)
- [Countdowns and Stopwatches](#countdowns-and-stopwatches)
- [Rotation (ASS Only)](#rotation-ass-only)
- [Expression Reference](#expression-reference)
- [Sources](#sources)

Snippets that start with `-vf` slot into `ffmpeg -i input.mp4 ... output.mp4`. Add `-pix_fmt yuv420p` for delivery files.

## Scaled Text Layer (Size Animation)

Draw the text once at a fixed `fontsize` on a transparent canvas, scale that canvas per frame with `eval=frame`, and overlay it centred. Set the `color` source to the video's size and duration. `SCALE` is a shell variable holding any expression in `t` that gives the size factor (1 = the drawn size); the recipes in this file only set `SCALE`:

```bash
SCALE='0.5+0.5*min(1,t/0.5)'   # example: grow from 50% to 100% in 0.5 s
ffmpeg -i input.mp4 -filter_complex "\
  color=c=black@0:s=1920x1080:d=10,format=rgba,\
  drawtext=text='TEXT':fontsize=120:fontcolor=white:x=(w-tw)/2:y=(h-th)/2,\
  scale=w='iw*($SCALE)':h=-2:eval=frame[txt];\
  [0:v][txt]overlay=x=(W-w)/2:y=(H-h)/2:shortest=1,format=yuv420p[v]" \
  -map "[v]" -map 0:a? -c:a copy out.mp4
```

Factors above 1 enlarge the drawn glyphs (slightly soft). Draw at the largest size needed and keep factors at or below 1 for crisp text.

| Animation | `SCALE` |
|-----------|---------|
| Pop 50% -> 100% over 0.3 s, starting at t=0.5 (add `:enable='gte(t,0.5)'` to the overlay) | `0.5+0.5*clip((t-0.5)/0.3,0,1)` |
| Elastic: 100% -> ~132% -> ~80% -> ~113% -> ~92% -> ~105% -> 100%, settles in ~1.5 s | `1+0.4*exp(-t*3)*sin(t*20)` |
| Heartbeat: two quick beats, pause, every 1.2 s, up to +30% | `1+0.3*max(0,sin(t*15)*exp(-mod(t,1.2)*10))` |
| Alarm: one pulse every pi/8 = 0.39 s (~2.5 Hz), up to +25% | `1+0.25*abs(sin(t*8))` |
| Decay from 150% to 100% | `1+0.5*exp(-t*2)` |

The elastic factor has its first peak at ~132%, not 140%, because `exp(-3t)` has already decayed by the first sine peak at t~0.07 s. The ASS keyframed equivalent is the `elastic` preset in [`kinetic-captions.md`](kinetic-captions.md#quick-reference). More rhythms (resting heartbeat, walking pace, breathing): [Biological Rhythms](animation-timing.md#biological-rhythms).

### Pulsing in Place (Small Layer)

When the text is not centred, use a layer only as big as the text and overlay it at a fixed anchor, so it grows and shrinks around that point:

```bash
# Text pulses +/-11% at ~1.5 Hz, centred 150 px above the bottom
ffmpeg -i input.mp4 -filter_complex "\
  color=c=black@0:s=800x160:d=10,format=rgba,\
  drawtext=text='SUBSCRIBE':fontsize=72:fontcolor=yellow:x=(w-tw)/2:y=(h-th)/2:borderw=3:bordercolor=black,\
  scale=w='iw*(1+0.11*sin(t*9.42))':h=-2:eval=frame[txt];\
  [0:v][txt]overlay=x=(W-w)/2:y=H-150-h/2:shortest=1,format=yuv420p[v]" \
  -map "[v]" -map 0:a? -c:a copy output.mp4
# 9.42 rad/s = 1.5 Hz (1.5 * 2*pi = 9.42); d= must cover the video length
```

### Countdown that Pops Each Second

```bash
# The number is drawn on the transparent layer (text changes every second, size
# is fixed) and the layer is scaled: full size at each whole second, settling to
# 80% within it
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=10" -filter_complex "\
  color=c=black@0:s=1920x1080:d=10,format=rgba,\
  drawtext=text='%{eif\:10-floor(t)\:d}':fontsize=250:fontcolor=white:x=(w-tw)/2:y=(h-th)/2,\
  scale=w='iw*(0.8+0.2*exp(-(t-floor(t))*8))':h=-2:eval=frame[txt];\
  [0:v][txt]overlay=x=(W-w)/2:y=(H-h)/2:shortest=1,format=yuv420p[v]" \
  -map "[v]" countdown_pop.mp4

# %{eif\:10-floor(t)\:d} = countdown number (10, 9, 8, ...)
# exp(-(t-floor(t))*8) = 1 at each whole second, decaying within it
```

## Fades and Blinking

```bash
# Fade in over 2 s
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Title':fontsize=100:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(lt(t,2),t/2,1)'" \
  fade_in.mp4

# Fade out over the last 2 s of a 10 s video
ffmpeg -i input.mp4 \
  -vf "drawtext=text='Goodbye':fontsize=100:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(gt(t,8),1-(t-8)/2,1)'" \
  fade_out.mp4

# Title card with fade in/out
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=6" \
  -vf "drawtext=text='Chapter One':fontsize=120:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2:\
       alpha='if(lt(t,1),t,if(gt(t,5),1-(t-5),1))'" \
  title_card.mp4

# Fade in 0.5 s, hold, fade out 0.3 s (5 s total)
-vf "drawtext=text='Hello':fontsize=64:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:\
     alpha='if(lt(t,0.5),t/0.5,if(lt(t,4.7),1,(5-t)/0.3))':enable='lt(t,5)'"

# Blinking text (on 0.5 s, off 0.5 s)
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BLINK':x=10:y=10:fontsize=36:fontcolor=red:alpha='if(mod(floor(t*2),2),1,0)'" \
  blink.mp4
```

Eased fades (exponential, sigmoid, cubic and the rest, on normalised progress) are in `easing-and-springs.md`.

## Moving Text

```bash
# Slide in from the right, stopping at the right edge after 1 s
ffmpeg -i input.mp4 \
  -vf "drawtext=text='SLIDE IN':fontsize=80:fontcolor=white:\
       x='if(lt(t,1),w-tw*(t),w-tw)':\
       y=(h-th)/2" \
  slide_in.mp4

# Slide in from the left
ffmpeg -i input.mp4 \
  -vf "drawtext=text='FROM LEFT':fontsize=80:fontcolor=white:\
       x='if(lt(t,1),-tw+tw*t,0)':\
       y=(h-th)/2" \
  slide_left.mp4

# Rise from the bottom to the top over 1 s
-vf "drawtext=text='RISING':fontsize=100:fontcolor=white:\
     x=(w-tw)/2:\
     y='if(lt(t,1),h-t*h,0)'"

# Horizontal ping-pong
ffmpeg -i input.mp4 \
  -vf "drawtext=text='PING PONG':fontsize=60:fontcolor=cyan:\
       x='(w-tw)/2+200*sin(t*3)':\
       y=(h-th)/2" \
  horizontal_bounce.mp4

# Circular orbit
ffmpeg -i input.mp4 \
  -vf "drawtext=text='ORBIT':fontsize=60:fontcolor=white:\
       x='(w/2)+200*cos(t*2)-tw/2':\
       y='(h/2)+200*sin(t*2)-th/2'" \
  orbit.mp4

# Split-flap drop: for the first 0.15 s of each second the new number drops
# in from 100 px above and settles (FFmpeg has no step(); use if()/lt())
-vf "drawtext=text='%{eif\:10-floor(t)\:d}':\
     fontsize=200:fontcolor=white:\
     x=(w-tw)/2:\
     y='(h-th)/2-100*if(lt(mod(t,1),0.15),1-mod(t,1)/0.15,0)'"
```

## Bounce, Wobble and Shake

```bash
# Continuous vertical bounce
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BOUNCE':fontsize=80:fontcolor=yellow:\
       x=(w-tw)/2:\
       y='(h-th)/2+50*sin(t*5)'" \
  bounce.mp4

# Spring entry: decaying bounce that settles at the centre, starting at t=1.
# Use (t-1), not t: with absolute t the bounce would have decayed by the time
# the text appears
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BOUNCE':fontsize=80:fontcolor=white:x=(w-tw)/2:y='(h-th)/2-30*exp(-(t-1)*3)*sin((t-1)*15)':borderw=3:bordercolor=black:enable='gte(t,1)'" \
  output.mp4

# Dual-frequency wobble (organic motion)
-vf "drawtext=text='WOBBLE':fontsize=80:fontcolor=white:\
     x='(w-tw)/2+8*sin(t*7)+4*sin(t*17)':\
     y='(h-th)/2+6*cos(t*7)+3*cos(t*13)'"

# Drunk/unstable (low frequency, large amplitude)
-vf "drawtext=text='UNSTABLE':fontsize=80:fontcolor=white:\
     x='(w-tw)/2+20*sin(t*2.5)+10*sin(t*6.3)':\
     y='(h-th)/2+15*cos(t*3.1)+8*cos(t*7.2)'"

# Shake on impact: decaying amplitude, starting at t=2 (decay uses t-2)
ffmpeg -i input.mp4 \
  -vf "drawtext=text='IMPACT':fontsize=100:fontcolor=white:x='(w-tw)/2+15*exp(-(t-2)*4)*sin((t-2)*50)':y='(h-th)/2+10*exp(-(t-2)*4)*cos((t-2)*47)':enable='gte(t,2)'" \
  output.mp4
```

Tuning:

- **Spring:** the decay rate (3) sets how fast it settles: 3-4 quick, 1-2 slow. The frequency (15 rad/s, ~2.4 Hz) sets the number of bounces: 10-12 slow, 15-20 fast. The amplitude (30) is the bounce height in pixels. Damping ratio and the critically damped form are in `easing-and-springs.md`.
- **Wobble:** two frequencies, the primary amplitude about twice the secondary. Frequency ratios that are not simple fractions (7 and 17) keep the pattern from visibly repeating.
- **Shake:** keep the amplitude at or below ~15% of the font size (rule of thumb).

## Pulses

Size pulses use the Scaled Text Layer (factor table above). Opacity pulses work on `alpha` directly:

```bash
# Breathing opacity between 40% and 100%, one cycle every 2 s
-vf "drawtext=text='LIVE':fontsize=64:fontcolor=red:x=20:y=20:alpha='0.7+0.3*sin(t*3.14)'"
```

## Wipe Reveals

```bash
# Left-to-right wipe: draw the text on a transparent layer, then zero its alpha
# right of X=T*500. (drawbox can't do this: its x/y/w/h are not evaluated per
# frame and its `t` option is the border thickness, not time.)
# Set the color source size to the video size.
-filter_complex "\
  color=c=black@0:s=1920x1080,format=rgba,\
  drawtext=text='REVEALED':fontsize=100:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2,\
  geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':a='if(lt(X,T*500),alpha(X,Y),0)'[txt];\
  [0:v][txt]overlay=shortest=1[v]" \
  -map "[v]"

# a='if(lt(X,T*500),...)' = visible region grows at 500 pixels/second
# (geq's time variable is uppercase T)
```

## Typewriter

### Growing Prefixes

Draw growing prefixes ('H', 'He', 'Hel', ...) at the same position, each visible in its own time slot. This keeps the font's real spacing (per-letter layers at fixed x offsets give uneven gaps). Use `gte(t,a)*lt(t,b)`, not `between()`, which is inclusive at both ends and draws two prefixes on the boundary frame:

```bash
# 0.1 s per character
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=3" \
  -vf "\
    drawtext=text='H':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.0)*lt(t,0.1)',\
    drawtext=text='He':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.1)*lt(t,0.2)',\
    drawtext=text='Hel':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.2)*lt(t,0.3)',\
    drawtext=text='Hell':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.3)*lt(t,0.4)',\
    drawtext=text='Hello':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.4)'" \
  -pix_fmt yuv420p typewriter.mp4
```

### Typewriter with Cursor

Put the cursor inside each prefix so it always sits right after the last character, then blink it after typing ends by alternating two layers:

```bash
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=3" \
  -vf "\
    drawtext=text='H|':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.0)*lt(t,0.1)',\
    drawtext=text='He|':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.1)*lt(t,0.2)',\
    drawtext=text='Hel|':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.2)*lt(t,0.3)',\
    drawtext=text='Hell|':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.3)*lt(t,0.4)',\
    drawtext=text='Hello|':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.4)*lt(mod(t,0.5),0.25)',\
    drawtext=text='Hello':x=100:y=500:fontsize=72:fontcolor=white:enable='gte(t,0.4)*gte(mod(t,0.5),0.25)'" \
  -pix_fmt yuv420p typewriter_cursor.mp4
```

### Long Text: ASS `\ko`

drawtext cannot reveal a textfile character by character (there is no substring function, and `eif()` exists only inside `text='%{eif:...}'`). For long text, use one ASS line: un-highlighted `\ko` karaoke text is drawn in SecondaryColour with no outline, so a fully transparent SecondaryColour (`&HFFFFFFFF`) hides each character until its `\ko` slot starts:

```bash
# 80 ms per character (\ko8): a slow, clear pace for teaching
TEXT="Photosynthesis converts light into energy"
KTEXT=$(printf '%s' "$TEXT" | sed 's/./{\\ko8}&/g')
cat > typewriter.ass <<EOF
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Type,Arial,48,&H00FFFFFF,&HFFFFFFFF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,0,7,50,50,100,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,0:00:10.00,Type,,0,0,0,,${KTEXT}
EOF
ffmpeg -i input.mp4 -vf "ass=typewriter.ass" -c:a copy typewriter.mp4
```

Typing speeds: 30-50 ms per character is fast, 50-80 ms normal, 80-120 ms slow (`animation-timing.md`).

## Sequential Words

```bash
# Word-by-word fade-in, stacked vertically (each word stays on screen)
ffmpeg -f lavfi -i "color=c=black:s=1080x1920:d=5" \
  -vf "\
    drawtext=text='THIS':fontsize=80:fontcolor=white:x=(w-tw)/2:y=h/2-80:alpha='if(lt(t-0.5,0.5),(t-0.5)*2,1)':enable='gte(t,0.5)',\
    drawtext=text='IS':fontsize=80:fontcolor=white:x=(w-tw)/2:y=h/2:alpha='if(lt(t-1,0.5),(t-1)*2,1)':enable='gte(t,1)',\
    drawtext=text='KINETIC':fontsize=80:fontcolor=yellow:x=(w-tw)/2:y=h/2+80:alpha='if(lt(t-1.5,0.5),(t-1.5)*2,1)':enable='gte(t,1.5)'" \
  kinetic_reveal.mp4
```

Words that pop in size need one Scaled Text Layer per word; ASS (`kinetic-captions.md`) is simpler for that.

## Animated Lower Third

```bash
# drawbox can't move over time (x/w are not per-frame expressions and its
# `t` is thickness), so slide a semi-transparent color layer with overlay,
# whose x/y are evaluated every frame.
ffmpeg -i input.mp4 \
  -filter_complex "\
    color=c=blue@0.7:s=500x100,format=rgba[box];\
    [0:v][box]overlay=x='if(lt(t,0.55),-500+1000*t,50)':y=H-150:\
            shortest=1:enable='between(t,0,8)',\
    drawtext=text='Name':fontsize=36:fontcolor=white:\
             x='if(lt(t,0.55),-480+1000*t,70)':y=h-140:\
             alpha='min(1,(t-0.3)/0.3)':\
             enable='between(t,0.3,8)',\
    drawtext=text='Title':fontsize=24:fontcolor=white:\
             x='if(lt(t,0.55),-480+1000*t,70)':y=h-100:\
             alpha='min(1,(t-0.5)/0.3)':\
             enable='between(t,0.5,8)'[v]" \
  -map "[v]" -map 0:a? -c:a copy animated_lower_third.mp4
```

A static lower third is in `drawtext.md`. Broadcast lower thirds usually enter in 400-600 ms (`animation-timing.md`).

## Scrolling Credits

`credits.txt` layout: a heading line, the names, a blank line between sections.

```text
DIRECTED BY
Name

PRODUCED BY
Name

STARRING
Actor One
Actor Two
```

### ASS Credits (Recommended on 8.0.1)

drawtext draws a missing-glyph box at the end of every line of a multi-line `textfile` on the FFmpeg 8.0.1 Ubuntu build (see `drawtext.md`). ASS has no such problem and centres every line. Join the lines with `\N` and scroll the block with `\move`:

```bash
# 1920x1080 canvas, 60 s roll from below the frame to above it
BODY=$(awk 'NR>1{printf "\\N"} {printf "%s", $0}' credits.txt)
cat > credits.ass <<EOF
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Credits,DejaVu Sans,48,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,1,0,8,0,0,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,0:01:00.00,Credits,,0,0,0,,{\an8\move(960,1080,960,-2400)}$BODY
EOF
ffmpeg -i input.mp4 -vf "ass=credits.ass" -c:v libx264 -crf 18 -pix_fmt yuv420p -c:a copy credits.mp4
```

`\move(x,y1,x,y2)` without times spans the whole line. Set `y2` to minus the block height (lines x line height) so the last line leaves the frame. Speed = (y1 - y2) / duration px/s.

### drawtext Credits

On builds that draw no box, a `textfile` scroll is one filter. `text_align=C` centres each line; without it the lines stay left-aligned inside a centred block:

```bash
# Start at the bottom (y=h), move up at 80 pixels/second
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=credits.txt:\
       fontfile=/path/to/font.ttf:\
       fontsize=48:fontcolor=white:text_align=C:\
       x=(w-tw)/2:\
       y=h-80*t" \
  -c:v libx264 -crf 18 -pix_fmt yuv420p output.mp4
```

Two speeds: a piecewise `y` changes speed mid-roll, here 80 px/s for the first 5 s (titles) and then 40 px/s (the name list). The second branch starts where the first ended (`80*5 = 400` px), so the text does not jump:

```bash
ffmpeg -i input.mp4 \
  -vf "drawtext=textfile=credits.txt:\
       fontsize=48:fontcolor=white:text_align=C:\
       x=(w-tw)/2:\
       y='h-if(lt(t,5),80*t,400+40*(t-5))':\
       line_spacing=20" \
  credits_two_speed.mp4
```

For more sections, nest more `if()` branches, each starting at the distance covered so far. The same piecewise speed works in ASS by splitting the roll into consecutive Dialogue lines, each with its own `\move`.

### Credits Speed

Rule of thumb (not a published standard): 60-80 px/s on a 1080-line frame, or about 1.2-1.5 x the font size per second.

```text
line_height    = font_size + line_spacing      (42 + 25 = 67 px)
scroll_speed   = font_size * 1.4               (42 * 1.4 = 59 px/s)
total_duration = line_count * line_height / scroll_speed
                                               (50 * 67 / 59 = 56.8 s)
Add h / scroll_speed seconds for the last line to leave the screen.
```

## News Tickers

```bash
# Right to left at 150 px/s, repeating with a full screen of gap between repeats
ffmpeg -i input.mp4 \
  -vf "drawtext=text='BREAKING NEWS... This is a scrolling ticker message':\
       fontsize=36:fontcolor=white:\
       y=h-50:\
       x='w-mod(t*150,w+tw)'" \
  ticker.mp4

# Ticker on a box
ffmpeg -i input.mp4 \
  -vf "drawtext=text='   LIVE NEWS     BREAKING STORY     UPDATES   ':\
       fontsize=40:fontcolor=yellow:\
       y=h-60:\
       x='w-mod(t*200\,w+tw)':\
       box=1:boxcolor=red@0.8:boxborderw=10" \
  news_ticker.mp4
```

### Gapless Ticker

Draw the same text twice, the second copy one text-width behind the first. This is gapless only when the text is at least as wide as the frame; repeat the message inside `text=` until it is:

```bash
MSG='   LIVE NEWS  +++  BREAKING STORY  +++  UPDATES  +++  WEATHER  +++  SPORTS  +++'
ffmpeg -i input.mp4 \
  -vf "drawbox=y=ih-75:w=iw:h=60:color=red@0.8:t=fill,\
       drawtext=text='$MSG':fontsize=40:fontcolor=yellow:y=h-65:x='-mod(t*200\,tw)',\
       drawtext=text='$MSG':fontsize=40:fontcolor=yellow:y=h-65:x='-mod(t*200\,tw)+tw'" \
  seamless_ticker.mp4
```

## Countdowns and Stopwatches

```bash
# 10 second countdown
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=10" \
  -vf "drawtext=text='%{eif\:ceil(10-t)\:d}':fontsize=200:fontcolor=white:\
       x=(w-tw)/2:y=(h-th)/2" \
  countdown.mp4

# Count-up timer (MM:SS)
ffmpeg -f lavfi -i "color=c=black:s=1920x1080:d=120" \
  -vf "drawtext=text='%{eif\:floor(t/60)\:d\:2}\:%{eif\:mod(t,60)\:d\:2}':\
       fontsize=100:fontcolor=green:\
       x=(w-tw)/2:y=(h-th)/2" \
  stopwatch.mp4
```

A countdown that pops on every second is under [Scaled Text Layer](#countdown-that-pops-each-second); a split-flap drop is under [Moving Text](#moving-text).

## Rotation (ASS Only)

`drawtext` cannot rotate text. Use ASS `\frz` (in-plane), `\frx`/`\fry` (3D):

```bash
cat << 'EOF' > spinning.ass
[Script Info]
ScriptType: v4.00+
PlayResX: 1920
PlayResY: 1080

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Spin,Arial,72,&H00FFFFFF,&H00FFFFFF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,0,5,0,0,0,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.00,0:00:05.00,Spin,,0,0,0,,{\an5\pos(960,540)\t(0,5000,\frz1080)}SPINNING
EOF

ffmpeg -i input.mp4 -vf "ass=spinning.ass" output.mp4
```

## Expression Reference

### Time Expressions

| Expression | Result |
|------------|--------|
| `t` | Current time in seconds |
| `t*100` | Speed factor |
| `mod(t,5)` | Loop every 5 seconds |
| `sin(t*3)` | Oscillate at 3 rad/s (~0.48 Hz; use `sin(t*2*PI*f)` for f Hz) |
| `exp(-t)` | Exponential decay |
| `if(lt(t,2),expr1,expr2)` | Conditional |
| `min(a,b)` / `max(a,b)` | Min/max |
| `clip(x,a,b)` | Clamp x to a..b |
| `floor(t)` / `ceil(t)` | Round down/up |

### Variables

| Variable | Meaning |
|----------|---------|
| `w`, `h` | Video width and height |
| `tw`, `th` | Text width and height |
| `lh` | Line height |
| `n` | Frame number (expressions) |
| `%{frame_num}` / `%{n}` | Frame number inside `text=` (text expansion, not an expression variable) |

### Common Patterns

```bash
# Appear after 2 seconds
enable='gte(t,2)'

# Visible between 2-5 seconds
enable='between(t,2,5)'

# Fade in over 1 second
alpha='min(1,t)'

# Center horizontally / vertically
x='(w-tw)/2'
y='(h-th)/2'

# Loop position
x='mod(t*100,w)'

# Smooth oscillation
y='h/2+50*sin(t*3)'

# Size change: never as fontsize (segfaults); use it as the scale factor of a
# fixed-size text layer
scale=w='iw*(1+0.5*exp(-t*2))':h=-2:eval=frame
```

## Sources

- [FFmpeg Drawtext Animation Exploration](https://www.braydenblackwell.com/blog/ffmpeg-text-rendering)
- [FFmpeg Expression Evaluation](https://ffmpeg.org/ffmpeg-utils.html#Expression-Evaluation)
- [ASS Override Tags](https://aegisub.org/docs/latest/ass_tags/)
