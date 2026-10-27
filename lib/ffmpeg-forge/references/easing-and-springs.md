# Easing Functions, Spring Physics, and Natural Motion

Formulas for easing, springs, oscillation and noise as FFmpeg expressions and ASS keyframes. This is the one home for these formulas; `drawtext-animation.md` and `kinetic-captions.md` use them, and `animation-timing.md` has the durations.

A per-frame drawtext `fontsize` segfaults FFmpeg 8.0.1: animate size with ASS `\t(\fscx\fscy)` or a scaled text layer (below).

## Contents

- [FFmpeg Easing Expressions](#ffmpeg-easing-expressions)
- [Recommended Easing by Context](#recommended-easing-by-context)
- [Complete Easing Function Formulas](#complete-easing-function-formulas) (normalised progress `p`)
- [Spring Physics](#spring-physics)
- [Oscillation and Wave Formulas](#oscillation-and-wave-formulas)
- [Pseudo-Random and Noise](#pseudo-random-and-noise)
- [Practical Animation Cookbook](#practical-animation-cookbook) (fades, scale layers, position, rotation)
- [Sources](#sources)

## FFmpeg Easing Expressions

### Ease Out (Deceleration) - Elements Entering

```bash
# Ease out: fast start, slow finish. Starts at t=0; for a later start T0 use
# alpha='1-exp(-max(0,t-T0)*5)' with enable='gte(t,T0)'
# Good for: Elements appearing, sliding in
-vf "drawtext=text='Hello':alpha='1-exp(-t*5)':fontsize=48:fontcolor=white:x=(w-tw)/2:y=(h-th)/2"
```

### Ease In (Acceleration) - Elements Leaving

```bash
# Ease in: slow start, fast finish, reaching 0 at the end time (5 s here)
# Good for: Elements disappearing, sliding out
-vf "drawtext=text='Goodbye':alpha='1-exp(-(5-t)*5)':fontsize=48:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:enable='lt(t,5)'"
```

### Approximating CSS Bezier Curves

FFmpeg has no bezier function. Exponentials and a sigmoid come close to the common CSS curves:

```bash
# Ease-out, close to cubic-bezier(0, 0, 0.2, 1): fast start, slow end.
# Visible until 1.5 s, so it holds at full opacity for about 1 s
-vf "drawtext=text='EASE OUT':\
     alpha='if(lt(t,0.5),1-exp(-t*6),1)':\
     fontsize=80:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:\
     enable='lt(t,1.5)'"

# Ease-in, close to cubic-bezier(0.8, 0, 1, 1): slow start, fast end at t=2
-vf "drawtext=text='EASE IN':\
     alpha='exp(-(2-t)*6)':\
     fontsize=80:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:\
     enable='between(t,1,2)'"

# Ease-in-out (S-curve) with a sigmoid centred at t=0.5:
# reaches ~0.99 at t=1 and holds until 2 s
-vf "drawtext=text='SMOOTH':\
     alpha='1/(1+exp(-10*(t-0.5)))':\
     fontsize=80:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:\
     enable='lt(t,2)'"
```

- `1 - e^(-kt)` gives natural deceleration.
- `1/(1+e^(-k(t-c)))` gives a smooth S-curve centred at `c`.
- `k` sets the sharpness: 6-10 subtle, 15-20 pronounced.

### Bounce Effect

```bash
# Decaying spring bounce that settles at the centre. Duration: 400-600ms recommended
# y_offset = amplitude * e^(-decay*t) * sin(frequency*t)
-vf "drawtext=text='BOUNCE':fontsize=80:fontcolor=white:\
     x=(w-tw)/2:\
     y='(h-th)/2-30*exp(-t*2.5)*sin(t*15)'"

# -30*exp(-t*2.5): amplitude decays from 30 px to 0
# sin(t*15): oscillates at 15 rad/s (~2.4 Hz); bounces 2-3 times in ~1 s
# For a later start T0, replace t with (t-T0) and add enable='gte(t,T0)'
```

Tuning: decay 3-4 settles quickly, 1-2 slowly; frequency 10-12 rad/s gives slow bounces, 15-20 fast ones; amplitude is the bounce height in pixels.

### Elastic Effect

For a drawtext layer, the elastic size factor `1+0.4*exp(-t*3)*sin(t*20)` scales a fixed-size text layer (Scaled Text Layer, `drawtext-animation.md`): 100% -> ~132% -> ~80% -> ~113% -> ~92% -> ~105% -> 100%, settled in ~1.5 s.

For ASS captions, use the `elastic` preset keyframes in [`kinetic-captions.md`](kinetic-captions.md#quick-reference) (40% -> 130% -> 90% -> 105% -> 100% over 380 ms).

### Smooth Oscillation (Continuous)

```bash
# Pulse/float effect
# Period: 2-4 seconds per cycle
-vf "drawtext=text='Float':y='h/2+20*sin(t*2)':fontsize=48:fontcolor=white:x=(w-tw)/2"
```

## Recommended Easing by Context

| Context | Function | Duration |
|---------|----------|----------|
| Element appearing (from T0) | `1-exp(-max(0,t-T0)*5)` (ease-out) | 200-400ms |
| Element disappearing (gone at T1) | `1-exp(-max(0,T1-t)*5)` (ease-in) | 150-300ms |
| Emphasis/attention | `1+0.2*sin(t*6)` | Continuous |
| Bounce entrance | `exp(-t*3)*sin(t*15)` | 400-600ms |
| Smooth transition | Linear (no easing) | Any |

## Complete Easing Function Formulas

Based on standard animation libraries (CSS, anime.js, React Spring) and adapted for FFmpeg.

**Every formula below expects normalised progress `p` from 0 to 1, not raw `t`.** Raw `t` keeps growing after 1 s, so `1-(1-t)^2` falls back to 0 at t=2 and `sqrt(1-(1-t)^2)` becomes NaN. Compute `p = clip((t-T0)/D, 0, 1)` for an animation that starts at `T0` and lasts `D` seconds, store it with `st(0,...)`, and read it with `ld(0)`:

```bash
# Quadratic ease-out fade, starting at T0=1 s, lasting D=0.5 s, then holding at 1:
-vf "drawtext=text='Hello':fontsize=48:fontcolor=white:x=(w-tw)/2:y=(h-th)/2:alpha='st(0,clip((t-1)/0.5,0,1));1-(1-ld(0))*(1-ld(0))'"

# The same curve driving position (slide from x=w to the centre over 0.5 s from t=1):
x='st(0,clip((t-1)/0.5,0,1));w+((w-tw)/2-w)*(1-(1-ld(0))*(1-ld(0)))'
```

In the **FFmpeg:** lines below, `P` stands for `ld(0)`; prefix each expression with `st(0,clip((t-T0)/D,0,1));`.

### Linear (No Easing)

```text
f(t) = t
```

**FFmpeg:** `alpha='P'` or `x='X0+(X1-X0)*P'`

Use for: Constant speed motion, mechanical effects.

### Quadratic Easing

Ease In (Acceleration):

```text
f(t) = t^2
```

**FFmpeg:** `alpha='P*P'`

Ease Out (Deceleration):

```text
f(t) = 1 - (1-t)^2
```

**FFmpeg:** `alpha='1-(1-P)*(1-P)'`

Ease In-Out:

```text
f(t) = if(t < 0.5, 2*t^2, 1 - 2*(1-t)^2)
```

**FFmpeg:** `alpha='if(lt(P,0.5),2*P*P,1-2*(1-P)*(1-P))'`

### Cubic Easing

Ease In:

```text
f(t) = t^3
```

**FFmpeg:** `alpha='P*P*P'`

Ease Out:

```text
f(t) = 1 - (1-t)^3
```

**FFmpeg:** `alpha='1-(1-P)*(1-P)*(1-P)'`

Ease In-Out (symmetric cubic; Material's standard curve is the asymmetric cubic-bezier(0.4, 0, 0.2, 1), not this):

```text
f(t) = if(t < 0.5, 4*t^3, 1 - 4*(1-t)^3)
```

**FFmpeg:** `alpha='if(lt(P,0.5),4*P*P*P,1-4*(1-P)*(1-P)*(1-P))'`

### Exponential Easing

Ease In:

```text
f(t) = 2^(10*(t-1))
```

**FFmpeg:** `alpha='exp(10*(P-1)*0.693)'` (note: `2^x = e^(x*ln(2))`, `ln(2) ~= 0.693`)

Ease Out (Recommended for text appearing):

```text
f(t) = 1 - 2^(-10*t)
```

**FFmpeg:** `alpha='1-exp(-10*P*0.693)'`

### Sine Easing (Smooth, Gentle)

Ease In:

```text
f(t) = 1 - cos(t*pi/2)
```

**FFmpeg:** `alpha='1-cos(P*1.571)'` (`pi/2 ~= 1.571`)

Ease Out:

```text
f(t) = sin(t*pi/2)
```

**FFmpeg:** `alpha='sin(P*1.571)'`

Ease In-Out:

```text
f(t) = -(cos(pi*t) - 1)/2
```

**FFmpeg:** `alpha='-(cos(3.1416*P)-1)/2'`

### Circular Easing (Sharp Curve)

Ease In:

```text
f(t) = 1 - sqrt(1 - t^2)
```

**FFmpeg:** `alpha='1-sqrt(1-P*P)'`

Ease Out:

```text
f(t) = sqrt(1 - (1-t)^2)
```

**FFmpeg:** `alpha='sqrt(1-(1-P)*(1-P))'`

### Elastic Easing (Overshoot with Oscillation)

Ease Out (most common):

```text
f(t) = 2^(-10*t) * sin((t*10 - 0.75)*2pi/3) + 1
```

**FFmpeg approximation:**

```bash
alpha='exp(-10*P*0.693)*sin((P*10-0.75)*2.094)+1'
```

(`2pi/3 ~= 2.094`)

Ease In:

```text
f(t) = -2^(10*(t-1)) * sin((t*10 - 10.75)*2pi/3)
```

**FFmpeg:**

```bash
alpha='-exp(10*(P-1)*0.693)*sin((P*10-10.75)*2.094)'
```

### Bounce Easing

Ease-out bounce (standard `easeOutBounce`, n1 = 7.5625, d1 = 2.75; continuous, t in 0-1, every segment meets at 1.0):

```bash
alpha='if(lt(P,0.363636),
         7.5625*P*P,
         if(lt(P,0.727273),
            7.5625*(P-0.545455)*(P-0.545455)+0.75,
            if(lt(P,0.909091),
               7.5625*(P-0.818182)*(P-0.818182)+0.9375,
               7.5625*(P-0.954545)*(P-0.954545)+0.984375)))'
```

Simplified damped oscillation bounce:

```bash
alpha='1-abs(cos(P*4.5*3.1416))*exp(-P*6)'
```

### Back Easing (Overshoot)

Ease Out (slight overshoot then settle):

```text
f(t) = 1 + c3 * (t-1)^3 + c1 * (t-1)^2
where c1 = 1.70158, c3 = c1 + 1
```

FFmpeg (exact back ease-out, peaks ~1.10 near p=0.6; `alpha` is clamped to 1, so drive position or a scale factor with it, not alpha):

```bash
# Slide from x=-tw to the centre over 0.6 s starting at t=0.5, overshooting slightly:
x='st(0,clip((t-0.5)/0.6,0,1));-tw+((w-tw)/2+tw)*(1+2.70158*pow(ld(0)-1,3)+1.70158*pow(ld(0)-1,2))'
```

## Spring Physics

### Spring Parameter Guide

For `amplitude*exp(-damping*t)*sin(frequency*t)` style springs (rules of thumb):

| Parameter | Low Value | High Value | Effect |
|-----------|-----------|------------|--------|
| **Damping** | 2-3 | 5-8 | More bouncy -> less bouncy (faster settle) |
| **Frequency** | 8-10 rad/s | 15-20 rad/s | Slow oscillation -> fast oscillation |
| **Amplitude** | 5-10% | 15-25% | Subtle -> dramatic |

Damping ratio ζ (defined below):

- **ζ < 0.5**: very bouncy, multiple oscillations
- **ζ = 0.5-0.8**: balanced bounce, 1-2 oscillations
- **ζ = 1.0**: critical damping (no overshoot)
- **ζ > 1.0**: over-damped (sluggish)

ASS keyframe versions (bouncy, balanced, quick settle) are in `kinetic-captions.md` (Spring Physics Animation).

### Standard Mass-Spring-Damper

Differential equation:

```text
m * x''(t) + c * x'(t) + k * x(t) = 0

m = mass
c = damping coefficient
k = spring stiffness
x(t) = position at time t
```

Natural frequency: `omega_n = sqrt(k/m)`.
Damping ratio: `zeta = c / (2 * sqrt(k * m))`.

### Damping Cases

Under-damped (0 < zeta < 1) - bouncy, overshoots:

```text
x(t) = e^(-zeta*omega_n*t) * [A*cos(omega_d*t) + B*sin(omega_d*t)]
omega_d = omega_n * sqrt(1 - zeta^2)
```

Critically damped (zeta = 1) - no overshoot, fastest settle:

```text
x(t) = (A + B*t) * e^(-omega_n*t)
```

Over-damped (zeta > 1) - slow, sluggish:

```text
x(t) = A*e^(r1*t) + B*e^(r2*t)
```

### Simplified Spring for UI

```python
# Two-parameter approach (bounce + duration)
mass = 1
stiffness = (2*pi / duration)**2

if bounce >= 0:
    damping = (1 - bounce) * 4*pi / duration
else:
    damping = 4*pi / (duration * (1 + bounce))
```

Bounce mapping:

- `bounce = 0`: critically damped (no overshoot)
- `0 < bounce < 1`: under-damped (1 = undamped oscillation)
- `bounce < 0`: over-damped (negative = slower settling)

### FFmpeg Spring Implementation

Basic under-damped spring (stiffness=100, damping=10, mass=1):

```bash
# omega_n = sqrt(100/1) = 10
# zeta = 10 / (2*sqrt(100*1)) = 0.5 (under-damped)
# omega_d = 10 * sqrt(1 - 0.25) ~= 8.66

-vf "drawtext=text='SPRING':\
     y='(h-th)/2-50*exp(-5*t)*cos(8.66*t)':\
     fontsize=80:fontcolor=white:x=(w-tw)/2"
```

Tunable spring parameters:

```bash
# exp(-a*t)*sin(wd*t) has zeta = a/sqrt(a^2+wd^2), omega_n = sqrt(a^2+wd^2)

# Low bounce (zeta~0.62, omega_n~12.8, quick settle):
y='(h-th)/2+amplitude*exp(-8*t)*sin(10*t)'

# Medium bounce (zeta~0.38, omega_n=13, balanced):
y='(h-th)/2+amplitude*exp(-5*t)*sin(12*t)'

# High bounce (zeta~0.21, omega_n~14.3, very bouncy):
y='(h-th)/2+amplitude*exp(-3*t)*sin(14*t)'

# Critical damping (zeta=1, no overshoot):
y='(h-th)/2+amplitude*exp(-10*t)*(1+10*t)'
```

## Oscillation and Wave Formulas

### Basic Trig

Sine wave (smooth oscillation):

```text
y = A * sin(omega*t + phi)

A = amplitude
omega = angular frequency (rad/s)
t = time (s)
phi = phase offset (rad)
```

Frequency conversion: `omega = 2*pi*f`.

```text
1 Hz = 6.28 rad/s
2 Hz = 12.56 rad/s
3 Hz = 18.85 rad/s
```

FFmpeg examples:

```bash
# 2 Hz oscillation:
y='50*sin(12.56*t)'

# 1 Hz with phase offset (starts at peak):
y='50*sin(6.28*t+1.571)'

# Cosine (equivalent to sin(t + pi/2)):
y='50*cos(6.28*t)'
```

### Amplitude Modulation

```bash
# Exponential decay envelope:
y='50*exp(-2*t)*sin(10*t)'

# Linear decay:
y='50*max(0,1-t)*sin(10*t)'

# Low-frequency modulates high-frequency:
y='(30+20*sin(2*t))*sin(20*t)'
```

### Frequency Modulation

```bash
# Accelerating oscillation (siren):
y='50*sin(5*t*t)'

# Decelerating:
y='50*sin(20*t-5*t*t)'

# Vibrato:
y='50*sin(10*t+2*sin(3*t))'
```

### Lissajous (Parametric Motion)

```bash
# Circular orbit:
-vf "drawtext=text='o':\
     x='(w/2)+200*cos(2*t)':\
     y='(h/2)+200*sin(2*t)':\
     fontsize=40:fontcolor=white"

# Elliptical:
x='(w/2)+200*cos(2*t)'
y='(h/2)+100*sin(2*t)'

# Figure-8 (Lissajous 1:2):
x='(w/2)+150*sin(1*t)'
y='(h/2)+150*sin(2*t)'
```

## Pseudo-Random and Noise

```bash
# Pseudo-random using irrational sine frequency:
'10*sin(t*137.5)'

# Multi-layered:
'5*sin(t*137.5)+3*sin(t*241.3)+2*sin(t*89.7)'

# Smooth (Perlin-like):
noise = 'sin(t*2.3)+0.5*sin(t*5.1)+0.25*sin(t*11.7)'

# Normalized 0-1:
normalized = '(sin(t*2.3)+0.5*sin(t*5.1)+0.25*sin(t*11.7)+1.75)/3.5'
```

### Jitter / Shake

```bash
# Continuous shake:
x='(w-tw)/2+5*sin(t*50)'
y='(h-th)/2+5*cos(t*47)'

# Decaying shake (impact):
x='(w-tw)/2+10*exp(-t*3)*sin(t*50)'
y='(h-th)/2+10*exp(-t*3)*cos(t*47)'

# Triggered shake (between t=2 and 2.5):
x='(w-tw)/2+if(between(t,2,2.5),15*sin(t*60),0)'
```

## Practical Animation Cookbook

### Fade Transitions

```bash
# Linear fade in 0-0.5s:
alpha='min(1,t/0.5)'

# Ease-out fade in:
alpha='1-exp(-5*t)'

# Cubic fade in:
alpha='min(1,(t/0.5)*(t/0.5)*(t/0.5))'

# Fade out (last 2s of a 10s video):
alpha='if(gt(t,8),1-(t-8)/2,1)'

# Exponential fade out:
alpha='if(gt(t,8),exp(-(t-8)*3),1)'

# Fade in 0-1s, hold, fade out 9-10s:
alpha='if(lt(t,1),t,if(gt(t,9),10-t,1))'
```

### Scale Animations (ASS)

```ass
; Scale in from zero (linear, 300 ms; the canonical pop is 50 -> 115 -> 100%, see kinetic-captions.md):
{\fscx0\fscy0\t(0,300,\fscx100\fscy100)}Text

; Pulse with hold:
{\t(0,300,\fscx110\fscy110)\t(300,600,\fscx100\fscy100)}

; Overshoot bounce (80% -> 120% -> 95% -> 100% over 300 ms):
{\fscx80\fscy80\t(0,100,\fscx120\fscy120)\t(100,200,\fscx95\fscy95)\t(200,300,\fscx100\fscy100)}
```

### Scale Animations (FFmpeg layer, no ASS)

For a time-driven size change without ASS, draw the text once at a fixed size on a transparent layer, scale that layer per frame (`eval=frame`), and overlay it centred:

```bash
# Pop from 50% to 100% over 0.5 s (set the color source to the frame size and duration)
ffmpeg -i input.mp4 -filter_complex "\
  color=c=black@0:s=1280x720:d=5,format=rgba,\
  drawtext=text='POP':fontsize=120:fontcolor=white:x=(w-tw)/2:y=(h-th)/2,\
  scale=w='iw*(0.5+0.5*min(1,t/0.5))':h=-2:eval=frame[txt];\
  [0:v][txt]overlay=x=(W-w)/2:y=(H-h)/2:shortest=1,format=yuv420p[v]" \
  -map "[v]" -map 0:a? -c:a copy pop.mp4
```

Swap the `scale` factor for any rhythm below, e.g. `w='iw*(1+0.08*max(0,sin(t*7.33)))'` for a 70 BPM heartbeat.

### Position Animations

```bash
# Slide in from right (linear):
x='if(lt(t,1),w-((w-(w-tw)/2)*t),(w-tw)/2)'

# Slide in with ease-out:
x='if(lt(t,1),w-((w-(w-tw)/2)*(1-exp(-5*t))),(w-tw)/2)'

# Bounce in from bottom (ASS):
# {\move(540,1920,540,960,0,400)\t(0,150,\fscy115)\t(150,300,\fscy95)\t(300,400,\fscy100)}

# Circular path:
x='(w/2)+radius*cos(speed*t)'
y='(h/2)+radius*sin(speed*t)'
```

### Rotation (ASS only)

```ass
; Continuous spin (360 deg over 2s):
{\t(0,2000,\frz360)}Text

; Wobble:
{\t(0,200,\frz15)\t(200,400,\frz-10)\t(400,600,\frz5)\t(600,800,\frz0)}
```

## Sources

- FFmpeg Expression Evaluation Documentation: https://ffmpeg.org/ffmpeg-utils.html#Expression-Evaluation
- Spring Physics for UI Animations: https://www.kvin.me/posts/effortless-ui-spring-animations
- Easing Functions Mathematical Reference: https://easings.net/
- React Spring Physics Documentation: https://www.react-spring.dev/docs/advanced/spring-configs
- ASS Subtitle Format Specification: https://aegisub.org/docs/latest/ass_tags/
- WCAG 2.2 Animation Accessibility: https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions
- Accessible Animations: https://www.a11y-collective.com/blog/wcag-animation/
