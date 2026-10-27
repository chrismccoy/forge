# Complete Kinetic Caption Generator (Python + ASS)

A full Python script that takes word-level timestamps and emits Advanced SubStation Alpha (ASS) captions with kinetic animation. `kinetic-captions.md` keeps the per-effect recipes; this reference holds the assembled generator.

## Complete Kinetic Caption Generator

```python
#!/usr/bin/env python3
"""
kinetic_captions.py - Generate kinetic ASS captions from word-level timestamps

Usage: python kinetic_captions.py transcript.json output.ass [style] [platform]
Styles: pop, grow, karaoke, bounce, elastic, shake

Input JSON format (word-level timestamps, e.g. openai-whisper with
word_timestamps=True; FFmpeg's own whisper filter emits segments, not words):
{
  "segments": [
    {
      "words": [
        {"word": "This", "start": 0.0, "end": 0.5},
        {"word": "is", "start": 0.5, "end": 0.8},
        ...
      ]
    }
  ]
}
"""

import json
import sys
from typing import List, Dict

# Animation presets
PRESETS = {
    'pop': {
        'start_scale': 50,
        'peak_scale': 115,
        'end_scale': 100,
        'grow_ms': 100,
        'shrink_ms': 100
    },
    'grow': {
        'start_scale': 80,
        'peak_scale': 115,
        'end_scale': 100,
        'grow_ms': 150,
        'shrink_ms': 200
    },
    'karaoke': {
        'use_karaoke': True,
        'peak_scale': 112,
        'end_scale': 100,
        'grow_ms': 150,
        'shrink_ms': 200
    },
    'bounce': {
        'start_scale': 80,
        'peak_scale': 120,
        'bounce_scale': 95,
        'end_scale': 100,
        'grow_ms': 100,
        'bounce_ms': 100,
        'settle_ms': 100
    },
    'elastic': {
        'start_scale': 40,
        'peak1_scale': 130,
        'valley_scale': 90,
        'peak2_scale': 105,
        'end_scale': 100,
        'phase1_ms': 80,
        'phase2_ms': 80,
        'phase3_ms': 100,
        'phase4_ms': 120
    },
    'shake': {
        'peak_scale': 115,
        'shake_degrees': 6,      # first jitter angle; decays to 0
        'shake_cycles': 3,       # left-right swings
        'shake_duration_ms': 150,
        'grow_ms': 80
    }
}

# Platform presets
PLATFORMS = {
    'tiktok': {
        'font_name': 'Arial Black',
        'font_size': 88
    },
    'youtube': {
        'font_name': 'Montserrat',
        'font_size': 76
    },
    'instagram': {
        'font_name': 'Impact',
        'font_size': 82
    }
}

def format_time_ass(seconds: float) -> str:
    """Convert seconds to ASS timestamp (H:MM:SS.cc)"""
    cs = int(round(seconds * 100))
    h, rem = divmod(cs, 360000)
    m, rem = divmod(rem, 6000)
    s, cs = divmod(rem, 100)
    return f"{h}:{m:02d}:{s:02d}.{cs:02d}"

def ass_escape(text: str) -> str:
    """Escape { and } in user text: an unescaped {...} is parsed as an
    override block and hidden. libass (FFmpeg's subtitles/ass filters)
    draws \\{ and \\} as literal braces."""
    return text.replace('{', '\\{').replace('}', '\\}')

def generate_pop_effect(word: str, preset: dict) -> str:
    """Generate pop animation tags"""
    s = preset['start_scale']
    p = preset['peak_scale']
    e = preset['end_scale']
    g = preset['grow_ms']
    sh = preset['shrink_ms']

    return f"{{\\fscx{s}\\fscy{s}\\t(0,{g},\\fscx{p}\\fscy{p})\\t({g},{g+sh},\\fscx{e}\\fscy{e})}}{word}"

def generate_grow_effect(word: str, preset: dict) -> str:
    """Generate grow animation tags for a word on its own Dialogue line"""
    s = preset.get('start_scale', 100)
    p = preset['peak_scale']
    e = preset['end_scale']
    g = preset['grow_ms']
    sh = preset['shrink_ms']
    return f"{{\\fscx{s}\\fscy{s}\\t(0,{g},\\fscx{p}\\fscy{p})\\t({g},{g+sh},\\fscx{e}\\fscy{e})}}{word}"

def karaoke_grow_tags(preset: dict, offset_ms: int) -> str:
    """Grow tags for one word inside a karaoke line (no braces, no word).
    The caller prefixes \\r so this word's animation does not carry over
    to the words after it.
    \\t times are relative to the Dialogue start, so each word is offset
    by the time its highlight begins."""
    p = preset['peak_scale']
    e = preset['end_scale']
    g = preset['grow_ms']
    sh = preset['shrink_ms']
    return (f"\\t({offset_ms},{offset_ms + g},\\fscx{p}\\fscy{p})"
            f"\\t({offset_ms + g},{offset_ms + g + sh},\\fscx{e}\\fscy{e})")

def generate_bounce_effect(word: str, preset: dict) -> str:
    """Generate spring bounce animation tags"""
    s = preset['start_scale']
    p = preset['peak_scale']
    b = preset['bounce_scale']
    e = preset['end_scale']
    g = preset['grow_ms']
    bm = preset['bounce_ms']
    st = preset['settle_ms']

    t1 = g
    t2 = t1 + bm
    t3 = t2 + st

    return f"{{\\fscx{s}\\fscy{s}\\t(0,{t1},\\fscx{p}\\fscy{p})\\t({t1},{t2},\\fscx{b}\\fscy{b})\\t({t2},{t3},\\fscx{e}\\fscy{e})}}{word}"

def generate_elastic_effect(word: str, preset: dict) -> str:
    """Generate elastic overshoot animation tags"""
    s = preset['start_scale']
    p1 = preset['peak1_scale']
    v = preset['valley_scale']
    p2 = preset['peak2_scale']
    e = preset['end_scale']
    t1 = preset['phase1_ms']
    t2 = t1 + preset['phase2_ms']
    t3 = t2 + preset['phase3_ms']
    t4 = t3 + preset['phase4_ms']

    return f"{{\\fscx{s}\\fscy{s}\\t(0,{t1},\\fscx{p1}\\fscy{p1})\\t({t1},{t2},\\fscx{v}\\fscy{v})\\t({t2},{t3},\\fscx{p2}\\fscy{p2})\\t({t3},{t4},\\fscx{e}\\fscy{e})}}{word}"

def generate_shake_effect(word: str, preset: dict) -> str:
    """Generate scale punch + decaying rotational shake.
    \\pos cannot be animated with \\t, but \\frz can, so the shake is a
    left-right rotation jitter that decays to 0 within one Dialogue line."""
    p = preset['peak_scale']
    deg = preset['shake_degrees']
    cycles = preset['shake_cycles']
    dur = preset['shake_duration_ms']
    g = preset['grow_ms']

    steps = cycles * 2
    step_ms = dur / steps
    jitter = ""
    for i in range(steps):
        angle = deg * (1 - i / steps) * (1 if i % 2 == 0 else -1)
        t0, t1 = round(i * step_ms), round((i + 1) * step_ms)
        jitter += f"\\t({t0},{t1},\\frz{angle:.1f})"
    jitter += f"\\t({dur},{dur + 30},\\frz0)"
    return (f"{{\\fscx100\\fscy100\\t(0,{g},\\fscx{p}\\fscy{p})"
            f"\\t({g},{g+dur},\\fscx100\\fscy100){jitter}}}{word}")

def generate_karaoke_line(words: List[Dict], preset: dict, style_name: str) -> str:
    """Generate karaoke line with grow effect"""
    if not words:
        return ""

    karaoke_text = ""
    offset_ms = 0
    for i, word_data in enumerate(words):
        word = ass_escape(word_data['word'].strip())
        # \k runs until the next word starts, so pauses between words are
        # included and the highlight stays in sync with the audio
        next_start = words[i + 1]['start'] if i + 1 < len(words) else word_data['end']
        duration_cs = max(1, round((next_start - word_data['start']) * 100))
        tags = karaoke_grow_tags(preset, offset_ms)
        karaoke_text += f"{{\\r\\k{duration_cs}{tags}}}{word} "
        offset_ms += duration_cs * 10

    return karaoke_text.strip()

def create_ass_header(platform: str = 'tiktok') -> str:
    """Create ASS file header with styles.
    KineticKaraoke: karaoke text is drawn in SecondaryColour (white) until it
    is sung, then in PrimaryColour (yellow). The other styles show only
    PrimaryColour (white)."""
    plat = PLATFORMS[platform]

    return f"""[Script Info]
ScriptType: v4.00+
PlayResX: 1080
PlayResY: 1920
WrapStyle: 0
Title: Kinetic Captions

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: KineticPop,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticGrow,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticKaraoke,{plat['font_name']},{plat['font_size']},&H0000FFFF,&H00FFFFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticBounce,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticShake,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,280,1
Style: KineticElastic,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,280,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

def generate_kinetic_captions(transcript_path: str, output_path: str,
                              style: str = 'pop', platform: str = 'tiktok'):
    """Generate kinetic ASS captions from Whisper JSON transcript"""

    style = style.lower()
    platform = platform.lower()
    if style not in PRESETS:
        sys.exit(f"Unknown style '{style}'. Choose one of: {', '.join(PRESETS)}")
    if platform not in PLATFORMS:
        sys.exit(f"Unknown platform '{platform}'. Choose one of: {', '.join(PLATFORMS)}")

    with open(transcript_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    preset = PRESETS[style]
    style_name = f"Kinetic{style.title()}"

    header = create_ass_header(platform)
    events = []

    # Extract all words
    all_words = []
    segments = data.get('segments', [])
    for segment in segments:
        words = segment.get('words', [])
        all_words.extend(words)

    if style == 'karaoke':
        # Group words into lines and generate karaoke
        for segment in segments:
            words = segment.get('words', [])
            if not words:
                continue

            start = words[0]['start']
            end = words[-1]['end']
            karaoke_line = generate_karaoke_line(words, preset, style_name)

            events.append(
                f"Dialogue: 0,{format_time_ass(start)},{format_time_ass(end)},{style_name},,0,0,0,,{karaoke_line}"
            )
    else:
        # Word-by-word animation
        effect_func = {
            'pop': generate_pop_effect,
            'grow': generate_grow_effect,
            'bounce': generate_bounce_effect,
            'elastic': generate_elastic_effect,
            'shake': generate_shake_effect
        }[style]

        for i, word_data in enumerate(all_words):
            word = ass_escape(word_data['word'].strip())
            start = word_data['start']
            # Words share one screen position: end each word when the next
            # starts so two words are never drawn on top of each other
            end = word_data['end']
            if i + 1 < len(all_words):
                end = min(end, all_words[i + 1]['start'])

            effect_text = effect_func(word, preset)
            events.append(
                f"Dialogue: 0,{format_time_ass(start)},{format_time_ass(end)},{style_name},,0,0,0,,{effect_text}"
            )

    # Write output
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(header)
        f.write('\n'.join(events))

    print(f"Created {output_path} with {len(events)} caption events ({style} style for {platform})")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python kinetic_captions.py transcript.json output.ass [style] [platform]")
        print("Styles: pop, grow, karaoke, bounce, elastic, shake")
        print("Platforms: tiktok, youtube, instagram")
        sys.exit(1)

    transcript = sys.argv[1]
    output = sys.argv[2]
    style = sys.argv[3] if len(sys.argv) > 3 else 'pop'
    platform = sys.argv[4] if len(sys.argv) > 4 else 'tiktok'

    generate_kinetic_captions(transcript, output, style, platform)
```

For drawtext-based effects without ASS files, see `karaoke-text-drawtext-animation-recipes.md`.
