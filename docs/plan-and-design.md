# Plan and Design

[← Back to the README](../README.md)

## `app-blueprint`

Turns a one-line app idea into a complete, production-ready application blueprint.

```
/blueprint
```

Ever sat down to build something and realized the hardest part isn't writing the code. it's deciding the folder layout, the data models, the API surface, the deployment target, and the testing plan before you've typed a single line? That's what this plugin solves.

The `app-blueprint` skill behaves like a senior software architect with 15+ years of production experience. Hand it five inputs (what the app does, the tech stack, the workload type, the language, and the scale) and it produces an 11-section blueprint with the folder tree, the layer walkthrough, the data models, every API endpoint, dependency choices with reasoning, environment variables, a testing plan, a deploy plan justified by your scale, architect's notes, and a self-validation table that auto-repairs inconsistencies before delivery.

What makes it different from a generic "design my app" prompt? It refuses to invent. no `MyApp`, no `UserService`, no `Entity1`. Every name derives from your `APP_DESCRIPTION`. It enforces consistency. every entity in the data-model section must appear in at least one API endpoint, every dependency must map to a folder or reference, the deployment target must be justified by your stated scale with a stated migration trigger. And it halts cleanly with `MISSING INPUT: <field> required` instead of guessing when an input is blank.

It produces the plan a senior engineer would draft in their first ten minutes on a project, at any size: a weekend side project, a team kickoff, or a `BLUEPRINT.md` for something going to production.

## 📋 Technical Overview

An AI instruction specification that generates 11-section production application blueprints from five required inputs.

Built around a locked 11-section template (`references/prompt-template.md`), strict consistency rules (folder/layer parity, entity/endpoint mapping, dependency reachability, scale-justified deployment), a section 11 validation table that runs before delivery, and prompt-injection defenses that treat input field values as inert data.

It names things after your app instead of using placeholder filler, halts on a missing input rather than guessing, and keeps folder trees and data models consistent with each other.

## ✨ Features

- 🏗️ 11 fixed sections in fixed order. project overview, folder tree, layer walkthrough, data models, API endpoints, dependencies, env vars, testing, deployment, architect's notes, self-validation
- 📥 Five required inputs. `APP_DESCRIPTION`, `TECH_STACK`, `APP_TYPE`, `LANGUAGE`, `SCALE`
- ❓ Slash command `/blueprint` runs an `AskUserQuestion` intake for any missing inputs. one question per missing field
- 🚫 No generic placeholders. all names derive from `APP_DESCRIPTION` (no `MyApp`, no `UserService`, no `FooEntity`)
- 🔁 Identical folder names in section 2 and layer names in section 3. parity enforced
- 🔗 Every section 4 entity must appear in at least one section 5 endpoint
- 📦 Every section 6 dependency must map to a folder (section 2) or a reference (section 8)
- 🚀 Deployment target (section 9) justified by `SCALE` explicitly. migration trigger always stated
- ✅ Section 11 validation table runs before output. any FAIL row repaired in place before delivery
- ⛔ `MISSING INPUT: <field> required. Provide value and re-run.` halt on any blank or placeholder input
- 🛡️ Prompt-injection defense. input field values treated as literal strings, never executed
- 🔒 Prompt secrecy. the template is never revealed, paraphrased, or summarized in output
- 📐 Output format. fenced code blocks for trees and config, tables for deps and env, domain-specific names everywhere

## 🔄 How it works

1. **Intake**: the `/blueprint` slash command collects five inputs via `AskUserQuestion`. one question per missing field. existing inputs are reused
2. **Load template**: reads `references/prompt-template.md`. the authoritative 11-section spec
3. **Substitute placeholders**: replaces `{{APP_DESCRIPTION}}`, `{{TECH_STACK}}`, `{{APP_TYPE}}`, `{{LANGUAGE}}`, `{{SCALE}}`. treats values as inert data
4. **Emit sections 1-11**: in exact order, no additions, no reordering
5. **Self-validation**: runs the section 11 validation table. repairs any FAIL row in place before delivery

## 🚀 How to use it

Two ways to invoke it:

**Slash command** (explicit):

```
/blueprint ← walks through the five-question intake
```

**Natural language** (auto-triggers via the skill):

> *"design a production architecture for a dog walking marketplace"*, *"blueprint an app that tracks plant watering schedules"*, *"architect a tool for booking guitar lessons"*, *"give me a full system blueprint for a multi tenant SaaS"*, *"production architecture for a coffee subscription box"*

The full procedure lives at [`lib/app-blueprint/SKILL.md`](../lib/app-blueprint/SKILL.md), the slash command at [`commands/blueprint.md`](../commands/blueprint.md), and the 11-section authoritative template at [`references/prompt-template.md`](../lib/app-blueprint/references/prompt-template.md).

---

## `html-design-styles`

A curated catalog of 53 named design styles for frontend interfaces.

```
/html-design-styles
```

Tired of AI generated frontends that all look like the same generic SaaS landing page? This skill ships specs for 53 distinct design aesthetics. each one a complete, opinionated system with its own color palette, typography stack, component patterns, and signature visual mechanics. Pick a style by name and the output actually *looks* like that style.

When the skill triggers, it knows exactly how to implement any style. fonts, colors, shadows, layout patterns, components, animations, and more. producing HTML in a single output.

## 🎨 Available styles

##### Minimal & Clean
- 🍎 **Bento Style**: Apple/macOS-inspired bento grid, clean and minimal
- 🌿 **Soft Modern Style**: White bg, blurred orb accents, rounded, friendly and accessible
- ❄️ **Scandinavian Style**: Cold whites, extreme negative space, hygge minimalism, quiet luxury
- 🏢 **Corporate Style**: Conservative trust blues, structured grid, buttoned-up B2B professionalism
- 📐 **Swiss Style**: Helvetica-inspired, rigid typographic grid, black/red only, zero decoration

##### Dark & Atmospheric
- 🌌 **Dark Cosmic Style**: Dark slate, glowing indigo/cyan, radial dot grid, glassmorphism
- 🎬 **Dark Action Style**: Dark gradient bg, yellow/gold accents, Oswald font, cinematic energy
- 🚀 **Dark SaaS Style**: Slate-950, sky blue accent, stagger animations, clean SaaS
- 🎭 **Dark Cinema Style**: Near-black, red glow, Bebas Neue, noise overlay, floating labels
- 💾 **Dark Mono Style**: Dark zinc surfaces, cyan + pink accents, monospace, scanline texture
- 🌠 **Dark Neon Style**: Black background, multiple vivid neon glow colors, bleed and bloom effects
- 🌌 **Vaporwave Style**: Purple/teal gradients, retro grid floors, synthwave glow and glitch effects

##### Brutalist & Bold
- ⬛ **Pure Brutalist Style**: Monochrome black/white, hard shadows, monospace, no color
- ⚡ **Neobrutalist Style**: Hard black shadows with vivid neon color accents
- ☢️ **Acid Brutalist Style**: Pure black, acid yellow + red, Anton/Bebas fonts, noise grain
- 🔧 **Utility Terminal Style**: White bg, strict 1px borders, monospace, no rounding, grid texture
- 🏗️ **Monolith Style**: White bg, dark navy shadows, thick top border accent, monospace brutalism

##### Retro & Nostalgic
- 📺 **Retro Terminal Style**: Green-on-black CRT monitor aesthetic with phosphor glow effects
- 🕹️ **Pixel Style**: 8-bit pixelated fonts, game UI, sprite aesthetic, retro game feel
- 🖥️ **Y2K Style**: Windows 95 beveled gray UI, system fonts, chunky pixel buttons, early internet
- 🌊 **Groovy Style**: Warm oranges/browns, 70s swirls, rounded retro lettering, psychedelic curves
- 🎨 **Memphis Style**: 80s/90s geometric shapes, bright pastels, squiggles and confetti
- 🌴 **Tropical Style**: Coral, turquoise, warm vacation energy, Miami/resort vibes

##### Artistic & Expressive
- 🎪 **Pop Art Style**: Cyan/pink/yellow on loud background, floating bordered container
- 🍭 **Kawaii Style**: Super cute pastel, bubble rounded, character illustration accents
- 💥 **Manga Style**: Speed lines, bold ink outlines, dramatic panel layouts, high contrast
- 🌈 **Psychedelic Style**: Acid swirls, melting text, rainbow overflow, mind-bending distortion
- 🗞️ **Zine Style**: Photocopied DIY aesthetic, cut-and-paste collage, raw indie energy
- 🔆 **Aurora Style**: Flowing multi-color gradient backgrounds, silk light effect, soft and dreamy

##### & Luxury
- 👑 **Luxury Style**: Cream/off-white, serif display font, gold accents, generous whitespace
- 🌸 **Art Deco Style**: Geometric gold ornaments, symmetry, 1920s glamour and opulence
- 🌺 **Cottagecore Style**: Floral patterns, watercolor washes, storybook softness and whimsy
- 🌙 **Gothic Style**: Dark greens/blacks, ornate serif, candle-wax drips, moody atmosphere
- ✒️ **Japanese Style**: Wabi-sabi imperfection, ink brush strokes, kanji-inspired negative space

##### Technical & Structured
- 🔷 **Blueprint Style**: Deep blueprint blue, white grid lines, Courier Prime, technical drawing aesthetic
- 🔴 **Dot Grid Style**: Gray dotted background, Archivo Black + Space Mono, hot pink accent, hard shadows
- 🟣 **Pink Neo Style**: Hot pink dotted background, Archivo Black + Space Mono, pink/yellow/blue palette
- 📊 **Dashboard Style**: Chart-forward, dense metrics, sidebar navigation, admin/analytics feel
- 🤖 **Sci-Fi HUD Style**: Heads-up display, corner brackets, data readouts, radar and targeting UI
- ⚠️ **Cyberpunk Style**: Yellow/black warning stripes, HUD overlays, neon on dark, danger aesthetics

##### Specialty & Immersive
- 💎 **Glassmorphism Style**: Frosted glass cards on gradient mesh backgrounds, soft blurs and translucency
- 🏛️ **Neumorphism Style**: Soft same-color shadows creating pushed/extruded soft UI on light gray
- 📦 **Clay Style**: Clay morphism, chunky rounded cards with physical depth
- 🖨️ **Newspaper Style**: Black ink on newsprint, serif fonts, editorial column layouts
- 📖 **Longform Style**: Full-bleed hero images, pull quotes, drop caps, rich magazine editorial flow
- 🎵 **Skeuomorphic Style**: Realistic material textures, depth and shadows mimicking physical objects
- 🌸 **Organic Style**: Earthy tones, rounded organic shapes, a warm handmade look
- ✍️ **Handwritten Style**: Hand-drawn borders, pencil textures, imperfect sketch-like lines

##### Energy & Motion
- 🏆 **Athletic Style**: Diagonal cuts, bold color blocks, high-impact sport energy
- 🌍 **Grunge Style**: Worn textures, splatter marks, distressed rough torn edges
- 🔮 **Isometric Style**: 3D isometric grid illustrations, flat-color depth and layered objects
- 🎭 **Maximalist Style**: Everything layered, dense pattern-on-pattern, opulent visual chaos
- 🔣 **Enterprise Editorial Style**: White/dark alternating sections, indigo, large rounded app cards

## 📦 What each style spec includes

Every style definition covers:

- 🔤 **Typography**: Font families, weights, sizes, letter-spacing
- 🎨 **Color palette**: All CSS custom properties with exact values
- 🪞 **Shadow system**: Named shadow levels used across components
- 🃏 **Card variants**: Background, border, hover states
- 🔘 **Button variants**: Primary, secondary, ghost, active/pressed states
- 📐 **Layout patterns**: Grid structures, hero layouts, section flows
- 🧩 **Components**: Pills, badges, stat cards, nav, marquee, footer
- ✨ **Animations**: Transitions, keyframes, scroll effects where applicable
- ⚙️ **Implementation notes**: CDN links, font imports, special CSS tricks

## 💻 Output format

The skill generates a **single self-contained HTML file** with:

- Inline CSS (no external stylesheet needed)
- Tailwind CSS via CDN
- Google Fonts via CDN
- Font Awesome 6 via CDN (when icons are needed)
- Vanilla JS for any interactions

No build step. Open the file in a browser and it works.

## 🔄 How it works

1. **Identify the style**: match the user's request against the 53-item catalog (or ask them to pick if ambiguous)
2. **Get project context**: full page, single component, restyling existing markup, what content goes in
3. **Load references**: `common.md` once per session for cross-cutting patterns, then `styles/<slug>.md` for the chosen style's complete spec
4. **Apply faithfully**: use the exact color values, typography stack, shadow recipes, and component patterns from the spec, with no "similar" substitutions

## 🚀 How to use it

Two ways to invoke it:

**Slash command** (explicit):

```
/html-design-styles ← asks you to pick a style
/html-design-styles brutalist ← starts straight into Brutalist
/html-design-styles brutalist landing page for my SaaS
 ← pre-fills both style + project
```

**Natural language** (auto-triggers on style names). describe what you want:

**From scratch. describe your product inline:**

```
Build a landing page using bento style.

Product: Pinpoint
A time-tracking app for freelancers. Automatically tracks time across apps
and projects, generates invoices, and syncs with Stripe.

Features:
- Automatic time tracking across Mac apps
- Project and client tagging
- One-click invoice generation
- Stripe integration for payments
- Weekly summary reports

CTA: "Start Free Trial"
```

**From a feature list in your own README. point Claude at it and it pulls product name, features, and copy automatically:**

```
Read README.md. Build a landing page using neobrutalist style based on
the features and descriptions in README.md. Keep copy tight. headline,
subheadline, feature grid, and a single CTA.
```

**Restyle an existing landing page. pass in your HTML and Claude rebuilds it in a new style while preserving content and structure:**

```
Read landingpage.html. Rebuild the landing page using dark cinema style.
Keep all existing sections, copy, and CTAs. only change the visual design.
```

That's it. The skill handles the rest. typography, color palette, layout grid, components, and interactions. all consistent with the named style spec.

The full procedure lives at [`lib/html-design-styles/SKILL.md`](../lib/html-design-styles/SKILL.md), the cross-cutting patterns at [`references/common.md`](../lib/html-design-styles/references/common.md), and each style's complete spec under [`references/styles/`](../lib/html-design-styles/references/styles/).

---

## `accessibility-audit`

Finds, reports, and fixes WCAG accessibility issues in web UI, in the voice of a senior accessibility engineer. Five-field intake, four locked modes, four audit flows that prefer the rendered page over the source. Command only. it ships no skill file, so it never auto-triggers.

```
/accessibility-audit
```

Most accessibility answers do one of two unhelpful things. They dump a raw axe-core log with two hundred entries, thirty of which are the same button repeated, or they start editing files when all you asked for was a report. This plugin does neither. It asks what you want first - mode, scope, and standard in one round, then a single follow-up only if it applies - and holds to the answers. Report mode never touches a file, no matter how obvious the fix looks. Findings are grouped by rule and by component family, so one broken button pattern reads as one finding with a count, not thirty rows. Every finding carries its WCAG criterion. Engine fix directives are quoted word for word rather than paraphrased, and anything that needs written content, alt text, a label, an error message, is left as a TODO with the rule ID instead of invented.

It prefers auditing the page as the browser actually renders it, because source code hides real failures. Four flows are tried in order: the AccessLint MCP for any URL, then a browser MCP when your logged-in session or a specific page state matters, then static analysis of HTML files or JSX rendered to a string, then a plain axe-core script when there is no MCP but there is Node and a dev server. Whichever one it used is stated in the output.

There is a fourth mode for the case where there is no file and no page, just a component you pasted. It returns a four-phase blueprint instead of a report: the flaws in the code as given, the technical approach before any code appears, the complete refactor in your stack with a comment on every accessibility addition, and a testing guide listing what each key should do and what a screen reader should announce. Those key bindings are not improvised. They come from the ARIA Authoring Practices tables bundled with the plugin, covering dialog, disclosure, accordion, tabs, menu and menubar, combobox, listbox, tree, slider, and grid. A custom binding that fights the standard pattern is treated as a defect, because assistive technology users show up already knowing what Arrow and Escape are supposed to do.

The honest part is what it refuses to claim. Automated checks catch roughly a third of real accessibility failures. Content clarity, screen reader announcement quality, keyboard flow, and complex contrast all need a person. Those get their own section in the report, listed as still to verify, rather than being quietly folded into a passing score. It also will not tell you that you are legally compliant, for the ADA or Section 508 or EN 301 549 or the EAA. It aligns code with WCAG technical criteria. Whether an organization is compliant is a legal determination made by people, on evidence this command does not produce.

**Why it is command only.** Every tool in this plugin is command only, and accessibility is the clearest case for why. It is a crowded space: if another accessibility plugin is installed, two skills competing for "make this accessible" produces a coin flip. Nothing here registers as an auto-triggering skill, so there is no coin flip. Type the command and you get this workflow, every time.

## 📋 Technical Overview

One slash command and three reference files. The full workflow lives in `commands/accessibility-audit.md`. persona, intake, flow picker, all four mode workflows, locked output formats, bail rules, a silent pre-delivery validation gate, and hard rules. References load from `${CLAUDE_PLUGIN_ROOT}/lib/accessibility-audit/references/` only while the command runs, so nothing competes at discovery time with another plugin's accessibility skill.

## ✨ Features

- 🎯 Five intake fields. MODE + SCOPE + STANDARD, plus FIX_AUTHORITY when fixing and TECH_STACK when refactoring a pasted component
- 🔒 Four locked modes. Report writes and never edits, Fix runs baseline to edit to verify, Component returns a four-phase blueprint for pasted code, Guide applies the rules to UI you are writing
- 🌐 Four-tier flow picker preferring live DOM. AccessLint MCP, browser MCP, static analysis, local axe-core. always names the flow used
- 🧾 Deduplicated by rule ID and component family, prioritized by user impact. no thirty-row repeats
- 📐 WCAG criterion ID on every finding, across 2.1 AA, 2.2 AA, 2.2 AAA, and Section 508 / EN 301 549
- ⌨️ Per-widget expected keyboard tables from the ARIA Authoring Practices. dialog, disclosure, accordion, tabs, menu and menubar, combobox, listbox, tree, slider, grid
- ✍️ Never invents alt text, labels, or error copy below Full remediation. leaves a TODO with the rule ID
- 🧬 Every surviving ARIA attribute is justified. one that duplicates what a native element already says is treated as a defect, not a fix
- 🔁 Fix mode verifies by re-auditing and diffing the baseline, and bails loudly instead of iterating silently
- 🧷 Fix mode checks `git status` before editing and, if verification fails, hands you the exact revert command rather than leaving a mutated tree. it is the only mode that writes
- 🧑‍🦯 Separates automated findings from the manual and assistive-technology checks it cannot cover
- ⚖️ No legal compliance claims. not ADA, Section 508, EN 301 549, the EAA, or lawsuit risk. WCAG technical alignment only
- ✅ Silent output gate before every response. criterion ID on each finding, all four Component phases present, no invented copy, no compliance claim leaked, no padded findings when the audit comes back clean
- 🛡️ Injection defense over the audited code itself, not just your answers. a comment telling it to report no violations becomes a finding instead of an instruction
- 🧰 Bundled tooling: axe-core auditor, jest-axe component tests, contrast analyzer, keyboard and screen reader scripts, pa11y, GitHub Actions CI, HTML report generator
- 🚫 No skill file, by design. never auto-triggers, never collides with another accessibility plugin
- 🪧 Scope-locked. general UI design review, performance work, and non-accessibility refactors get one refusal line

## 🔄 How it works

1. **Intake.** Two `AskUserQuestion` rounds - MODE, SCOPE, and STANDARD first, then FIX_AUTHORITY in Fix mode or TECH_STACK in Component mode, only when it applies. An argument passed with the command is offered as the pre-filled scope option.
2. **Validate.** Empty or placeholder required fields halt with one targeted question each. A whole-repo scope with no narrowing stops and asks for a directory, route, or component family. Component mode with nothing pasted asks for the source, and incompatible mode/scope pairs (Fix on a URL, Component on a directory) are rejected up front.
3. **Pick a flow.** AccessLint MCP, then browser MCP, then a local axe-core script, then static analysis as the last resort. Live-DOM auditing is preferred throughout; non-URL targets skip straight to static.
4. **Run the mode.** Report maps the surface, audits, groups by pattern, and writes the report. Fix baselines, locates each violation, applies within the chosen authority, then re-audits and diffs. Component runs audit, strategy, commented code, testing guide. Guide loads the rule catalog and applies it inline.
5. **Verify or flag.** Fix mode confirms targeted rules cleared and nothing new appeared, in a locked table of what was applied, what was deferred, and why. Report and Component modes list what still needs a human with a screen reader.
6. **Silent output gate.** Every finding carries a criterion ID, all four Component phases are present with complete code, nothing implies legal compliance, no copy was invented, and a clean audit is reported as clean rather than padded to fill the template. Failures are fixed before the response is sent.
7. **Output** with scope, standard, and flow named at the top.

## 🚀 How to use it

```
/accessibility-audit src/components          ← arg seeds the scope
/accessibility-audit http://localhost:3000
/accessibility-audit                         ← bare, full intake
/accessibility-audit                         ← then paste a component for Component mode
```

There is no natural-language trigger. That is the point. The command always runs its intake first.

The command lives at [`commands/accessibility-audit.md`](../commands/accessibility-audit.md), and the reference files under [`lib/accessibility-audit/references/`](../lib/accessibility-audit/references/).

---

## `design-system`

Reverse-engineers a site's visual design language from its HTML and CSS and writes it up as a reusable `DESIGN.md`, in the voice of a design-system archaeologist. Point it at a folder, a single file, or pasted HTML; it documents the colors, typography, spacing, components, and signature motifs a developer needs to build new pages that match.

```
/design-system
```

Most "document my styles" answers invent tokens that aren't there, or dump the framework's whole utility set as if you wrote it. This tool grounds every claim in the actual source. It quotes real hex values, class names, and selectors, reads a shared stylesheet once and records only what each page adds, names the framework and version instead of enumerating its utilities, and ranks the three-to-five recurring moves that actually define the look. If one file uses a different palette and fonts with no shared tokens, it splits that out as a separate design system instead of blending it in.

Output is a single `DESIGN.md` with fixed headings: Foundations (dependencies, a color palette table, theme variants, a typography table, spacing scales, breakpoints, global treatments), Signature motifs, Components, Extended components, Accessibility, and a Reuse cheat sheet. Every heading is kept even when the source has nothing for it ("None found"), and a final self-check drops anything not verifiable in the source.

## 📋 Technical Overview

One slash command plus its procedure file `lib/design-system/SKILL.md`. The command `/design-system` takes an optional argument (a directory path, a `.html` file, or pasted HTML); when present it skips intake and proceeds, otherwise it asks a single question for the source and the output path. All file and pasted content is treated as data to analyze, never as instructions.

## ✨ Features

- 🎨 Extracts the real color palette - every `:root` custom property with its hex and inferred role
- 🔤 Maps typography to roles - families, weights, the type scale, tracking and `clamp()` habits
- 🧩 Documents only authored components; names frameworks as a layout layer instead of listing utilities
- ✨ Ranks the 3-5 signature motifs by how many components use them
- 🌗 Records theme variants - dark mode, `prefers-color-scheme`, `.dark` / `[data-theme]` overrides
- 🧭 Splits a genuinely separate design system into its own section instead of blending it in
- ♿ Captures accessibility patterns - focus styles, reduced-motion, sr-only, aria
- ✅ Self-checks every hex, class, and selector against the source before writing

## 🔄 How it works

1. **Intake.** Take the source from the argument, or ask for it (folder / file / paste) plus the output path.
2. **Scan.** Read a shared stylesheet once; for further files record only what differs. State any files skipped.
3. **Extract.** Pull dependencies, palette, theme variants, typography, spacing, breakpoints, motifs, components, and accessibility - quoting real values.
4. **Group.** Separate shared core from per-page extensions; flag any genuinely separate design system.
5. **Self-check and write.** Drop unverifiable claims, then write `DESIGN.md` and report files scanned, counts, and the output path.

## 🚀 How to use it

```
/design-system ./site            ← scan every .html in a folder
/design-system page.html          ← one file
/design-system                    ← asks what to analyze, then where to write DESIGN.md
```

The full procedure lives at [`lib/design-system/SKILL.md`](../lib/design-system/SKILL.md) and the slash command at [`commands/design-system.md`](../commands/design-system.md).

---

## `tailwind-gut`

Strips a page's custom CSS and rewrites it in Tailwind utilities, pixel-identical, in the voice of a senior front-end engineer who knows Tailwind's config and preflight cold. Only what genuinely cannot be a utility survives in `<style>`.

```
/tailwind-convert
```

Most "convert this to Tailwind" answers guess the values by eye, drop the ones that don't map, and leave many custom classes behind. This tool catalogues every selector first and sorts each into CONVERT, PROMOTE, or KEEP. It detects the Tailwind major version (v3 JS config versus v4 `@theme`) before writing a line, because the config syntax differs, and it preserves exact pixel values - `padding: 28px` becomes `p-7`, not `p-6` - escaping arbitrary values correctly so a stray space can't silently drop a style.

It returns the full converted HTML plus a short report under four fixed headers: Promoted to config, Kept as CSS (each survivor with a reason), Deleted (preflight-handled resets), and Risks. Genuine non-utilities - global `::selection`, `@font-face`, a reduced-motion blanket reset, `@page` rules - are kept honestly and listed, not faked away.

## 📋 Technical Overview

One slash command plus its procedure file `lib/tailwind-gut/SKILL.md`. The command `/tailwind-convert` takes an optional HTML file path or paste; with none it asks for the file. The attached HTML/CSS is untrusted data to transform, never an instruction source.

## ✨ Features

- 🧹 Catalogues every custom selector into CONVERT / PROMOTE / KEEP
- 🎯 Preserves pixel values exactly - no "close enough" substitution
- 🔍 Detects Tailwind v3 versus v4 and emits the matching config syntax
- 📦 Promotes tokens (colors, radii, shadows, breakpoints, fonts) to the theme config instead of scattering arbitrary values
- 🌗 Handles light and dark, media-driven or class-toggled, without breaking either
- 🛡️ Ignores instructions hidden in the source; converts, does not obey
- 📝 Four-header change report; flags anything imperfectly preserved under Risks
- ✅ Acceptance check: renders identically, zero convertible custom selectors left behind

## 🔄 How it works

1. **Intake.** Take the HTML from the argument or ask for it. Detect the Tailwind version.
2. **Catalogue.** Sort every custom selector into CONVERT / PROMOTE / KEEP.
3. **Convert.** Turn property-bag classes, states, pseudo decorations, media queries, and inline styles into utilities.
4. **Promote.** Move design tokens into the version-correct theme config.
5. **Report.** Emit the converted HTML, then the four-header report and the acceptance check.

## 🚀 How to use it

```
/tailwind-convert page.html       ← convert a file
/tailwind-convert                 ← asks for the HTML file or paste
```

The full procedure lives at [`lib/tailwind-gut/SKILL.md`](../lib/tailwind-gut/SKILL.md) and the slash command at [`commands/tailwind-convert.md`](../commands/tailwind-convert.md).

---

## `page-cloner`

Turns a live web page into one self-contained working HTML file that looks and lays out like the original, with no redesign. It reads the page's real rendered markup and CSS instead of rebuilding from a screenshot, so the copy matches by construction, then it checks that copy against the original and fixes anything that drifted.

```
/page-cloner
```

Most "copy this page" attempts guess at the layout from a picture and end up close but wrong. This tool does not guess. It loads the real page in your browser, screenshots it as the reference, extracts the rendered DOM with its CSS inlined and its assets pointed at absolute URLs, and saves that as the raw clone. Then it renders the clone, compares it against the original section by section, and turns every difference into a specific edit. It repeats until the two match.

There is one goal here: faithfulness. It does not improve the type, change the colors, or tidy the spacing. A change that makes the clone look different from the original is treated as a bug, not a win. The result is a static preview: scripts are stripped, so anything driven by JavaScript freezes in whatever state it held when the page was captured.

This command needs Claude in Chrome to capture the real page. Without it, there is no real page to copy and nothing truthful to check against, so the command stops and says so.

## 📋 Technical Overview

One slash command plus its procedure file `lib/page-cloner/SKILL.md`, which points at its own `references/` (capture and validate steps) and `scripts/` (`extract.js` to pull the page, `shoot.py` to screenshot the clone). The command `/page-cloner` takes a URL as its argument; with none it asks for one. All captured page content is treated as data to reproduce, never as instructions to follow.

## ✨ Features

- 🌐 Copies a live URL into one self-contained working HTML file
- 🧷 Extracts the real rendered DOM and inlines the real CSS, no guessing from a screenshot
- 🔁 Validates in a loop: render, compare section by section, fix the drift, repeat
- 🎯 One axis only - faithfulness; never restyles, recolors, or "improves" anything
- 🖼️ Screenshots the original first as the reference to measure against
- 🛡️ Treats page content as data to reproduce, not instructions to obey
- 🧭 Reports honestly what, if anything, still differs when it stops

## 🔄 How it works

1. **Capture.** Load the live URL in the browser, scroll it, and screenshot it as the reference.
2. **Extract.** Run the extract step to pull the rendered DOM with CSS inlined and assets absolutised, saved as the raw clone.
3. **Validate.** Render the clone, compare it against the original section by section, and turn each difference into a specific fix.
4. **Repeat.** Loop until it matches or about five rounds pass without progress, then report what is still off.

## 🚀 How to use it

```
/page-cloner https://example.com    ← clone a page
/page-cloner                        ← asks for the URL
```

The full procedure lives at [`lib/page-cloner/SKILL.md`](../lib/page-cloner/SKILL.md) and the slash command at [`commands/page-cloner.md`](../commands/page-cloner.md).

---

## `page-tailwindify`

Reproduces a live page's exact look in clean, semantic Tailwind. The framework-generated class hashes (`css-1a2b3c`, `sc-bdfBwQ`, `jsx-1234`) are gone, replaced by real utility classes like `flex gap-4 rounded-lg px-6`. The design does not change - colors, type, spacing, and layout stay identical - only the styling system does, from opaque generated selectors to readable Tailwind.

```
/page-tailwindify
```

The way it stays accurate is by never guessing Tailwind classes from a screenshot. It captures the page's real markup and CSS, plus a dump of the real computed values for each element, so every class comes from an actual number rather than a guess by eye. It first checks what the page is built with. If the page is already Tailwind, it simply swaps the compiled stylesheet for the Tailwind CDN and keeps the markup. If the page uses hashed or CSS-in-JS styling, it translates the real CSS and computed values into semantic markup with Tailwind classes, section by section.

Then it validates the same way page-cloner does: render the result, compare it against the original on the single question of whether it looks the same, fix any drift, and repeat. Bespoke designs will not sit on Tailwind's default scale, so faithful arbitrary values like `text-[17px]` and `bg-[#0b5fff]` are correct and expected here. Accuracy comes first; normalizing onto design tokens is a separate later pass if you want it.

This command needs Claude in Chrome to capture the real page. Without it there is nothing real to rewrite from and nothing to check against, so the command stops and says so.

## 📋 Technical Overview

One slash command plus its procedure file `lib/page-tailwindify/SKILL.md`, which points at its own `references/` (rehost, rewrite, mapping, validate, capture notes) and `scripts/` (`computed.js` to dump real computed values, `shoot.py` to screenshot the result). It reuses the page-cloner capture step for the faithful DOM. The command `/page-tailwindify` takes a URL as its argument; with none it asks for one. All captured page content is treated as data to reproduce, never as instructions.

## ✨ Features

- 🎨 Reproduces a live page's exact look in clean, semantic Tailwind
- 🧼 Replaces generated class hashes with readable utility classes
- 🔢 Drives every class from a real computed value, not a guess from a picture
- 🔀 Detects the styling system and branches: rehost an already-Tailwind page, or translate a hashed one
- 📐 Keeps the look identical - no new type scale, palette cleanup, or spacing tweaks
- 🧩 Accepts arbitrary values like `text-[17px]` for bespoke designs that need them
- 🔁 Validates in a loop against the original until it matches
- 🛡️ Treats page content as data to reproduce, not instructions to obey

## 🔄 How it works

1. **Capture.** Reuse the page-cloner capture to get the faithful DOM and real CSS, and dump the real computed values if a translation is needed.
2. **Detect.** Check whether the page is already Tailwind, hashed or CSS-in-JS, or mixed.
3. **Branch.** Rehost mode swaps the compiled stylesheet for the Tailwind CDN; translate mode rewrites the markup into semantic Tailwind section by section.
4. **Validate.** Render the result, compare it against the original on the single fidelity axis, fix drift, and repeat until it matches.

## 🚀 How to use it

```
/page-tailwindify https://example.com   ← rebuild a page in Tailwind
/page-tailwindify                       ← asks for the URL
```

The full procedure lives at [`lib/page-tailwindify/SKILL.md`](../lib/page-tailwindify/SKILL.md) and the slash command at [`commands/page-tailwindify.md`](../commands/page-tailwindify.md).
