#!/usr/bin/env python3
"""
kinetic_captions.py - Generate kinetic ASS captions from word-level timestamps

Usage: kinetic_captions.py transcript.json output.ass [style] [platform]
Styles: pop, grow, karaoke, bounce, elastic, shake (default: pop)
Platforms: tiktok, youtube, instagram (default: tiktok)

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

The keyframes match scripts/generate-karaoke.sh. The output file must not
exist yet; the script refuses to overwrite it.
"""

import argparse
import json
import sys
from typing import List, Dict

# Animation presets (same keyframes as scripts/generate-karaoke.sh)
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
        'shrink_ms': 150
    },
    'karaoke': {
        'use_karaoke': True,
        'peak_scale': 115,
        'end_scale': 100,
        'grow_ms': 150,
        'shrink_ms': 150
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


# Canvas (PlayResX, PlayResY) per platform, as in scripts/generate-karaoke.sh:
# 9:16 for TikTok/Reels, 16:9 for YouTube. Burn onto a video of the same
# aspect ratio, or the captions are stretched.
PLATFORMS = {
    'tiktok': {
        'font_name': 'Arial Black',
        'font_size': 88,
        'res': (1080, 1920)
    },
    'youtube': {
        'font_name': 'Montserrat',
        'font_size': 76,
        'res': (1920, 1080)
    },
    'instagram': {
        'font_name': 'Impact',
        'font_size': 82,
        'res': (1080, 1920)
    }
}


class InputError(Exception):
    """Bad or unusable transcript."""


def margin_v(width: int, height: int) -> int:
    """Bottom margin: 280/1920 of the height on portrait (clear of the
    TikTok/Reels UI), 8% on landscape. Rules of thumb."""
    return round(height * 280 / 1920) if height > width else round(height * 0.08)

def format_time_ass(seconds: float) -> str:
    """Convert seconds to ASS timestamp (H:MM:SS.cc)"""
    cs = int(round(seconds * 100))
    h, rem = divmod(cs, 360000)
    m, rem = divmod(rem, 6000)
    s, cs = divmod(rem, 100)
    return f"{h}:{m:02d}:{s:02d}.{cs:02d}"

# U+2060 WORD JOINER: zero width, no glyph, no line break opportunity
WORD_JOINER = '\u2060'

def ass_escape(text: str) -> str:
    """Make user text render literally in libass (FFmpeg's subtitles/ass filters).

    - A backslash followed by N, n, h, { or } would be read as a line break,
      a hard space or a brace escape ("C:\\Notes" would break the line), and
      libass has no escape for the backslash itself (\\\\ draws two). So a
      word joiner goes after every backslash: it draws nothing and separates
      the backslash from the next character, including a following tag block.
    - An unescaped {...} is parsed as an override block and hidden; libass
      draws \\{ and \\} as literal braces.
    """
    text = text.replace('\\', '\\' + WORD_JOINER)
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

def generate_karaoke_line(words: List[Dict], preset: dict) -> str:
    """Generate karaoke line with grow effect"""
    if not words:
        return ""

    karaoke_text = ""
    offset_ms = 0
    for i, word_data in enumerate(words):
        word = ass_escape(word_data['word'])
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
    w, h = plat['res']
    mv = margin_v(w, h)

    return f"""[Script Info]
ScriptType: v4.00+
PlayResX: {w}
PlayResY: {h}
WrapStyle: 0
Title: Kinetic Captions

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: KineticPop,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,{mv},1
Style: KineticGrow,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,{mv},1
Style: KineticKaraoke,{plat['font_name']},{plat['font_size']},&H0000FFFF,&H00FFFFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,{mv},1
Style: KineticBounce,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,{mv},1
Style: KineticShake,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,5,0,2,10,10,{mv},1
Style: KineticElastic,{plat['font_name']},{plat['font_size']},&H00FFFFFF,&H0000FFFF,&H00000000,&H40000000,1,0,0,0,100,100,0,0,1,6,0,2,10,10,{mv},1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

def clean_words(words) -> List[Dict]:
    """Validate one segment's word list. Returns words with stripped text and
    float times; words whose text is empty after stripping are dropped."""
    if not isinstance(words, list):
        raise InputError("'words' must be a list")
    out = []
    for w in words:
        if not isinstance(w, dict) or not all(k in w for k in ('word', 'start', 'end')):
            raise InputError(f"each word needs 'word', 'start' and 'end': {w!r}")
        try:
            start, end = float(w['start']), float(w['end'])
        except (TypeError, ValueError):
            raise InputError(f"'start'/'end' must be numbers: {w!r}") from None
        if start < 0 or end < start:
            raise InputError(f"bad times (need 0 <= start <= end): {w!r}")
        text = str(w['word']).strip()
        if text:
            out.append({'word': text, 'start': start, 'end': end})
    return out

def load_segments(transcript_path: str) -> List[List[Dict]]:
    """Read the transcript and return the cleaned word list of each segment."""
    try:
        with open(transcript_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except OSError as e:
        raise InputError(f"cannot read {transcript_path}: {e.strerror}") from None
    except (json.JSONDecodeError, UnicodeDecodeError) as e:
        raise InputError(f"{transcript_path} is not valid JSON: {e}") from None
    if not isinstance(data, dict) or not isinstance(data.get('segments'), list):
        raise InputError("expected a JSON object with a 'segments' list")
    segments = []
    for seg in data['segments']:
        if not isinstance(seg, dict):
            raise InputError(f"each segment must be an object: {seg!r}")
        segments.append(clean_words(seg.get('words', [])))
    if not any(segments):
        raise InputError("no words found; the transcript needs word-level timestamps "
                         "(e.g. openai-whisper --word_timestamps True)")
    return segments

def generate_kinetic_captions(transcript_path: str, output_path: str,
                              style: str = 'pop', platform: str = 'tiktok') -> int:
    """Generate kinetic ASS captions from Whisper JSON transcript.
    Returns the number of Dialogue events written."""

    segments = load_segments(transcript_path)
    preset = PRESETS[style]
    style_name = f"Kinetic{style.title()}"

    header = create_ass_header(platform)
    events = []

    if style == 'karaoke':
        # One karaoke line per segment
        for words in segments:
            if not words:
                continue

            start = words[0]['start']
            end = words[-1]['end']
            karaoke_line = generate_karaoke_line(words, preset)

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

        all_words = [w for words in segments for w in words]
        for i, word_data in enumerate(all_words):
            word = ass_escape(word_data['word'])
            start = word_data['start']
            # Words share one screen position: end each word when the next
            # starts so two words are never drawn on top of each other
            end = word_data['end']
            if i + 1 < len(all_words):
                end = max(start, min(end, all_words[i + 1]['start']))

            effect_text = effect_func(word, preset)
            events.append(
                f"Dialogue: 0,{format_time_ass(start)},{format_time_ass(end)},{style_name},,0,0,0,,{effect_text}"
            )

    # Write output; mode 'x' refuses to overwrite an existing file
    with open(output_path, 'x', encoding='utf-8') as f:
        f.write(header)
        f.write('\n'.join(events))
        f.write('\n')

    return len(events)

def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        prog='kinetic_captions.py',
        description='Generate kinetic ASS captions from word-level timestamps (JSON).',
        epilog='Burn with: ffmpeg -i in.mp4 -vf "ass=captions.ass" -c:v libx264 -crf 18 '
               '-pix_fmt yuv420p -c:a copy out.mp4. Pick the platform whose canvas '
               'matches the video: tiktok/instagram 1080x1920, youtube 1920x1080.')
    parser.add_argument('transcript', help='JSON with segments[].words[] = {word, start, end} (seconds)')
    parser.add_argument('output', help='ASS file to write (must not exist)')
    parser.add_argument('style', nargs='?', default='pop', type=str.lower,
                        choices=list(PRESETS), help='animation style (default: pop)')
    parser.add_argument('platform', nargs='?', default='tiktok', type=str.lower,
                        choices=list(PLATFORMS), help='canvas and font preset (default: tiktok)')

    if argv is None:
        argv = sys.argv[1:]
    if not argv:
        parser.print_help(sys.stderr)
        return 1
    args = parser.parse_args(argv)

    try:
        n = generate_kinetic_captions(args.transcript, args.output, args.style, args.platform)
    except InputError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    except FileExistsError:
        print(f"Error: Output already exists: {args.output}", file=sys.stderr)
        return 1
    except OSError as e:
        print(f"Error: cannot write {args.output}: {e.strerror}", file=sys.stderr)
        return 1

    w, h = PLATFORMS[args.platform]['res']
    print(f"Created {args.output} with {n} caption events "
          f"({args.style} style for {args.platform}, canvas {w}x{h})")
    return 0

if __name__ == "__main__":
    sys.exit(main())
