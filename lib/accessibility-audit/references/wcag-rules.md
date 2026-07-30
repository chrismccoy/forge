# WCAG Rule Catalog

Eight rule categories, ordered by priority. Fix the critical ones first (names, keyboard, focus). Editing constraints are not WCAG rules and live in their own section at the end.

| Priority | Category | Impact |
|----------|----------|--------|
| 1 | Accessible names | critical |
| 2 | Keyboard access | critical |
| 3 | Focus and dialogs | critical |
| 4 | Semantics | high |
| 5 | Forms and errors | high |
| 6 | Announcements | medium-high |
| 7 | Contrast and states | medium |
| 8 | Media and motion | low-medium |

## 1. Accessible names (critical)

- Every interactive control must have an accessible name.
- Icon-only buttons must have `aria-label` or `aria-labelledby`.
- Every `input`, `select`, and `textarea` must be labeled.
- Links must have meaningful text - no "click here".
- Decorative icons must be `aria-hidden="true"`.

WCAG: 4.1.2 Name, Role, Value; 2.4.4 Link Purpose.

## 2. Keyboard access (critical)

- Never use `div` or `span` as a button without full keyboard support.
- All interactive elements must be reachable by Tab.
- Focus must be visible for keyboard users.
- Never use `tabindex` greater than 0.
- Escape must close dialogs and overlays where applicable.

WCAG: 2.1.1 Keyboard; 2.1.2 No Keyboard Trap; 2.4.7 Focus Visible.

## 3. Focus and dialogs (critical)

- Modals must trap focus while open.
- Restore focus to the trigger on close.
- Set initial focus inside the dialog.
- Opening a dialog must not scroll the page unexpectedly.

WCAG: 2.4.3 Focus Order; 2.4.11 Focus Not Obscured (2.2).

## 4. Semantics (high)

- Prefer native elements (`button`, `a`, `input`) over role-based substitutes.
- When a role is used, all required ARIA attributes must be present.
- Lists must use `ul`/`ol` with `li`.
- Do not skip heading levels; every page needs one `h1`.
- Tables must use `th` for headers where applicable.

WCAG: 1.3.1 Info and Relationships.

## 5. Forms and errors (high)

- Errors must be linked to fields with `aria-describedby`.
- Required fields must be announced. Native `required` is sufficient on form controls - do not add `aria-required="true"` alongside it, which duplicates what the element already communicates. Use `aria-required` only on custom widgets whose `role` has no native required state.
- Invalid fields must set `aria-invalid`.
- Helper text must be associated with its input.
- Disabled submit actions must explain why.

WCAG: 3.3.1 Error Identification; 3.3.2 Labels or Instructions.

## 6. Announcements (medium-high)

- Critical form errors should use `aria-live` (or `role="alert"`).
- Loading states should use `aria-busy` or visible status text.
- Toasts must not be the only channel for critical information.
- Expandable controls must use `aria-expanded`. `aria-controls` is optional and poorly supported (VoiceOver largely ignores it) - add it only when the controlled region is not adjacent in DOM order.

WCAG: 4.1.3 Status Messages.

## 7. Contrast and states (medium)

- Text and icons need sufficient contrast - AA: 4.5:1 normal, 3:1 large; AAA: 7:1 / 4.5:1.
- Hover-only interactions must have keyboard equivalents.
- Disabled states must not rely on color alone.
- Never remove focus outlines without a visible replacement.

WCAG: 1.4.3 Contrast; 1.4.1 Use of Color; 1.4.11 Non-text Contrast.

## 8. Media and motion (low-medium)

- Images need correct alt text - meaningful, or empty (`alt=""`) when decorative.
- Videos with speech should provide captions.
- Respect `prefers-reduced-motion` for non-essential motion.
- Avoid autoplaying media with sound.

WCAG: 1.1.1 Non-text Content; 1.2.2 Captions (Prerecorded); 2.3.3 Animation from Interactions (**AAA** - advisory when the target standard is AA).

## Common fixes

```html
<!-- icon-only button: add aria-label, hide the glyph -->
<!-- before --> <button><svg>...</svg></button>
<!-- after -->  <button aria-label="Close"><svg aria-hidden="true">...</svg></button>

<!-- div as button: use the native element -->
<!-- before --> <div onclick="save()">Save</div>
<!-- after -->  <button onclick="save()">Save</button>

<!-- form error: link with aria-describedby -->
<!-- before --> <input id="email" /> <span>Invalid email</span>
<!-- after -->  <label for="email">Email</label>
                <input id="email" aria-describedby="email-err" aria-invalid="true" />
                <span id="email-err">Invalid email</span>

<!-- decorative image -->
<!-- before --> <img src="divider.png">
<!-- after -->  <img src="divider.png" alt="">
```

## ARIA patterns

```html
<!-- modal -->
<div role="dialog" aria-labelledby="modal-title" aria-modal="true">
  <h2 id="modal-title">Modal Title</h2>
  <button aria-label="Close">&times;</button>
</div>

<!-- tabs -->
<div role="tablist" aria-label="Navigation">
  <button id="tab-1" role="tab" aria-selected="true" aria-controls="panel-1">Tab 1</button>
</div>
<!-- tabindex="0" so keyboard users can reach panel text that contains no
     focusable element of its own -->
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1" tabindex="0">Content</div>

<!-- labeled, validated field -->
<!-- the asterisk is decorative: ARIA forbids naming a generic span, so hide it
     and put the requirement in real text that aria-describedby points at.
     role="alert" is implicitly assertive - do not pair it with aria-live="polite". -->
<label for="name">Name <span aria-hidden="true">*</span></label>
<input id="name" required aria-describedby="name-hint name-error">
<span id="name-hint">Required</span>
<span id="name-error" role="alert"></span>
```

```jsx
// React: live region for async status
const LiveRegion = ({ message, politeness = "polite" }) => (
  <div role="status" aria-live={politeness} aria-atomic="true" className="sr-only">
    {message}
  </div>
);
```

## High-contrast CSS

```css
@media (prefers-contrast: high) {
  :root {
    --text-primary: #000;
    --bg-primary: #fff;
    --border-color: #000;
  }
  a { text-decoration: underline !important; }
  button, input { border: 2px solid var(--border-color) !important; }
}
```

## Editing constraints (not WCAG)

These govern how edits are made, not what the standard requires. They carry no criterion ID and must never be reported as findings.

- Make minimal changes; do not refactor unrelated code.
- Do not add ARIA when native semantics already solve the problem.
- Do not migrate UI libraries unless asked.

## Review guidance

- Quote the exact snippet, state the failure, propose a small fix.
- Fix critical categories before cosmetic ones.
- Prefer native HTML before adding ARIA.
- For menus, dialogs, and comboboxes, use established accessible primitives rather than custom behavior.
