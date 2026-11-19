# Text Measurement Reference

## Width concepts

- Bytes: storage encoding, not visual width.
- Code points: Unicode scalar values, still not visual width.
- Grapheme clusters: user-perceived characters, useful for cursor movement and deletion.
- Cell width: terminal display columns, needed for layout.

A renderer usually needs both grapheme segmentation and width calculation.

## UAX-to-implementation mapping

| Unicode spec | What it covers | TUI implementation use |
|--|--|--|
| UAX #9 Bidirectional Algorithm | Logical-to-visual ordering for RTL/LTR text | Keep data logical; test mixed RTL/LTR; avoid manual reordering unless the app owns BiDi rendering. |
| UAX #11 East Asian Width | Narrow, wide, fullwidth, ambiguous character classes | Feed width library decisions; default ambiguous width narrow unless target CJK environment says otherwise. |
| UAX #14 Line Breaking | Allowed line break opportunities | Wrap prose without splitting required clusters; combine with terminal cell width. |
| UAX #29 Text Segmentation | Grapheme, word, sentence boundaries | Cursor movement, deletion, selection, truncation boundaries. |
| Emoji data / variation selectors | Emoji presentation, ZWJ sequences, modifiers, flags | Keep emoji ZWJ/flag sequences intact; test terminal-specific width differences. |

Implementation pipeline:

```text
input string
  -> parse/remove ANSI controls into style spans
  -> segment grapheme clusters (UAX #29)
  -> assign display cell width per cluster (wcwidth/EAW/emoji policy)
  -> wrap/truncate by accumulated cells (UAX #14 where wrapping prose)
  -> render cells with style metadata, never counting escape bytes
```

## Width and grapheme libraries

Do not hand-roll width tables. Use a maintained library per ecosystem:

| Ecosystem | Width | Grapheme segmentation |
|--|--|--|
| Rust | `unicode-width` (`UnicodeWidthStr::width`) | `unicode-segmentation` (`graphemes(true)`) |
| Python | `wcwidth` (`wcswidth`; returns -1 if the string has a control character, so strip controls first and treat -1 as an error, never add it to a width) | `regex` module `\X` (the older `grapheme` package is unmaintained, with stale Unicode data) |
| Go | `rivo/uniseg` (`StringWidth`) or `mattn/go-runewidth` | `rivo/uniseg` |
| Node | `string-width` (strips ANSI too) | `Intl.Segmenter` with `granularity: "grapheme"` |
| C | `wcwidth(3)`/`wcswidth(3)` (libc tables are often stale; consider a bundled table such as utf8proc) | utf8proc or ICU |

Frameworks usually bundle one of these (Ratatui uses `unicode-width`, Lip Gloss uses `uniseg`/`go-runewidth`, Rich and Textual carry their own tables, Ink uses `string-width`). Measure with the same library the framework uses, or columns drift.

## When terminals disagree on width

Libraries implement Unicode data; terminals implement their own tables. Emoji with a variation selector (VS16, U+FE0F), ZWJ sequences, skin-tone modifiers, and flags are the usual disagreements: one terminal draws `👩‍💻` in 2 cells, another in 4 or 5.

- Keep emoji, ZWJ sequences, and flags out of aligned table columns, or pad each cell to a fixed width and give the column 1 cell of slack.
- When exact width matters (an editor, a grid), probe: save the cursor, print the cluster at a known column, send `CSI 6 n` (cursor position report), read `CSI row ; col R`, then erase and restore. Cache results per cluster. Accept `CSI r;c R` as the reply only while the probe is outstanding: the same shape is a modified F3 key (`CSI 1;5R`).
- Grapheme cluster mode (DEC private mode 2027) asks the terminal to size whole clusters. Query it with `CSI ? 2027 $ p` (DECRQM). Enable it with `CSI ? 2027 h` only when the reply's Ps is 1 or 2 (set or reset), and disable it on exit. Contour, Ghostty, and foot answer the query. Some terminals that cluster graphemes, such as kitty, do not answer it (as of 2026-11, recheck), so a missing reply does not prove legacy widths.

## ANSI-aware measurement

Strip or parse ANSI escape sequences before measuring visible text. Preserve style metadata separately from text where possible. Never let escape bytes contribute to table width, wrapping, truncation, or cursor position.

Styled truncation example:

```text
input spans: [red "ERROR"], [plain ": database unavailable"]
limit: 12 cells
visible: "ERROR: datab"
output: SGR(red) "ERROR" SGR(reset) ": datab" SGR(reset)
```

If truncating inside a styled span, close/reset the active style. If the parent style must continue after the truncated fragment, reset then reapply the parent style explicitly.

## Test strings

Use these in unit, snapshot, and manual tests:

| Case | String | Expected concern |
|--|--|--|
| ASCII | `abcXYZ123` | Width equals character count. |
| CJK | `コンニチハ世界` | All are 2 cells (14 cells total). |
| Fullwidth punctuation | `ＡＢＣ，：！` | Fullwidth Latin/punctuation are wide. |
| Combining mark | `é` (`e` + U+0301) | One grapheme, usually 1 cell. |
| Precomposed | `é` | Same visual intent as combining form. |
| Emoji | `🙂` | Often 2 cells; terminals vary. |
| Emoji skin tone | `👍🏽` | One grapheme; do not split modifier. |
| ZWJ sequence | `👩‍💻` | One grapheme sequence; width varies but often 2 cells. |
| Family emoji | `👨‍👩‍👧‍👦` | Long ZWJ sequence; never truncate mid-sequence. |
| Flag | `🇺🇸` | Regional indicator pair; keep together. |
| Variation selector | `✈︎ ✈️` | Text vs emoji presentation can alter width. |
| RTL | `abc שלום 123` | Logical storage with terminal/display BiDi behavior. |
| ANSI styled | `\x1b[31mred\x1b[0m plain` | Visible width excludes SGR. |
| Controls | `safe\x1b[2Jspoof` | Sanitizer must not execute ESC. |
| Ambiguous | `·Ω─` | Width may differ in CJK contexts. |

## Double-width and zero-width cases

Test CJK ideographs, Hangul, fullwidth punctuation, combining accents, emoji with skin tone modifiers, zero-width joiner sequences, flag sequences, variation selectors, and private-use glyphs. Different terminals and fonts can disagree; keep fallbacks practical.

## Truncation and wrapping

Truncate by grapheme and cell width, not bytes. Do not split a double-width glyph at the final column. When a styled string is truncated, close/reset styles safely. Account for wide characters when wrapping, and preserve indentation semantics.

Pseudo-code:

```text
truncate_to_cells(spans, limit):
  out = []
  used = 0
  for span in spans:
    for cluster in graphemes(span.text):
      w = cell_width(cluster)
      if used + w > limit: return close_styles(out)
      out.append(cluster with span.style)
      used += w
  return close_styles(out)
```

## Line breaking and shaping

Unicode line breaking, grapheme segmentation, and terminal cell width are related but different. Wrap on grapheme boundaries and avoid splitting combining sequences, emoji ZWJ sequences, flags, and double-width cells. Terminals generally do not expose full font shaping decisions to applications; ligatures and font-specific glyph substitution can change appearance without changing cell counts.

## BiDi text

Keep text in logical order when possible and let terminal display behavior handle ordering. For full-screen cell renderers, test mixed LTR/RTL content and avoid manual reordering unless the application intentionally owns a BiDi strategy. If precise BiDi layout is required, document the strategy and test with UAX #9-style cases.

## Symbol sets and fonts

Box drawing, block elements, braille patterns, powerline glyphs, Nerd Font icons, emoji presentation sequences, variation selectors, and private-use characters can render differently across fonts and terminals. Provide ASCII mode, avoid private-use icons for essential meaning, and test with common monospace fonts.
