# TUI Visual Design and Aesthetic Polish

Use this guide when a terminal UI needs to look deliberate, elegant, readable, and production-grade, not merely functional. Good TUI design is the craft of using cells, text, whitespace, color, borders, glyphs, rhythm, and motion under harsh terminal constraints. This guide holds the principles and checklists; each area's detailed recipes live in the reference files listed at the end.

## Design operating principles

1. **Start with information architecture.** Decide what the user must notice first, what is secondary, and what can be hidden until requested.
2. **Design in cells.** Every visual decision consumes fixed-width character cells. Padding, borders, scrollbars, and icons must earn their space.
3. **Use fewer treatments, consistently.** A polished TUI usually has one border language, one spacing scale, one heading system, and semantic color roles.
4. **Prefer calm defaults.** High-intensity color, heavy borders, inverse video, animation, and icons highlight state changes or actions; never use them to decorate every element.
5. **Make degradation intentional.** Make every visual design work in no-color, ASCII, narrow-width, light theme, remote SSH, and screen-reader-friendly modes.

## Area essentials

**Hierarchy and composition.** Build hierarchy with, in order: placement, spacing, grouping, text labels, alignment, weight, then color. Use a spacing scale such as 0, 1, 2, and 4 cells. Reserve full borders for important regions, and use progressive disclosure (detail panes, command palettes, help overlays) to keep the default screen calm.

**Typography.** Treat text as a hierarchy: title, section label, field label, hint, status. Use bold for headings and key values; use dim only for optional hints. Align labels left and numbers right, and truncate with intent (keep IDs unique, preserve file extensions).

**Borders.** Borders are punctuation. Pick one border family, avoid deep nested boxes, and use one cell of horizontal padding inside a border.

**Color.** Define semantic roles (primary, accent, success, warning, error, info, muted, selected, focused, disabled, border, surface) before raw colors. Keep one accent plus semantic states, support dark and light backgrounds, and downsample deliberately for 256 and 16 colors. Never encode meaning by color alone.

**Charts and density.** Make charts answer a question faster than raw numbers. Horizontal bars are the safest chart. Sparklines need min/max/current text, and heat maps need legends and text alternatives. Group dashboards by decision, not by available space.

**Motion.** Use motion only to communicate waiting, progress, transition, or attention. Pause or simplify it over SSH, in CI and logs, and in reduced-motion mode. Follow the flashing limit in `domains/unicode-color-accessibility/references/accessibility-fallbacks.md`.

**Icons and glyphs.** Pair status symbols with labels. Never require Nerd Fonts or private-use glyphs; offer `--ascii`. Test emoji width before using emoji in aligned layouts.

**Prompts and dialogs.** Show validation next to the failing field and defaults and consequences in text. Use focus indicators that survive no-color mode. Give destructive confirmations explicit action labels and safe defaults, and keep persistent errors in a stable region.

**Framework styling.** For Ratatui, Textual, Bubble Tea/Lip Gloss, Rich, Ink, Terminal.Gui, or Spectre.Console, read `domains/tui-visual-design/references/framework-styling.md`.

## Polish checklist

- One border family, one spacing scale, one heading system.
- Semantic color roles, tested on dark and light backgrounds and in 256, 16, and no-color modes.
- Focus, selection, and errors visible without color.
- Layout holds at 80×24 and at the declared minimum size, with a small-screen message below it.
- Numbers right-aligned, labels consistent, truncation preserves meaning.
- ASCII and plain modes available; decorative banners hidden in plain, narrow, CI, and accessibility modes.
- Animation is cheap, interruptible, and off in CI and reduced-motion mode.

## Visual anti-patterns

- Rainbow palettes with no semantic system.
- Every widget in a heavy border.
- Tiny text crammed against borders or terminal edges.
- Color-only errors, selections, or warnings.
- Center-aligned tables or numbers.
- Icons from Nerd Fonts with no fallback.
- Animated dashboards that redraw faster than data changes.
- Designs that only work at 120 columns.
- Ignoring light terminal themes, `NO_COLOR`, `TERM=dumb`, and non-TTY output.

## Reference files

- `domains/tui-visual-design/references/layout-typography.md` - Hierarchy, spacing, rhythm, typography, alignment, wrapping, and truncation. Read when laying out screens or fixing cramped or misaligned text.
- `domains/tui-visual-design/references/color-design.md` - Semantic palettes, contrast, theme adaptation, gradients, and constrained color modes. Read when building a palette or a theme.
- `domains/tui-visual-design/references/borders-icons-prompts.md` - Box drawing, containers, glyphs, icons, prompts, forms, dialogs, and notifications. Read when styling panels, prompts, or dialogs.
- `domains/tui-visual-design/references/charts-visualization.md` - Bars, sparklines, gauges, progress, tables, trees, heat maps, and dashboard density. Read when building data displays.
- `domains/tui-visual-design/references/animation-motion.md` - Spinners, transitions, scrolling, decorative effects, and performance limits. Read before adding any motion.
- `domains/tui-visual-design/references/framework-styling.md` - Styling recipes for Ratatui, Textual, Bubble Tea/Lip Gloss, Rich, Ink, Terminal.Gui, and Spectre.Console. Read when styling within a named framework.
