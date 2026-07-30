# Manual Accessibility Checklist

Automated engines catch roughly a third of WCAG failures. Run these checks by hand and report results separately from automated findings.

## Keyboard navigation

- [ ] All interactive elements reachable via Tab
- [ ] Buttons activate with Enter and Space
- [ ] Escape closes modals, menus, and overlays
- [ ] Focus indicator always visible and high-contrast
- [ ] No keyboard traps - focus can always leave a region
- [ ] Tab order matches visual order
- [ ] Focus moves into a dialog on open and returns to the trigger on close
- [ ] Skip link present and functional on content-heavy pages

## Screen reader

Test with VoiceOver (macOS/iOS), NVDA (Windows), or TalkBack (Android).

- [ ] Page title descriptive and unique
- [ ] Headings form a logical outline; exactly one `h1`
- [ ] Landmarks present (`header`, `nav`, `main`, `footer`)
- [ ] Images have accurate alt text; decorative images announce nothing
- [ ] Form fields announce label, state, and requirement
- [ ] Error messages announced when they appear
- [ ] Dynamic updates announced without stealing focus
- [ ] Icon-only controls announce a meaningful name
- [ ] Tables announce header associations

## Visual

- [ ] Text resizes to 200% without content loss
- [ ] Content reflows at 320px width without horizontal scroll
- [ ] Color is never the sole means of conveying information
- [ ] Focus indicators meet 3:1 contrast against adjacent colors
- [ ] Animations can be paused, stopped, or hidden
- [ ] Layout survives `prefers-reduced-motion` and `prefers-contrast: high`
- [ ] Hover-revealed content is dismissible and keyboard-reachable

## Cognitive

- [ ] Instructions clear and plainly worded
- [ ] Error messages state what went wrong and how to fix it
- [ ] No time limits on forms, or limits are extendable
- [ ] Navigation consistent across pages
- [ ] Important actions reversible or confirmed
- [ ] No unexpected context changes on focus or input

## Expected keyboard interactions by widget

Derived from the ARIA Authoring Practices Guide. Use these as the authoritative expected behavior when auditing or refactoring a known pattern. Do not improvise key bindings - a custom binding that fights the pattern is itself a defect, because assistive technology users arrive with these expectations already learned.

All patterns share a baseline: `Tab` and `Shift+Tab` move between widgets, focus is always visible, and focus is never lost to the document body after an interaction.

### Dialog (modal)

| Key | Expected result |
|-----|-----------------|
| `Tab` | Moves to next focusable element inside the dialog; wraps to the first after the last |
| `Shift+Tab` | Moves to previous; wraps to the last from the first |
| `Escape` | Closes the dialog, returns focus to the trigger |

On open, focus moves into the dialog - to the first focusable element, or the dialog container when there is nothing sensible to focus. Content outside the dialog is inert to both pointer and keyboard.

### Disclosure (show/hide)

| Key | Expected result |
|-----|-----------------|
| `Enter` or `Space` | Toggles the controlled region, updates `aria-expanded` |

Focus stays on the trigger. The revealed region follows the trigger in DOM order.

### Accordion

| Key | Expected result |
|-----|-----------------|
| `Enter` or `Space` | Toggles the focused panel |
| `Down` / `Up` | Optional. Moves focus between accordion headers |
| `Home` / `End` | Optional. First / last accordion header |

Each header is a `button` inside its heading element, not a heading acting as a button.

### Tabs

| Key | Expected result |
|-----|-----------------|
| `Tab` | Moves into the tab list (active tab only), then out to the tab panel |
| `Right` / `Left` | Next / previous tab in a horizontal tab list |
| `Down` / `Up` | Next / previous tab in a vertical tab list |
| `Home` / `End` | First / last tab |
| `Enter` or `Space` | Activates the focused tab in manual-activation mode |

The tab list is a single tab stop - roving `tabindex`, not one stop per tab. Automatic activation on arrow is acceptable only when panel content is cheap to render.

### Menu and menubar

| Key | Expected result |
|-----|-----------------|
| `Enter` or `Space` | Opens the menu from its button, focuses the first item; activates the focused item |
| `Down` / `Up` | Next / previous item, wrapping at the ends |
| `Right` / `Left` | Opens a submenu / closes it; moves between menubar items |
| `Home` / `End` | First / last item |
| `Escape` | Closes the menu, returns focus to the trigger |
| Printable character | Moves focus to the next item starting with that character |

A menu is for application commands. A list of page links is navigation, not a menu, and needs none of this.

### Combobox

| Key | Expected result |
|-----|-----------------|
| `Down` | Opens the popup and makes the first or selected option active |
| `Alt+Down` | Opens the popup without making any option active |
| `Up` / `Down` | Moves the active option while open |
| `Enter` | Selects the active option, closes the popup |
| `Escape` | Closes the popup; a second press clears the input where applicable |
| `Home` / `End` | Start / end of the text input |

Most implementations keep DOM focus in the text input throughout and track the active option with `aria-activedescendant` - which is why the rows above say "active option" rather than "focus". Moving DOM focus into the listbox is also permitted by the APG. Pick one and stay consistent.

### Listbox

| Key | Expected result |
|-----|-----------------|
| `Up` / `Down` | Moves focus between options |
| `Home` / `End` | First / last option |
| `Space` | Toggles selection in a multi-select listbox |
| `Shift+Up` / `Shift+Down` | Extends selection in a multi-select listbox |

### Tree

| Key | Expected result |
|-----|-----------------|
| `Up` / `Down` | Previous / next visible node |
| `Right` | Expands a collapsed node, or moves to its first child |
| `Left` | Collapses an expanded node, or moves to its parent |
| `Home` / `End` | First / last visible node |
| `Enter` | Activates the focused node |

### Slider

| Key | Expected result |
|-----|-----------------|
| `Right` / `Up` | Increases by one step |
| `Left` / `Down` | Decreases by one step |
| `Page Up` / `Page Down` | Increases / decreases by a larger step |
| `Home` / `End` | Minimum / maximum value |

`aria-valuenow`, `aria-valuemin`, and `aria-valuemax` update on every change, with `aria-valuetext` when the raw number is not meaningful to a listener.

### Grid and data table with interactive cells

| Key | Expected result |
|-----|-----------------|
| `Right` / `Left` | Next / previous cell in the row |
| `Down` / `Up` | Same column, next / previous row |
| `Home` / `End` | First / last cell in the row |
| `Ctrl+Home` / `Ctrl+End` | First / last cell in the grid |

The grid is one tab stop. A static table with no interactive cells needs none of this - it needs correct `th`, `scope`, and a caption.

## Reporting manual results

For each failed check, record: the check, the page or component, what happened, the expected behavior, the WCAG criterion, and the assistive technology and version used.
