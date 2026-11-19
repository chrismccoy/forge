# Unicode, Color, Accessibility, and Non-TUI Fallbacks

Use this guide when terminal output must be visually correct, readable, inclusive, and robust across fonts, locales, themes, and assistive technologies.

## Text correctness rules

- Display width is not byte length, code point count, or user-perceived character count.
- Run cursor movement and deletion on grapheme clusters.
- Measure printable text for layout after stripping ANSI control sequences.
- Double-width characters, combining marks, emoji sequences, variation selectors, and zero-width joiners must be tested.
- Treat ambiguous East Asian width as narrow by default unless the target environment explicitly differs.
- Measure with a maintained width/grapheme library (`unicode-width`, `wcwidth`, `uniseg`, `string-width`), preferably the one the framework already uses.
- Terminals disagree on emoji widths (VS16, ZWJ sequences, flags). Keep emoji out of aligned columns or pad them. Probe with `CSI 6 n` or grapheme mode 2027 when exact width matters. Library table and probe recipe: `domains/unicode-color-accessibility/references/text-measurement.md`.

## Visual design rules

- Use semantic roles: error, warning, success, info, muted, selected, focused, disabled.
- Do not encode meaning by color alone; pair color with text, shape, icon, or position.
- Provide ASCII fallback for box drawing, braille charts, block elements, emoji, and private-use icons.
- Avoid assuming Nerd Fonts or patched fonts.
- Support light and dark backgrounds, 16-color, 256-color, truecolor, and no-color modes.

## Color preferences

Respect user and environment preferences. Resolve conflicts with the override precedence in `domains/terminal-standards/GUIDE.md` (CLI flags, then environment, then TTY detection, then defaults):

- `NO_COLOR` disables non-essential color.
- `CLICOLOR_FORCE` and `FORCE_COLOR` force color (`FORCE_COLOR=0` or `false` disables it instead; see `domains/terminal-standards/GUIDE.md`); `CLICOLOR=0` disables it. Ecosystems differ on which wins when several are set, so follow the override precedence in `domains/terminal-standards/GUIDE.md` and document the choice.
- `TERM=dumb`, non-TTY output, and CI (`CI` set to a non-empty value other than `0`/`false`, case-insensitive) imply plain output unless overridden (steps 4 and 6 of that precedence list).
- Cursor-control or progress sequences (`\r`, `CSI 2K`, spinner frames) in pipes, files, or CI logs: gate them on `isatty` of the stream written to; see `domains/rendering-layout-performance/references/inline-progress.md`.
- Provide explicit flags such as `--color=auto|always|never`, `--plain`, and `--ascii`.

## Accessibility requirements

- All functionality must be keyboard-operable.
- Focus indicators must be visible without relying on color alone.
- Follow the flashing limit in `domains/unicode-color-accessibility/references/accessibility-fallbacks.md` (Cognitive and motion accessibility).
- Allow spinner, animation, and live-region suppression for reduced motion, logs, and CI.
- Provide screen-reader friendly alternatives: plain prompts, line-oriented commands, `--json`, `--plain`, or documented stdin/stdout workflows.
- Use meaningful labels, stable ordering, and visible status messages.

## Failure modes

| Symptom | Likely cause | Fix |
|--|--|--|
| Misaligned tables | byte length or ANSI counted as visible width; terminal emoji width differs from library | use ANSI-aware width library; keep emoji out of aligned columns or pad |
| Cursor splits emoji | movement by code point | move by grapheme cluster |
| Borders look broken | font or width mismatch | provide ASCII mode and test common fonts |
| Error only shown in red | color-only meaning | add text/icon/label and contrast check |
| Screen reader unusable | full-screen repaint grid | provide non-TUI mode and line-oriented flows |

## Reference files

- `domains/unicode-color-accessibility/references/text-measurement.md` - Unicode width, graphemes, width libraries per language, terminal width disagreement and probing, emoji, BiDi, and ANSI measurement. Read when columns misalign or the cursor drifts on non-ASCII text.
- `domains/unicode-color-accessibility/references/accessibility-fallbacks.md` - Color policy, screen-reader alternatives, and inclusive UX checklist. Read when adding color fallbacks, plain modes, or doing an accessibility review.
