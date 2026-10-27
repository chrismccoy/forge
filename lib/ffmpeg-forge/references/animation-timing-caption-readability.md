# Caption Readability Formula

Optimal caption display duration calculation based on reading-speed research and broadcaster/streaming style guides (BBC Subtitle Guidelines, Netflix Timed Text Style Guide, DCMP Captioning Key). WCAG 2.2 requires that captions exist; it does not set durations or reading speeds (see the end of this file).

## Reading Speed Standards

| Audience | Words Per Minute (WPM) | Use Case |
|----------|------------------------|----------|
| Slow readers | 120-140 WPM | Accessibility, elderly |
| **Average** | **160-180 WPM** | **Recommended default** |
| Fast readers | 200-220 WPM | Experienced viewers |
| Skim reading | 250-300 WPM | Not recommended for video |

## Caption Duration Calculation

### Formula

```python
# Basic formula:
caption_duration = (word_count / words_per_minute) * 60

# With minimum duration (house-style floor, not a WCAG rule;
# Netflix's minimum is 5/6 s, many styles use 1-1.5 s):
minimum_duration = 1.5  # seconds
duration = max(minimum_duration, caption_duration)

# Conservative formula (recommended):
duration = max(1.5, (word_count / 160) * 60)
```

### Quick Reference Table

| Word Count | @ 160 WPM | @ 180 WPM | Recommended |
|------------|-----------|-----------|-------------|
| 1-2 words | 0.75s | 0.67s | **1.5s** (minimum) |
| 3 words | 1.13s | 1.0s | **1.5s** (minimum) |
| 4 words | 1.5s | 1.33s | **1.5s** |
| 5 words | 1.88s | 1.67s | **1.9s** |
| 6 words | 2.25s | 2.0s | **2.3s** |
| 8 words | 3.0s | 2.67s | **3.0s** |
| 10 words | 3.75s | 3.33s | **3.8s** |
| 15 words | 5.63s | 5.0s | **5.6s** |

### Python Implementation

```python
def calculate_caption_duration(text: str, wpm: int = 160) -> float:
    """
    Calculate optimal caption display duration.

    Args:
        text: Caption text
        wpm: Words per minute (default 160 for comfortable reading)

    Returns:
        Duration in seconds
    """
    word_count = len(text.split())
    calculated = (word_count / wpm) * 60

    # House-style floor (not a WCAG requirement): 1.5 seconds for any caption
    minimum = 1.5

    # Add 0.5s buffer for cognitive processing
    buffer = 0.5

    return max(minimum, calculated + buffer)

# Examples:
print(calculate_caption_duration("Hello"))           # 1.5s (minimum)
print(calculate_caption_duration("This is a test")) # 2.0s
print(calculate_caption_duration("Check out this incredible transformation")) # 2.375s
```

## Caption Style Rules and Their Sources

These limits come from broadcaster and platform style guides, not from WCAG:

| Rule | Typical value | Source |
|------|---------------|--------|
| Reading rate | 160-180 WPM | BBC Subtitle Guidelines |
| Reading rate (characters) | 20 characters/second adult, 17 children | Netflix Timed Text Style Guide |
| Characters per line | 42 (Netflix, most Latin-script languages); 32 (DCMP); ~37 (BBC) | Netflix, DCMP Captioning Key, BBC |
| Lines per caption | Maximum 2 | BBC, Netflix, DCMP |
| Minimum duration | 5/6 s (20 frames at 24 fps) | Netflix Timed Text Style Guide |
| Maximum duration | 7 s | Netflix Timed Text Style Guide |

## What WCAG 2.2 Actually Requires

- **SC 1.2.2 Captions (Prerecorded), Level A**: captions are provided for all prerecorded audio content in synchronized media.
- **SC 1.2.4 Captions (Live), Level AA**: captions are provided for all live audio content in synchronized media.

WCAG does not specify caption duration, reading speed, characters per line, or line count. Use the style guides above for those, and cite them (not WCAG) when explaining a timing choice.
