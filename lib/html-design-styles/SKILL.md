# HTML Design Styles

This skill provides 53 named design styles for HTML/CSS frontend work. Each style is a complete, opinionated specification - color palette, typography stack, component patterns (cards, buttons, navs), layout conventions, and signature visual mechanics. Apply the chosen style faithfully without substitution.

The styles range across many design traditions: minimalist (Swiss, Scandinavian, Japanese), brutalist (Pure Brutalist, Neobrutalist, Acid Brutalist, Monolith), retro (Y2K, Vaporwave, Memphis, Pixel, Retro Terminal), dark/atmospheric (Dark Cinema, Dark Cosmic, Dark Action, Dark Neon, Cyberpunk, Sci-Fi HUD), warm/organic (Cottagecore, Organic, Tropical, Groovy), editorial (Newspaper, Longform, Enterprise Editorial, Luxury), playful (Kawaii, Memphis, Manga, Pop Art), and many more.

---

## Initialization Gate

Before generating any code, confirm:

1. **Which style?** The user must name one from the catalog. If they say "modern", "clean", "minimal", a category word like "brutalist" / "dark" / "retro" / "terminal" that matches multiple catalog entries, or nothing at all, **prefer the `AskUserQuestion` tool over plain text** to present the matching styles as a structured multi-choice picker - that gives the user keyboard navigation and selection rather than forcing them to retype a style name. Include each candidate style as a suggested option with its one-line description from the catalog table; allow a free-text fallback for "something else from the catalog" or to switch styles. Use plain text only when `AskUserQuestion` isn't available in the runtime.
2. **Determine what is being styled.** A full page, a single component, a section? If the user pasted markup to restyle, work from that markup; if they want something built from scratch, confirm the page type (landing page, dashboard, blog post, app shell, etc.).
3. **Identify any constraints.** Existing color palette to honor? Required content (specific headlines, sections)? Output format (single HTML file vs. multiple files)? If unstated, default to a single self-contained HTML file with CDN Tailwind and inline `<style>` for custom rules.

If the user has not picked a style, do not invent one. Ask - via `AskUserQuestion` if available.

---

## How to use this skill

1. **Identify the style** from the user's request. Match against the catalog table below. If the request is ambiguous (no style named, a category word that matches multiple styles like "brutalist"/"dark"/"retro", or anything not corresponding to a single catalog entry), **prefer the `AskUserQuestion` tool** to present matching styles as a structured multi-choice picker rather than asking via plain text - keyboard selection is faster than retyping a style name. Pass each candidate style as an option with its one-line description from the catalog table.
2. **Get project context** - page type, content, any markup to restyle.
3. **Load references**:
   - Read `${CLAUDE_PLUGIN_ROOT}/lib/html-design-styles/references/common.md` once per session for cross-cutting patterns (font loading, container widths, marquee, scrollbar, focus states, accessibility).
   - Read `${CLAUDE_PLUGIN_ROOT}/lib/html-design-styles/references/styles/<slug>.md` for the chosen style's complete spec. The slug is in the table below.
4. **Apply the style faithfully**. Use the exact color values, typography stack, shadow recipes, and component patterns from the style file. Do not substitute "similar" colors or "close enough" fonts. Do not blend two styles unless the user explicitly asks. The opinionated specifications are the entire value of the catalog - preserve them.

---

## Available styles

| Style | Slug | One-line description |
|-------|------|----------------------|
| Acid Brutalist | `acid-brutalist` | Pure black with acid yellow + brutal red, Anton/Bebas Neue display, noise grain overlay - punk and chaotic. |
| Art Deco | `art-deco` | 1920s symmetry, geometric gold ornaments and sunburst motifs on black or ivory - opulent and formal. |
| Athletic | `athletic` | Diagonal clip-path cuts, condensed Barlow caps, hard color blocks - sports-branding energy. |
| Aurora | `aurora` | Drifting multi-color gradient blobs blended like silk over deep base - dreamy and ethereal. |
| Bento | `bento` | Apple/macOS bento grid: white cards on light gray, Plus Jakarta Sans, blue accent - clean and trust-building. |
| Blueprint | `blueprint` | Midnight blueprint blue with white grid, Courier Prime, crosshair cursor, technical drawing details. |
| Clay | `clay` | Chunky rounded cards with 3-layer purple shadow, Nunito 900, candy section colors - physical and toy-like. |
| Corporate | `corporate` | Conservative navy + blue, IBM Plex Sans, structured grid, professional B2B trust signals. |
| Cottagecore | `cottagecore` | Sage and dusty-rose pastels, Playfair italic + Lato Light, botanical SVG accents - storybook softness. |
| Cyberpunk | `cyberpunk` | Yellow/black hazard stripes, clip-path angled corners, Orbitron + Rajdhani - dystopian danger aesthetic. |
| Dark Action | `dark-action` | Cobra-black gradient with FCD34D yellow, Oswald display, gold pulse-glow - cinematic martial energy. |
| Dark Cinema | `dark-cinema` | Near-black with red glow, Bebas Neue, noise overlay, floating animated rotated labels - visceral. |
| Dark Cosmic | `dark-cosmic` | Slate-950 base with indigo/cyan glow blobs, glassmorphism cards, dot grid - SaaS infrastructure feel. |
| Dark Mono | `dark-mono` | Dark zinc panels, system monospace, cyan + pink color pops, scanline texture - compact and techy. |
| Dark Neon | `dark-neon` | Pure black with multiple simultaneous neon glow colors (pink/cyan/green/purple) - club/gaming. |
| Dark SaaS | `dark-saas` | Slate-950 base, sky-blue accent, staggered fade-up animations, trust chips - polished SaaS landing. |
| Dashboard | `dashboard` | 240px sidebar + slate-50 main, Inter, metric cards, data tables, status badges - admin/analytics. |
| Dot Grid | `dot-grid` | Gray dotted bg, Archivo Black + Space Mono, hot pink hover, hard 10px black shadows - content portal. |
| Enterprise Editorial | `enterprise-editorial` | Alternating white/dark sections, Inter font-black, indigo, large rounded "app" mockup cards. |
| Glassmorphism | `glassmorphism` | Frosted blur cards over vivid mesh-gradient backgrounds, Outfit/DM Sans - futuristic and airy. |
| Gothic | `gothic` | Forest greens and near-black, Cinzel + Crimson Text, blood-red wax drips, gold ornament accents. |
| Groovy | `groovy` | Warm 70s oranges/mustards/avocado, Righteous bubble lettering, irregular border-radius cards. |
| Grunge | `grunge` | Aged paper textures, Bebas Neue + Courier, splatter clip-paths, distressed worn aesthetic. |
| Handwritten | `handwritten` | Caveat headlines, SVG-displaced sketchy borders, irregular border-radius - designer's sketchbook feel. |
| Isometric | `isometric` | Soft blue-white bg with isometric 3D cubes, blue-purple top/left/right faces, iso-direction shadows. |
| Japanese | `japanese` | Washi off-white with sumi black, Cormorant Garamond, persimmon accent, asymmetric negative space. |
| Kawaii | `kawaii` | Blush whites with candy pastels, Nunito 900, bounce/wiggle animations, mascot emoji accents. |
| Longform | `longform` | Full-bleed hero photo, Merriweather + Playfair, drop caps, pull quotes, sidebar annotations - magazine. |
| Luxury | `luxury` | Cream + Cormorant Garamond, generous py-32/py-48 whitespace, brass gold accents - refined and editorial. |
| Manga | `manga` | High-contrast black/white with single red pop, Bangers SFX text, halftone dots, panel clip-paths. |
| Maximalist | `maximalist` | Layered patterns on patterns, Bebas Neue + Abril Fatface, clashing colors, intentional density. |
| Memphis | `memphis` | 80s/90s pastels (pink, yellow, turquoise), Fredoka One, scattered geometric shapes - playful chaos. |
| Monolith | `monolith` | White with thick `border-t-8` dark navy top edge, system monospace, 4px navy offset shadows. |
| Neobrutalist | `neobrutalist` | Light gray bg, hard 5px black shadows, neon accents (purple/green/pink/yellow/blue), Space Grotesk. |
| Neumorphism | `neumorphism` | All elements share `#e0e5ec` bg; dual light/dark shadows extrude or inset everything - soft tactile UI. |
| Newspaper | `newspaper` | Warm newsprint paper, Playfair + Lora serif, column grids, drop caps, red flag accents - print editorial. |
| Organic | `organic` | Warm cream + terracotta + sage, Fraunces serif, irregular blob border-radius - hand-crafted natural. |
| Pink Neo | `pink-neo` | Hot-pink dotted page with floating white cards, Archivo Black + Space Mono, multi-color tag pills. |
| Pixel | `pixel` | Press Start 2P with classic NES/Game Boy/CGA palettes, image-rendering pixelated - 8-bit game UI. |
| Pop Art | `pop-art` | Cyan page hosting a max-w-1280 white-bordered floating box, IBM Plex Mono headlines - energetic. |
| Psychedelic | `psychedelic` | Cycling rainbow gradient body, morphing blob border-radius, wavy skew text - melting reality. |
| Pure Brutalist | `pure-brutalist` | System monospace, pure black/white, hard 8/5/3px black shadows, no border-radius - confrontational. |
| Retro Terminal | `retro-terminal` | #00ff41 phosphor green on near-black, CRT scanlines, screen vignette, blinking cursor, glow-text. |
| Scandinavian | `scandinavian` | Barely-warm white, Sora 300, single terracotta accent, lowercase headings, py-28 whitespace. |
| Sci-Fi HUD | `sci-fi-hud` | Cyan corner brackets, Orbitron + Share Tech Mono, scan-line animation, data-readout patterns. |
| Skeuomorphic | `skeuomorphic` | Realistic material gradients (metal, leather, paper, wood), inset+outset shadows, top-left light source. |
| Soft Modern | `soft-modern` | White with blurred orb backgrounds, system-ui, blue/pink, focus-visible rings - friendly and accessible. |
| Swiss | `swiss` | International Typographic Style: white/black/red only, mathematical grid, no decoration. |
| Tropical | `tropical` | Coral/turquoise/sandy palette, Nunito 800, rounded cards with colored top bars - vacation/resort. |
| Utility Terminal | `utility-terminal` | White with strict 1px black borders, system monospace, no border-radius, terminal panel + scanlines. |
| Vaporwave | `vaporwave` | Dark purple-black with retro perspective grid floor + synthwave sun, Audiowide + VT323, gradient text. |
| Y2K | `y2k` | Windows 95/98 gray bevels, system fonts, raised/sunken outset/inset borders, blue title bar gradient. |
| Zine | `zine` | Aged newsprint, Special Elite + VT323, intentionally rotated cards, rubber-stamp labels, tape strips. |

---

## Always-active rules

- **Load `common.md` once per session** - it covers font loading, container/padding conventions, focus rings, marquees, scrollbars, and accessibility patterns shared across many styles. Don't re-load it per request.
- **Output complete working code.** Single self-contained HTML file by default, with CDN Tailwind and an inline `<style>` block for custom rules. Production-ready, not a stub.
- **Preserve the user's existing structure when restyling.** If they paste markup and ask for a new look, change classes, colors, fonts, and decorative elements - but keep their content, semantic tags, and DOM hierarchy intact unless they ask otherwise.
- **Honor accessibility baselines from `common.md`** (skip link, landmarks, focus-visible rings, aria-labels, prefers-reduced-motion). If a style's signature mechanic conflicts with WCAG (e.g. extremely low-contrast text in some maximalist or grunge variants), implement the style as specified but flag the deviation in a one-line comment so the user can review.
- **Don't blend styles.** If the user names one style, deliver that one style. Cross-pollination dilutes both. If they want a hybrid, ask which one is dominant and which one provides the accent.

---

## Decision points

### User names a style not in the catalog

Suggest the closest match from the table above. Examples:
- "wireframe" → Blueprint or Utility Terminal
- "cartoon" → Kawaii or Memphis
- "futuristic" → Sci-Fi HUD, Cyberpunk, or Dark Cosmic
- "minimal" → Scandinavian, Swiss, or Soft Modern (ask which)
- "elegant" → Luxury or Art Deco (ask which)
- "old-school computer" → Retro Terminal, Y2K, or Pixel (ask which)
- "newspaper" → Newspaper (already in catalog)

Offer 2-3 candidates with one-line distinctions and let the user pick.

### User asks for ambiguous adjectives

Words like "modern", "clean", "professional", "simple", "fresh", "bold", or "fun" map to many styles. Ask the user to choose from a short list rather than guessing:

> "Several catalog styles fit 'modern and clean' - would you like:
> - **Soft Modern** (white + blurred blue/pink orbs, system font, friendly)
> - **Bento** (Apple-style cards on light gray, Plus Jakarta Sans, blue accent)
> - **Dark SaaS** (slate-950 + sky blue, staggered animations, polished)
> - **Swiss** (white + black + red only, rigid grid, zero decoration)?"

### User asks "what styles do you support"

List the table above. Group by mood if helpful (minimalist / brutalist / dark / retro / playful / editorial / etc.) but the table is the authoritative inventory.

### User asks for two styles at once

Confirm: "Should the page be primarily [style A] with [style B] accents, or vice versa?" Then deliver one as the dominant frame and use the other only for specific components (e.g., a Bento layout with Memphis decorative accents). Note in a comment which style is dominant.

### User wants to restyle existing markup

Read their HTML carefully. Preserve content, semantic tags, IDs/classes that drive functionality, and overall DOM shape. Replace styling-only classes (Tailwind utilities, CSS class names) and inject the new style's color palette, typography, and component patterns. If they have existing custom CSS, replace it wholesale - don't try to merge two design systems.
