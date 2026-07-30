# Debounce a Search Input in Vanilla JS

> What You'll Learn: build a debounce wrapper; stop firing a fetch on every keystroke
> Prerequisites: JS functions, setTimeout, addEventListener
> Time: short session | Level: Beginner

## Setup

Create `index.html` with an input and a script tag:

```html
<!-- index.html -->
<input id="q" placeholder="Search...">
<script src="app.js"></script>
```

## Section 1: Why Debounce

Typing "hello" fires one request per keystroke - five wasted calls. Debounce
waits until typing pauses, then fires once. Think of an elevator holding the
door for late arrivers instead of running empty each time someone approaches.

```js
// app.js
function debounce(fn, ms) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  };
}

const search = debounce((value) => console.log("fetch:", value), 300);
document.querySelector("#q").addEventListener("input", (e) => search(e.target.value));
// Output: after typing stops for 300ms → fetch: hello
```

## Checkpoint 1: Able to explain what `clearTimeout` does here

Removing it makes the function fire on every keystroke again. The reset is the
whole mechanism.

### Try It Yourself

Make the delay configurable per input via a `data-ms` attribute.

**Success:** an input with `data-ms="500"` debounces at 500ms; one with no attribute falls back to 300ms.

<details>
<summary>Solution</summary>

```js
const el = document.querySelector("#q");
const ms = Number(el.dataset.ms) || 300;
const search = debounce((v) => console.log("fetch:", v), ms);
```

</details>

## Troubleshooting

┌──────────────────────┬─────────────────────────┬──────────────────────────┐
│ Symptom              │ Cause                   │ Fix                      │
├──────────────────────┼─────────────────────────┼──────────────────────────┤
│ Fires on every key   │ Timer not cleared       │ clearTimeout before set  │
│ Never fires          │ Listener not bound      │ Check the selector/id    │
└──────────────────────┴─────────────────────────┴──────────────────────────┘

## Summary

- Debounce collapses a burst of events into one trailing call.
- `clearTimeout` + `setTimeout` is the entire mechanism.
- Tune the delay to the interaction (search ≈ 300ms).

## Next Steps

1. Add a leading-edge variant (fire immediately, then wait).
2. Compare with throttle (fire at a steady rate).
3. Wire the callback to a real `fetch()` against a public API.
