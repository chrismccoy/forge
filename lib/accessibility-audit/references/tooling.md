# Accessibility Tooling

Runnable scripts and configs for automated auditing. Adapt to the project's package manager and framework before running; verify dependencies exist.

## 1. axe-core page audit (Puppeteer)

```javascript
// accessibility-test.js
const { AxePuppeteer } = require("@axe-core/puppeteer");
const puppeteer = require("puppeteer");

class AccessibilityAuditor {
  constructor(options = {}) {
    this.wcagLevel = options.wcagLevel || "AA";
    this.wcagVersion = options.wcagVersion || "2.1";
    this.viewport = options.viewport || { width: 1920, height: 1080 };
  }

  // Maps the chosen standard to axe tags. Without this the runner silently
  // audits 2.1 AA no matter what the user picked.
  tagsFor(level = "AA", version = "2.1") {
    const tags = ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"];
    // 2.2 adds Level A criteria too (3.2.6 Consistent Help, 3.3.7 Redundant
    // Entry). Pushing only wcag22aa silently skips them.
    if (version === "2.2") tags.push("wcag22a", "wcag22aa");
    if (level === "AAA") {
      tags.push("wcag2aaa", "wcag21aaa");
      if (version === "2.2") tags.push("wcag22aaa"); // 2.4.13 Focus Appearance
    }
    return tags;
  }

  async runFullAudit(url) {
    const browser = await puppeteer.launch();
    try {
      const page = await browser.newPage();
      await page.setViewport(this.viewport);
      await page.goto(url, { waitUntil: "networkidle2" });

      const results = await new AxePuppeteer(page)
        .withTags(this.tagsFor(this.wcagLevel, this.wcagVersion))
        .exclude(".no-a11y-check")
        .analyze();

      return {
        url,
        timestamp: new Date().toISOString(),
        violations: results.violations.map((v) => ({
          id: v.id,
          impact: v.impact,
          description: v.description,
          help: v.help,
          helpUrl: v.helpUrl,
          nodes: v.nodes.map((n) => ({
            html: n.html,
            target: n.target,
            failureSummary: n.failureSummary,
          })),
        })),
        score: this.calculateScore(results),
      };
    } finally {
      // networkidle2 times out on any app with polling or websockets.
      // Without finally, that leaks a headless Chrome per run.
      await browser.close();
    }
  }

  calculateScore(results) {
    const weights = { critical: 10, serious: 5, moderate: 2, minor: 1 };
    let totalWeight = 0;
    results.violations.forEach((v) => {
      totalWeight += weights[v.impact] || 0;
    });
    return Math.max(0, 100 - totalWeight);
  }
}
```

Construct it with the standard the user chose, or it audits WCAG 2.1 AA no matter what they picked:

```javascript
const auditor = new AccessibilityAuditor({ wcagLevel: "AA", wcagVersion: "2.2" });
```

Playwright equivalent: `@axe-core/playwright` with the same `withTags` chain.

## 2. Component tests with jest-axe

Add these when fixing component-level violations so regressions get caught.

```jsx
import { render } from "@testing-library/react";
import { axe, toHaveNoViolations } from "jest-axe";

expect.extend(toHaveNoViolations);

describe("Accessibility", () => {
  it("has no violations", async () => {
    const { container } = render(<MyComponent />);
    expect(await axe(container)).toHaveNoViolations();
  });
});
```

## 3. Color contrast analyzer

```javascript
// color-contrast.js
class ColorContrastAnalyzer {
  constructor() {
    this.wcagLevels = {
      AA: { normal: 4.5, large: 3 },
      AAA: { normal: 7, large: 4.5 },
    };
  }

  async analyzePageContrast(page, level = "AA") {
    const elements = await page.evaluate(() => {
      // Match only elements that own a text node. Filtering on innerText
      // matches every ancestor too, since innerText aggregates descendants -
      // body and every wrapper would pass, reporting the wrong color.
      const ownsText = (el) =>
        Array.from(el.childNodes).some(
          (n) => n.nodeType === 3 && n.textContent.trim(),
        );

      // Chrome preserves oklch(), lab() and color(srgb ...) in the computed
      // value when the author wrote them - and Tailwind v4 emits oklch() for
      // its entire default palette. Painting into a 1x1 canvas makes the
      // browser resolve any color syntax it understands down to rgba bytes.
      const canvas = document.createElement("canvas");
      canvas.width = canvas.height = 1;
      const ctx = canvas.getContext("2d", { willReadFrequently: true });
      const cache = new Map(); // pages reuse a handful of colors

      // Returns {r,g,b,a} or null. Assigning an invalid value to fillStyle is
      // silently IGNORED per spec - it does not throw - so a try/catch cannot
      // detect a bad color. Round-trip a sentinel instead: if fillStyle still
      // holds the sentinel after assignment, the candidate was rejected.
      const SENTINEL = "#010203";
      const resolve = (color) => {
        if (!color) return null;
        if (cache.has(color)) return cache.get(color);
        let out = null;
        ctx.fillStyle = SENTINEL;
        ctx.fillStyle = color;
        const accepted =
          ctx.fillStyle !== SENTINEL ||
          /^#010203$|^rgb\(\s*1,\s*2,\s*3\s*\)$/.test(String(color).trim());
        if (accepted) {
          ctx.clearRect(0, 0, 1, 1);
          ctx.fillRect(0, 0, 1, 1);
          const [r, g, b, a] = ctx.getImageData(0, 0, 1, 1).data;
          out = { r, g, b, a };
        }
        cache.set(color, out);
        return out;
      };

      // getComputedStyle returns a fully transparent value for unpainted
      // backgrounds - rgba(0,0,0,0), but also oklch(0 0 0 / 0) or
      // color(srgb 0 0 0 / 0) on modern stacks. Resolve through the canvas and
      // test the actual alpha byte rather than pattern-matching the string.
      const effectiveBg = (el) => {
        for (let n = el; n; n = n.parentElement) {
          const rgba = resolve(window.getComputedStyle(n).backgroundColor);
          if (rgba && rgba.a === 255) return rgba;
        }
        return { r: 255, g: 255, b: 255, a: 255 };
      };

      return Array.from(document.querySelectorAll("*"))
        .filter(ownsText)
        .map((el) => {
          const styles = window.getComputedStyle(el);
          const fg = resolve(styles.color);
          if (!fg) return null; // unparseable, skip rather than guess
          const bg = effectiveBg(el);
          return {
            text: el.textContent.trim().substring(0, 50),
            color: [fg.r, fg.g, fg.b],
            backgroundColor: [bg.r, bg.g, bg.b],
            // Translucent text measures as opaque unless composited. Flag it
            // instead of reporting a contrast figure that is too generous.
            translucent: fg.a < 255,
            fontSize: parseFloat(styles.fontSize),
            fontWeight: styles.fontWeight,
          };
        })
        .filter(Boolean);
    });

    const thresholds = this.wcagLevels[level] || this.wcagLevels.AA;

    return elements
      .map((el) => {
        const contrast = this.calculateContrast(el.color, el.backgroundColor);
        if (contrast === null) return null; // unparseable, skip rather than guess
        const isLarge = this.isLargeText(el.fontSize, el.fontWeight);
        const required = isLarge ? thresholds.large : thresholds.normal;
        if (contrast < required) {
          return {
            text: el.text,
            currentContrast: contrast.toFixed(2),
            requiredContrast: required,
            foreground: `rgb(${el.color.join(", ")})`,
            background: `rgb(${el.backgroundColor.join(", ")})`,
            // Measured as opaque. The real ratio is worse than reported.
            note: el.translucent
              ? "translucent text - verify manually, measured contrast is optimistic"
              : undefined,
          };
        }
        return null;
      })
      .filter(Boolean);
  }

  calculateContrast(fg, bg) {
    const a = this.parseColor(fg);
    const b = this.parseColor(bg);
    if (!a || !b) return null;
    const l1 = this.relativeLuminance(a);
    const l2 = this.relativeLuminance(b);
    const lighter = Math.max(l1, l2);
    const darker = Math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  relativeLuminance(rgb) {
    const [r, g, b] = rgb.map((val) => {
      val = val / 255;
      return val <= 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  // Returns [r,g,b] or null. analyzePageContrast already resolves colors to
  // byte triples in the browser, so those pass straight through; the string
  // branches exist for calling calculateContrast directly with CSS values.
  // Never guess: a wrong color produces a fabricated pass or a fabricated
  // violation, and both are worse than skipping the node. Anything the regexes
  // do not recognize - oklch(), lab(), color(srgb ...) - returns null here, so
  // resolve colors through the browser when the page uses modern syntax.
  parseColor(value) {
    if (Array.isArray(value)) return value.length >= 3 ? value.slice(0, 3) : null;
    const m = String(value).match(/rgba?\(([^)]+)\)/);
    if (m) return m[1].split(/[,\s/]+/).filter(Boolean).slice(0, 3).map(parseFloat);
    const hex = String(value).trim().replace("#", "");
    if (/^[0-9a-f]{3}$/i.test(hex)) {
      return hex.split("").map((c) => parseInt(c + c, 16));
    }
    if (/^[0-9a-f]{6}$/i.test(hex)) {
      return [0, 2, 4].map((i) => parseInt(hex.slice(i, i + 2), 16));
    }
    return null;
  }

  isLargeText(fontSize, fontWeight) {
    const bold = parseInt(fontWeight, 10) >= 700 || fontWeight === "bold";
    return fontSize >= 24 || (bold && fontSize >= 18.66);
  }
}
```

`parseColor` returns `null` rather than guessing. A wrong color produces a fabricated pass or a fabricated violation, and both are worse than skipping the node.

## 4. Keyboard navigation testing

```javascript
// keyboard-navigation.js
class KeyboardNavigationTester {
  async testKeyboardNavigation(page) {
    const results = {
      focusableElements: [],
      missingFocusIndicators: [],
      keyboardTraps: [],
    };

    const focusable = await page.evaluate(() => {
      const selector =
        'a[href], button, input, select, textarea, [tabindex]:not([tabindex="-1"])';
      return Array.from(document.querySelectorAll(selector)).map((el) => ({
        tagName: el.tagName.toLowerCase(),
        text: el.innerText || el.value || el.placeholder || "",
        tabIndex: el.tabIndex,
      }));
    });

    results.focusableElements = focusable;

    // Establish a known starting point, otherwise the first Tab lands
    // unpredictably and activeElement can still be <body>.
    await page.evaluate(() => document.body.focus());

    let lastTag = null;
    let stuckCount = 0;

    for (let i = 0; i < focusable.length; i++) {
      await page.keyboard.press("Tab");

      const focused = await page.evaluate(() => {
        const el = document.activeElement;
        if (!el || el === document.body) return null;

        // Compare focused styles against the element's own unfocused styles.
        // Testing borderStyle alone passes every bordered input, hiding real
        // missing-outline bugs; testing a static boxShadow passes elements
        // that never change on focus.
        const focusedStyle = window.getComputedStyle(el);
        const snapshot = {
          outline: focusedStyle.outlineStyle + focusedStyle.outlineWidth,
          boxShadow: focusedStyle.boxShadow,
        };
        el.blur();
        const restStyle = window.getComputedStyle(el);
        const rest = {
          outline: restStyle.outlineStyle + restStyle.outlineWidth,
          boxShadow: restStyle.boxShadow,
        };
        el.focus();

        return {
          tagName: el.tagName.toLowerCase(),
          text: (el.innerText || el.value || "").slice(0, 40),
          hasFocusIndicator:
            snapshot.outline !== rest.outline ||
            snapshot.boxShadow !== rest.boxShadow,
        };
      });

      if (!focused) continue;
      if (!focused.hasFocusIndicator) results.missingFocusIndicators.push(focused);

      // Focus that fails to advance across consecutive presses is a trap.
      if (focused.tagName === lastTag && focused.text === (results._lastText || "")) {
        if (++stuckCount >= 2) results.keyboardTraps.push(focused);
      } else {
        stuckCount = 0;
      }
      lastTag = focused.tagName;
      results._lastText = focused.text;
    }

    delete results._lastText;
    return results;
  }
}
```

The blur-and-refocus comparison is the only reliable way to detect a missing focus indicator from computed styles. It does fire focus and blur handlers, so run it against a page where that is harmless, or gate it behind a flag.

## 5. Screen-reader structure checks

```javascript
// screen-reader-test.js - heading outline and form labeling
async function testHeadingStructure(page) {
  const headings = await page.evaluate(() =>
    Array.from(document.querySelectorAll("h1,h2,h3,h4,h5,h6")).map((h) => ({
      level: parseInt(h.tagName[1]),
      text: h.textContent.trim(),
      isEmpty: !h.textContent.trim(),
    })),
  );

  const issues = [];
  let previousLevel = 0;
  headings.forEach((heading, index) => {
    if (heading.level > previousLevel + 1 && previousLevel !== 0) {
      issues.push({
        type: "skipped-level",
        message: `Heading level ${heading.level} skips from level ${previousLevel}`,
      });
    }
    if (heading.isEmpty) issues.push({ type: "empty-heading", index });
    previousLevel = heading.level;
  });
  if (!headings.some((h) => h.level === 1)) {
    issues.push({ type: "missing-h1", message: "Page missing h1 element" });
  }
  return { headings, issues };
}

async function testFormAccessibility(page) {
  const fields = await page.evaluate(() => {
    // Query the document, not per-form: inputs outside a <form> need labels
    // too. Exclude control types that take no visible label.
    const selector =
      "input:not([type=hidden]):not([type=submit]):not([type=button]):not([type=image]), textarea, select";

    return Array.from(document.querySelectorAll(selector)).map((input) => ({
      type: input.type || input.tagName.toLowerCase(),
      id: input.id,
      // CSS.escape is required: React Hook Form, Angular and Formik generate
      // IDs containing "." or ":" or starting with a digit, and an unescaped
      // selector throws SyntaxError, killing the whole check.
      hasLabel: input.id
        ? !!document.querySelector('label[for="' + CSS.escape(input.id) + '"]')
        : !!input.closest("label"),
      hasAriaLabel: !!input.getAttribute("aria-label"),
      hasAriaLabelledby: !!input.getAttribute("aria-labelledby"),
      hasTitle: !!input.getAttribute("title"),
      required: input.required,
      selector: input.id ? "#" + input.id : input.name || input.type,
    }));
  });

  const issues = fields
    .filter(
      (f) =>
        !f.hasLabel && !f.hasAriaLabel && !f.hasAriaLabelledby && !f.hasTitle,
    )
    .map((f) => ({ type: "missing-label", field: f.selector, wcag: "3.3.2" }));

  return { fields, issues };
}
```

## 6. CI integration

```yaml
# .github/workflows/accessibility.yml
name: Accessibility Tests

on: [push, pull_request]

jobs:
  a11y-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: "20"

      - name: Install and build
        run: |
          npm ci
          npm run build

      - name: Start server
        run: |
          npm start &
          npx wait-on http://localhost:3000

      - name: Run axe tests
        run: npm run test:a11y

      - name: Run pa11y
        run: npx pa11y http://localhost:3000 --standard WCAG2AA --threshold 0

      - name: Upload report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: a11y-report
          path: a11y-report.html
```

## 7. HTML report generator

```javascript
// report-generator.js
// Every interpolated value is page-derived and therefore untrusted. axe help
// strings also contain literal < and > (element names), which break the markup
// unescaped, and the report is an artifact CI uploads and people open.
const esc = (s) =>
  String(s ?? "").replace(
    /[&<>"']/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c],
  );

function generateHTMLReport(auditResults) {
  return `<html lang="en">
<head>
  <title>Accessibility Audit</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 20px; }
    .summary { background: #f0f0f0; padding: 20px; border-radius: 8px; }
    .score { font-size: 48px; font-weight: bold; }
    .violation { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }
    .critical { border-color: #a00; background: #fee; }
    .serious { border-color: #a60; background: #ffe; }
  </style>
</head>
<body>
  <h1>Accessibility Audit Report</h1>
  <p>Generated: ${new Date().toLocaleString()}</p>
  <div class="summary">
    <h2>Summary</h2>
    <div class="score">${auditResults.score}/100</div>
    <p>Total violations: ${auditResults.violations.length}</p>
  </div>
  <h2>Violations</h2>
  ${auditResults.violations
    .map(
      (v) => `<div class="violation ${esc(v.impact || "unknown")}">
      <h3>${esc(v.help)}</h3>
      <p><strong>Impact:</strong> ${esc(v.impact)}</p>
      <p>${esc(v.description)}</p>
      <a href="${esc(v.helpUrl)}">Learn more</a>
    </div>`,
    )
    .join("")}
</body>
</html>`;
}
```

## 8. Triage flagging snippets (they mark, they do not author)

These mark what a human must fix. They never write user-facing content, because
generated alt text and placeholder-as-label are both worse than the gap they
fill - `alt="Image"` announces nothing and duplicates the implicit role, and a
placeholder disappears the moment the field has a value.

```javascript
// Flag images with no alt attribute. An empty alt is a real decision
// (decorative); a missing one is not.
document.querySelectorAll("img:not([alt])").forEach((img) => {
  const decorative =
    img.getAttribute("role") === "presentation" ||
    img.closest('[role="presentation"]');
  if (decorative) {
    img.setAttribute("alt", ""); // safe: decorative is unambiguous
  } else {
    img.setAttribute("data-a11y-todo", "1.1.1 alt text required - human must author");
  }
});

// Flag inputs with no accessible name. Check every naming mechanism before
// concluding one is missing - the earlier version matched inputs wrapped in a
// <label> and stamped an aria-label that OVERRODE the correct name.
document
  .querySelectorAll(
    "input:not([type=hidden]):not([type=submit]):not([type=button]):not([type=image]), textarea, select",
  )
  .forEach((input) => {
    const named =
      input.getAttribute("aria-label") ||
      input.getAttribute("aria-labelledby") ||
      input.closest("label") ||
      (input.id &&
        document.querySelector('label[for="' + CSS.escape(input.id) + '"]'));
    if (!named) {
      input.setAttribute("data-a11y-todo", "3.3.2 label required - human must author");
    }
  });
```

Then collect the flags: `document.querySelectorAll("[data-a11y-todo]")`.
