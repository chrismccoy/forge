# CSS value → Tailwind utility mapping

Turn the real computed values (from `original/computed.json`) into canonical Tailwind
classes. Map to the **nearest** Tailwind step unless the value is oddly specific — then
use an arbitrary value `[...]` so the look stays exact. Fidelity beats tidiness: a
`px-[19px]` that matches the original is better than a `px-5` that doesn't.

## Spacing — padding / margin / gap / width / height

Tailwind spacing unit = 0.25rem = 4px. `n = px / 4`.

| px | class step | | px | class step |
|----|-----------|-|----|-----------|
| 4  | 1 | | 32 | 8 |
| 8  | 2 | | 40 | 10 |
| 12 | 3 | | 48 | 12 |
| 16 | 4 | | 64 | 16 |
| 20 | 5 | | 80 | 20 |
| 24 | 6 | | 96 | 24 |

Prefixes: `p`/`px`/`py`/`pt…`, `m`/`mx…`, `gap`, `w`/`h`, `max-w`, `min-h`.
Off-scale → arbitrary: `pt-[13px]`, `gap-[18px]`, `w-[340px]`.
Common maxWidth containers: 640→`max-w-screen-sm`, 768→`md`, 1024→`lg`, 1280→`xl`,
1536→`2xl`; or `max-w-[1200px]` for custom.

**`width`/`height` are resolved, not authored — apply judiciously.** `computed.json`'s
`width`/`height` are the *used* pixels at the 1280 capture (e.g. a full-width block
reads `1232px`). Do NOT blindly emit `w-[1232px]`/`h-[…]` — that hardcodes a layout that
should flex, and it breaks at the narrow-width check. Only translate them when the
source CSS in `clone/index.html` actually authored a fixed size (a `150px` avatar, a
fixed sidebar). For everything else, let flow/flex/`max-w`/`min-h` size the element and
ignore the incidental width/height. Same rule as grid tracks and line-height below.

## Typography

- **font-size** (px→class): 12`text-xs` 14`text-sm` 16`text-base` 18`text-lg`
  20`text-xl` 24`text-2xl` 30`text-3xl` 36`text-4xl` 48`text-5xl` 60`text-6xl`
  72`text-7xl`. Off-scale → `text-[17px]`.
- **font-weight**: 400`font-normal` 500`font-medium` 600`font-semibold`
  700`font-bold` 800`font-extrabold` 900`font-black`.
- **line-height**: unitless 1`leading-none` 1.25`leading-tight` 1.375`leading-snug`
  1.5`leading-normal` 1.625`leading-relaxed` 2`leading-loose`; or `leading-[1.15]`.
  Note: `computed.json` reports line-height **resolved to px** (`27px`), not a ratio.
  Either divide by the element's font-size to get the ratio, or use `leading-[27px]`
  directly — both match; arbitrary px is expected here, not a mistake.
- **letter-spacing**: negative→`tracking-tight`/`tracking-tighter`,
  0`tracking-normal`, wide→`tracking-wide`/`wider`; exact → `tracking-[0.02em]`.
- **text-align**: `text-left/center/right/justify`.
- **text-transform**: `uppercase`/`lowercase`/`capitalize`.
- **font-family**: match by stack — serif→`font-serif`, mono→`font-mono`, else keep
  the real family with an arbitrary class `font-['Inter']` and load the font (see
  below). Don't silently swap fonts; that changes the look.

## Color

Read the real hex/rgb. Don't force it onto Tailwind's default palette unless it's a
genuine match — brand colors rarely are. Use arbitrary values:
`text-[#1a1a1a]`, `bg-[#0b5fff]`, `border-[#e5e7eb]`. Reserve named tokens
(`text-gray-900`, `bg-white`, `bg-black`) for exact matches. `rgba()` with alpha →
`bg-[rgba(0,0,0,0.5)]` or `bg-black/50`.

**Watch the resolved formats in `computed.json`:** colors come back as `rgb()`/`rgba()`,
not hex — `rgb(58, 75, 227)` is `#3a4be3`; convert or use `bg-[rgb(58,75,227)]`
(strip the spaces inside the arbitrary value). `box-shadow` comes back **color-first**
(`rgb(...) 0px 4px 12px`), while the CSS you'd author is offset-first — reorder to
`shadow-[0_4px_12px_rgb(...)]`. Gradient stops and `letter-spacing` are likewise
resolved to px/rgb.

- **background-image** with `linear-gradient(...)` → `bg-[linear-gradient(...)]`, or
  Tailwind's `bg-gradient-to-r from-[..] to-[..]` when it's a simple 2-stop.

## Border / radius / shadow

- **border-radius**: 2`rounded-sm` 4`rounded` 6`rounded-md` 8`rounded-lg`
  12`rounded-xl` 16`rounded-2xl` 24`rounded-3xl` 9999`rounded-full`; else
  `rounded-[10px]`.
- **border**: width 1`border` 2`border-2`; color `border-[#e5e7eb]`; style
  `border-dashed` etc. Full: `border border-[#e5e7eb]`.
- **box-shadow**: map to `shadow-sm/DEFAULT/md/lg/xl/2xl` by rough blur size; exact →
  `shadow-[0_4px_12px_rgba(0,0,0,0.08)]`.

## Layout — flex / grid

- `display:flex` → `flex`; `flex-direction:column` → `flex-col`.
- justify-content: start`justify-start` center`justify-center` space-between
  `justify-between` etc. align-items: center`items-center` stretch`items-stretch`.
- `flex-wrap:wrap` → `flex-wrap`.
- `display:grid` + `grid-template-columns: repeat(3,1fr)` → `grid grid-cols-3`;
  arbitrary tracks → `grid-cols-[200px_1fr]`. Note: `computed.json` reports grid
  tracks **resolved to pixels** (`200px 200px 200px`), not `repeat(3,1fr)` — read the
  real template from `clone/index.html`'s CSS to pick `grid-cols-3` over a pixel blob.
- position: `relative`/`absolute`/`fixed`/`sticky`.

## Responsive & states — from the REAL CSS, not computed.json

computed.json is one viewport, one state. For the rest, read the inlined CSS in
page-cloner's `clone/index.html`:

- `@media (min-width: 768px){…}` → `md:` prefix (640`sm:` 768`md:` 1024`lg:`
  1280`xl:` 1536`2xl:`). Tailwind is mobile-first: base classes = smallest
  breakpoint, `md:` etc. layer larger screens on top.
- `:hover` rules → `hover:`; `:focus` → `focus:`; `:active` → `active:`.
- transitions → `transition` + `duration-200` + `ease-…`.

## Tailwind Preflight strips defaults — restore them explicitly

The rewrite loads Tailwind's CDN, which includes **Preflight**: it zeroes heading
sizes/weights (→ inherit), removes list markers and indent, and zeroes default block
margins. So a semantic `<h1>`/`<ul>`/`<p>` with no utilities renders flat. `computed.json`
force-emits these props (even when they matched the browser default), so always map
them onto the element: headings → `text-*`/`font-*`, lists → `list-disc pl-*`, block
margins → `mt-*`/`mb-*`. If a heading or list looks unstyled in validation, this is why.

## Fonts

If the original loads a web font (Google Fonts `<link>` or `@font-face`), keep that
`<link>`/`@font-face` in the rewrite's `<head>` and reference the family via
`font-['Family_Name']`. A clone that falls back to system fonts does not match.
