/*
 * extract.js — turn the LIVE, fully-rendered page into one self-contained HTML string.
 *
 * Runs in the page's own context (via Claude in Chrome's javascript_tool / an
 * evaluate call). Returns a complete HTML document as a string. The caller writes
 * that string to <workspace>/clone/index.html.
 *
 * What it does, and why:
 *   - Snapshots the RENDERED DOM (document.documentElement.outerHTML), not the
 *     server's original source — so JS-built content is already materialised.
 *   - Inlines external stylesheets into <style> tags, rewriting their url()
 *     references to absolute URLs so backgrounds/fonts still resolve. If a sheet
 *     is CORS-blocked and can't be read, its <link> is kept (absolutised) so the
 *     browser still loads it when online — a working clone, just not fully offline.
 *   - Absolutises every href / src / srcset so relative asset paths keep working
 *     when the file is opened from disk.
 *   - Strips <script> tags. This is a STATIC visual clone; leaving framework JS in
 *     would re-hydrate and often blank out the very DOM we just captured.
 *
 * Usage (inside the page): evaluate this whole file once — it defines
 *   window.__extractClone — then call it:
 *     window.__CLONE = await window.__extractClone();
 * Under Playwright: page.evaluate(fileText) to define it, then
 *   page.evaluate("window.__extractClone()") returns the HTML string.
 * Evaluating the file is a plain statement (a function definition), so it works
 * the same whether pasted into the Chrome REPL or passed to page.evaluate.
 */
window.__extractClone = async () => {
  // document.baseURI honors a <base href> element; falls back to location.href.
  const pageUrl = document.baseURI || location.href;

  const abs = (url, base = pageUrl) => {
    if (!url) return url;
    const t = url.trim();
    if (!t || t.startsWith('data:') || t.startsWith('#') ||
        t.startsWith('mailto:') || t.startsWith('tel:') ||
        t.startsWith('javascript:')) return url;
    try { return new URL(t, base).href; } catch { return url; }
  };

  // Rewrite url(...) tokens inside a chunk of CSS, relative to that CSS file's URL.
  // Quote-aware so ')' inside a quoted value (e.g. inline SVG data URIs) doesn't
  // truncate the match; data: URIs are passed through untouched.
  const absCss = (css, base) =>
    css.replace(
      /url\(\s*(?:(['"])((?:\\.|(?!\1)[^\\])*)\1|([^)]*))\s*\)/gi,
      (m, q, quoted, unq) => {
        const u = (q ? quoted : unq).trim();
        if (!u || u.startsWith('data:')) return m;
        return `url(${q || ''}${abs(u, base)}${q || ''})`;
      });

  // Recursively fetch a stylesheet, inlining any @import it pulls in.
  const seen = new Set();
  const fetchCss = async (url, base) => {
    const full = abs(url, base);
    if (seen.has(full)) return '';
    seen.add(full);
    let text;
    try {
      const res = await fetch(full);
      if (!res.ok) throw new Error(res.status);
      text = await res.text();
    } catch (e) {
      return `/* could not inline ${full}: ${e} */`;
    }
    // Resolve @import chains first, then absolutise this sheet's own url()s.
    const importRe = /@import\s+(?:url\(\s*)?(['"]?)([^'")\s]+)\1\s*\)?\s*([^;]*);/g;
    let out = '', last = 0, m;
    while ((m = importRe.exec(text))) {
      out += text.slice(last, m.index);
      const imported = await fetchCss(m[2], full);
      const cond = (m[3] || '').trim();
      // Preserve a media condition so the import isn't applied at all widths. But only
      // a real media query — a `layer(...)`/`supports(...)` prefix isn't valid inside
      // @media and would get the whole block dropped, so inline those unwrapped.
      const wrap = cond && !/^(layer|supports)\b/i.test(cond);
      out += wrap ? `@media ${cond}{\n${imported}\n}` : imported;
      last = importRe.lastIndex;
    }
    out += text.slice(last);
    return absCss(out, full);
  };

  const doc = document.cloneNode(true);

  // 1. Drop scripts — static clone.
  doc.querySelectorAll('script, noscript').forEach(n => n.remove());

  // 2. Inline external stylesheets in document order (order = cascade).
  // Real stylesheets only — skip `alternate stylesheet` links (disabled in the live
  // page, so inlining them would apply styles the user never saw).
  const links = [...doc.querySelectorAll('link[rel~="stylesheet"]:not([rel~="alternate"])')];
  for (const link of links) {
    const href = link.getAttribute('href');
    const css = await fetchCss(href, pageUrl);
    if (css && !css.startsWith('/* could not inline')) {
      const style = doc.createElement('style');
      if (link.media) style.media = link.media;
      style.textContent = css;
      link.replaceWith(style);
    } else {
      // Keep it as a working link so the browser fetches it live.
      link.setAttribute('href', abs(href));
    }
  }

  // 3. Absolutise inline <style> blocks that were already in the page.
  doc.querySelectorAll('style').forEach(s => {
    if (s.textContent) s.textContent = absCss(s.textContent, pageUrl);
  });

  // 3b. Recover CSSOM-injected rules. styled-components/Emotion in their production
  // "speedy" mode, and anything using insertRule/adoptedStyleSheets, put rules ONLY in
  // the CSSOM — the <style> node's textContent is empty, so cloneNode captured nothing.
  // Serialise those rules from the live document into one appended <style>, or the
  // clone renders unstyled. (This is the common case for CSS-in-JS prod builds.)
  const recovered = [];
  for (const sheet of document.styleSheets) {
    const node = sheet.ownerNode;
    // Only <style> nodes whose text is empty but whose sheet holds rules (CSSOM-only).
    if (!node || node.tagName !== 'STYLE') continue;
    if ((node.textContent || '').trim() !== '') continue;
    try {
      const txt = [...sheet.cssRules].map(r => r.cssText).join('\n');
      if (txt) recovered.push(absCss(txt, pageUrl));
    } catch { /* cross-origin sheet — unreadable, skip */ }
  }
  for (const sheet of (document.adoptedStyleSheets || [])) {
    try {
      const txt = [...sheet.cssRules].map(r => r.cssText).join('\n');
      if (txt) recovered.push(absCss(txt, pageUrl));
    } catch { /* skip */ }
  }
  if (recovered.length) {
    const head = doc.querySelector('head') || doc.documentElement;
    const s = doc.createElement('style');
    s.setAttribute('data-cssom-recovered', '');
    s.textContent = recovered.join('\n');
    head.appendChild(s); // append last to preserve cascade order
  }

  // 4. Absolutise element URLs so nothing breaks off-origin.
  doc.querySelectorAll('[href]').forEach(el =>
    el.setAttribute('href', abs(el.getAttribute('href'))));
  doc.querySelectorAll('[src]').forEach(el =>
    el.setAttribute('src', abs(el.getAttribute('src'))));
  // Comma-safe srcset parse: a naive split(',') shreds transformation URLs that
  // contain commas (Cloudinary/imgix `w_200,h_100`) and data: candidates. Walk the
  // string per the srcset grammar — URL runs to whitespace, descriptor runs to comma.
  const parseSrcset = s => {
    const out = []; let i = 0; const n = s.length;
    while (i < n) {
      while (i < n && /[\s,]/.test(s[i])) i++;            // skip leading ws + commas
      let url = ''; while (i < n && !/\s/.test(s[i])) url += s[i++];
      let trailingComma = false;
      while (url.endsWith(',')) { url = url.slice(0, -1); trailingComma = true; }
      while (i < n && /\s/.test(s[i])) i++;
      let desc = '';
      if (!trailingComma) while (i < n && s[i] !== ',') desc += s[i++];
      if (url) out.push(abs(url) + (desc.trim() ? ' ' + desc.trim() : ''));
    }
    return out.join(', ');
  };
  doc.querySelectorAll('[srcset]').forEach(el =>
    el.setAttribute('srcset', parseSrcset(el.getAttribute('srcset'))));
  doc.querySelectorAll('[style]').forEach(el =>
    el.setAttribute('style', absCss(el.getAttribute('style'), pageUrl)));

  // 5. Ensure a correct charset so the file stands alone. No <base> needed —
  //    every URL was already absolutised above.
  const head = doc.querySelector('head') || doc.documentElement;
  if (!doc.querySelector('meta[charset]')) {
    const cs = doc.createElement('meta');
    cs.setAttribute('charset', 'utf-8');
    head.prepend(cs);
  }

  return '<!DOCTYPE html>\n' + doc.documentElement.outerHTML;
};
// Evaluating this file leaves a serializable completion value (not the function
// itself), so page.evaluate(fileText) under Playwright won't choke trying to return it.
null;
