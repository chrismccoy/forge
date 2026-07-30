/*
 * computed.js — dump the REAL computed styles of the live page as a compact spec.
 *
 * Runs in the page context (Claude in Chrome javascript_tool / evaluate). Returns a
 * JSON-serialisable array, one entry per visible element, carrying only the CSS
 * properties that map to Tailwind utilities — and only where they differ from the
 * browser default, so the output stays small.
 *
 * Why this exists: the Tailwind rewrite must reproduce the ORIGINAL look exactly.
 * Reading computed values gives exact numbers (16px, 600, #1a1a1a, 8px radius) to
 * map straight onto Tailwind's scale, instead of eyeballing a screenshot. Pseudo
 * states (:hover) and @media rules are NOT here — computed style is a single state;
 * get those from the real CSS in page-cloner's extracted index.html.
 *
 * Two things to know about the diffing:
 *   - Per-element entries drop any property equal to that tag's UA default, to keep
 *     the output small. For INHERITED props (color, font-family, font-size, …) the
 *     probe inherits the page's own body values, so an element whose text matches the
 *     body baseline won't list those props — that's fine, the baseline is captured
 *     separately as explicit <html>/<body> entries (first entries in the array).
 *   - Resolved values, not source: grid-template-columns comes back as pixel tracks
 *     (not `repeat(3,1fr)`) and line-height as px (not a ratio). Read grid templates
 *     from the real CSS in clone/index.html; expect arbitrary line-heights.
 *
 * Usage (inside the page):
 *   const spec = (() => { <this file's body> })();   // synchronous
 * Save the returned array to <workspace>/original/computed.json.
 */
(() => {
  // Properties worth translating to Tailwind. Keep this list tight.
  // NOTE on width/height: getComputedStyle returns the *used* pixel value for every
  // rendered element, not what the CSS authored. Most block elements get an incidental
  // width (e.g. 1232px) that is really "fill the container" — do NOT translate those to
  // w-[1232px]/h-[…] or the layout hardcodes and breaks at other widths. Only map
  // width/height when the source CSS actually authored a fixed size (see mapping.md).
  // boxSizing is intentionally omitted: Tailwind Preflight already makes border-box the
  // default, so capturing it would emit box-border on nearly every element as noise.
  const PROPS = [
    'display', 'position', 'top', 'right', 'bottom', 'left', 'zIndex',
    'flexDirection', 'justifyContent', 'alignItems', 'alignContent', 'alignSelf',
    'flexWrap', 'flexGrow', 'flexShrink', 'flexBasis', 'gap',
    'gridTemplateColumns', 'gridTemplateRows', 'gridAutoFlow',
    'gridColumn', 'gridRow', 'aspectRatio',
    'width', 'height', 'maxWidth', 'minHeight', 'overflow',
    'marginTop', 'marginRight', 'marginBottom', 'marginLeft',
    'paddingTop', 'paddingRight', 'paddingBottom', 'paddingLeft',
    'fontSize', 'fontWeight', 'lineHeight', 'letterSpacing', 'textAlign',
    'fontFamily', 'textTransform', 'fontStyle', 'whiteSpace',
    'color', 'backgroundColor', 'backgroundImage', 'objectFit', 'cursor',
    'backgroundSize', 'backgroundPosition', 'backgroundRepeat',
    'listStyleType', 'textDecorationLine', 'textDecorationColor',
    'borderRadius', 'borderStyle', 'borderColor',
    'borderTopWidth', 'borderRightWidth', 'borderBottomWidth', 'borderLeftWidth',
    'boxShadow', 'opacity',
  ];

  // Tailwind Preflight (loaded by the rewrite via the CDN) RESETS these UA defaults:
  // headings -> font-size/weight inherit, lists -> no marker + no padding, block
  // elements -> margin 0. So when one of these props equals the raw UA default it is
  // NOT neutral in the output — Preflight will actively change it. Force-emit these
  // per tag even when they match the default, so the rewrite can restore the look.
  const PREFLIGHT_KEEP = {
    h1: ['fontSize', 'fontWeight', 'marginTop', 'marginBottom'],
    h2: ['fontSize', 'fontWeight', 'marginTop', 'marginBottom'],
    h3: ['fontSize', 'fontWeight', 'marginTop', 'marginBottom'],
    h4: ['fontSize', 'fontWeight', 'marginTop', 'marginBottom'],
    h5: ['fontSize', 'fontWeight', 'marginTop', 'marginBottom'],
    h6: ['fontSize', 'fontWeight', 'marginTop', 'marginBottom'],
    ul: ['listStyleType', 'paddingLeft', 'marginTop', 'marginBottom'],
    ol: ['listStyleType', 'paddingLeft', 'marginTop', 'marginBottom'],
    p: ['marginTop', 'marginBottom'],
    figure: ['marginTop', 'marginBottom', 'marginLeft', 'marginRight'],
    blockquote: ['marginTop', 'marginBottom', 'marginLeft', 'marginRight'],
    a: ['color', 'textDecorationLine'],
  };

  // A throwaway element to read the UA defaults per tag, so we can diff them out.
  const defaultsCache = {};
  const defaultsFor = (tag) => {
    if (defaultsCache[tag]) return defaultsCache[tag];
    const probe = document.createElement(tag);
    probe.style.position = 'absolute';
    probe.style.visibility = 'hidden';
    document.body.appendChild(probe);
    const cs = getComputedStyle(probe);
    const d = {};
    for (const p of PROPS) d[p] = cs[p];
    document.body.removeChild(probe);
    defaultsCache[tag] = d;
    return d;
  };

  const out = [];
  let idx = 0;

  // Root baseline. <html>/<body> carry the font, color, and background the whole page
  // inherits from; querySelectorAll('body *') skips them, so capture them explicitly
  // and WITHOUT default-diffing — this baseline is exactly what the rewrite needs.
  for (const root of [document.documentElement, document.body]) {
    if (!root) continue;
    const cs = getComputedStyle(root);
    const props = {};
    for (const p of PROPS) {
      const v = cs[p];
      if (v && v !== 'none' && v !== 'auto' && v !== 'normal' &&
          v !== 'rgba(0, 0, 0, 0)') props[p] = v;
    }
    out.push({ i: idx++, tag: root.tagName.toLowerCase(),
               path: root.tagName.toLowerCase(), text: '', props });
  }

  const all = document.querySelectorAll('body *');
  for (const el of all) {
    const rect = el.getBoundingClientRect();
    const cs = getComputedStyle(el);
    if (cs.display === 'none' || cs.visibility === 'hidden') continue;
    if (rect.width === 0 && rect.height === 0) continue;

    const tag = el.tagName.toLowerCase();
    if (tag === 'script' || tag === 'style' || tag === 'noscript') continue;

    const def = defaultsFor(tag);
    const props = {};
    for (const p of PROPS) {
      const v = cs[p];
      // Keep anything that differs from this tag's UA default. Do NOT blanket-skip
      // '0px' — a real reset (e.g. <ul> with padding-left:0, default 40px) differs
      // from the default and must be kept so the rewrite emits p-0/m-0.
      if (v && v !== def[p] && v !== 'none' && v !== 'auto' &&
          v !== 'normal' && v !== 'rgba(0, 0, 0, 0)') {
        props[p] = v;
      }
    }
    // Force-emit the Preflight-reset props for this tag (see PREFLIGHT_KEEP above),
    // even when they equal the UA default, so the reset doesn't silently change them.
    const keep = PREFLIGHT_KEEP[tag];
    if (keep) for (const p of keep) {
      const v = cs[p];
      if (v && !(p in props)) props[p] = v;
    }
    if (Object.keys(props).length === 0) continue;

    // A short, stable path so the rewrite can locate this node in the DOM.
    const path = [];
    let n = el;
    while (n && n !== document.body && path.length < 6) {
      let seg = n.tagName.toLowerCase();
      if (n.id) { seg += '#' + n.id; path.unshift(seg); break; }
      const sibs = n.parentElement
        ? [...n.parentElement.children].filter(c => c.tagName === n.tagName)
        : [];
      if (sibs.length > 1) seg += `:nth-of-type(${sibs.indexOf(n) + 1})`;
      path.unshift(seg);
      n = n.parentElement;
    }

    out.push({
      i: idx++,
      tag,
      path: path.join(' > '),
      text: (el.childElementCount === 0 ? el.textContent.trim().slice(0, 60) : ''),
      props,
    });
  }
  return out;
})();
