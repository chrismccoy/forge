# Responsive Workflow

**Contents:** When to Use · Step 1: Gather Requirements · Step 2: Read Existing Context · Step 3: Choose the Mechanism · Step 4: Build Mobile-First · Step 5: Handle Touch and Device Concerns · Step 6: Verify · Output

Step-by-step process for "make this responsive" tasks. All syntax and examples live in `responsive.md`; this file links to its sections instead of repeating them.

## When to Use

- Making an existing layout work on mobile, tablet, and desktop
- Building a new grid, nav, hero, sidebar, card, or table that must adapt
- Fixing overflow, horizontal scroll, or broken layouts at certain widths

For dark mode work, use `dark-mode.md`.

## Step 1: Gather Requirements

Ask only what cannot be inferred from the code or request:

| Question | Infer from |
|----------|------------|
| Which widths matter (phone, tablet, desktop, wide)? | Default to all; check analytics notes or design files |
| Does the component live in varying-width containers? | Is it reused in sidebars, modals, grids? |
| What content shows, hides, or reorders at each size? | Existing desktop design; ask if priorities are unclear |
| Custom breakpoints in use? | `@theme { --breakpoint-* }` in the project CSS |
| Fluid type/spacing tokens already defined? | `--text-fluid-*`, `--spacing-fluid-*` in `@theme` |
| Touch-first audience? | Product type (mobile app, kiosk, internal desktop tool) |

## Step 2: Read Existing Context

- Find the project CSS entry (`@import "tailwindcss"`) and read its `@theme` for breakpoints, container sizes, and tokens.
- Read sibling components for existing responsive conventions (which breakpoints, spacing scale, nav pattern).
- Reuse existing tokens and patterns. Do not add new breakpoints when the defaults work.

## Step 3: Choose the Mechanism

| Situation | Use | Reference |
|-----------|-----|-----------|
| Page shell, header, full-width sections | Viewport breakpoints (`md:`, `lg:`) | responsive.md → Breakpoints |
| Reusable component in varying containers | Container queries (`@container`, `@md:`) | responsive.md → Container Queries |
| Style only below a size, or a range | `max-md:`, `md:max-lg:`, `max-[600px]:` | responsive.md → Breakpoints (Ranges and max-width) |
| Smooth scaling type/spacing | Fluid tokens in `@theme` | responsive.md → Fluid Type and Spacing |
| Grid without breakpoints | `repeat(auto-fit, minmax(...))` | responsive.md → Layout Patterns |
| Touch vs mouse differences | `pointer-coarse:`, `pointer-fine:` | responsive.md → Input and Device Media |

## Step 4: Build Mobile-First

1. Write the narrowest layout with no prefixes (single column, stacked, full width).
2. Widen the viewport until something looks wrong; add the smallest prefix that fixes it.
3. Repeat up to the widest size. Stop adding prefixes when nothing changes.
4. Remove redundant variants (same value repeated at a larger breakpoint).
5. Check that no prefix is used as "this size only" (see responsive.md → Mobile-First Rules).

Pattern starting points in responsive.md:

- Grids, stack-to-row, sidebar, page shell, stacked tables → Layout Patterns
- Hamburger menu and bottom tab bar → Mobile Navigation
- Images, art direction, video and embeds → Responsive Images and Media

## Step 5: Handle Touch and Device Concerns

- [ ] Interactive elements ≥ 44px on touch (`min-h-11 min-w-11`), never below 24px → Touch Targets
- [ ] Hover-revealed UI also appears on focus and is visible on touch → Input and Device Media
- [ ] Fixed headers/bottom bars clear the notch and home indicator → Safe Areas
- [ ] Full-height sections use `min-h-dvh` → Layout Patterns
- [ ] Media has `aspect-*` or width/height, below-fold media is lazy → Responsive Images and Media
- [ ] Mobile menu toggle has `aria-expanded`, `aria-controls`, and a label → Mobile Navigation

## Step 6: Verify

Run the checklist in responsive.md → Mobile Testing. At minimum:

- [ ] 320px: no horizontal scroll, nothing clipped
- [ ] Each breakpoint boundary (just below and just above)
- [ ] Portrait and landscape
- [ ] 200% browser zoom
- [ ] Keyboard-only pass through navigation and menus

## Output

Provide:

1. The complete responsive markup (and any `@theme` additions, in `rem`).
2. A short note per breakpoint or container query explaining what changes and why.
3. What is shown, hidden, or reordered at each size.
4. Any assumptions made in Step 1.
5. Remaining manual checks (real-device testing, content-length edge cases).
