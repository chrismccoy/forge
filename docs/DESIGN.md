# Landing Page Design

Design reference for `docs/index.html`, the Forge landing page. Read this before changing the page or adding a section, so new work matches what is already there.

The page is one self-contained HTML file. It loads Tailwind (CDN), Inter (Google Fonts), and Font Awesome 6.5.1 (cdnjs).

## Building the page

`docs/index.html` is generated. Do not edit it directly; edit the template and rebuild:

```
python3 tools/build_landing.py
```

- `tools/landing-template.html` holds all markup, CSS, and script. It has two placeholders: `__TOOLS__` (the tool data) and `__VERSION__` (from `.claude-plugin/plugin.json`).
- `tools/build_landing.py` reads `README.md`, `SUMMARY.md`, and every `lib/<tool>/` folder, fills the placeholders, and writes `docs/index.html`. It prints the tool count per category.
- It writes nothing and exits with an error if a README tool has no `lib/` folder, no quick-start tagline, or no row in a `SUMMARY.md` table, or if a category is missing from `CATS` in the template.

Rebuild after adding, renaming, or moving a tool, and after changing the template. The output only changes when its inputs change, so a rebuild with no changes leaves the file byte-identical.

## Style

The page uses the **Dashboard** style from the `html-design-styles` catalog in this plugin (`lib/html-design-styles/references/styles/dashboard.md`): an admin/analytics look with a dark sidebar, a light main area, metric cards, a chart, data tables, and status badges.

The style is applied to a landing page on purpose. The marketing content is shown as data: stat cards hold real repo numbers, the chart shows real per-category sizes, and the catalog is a filterable, paged table. Keep that idea when adding content. A new section should look like a dashboard panel, not a marketing hero.

Rules that keep the style intact:

- Use only the colors in the token table below. Do not add new hues.
- Do not mix in other styles (gradients, glass, large illustrations, decorative shadows).
- Numbers, commands, file paths, and IDs are always `font-mono`.
- Headings are `font-medium`, never bold. Only metric numbers are bold.

## Color tokens

| Token | Hex | Tailwind | Used for |
|---|---|---|---|
| Background | `#f8fafc` | `slate-50` | Main area, table header, row hover |
| Sidebar | `#0f172a` | `slate-900` | Sidebar, code blocks |
| Surface | `#ffffff` | `white` | Cards, panels, tables |
| Border | `#e2e8f0` | `slate-200` | Card borders, dividers, pill borders |
| Row divider | `#f1f5f9` | `slate-100` | Lines between table rows |
| Text | `#1e293b` | `slate-800` | Body text |
| Heading | `#0f172a` | `slate-900` | Section titles |
| Muted | `#64748b` | `slate-500` | Subtitles, labels, captions |
| Primary | `#3b82f6` | `blue-500` | Chart bars, focus ring, selection, full toolkits |
| Primary action | `#2563eb` | `blue-600` | Main button, active nav item, command names |
| Success | `#22c55e` | `green-500` | Positive delta, guided helpers |
| Warning | `#f59e0b` | `amber-500` | Quick win |
| Danger | `#ef4444` | `red-500` | Negative delta, "off" icon |

There are ten categories and the style has only five colors, so categories are **not** color coded. Every chart bar is the same blue, and categories are told apart by their label and Font Awesome icon (the `icon` field in `CATS`). Color carries meaning only for tool size: full toolkit, guided helper, quick win.

Text selection is `#3b82f6` on white.

## Typography

- Font: Inter, weights 400, 500, 600, 700. Fallback `system-ui, sans-serif`.
- Body is `antialiased`.
- Page title: `text-2xl md:text-3xl font-medium tracking-tight text-slate-900`.
- Section title: `text-base font-medium text-slate-900`, with a `text-sm text-slate-500` subtitle under it.
- Metric number: `text-3xl font-bold font-mono tracking-tight`.
- Sidebar section label: `text-[10px] uppercase tracking-widest text-slate-500`.
- Table header: 11px, 600, uppercase, `letter-spacing: 0.05em`, `#64748b` (set in the `<style>` block).

## Layout

- `.dashboard-layout` is a CSS grid: one column on small screens, `240px 1fr` from 1024px (`lg`) up.
- The sidebar is sticky and full height on `lg` and up. Below `lg` it becomes a top bar with a menu button (`#navToggle`) that shows and hides `#sideNav`.
- The main area has 24px padding. Content sits in `mx-auto max-w-7xl space-y-6`, so every section is 24px apart.
- Panels use grids that collapse to one column: `grid-cols-1 sm:grid-cols-2 xl:grid-cols-4` for the stat cards, `xl:grid-cols-3` with a `xl:col-span-2` panel for the chart and table rows, `xl:grid-cols-2` for the picker row.
- Sections that the sidebar links to carry `scroll-mt-6`.
- The page must never scroll sideways at 390px width. Wide content (chart, tables, code) sits in an `overflow-x-auto` wrapper.

## Components

Each component has a fixed recipe. Copy it rather than inventing a variant.

**Panel / card.** `.chart-container` or `.metric-card`: white, `1px solid #e2e8f0`, 12px radius, 20px padding. Tables use the same border and radius with `rounded-xl border border-slate-200 bg-white` and no padding, with a padded header strip (`p-5 border-b border-slate-200`).

**Metric card.** Label top left (`text-sm text-slate-500`), icon top right in a 36px circle (`h-9 w-9 rounded-full bg-<color>-50 text-<color>-500`), big mono number, then a one-line note at the bottom that starts with a delta pill. Numbers that come from the data use `data-stat="<key>"` and are filled from `STATS`.

**Delta pill.** `.delta-up` (green on `#f0fdf4`) or `.delta-down` (red on `#fef2f2`), 100px radius, 12px, 600, with a small arrow or plus icon.

**Status badge.** `.badge` plus one color pair:

| Meaning | Classes |
|---|---|
| Full toolkit / active | `bg-green-100 text-green-700` |
| Quick win / caution | `bg-amber-100 text-amber-700` |
| Error | `bg-red-100 text-red-700` |
| Guided helper / neutral | `bg-slate-100 text-slate-600` |
| Info chip | `bg-blue-50 text-blue-600` |

`typeBadge(type)` in the script returns the right badge for a tool size.

**Pill group.** `.pill-group` wrapping `<button>`s. The selected button has `aria-pressed="true"`, which the CSS styles as `bg-blue-50 text-blue-600`. Use it for any single-choice switch (chart metric, size filter, table paging).

**Select.** The category filter is a native `<select>` with `rounded-lg border border-slate-200 bg-white py-1.5 pl-3 pr-8 text-sm`. Use a select instead of a pill group when there are more than about five choices.

**Buttons.** Primary: `rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700`. Secondary: `rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50`. Icons are Font Awesome with `aria-hidden="true"`.

**Sidebar nav item.** `flex items-center gap-3 px-4 py-2.5 rounded-lg mx-2 text-sm font-medium`. Active: `bg-blue-600 text-white`. Inactive: `text-slate-400 hover:bg-slate-800 hover:text-white`. Add `data-nav` to a link that points at a page section so the scroll tracker can highlight it. Sidebar category links are smaller (`py-1.5`) and carry `data-cat-link` instead.

**Data table.** Plain `<table>`; all styling comes from the `<style>` block (header, cell padding, row hover). Selectable rows get `tabindex="0"`, `data-cmd`, and `aria-selected`. The selected row is tinted `#eff6ff`. The commands table shows 12 rows per page (`PAGE_SIZE`) with a page strip below it.

**Bar chart.** Flex row of `.bar-col` columns, each holding its value in mono above a `.bar` (blue, `4px 4px 0 0` radius) whose height is a percentage of the largest value. Labels sit in a separate flex row below: icon, then the category's `short` name.

**Picker screen.** Mimics an `AskUserQuestion` menu: a header strip with an info chip and the question, numbered options as full-width buttons (`( 1 )` in mono), a "More..." or "Back to page 1" option last, and an `[Other]` footer line.

**Code block.** `rounded-xl bg-slate-900`, `font-mono text-sm text-slate-200`, comments in `text-slate-500`. Copyable blocks have a header strip with a `data-copy="<id>"` button that copies the `<pre id="<id>-code">`.

**Step card** (How it runs). Bordered `rounded-xl p-4` box: mono step number and a badge on top, a title, a mono path in `text-blue-600`, and one muted sentence.

## Page sections

In order: header (breadcrumb, title, buttons), stat cards, category chart and tool size card, commands table with the detail panel, picker demo and category pickers table, "How a command runs", install, footer.

## Script

All behavior is plain JavaScript at the bottom of the file. There are no frameworks.

**Data.** `TOOLS` is an array with one object per tool. `tools/build_landing.py` generates it from `README.md`, `SUMMARY.md`, and the `lib/` folders:

| Field | Meaning |
|---|---|
| `cmd` | Slash command without the slash, e.g. `explain-regex` |
| `lib` | Folder under `lib/` |
| `cat` | Category name, exactly as in the README (`Code Cleanup`, `Docs & Diagrams`, ...) |
| `doc` | File under `docs/` without `.md`; with `lib` it builds the "Full write-up" link |
| `type` | `Toolkit`, `Helper`, or `Quick win` (the tables in `SUMMARY.md`) |
| `tag` | Short tagline (the comment after the command in the README quick start) |
| `desc` | Full description (the README "Available commands" entry) |
| `lines` | Lines of `.md` in the tool's `lib/` folder |
| `refs`, `scripts`, `files` | Files under `references/`, under `scripts/`, and in total |

`CATS` lists the ten categories in README order. Each entry has `name` (must match `cat`), `short` (chart label), `picker` (category command), `icon`, and `screens` (from the README picker table).

Totals in the stat cards, the chart, the tool size card, the sidebar counts, the dropdown counts, and the category pickers table are all computed from `TOOLS` and `CATS`. Only the 11 pickers card and the text in the header and install sections are hard-coded.

**Render functions.** `renderChart(metric)`, `renderTable()`, `renderDetail(cmd)`, and `renderPicker()` rebuild their part of the page from the data. `jumpTo(cmd)` clears the filters, opens the table page that holds a tool, selects it, and scrolls to the table; the picker demo and the "Deepest procedures" list use it through `data-jump`. Change the data, not the generated HTML. Any text from the data goes through `esc()` before it is put into HTML, and `cap()` capitalizes taglines for display.

**In-page links.** One click handler catches every `a[href^="#"]`, scrolls to the target, and moves focus to it without writing `#` into the URL. A hash already in the URL is removed after load. Keep `href="#id"` on new links so they still work without JavaScript.

**Active section.** An `IntersectionObserver` watches each section that a `[data-nav]` link points to and highlights that link.

## Accessibility

- A skip link to `#main` is the first focusable element.
- Landmarks: `<aside>`, `<nav aria-label>`, `<main id="main">`, `<footer>`. Every `<nav>` has a distinct label.
- Focus ring: 2px `#3b82f6` outline with 2px offset on links, buttons, inputs, selects, and table rows, shown only with `:focus-visible`.
- Switches use `aria-pressed`; the detail panel uses `aria-live="polite"`; the chart has `role="img"` and an `aria-label`.
- `prefers-reduced-motion` turns off transitions and smooth scrolling.

## Adding to the page

All of these are edits to `tools/landing-template.html`, followed by a rebuild.

- **A new tool:** add it to the README (an "Available commands" entry and a quick-start tagline) and to a `SUMMARY.md` table, then rebuild. No template change is needed unless it adds a picker screen (update `screens` for its category in `CATS`) or changes the command total (update the 87 / 11 counts in the header, install text, and repo layout block).
- **A new category:** add an entry to `CATS` in README order with a `short` label of one word and a Font Awesome icon. The build stops until you do.
- **A new section:** wrap it in `.chart-container` (or a bordered table panel), give it an `id` and `scroll-mt-6`, add a sidebar link with `data-nav`, and use the section title and subtitle recipe above.
- **A new stat:** copy a `.metric-card`, add the value to `STATS`, and use an icon circle color from the token table.

Check the result at 1440px and 390px before committing.
