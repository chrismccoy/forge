/**
 * @file Logs in to WordPress and reports what demo scenes can target on admin pages.
 *
 * For each page it prints the heading, visible notices and every visible control with a
 * suggested Playwright locator, and saves an accessibility snapshot (.aria.yml) and a
 * full-page screenshot (.png).
 *
 * Read-only by design: it never clicks, skips URLs that match common data-changing patterns
 * (see isUnsafeUrl in wp.js), and blanks secret-looking field values in the browser tab before
 * saving anything (see redactSecrets in wp.js).
 *
 * Usage: node --env-file=.env inspect-page.js [--menu] [--out dir] ['admin path' ...]
 *   --menu  list every admin menu entry with its URL
 *   --out   where to save snapshots and screenshots (default: output/inspect)
 */

import { chromium } from 'playwright';
import { createHash } from 'node:crypto';
import { mkdirSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { parseArgs } from 'node:util';
import {
  readEnv,
  contextOptions,
  adminUrl,
  isUnsafeUrl,
  login,
  redactSecrets,
  refusedPageError,
} from './wp.js';

/**
 * One visible control on an admin page.
 * @typedef {object} Control
 * @property {string} type - Input type ("text", "checkbox"...), tag name, or "tab".
 * @property {string} id - The element's id, or "".
 * @property {string} name - The element's name attribute, or "".
 * @property {string} text - Button text, or the label, placeholder or title naming the field.
 * @property {boolean} disabled - Whether the control is disabled.
 * @property {string} locator - Suggested Playwright locator, or "(no stable locator)".
 */

/**
 * What collectControls() finds on a page.
 * @typedef {object} PageReport
 * @property {string} heading - Text of the page's main heading.
 * @property {string[]} notices - Text of visible admin notices.
 * @property {Control[]} rows - Visible controls, in page order.
 */

/**
 * One admin menu entry.
 * @typedef {object} MenuEntry
 * @property {number} level - 0 for a top-level entry, 1 for a submenu entry.
 * @property {string} text - Menu text without update counters.
 * @property {string | null} href - The link target as written in the page.
 */

// ---------------------------------------------------------------------------------------------
// Arguments and settings
// ---------------------------------------------------------------------------------------------

const { values: flags, positionals: targets } = parseArgs({
  allowPositionals: true,
  options: {
    menu: { type: 'boolean', default: false },
    out: { type: 'string', default: 'output/inspect' },
  },
});

if (!flags.menu && targets.length === 0) {
  console.error(
    "Usage: node --env-file=.env inspect-page.js [--menu] [--out dir] ['admin path' ...]",
  );
  console.error("Example: node --env-file=.env inspect-page.js --menu 'admin.php?page=my-plugin'");
  process.exit(1);
}

/** Viewport for inspection; screenshots are full-page, so only the width really matters. */
const SIZE = { width: 1920, height: 1080 };

/** @type {import('./wp.js').WpEnv} */
let env;
try {
  env = readEnv();
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
const outDir = path.resolve(flags.out);
mkdirSync(outDir, { recursive: true });

/**
 * Builds a file name for an admin path: a readable part plus a short hash of the full path,
 * so paths that differ only in punctuation ("page=a_b" and "page=a-b") never overwrite each
 * other's files.
 * @param {string} target - Admin path or URL.
 * @returns {string} File name without extension.
 */
function slug(target) {
  const readable =
    target
      .replace(/^https?:\/\/[^/]+/, '')
      .replace(/[^a-zA-Z0-9]+/g, '-')
      .replace(/^-|-$/g, '')
      .slice(0, 60) || 'dashboard';
  return `${readable}-${createHash('sha1').update(target).digest('hex').slice(0, 6)}`;
}

// ---------------------------------------------------------------------------------------------
// Functions that run inside the page (passed to page.evaluate, so they must be self-contained)
// ---------------------------------------------------------------------------------------------

/**
 * Lists the visible controls in the admin content area with the locator a scene should use.
 * Runs inside the page.
 *
 * Locator choice: getByRole for buttons, links and tabs; getByLabel for fields with a label
 * or aria-label; getByPlaceholder or getByTitle when a field has only that text (getByLabel
 * does not match those); then an escaped #id; then [name="..."].
 * @returns {PageReport} Heading, notices and controls.
 */
function collectControls() {
  const root = document.querySelector('#wpbody-content') ?? document.body;
  /**
   * Tells whether an element is rendered and not hidden.
   * @param {Element} el - Element to test.
   * @returns {boolean} True when the element takes up space on the page and is not hidden.
   */
  const visible = (el) =>
    el.getClientRects().length > 0 && getComputedStyle(el).visibility !== 'hidden';
  /**
   * Collapses whitespace and shortens text for one output column.
   * @param {string | null | undefined} s - Raw text.
   * @returns {string} Single-line text, at most 80 characters.
   */
  const clean = (s) => (s ?? '').replace(/\s+/g, ' ').trim().slice(0, 80);
  /**
   * Quotes text as a JS string literal, so labels such as "Don't import" stay valid code.
   * @param {string} s - Text to quote.
   * @returns {string} The text in single quotes, with backslashes and quotes escaped.
   */
  const q = (s) => `'${s.replace(/\\/g, '\\\\').replace(/'/g, "\\'")}'`;

  /**
   * Finds the text that names a field, and the locator that matches that kind of text:
   * label (aria-label, <label>), then placeholder, then title.
   * @param {HTMLInputElement} el - Form field (input, select or textarea).
   * @returns {{ text: string, locator: string }} The name and a suggested locator; both empty
   *   when the field has no accessible name.
   */
  const nameOf = (el) => {
    const label =
      el.getAttribute('aria-label') ||
      el.labels?.[0]?.textContent ||
      (el.id && document.querySelector(`label[for="${CSS.escape(el.id)}"]`)?.textContent);
    if (clean(label)) return { text: clean(label), locator: `getByLabel(${q(clean(label))})` };
    const placeholder = clean(el.getAttribute('placeholder'));
    if (placeholder) return { text: placeholder, locator: `getByPlaceholder(${q(placeholder)})` };
    const title = clean(el.getAttribute('title'));
    if (title) return { text: title, locator: `getByTitle(${q(title)})` };
    return { text: '', locator: '' };
  };

  const rows = [];
  const selector =
    'input:not([type=hidden]), select, textarea, button, a.button, a.page-title-action, [role=button], [role=tab], .nav-tab';
  // Typed as inputs for the properties read below (type, value, name, disabled); buttons,
  // links and selects simply return undefined or "" for the ones they lack.
  /** @type {NodeListOf<HTMLInputElement>} */
  const controls = root.querySelectorAll(selector);
  for (const el of controls) {
    if (!visible(el)) continue;
    const tag = el.tagName.toLowerCase();
    const type = tag === 'input' ? el.type : tag;
    const role = el.getAttribute('role');
    const isButton = ['button', 'submit', 'reset'].includes(type) || role === 'button';
    const isLink = tag === 'a' && !role;
    const isTab = role === 'tab';
    let text = '';
    let locator = '';
    if (isButton || isLink || isTab) {
      text = clean(el.textContent || el.value);
      const kind = isTab ? 'tab' : isLink ? 'link' : 'button';
      if (text) locator = `getByRole('${kind}', { name: ${q(text)} })`;
    } else {
      ({ text, locator } = nameOf(el));
    }
    // Fallbacks: CSS.escape keeps IDs such as "opt[color]" valid as selectors.
    if (!locator && el.id) locator = `locator('#${CSS.escape(el.id)}')`;
    if (!locator && el.name) locator = `locator('[name="${el.name.replace(/"/g, '\\"')}"]')`;
    rows.push({
      type: isTab ? 'tab' : type,
      id: el.id || '',
      name: el.getAttribute('name') || '',
      text,
      disabled: el.disabled || el.getAttribute('aria-disabled') === 'true',
      locator: locator || '(no stable locator)',
    });
  }
  const heading = clean(document.querySelector('.wrap h1, #wpbody-content h1, h1')?.textContent);
  const notices = [...document.querySelectorAll('.notice, .error, .updated')]
    .filter(visible)
    .map((n) => clean(n.textContent));
  return { heading, notices, rows };
}

/**
 * Lists every admin menu entry, top level and submenu. Runs inside the page.
 * @returns {MenuEntry[]} Menu entries in menu order.
 */
function collectMenu() {
  /**
   * Collapses whitespace in text.
   * @param {string | null | undefined} s - Raw text.
   * @returns {string} Single-line text.
   */
  const clean = (s) => (s ?? '').replace(/\s+/g, ' ').trim();
  /**
   * Menu text without update and notification counters such as "Plugins 3".
   * @param {Element} a - Menu link.
   * @returns {string} The link text without counters.
   */
  const name = (a) => {
    const copy = /** @type {Element} */ (a.cloneNode(true));
    copy.querySelectorAll('.awaiting-mod, .update-plugins, .count').forEach((n) => n.remove());
    return clean(copy.textContent);
  };
  return [...document.querySelectorAll('#adminmenu > li')].flatMap((li) => {
    const top = li.querySelector(':scope > a');
    if (!top) return [];
    const entries = [{ level: 0, text: name(top), href: top.getAttribute('href') }];
    for (const sub of li.querySelectorAll('.wp-submenu a')) {
      entries.push({ level: 1, text: name(sub), href: sub.getAttribute('href') });
    }
    return entries;
  });
}

// ---------------------------------------------------------------------------------------------
// Inspection
// ---------------------------------------------------------------------------------------------

const browser = await chromium.launch();
try {
  const storageState = await login(browser, env, SIZE).catch((error) => {
    // Login errors are already specific; a stack trace adds nothing.
    console.error(error.message);
    process.exit(1);
  });
  const context = await browser.newContext({
    viewport: SIZE,
    storageState,
    ...contextOptions(env),
  });
  const page = await context.newPage();
  console.log(`Logged in to ${env.base} as ${env.user}\n`);

  if (flags.menu) {
    await page.goto(adminUrl(env.base, 'index.php'));
    console.log('== Admin menu');
    for (const e of await page.evaluate(collectMenu)) {
      console.log(`${e.level ? '    ' : '  '}${e.text.padEnd(40)} ${e.href}`);
    }
    console.log();
  }

  for (const target of targets) {
    if (isUnsafeUrl(target)) {
      console.log(`== ${target}\n  Skipped: this URL matches a data-changing pattern.\n`);
      continue;
    }
    const response = await page.goto(adminUrl(env.base, target));
    // A refused page (inactive plugin, missing capability) is not the plugin's screen: say so
    // and save nothing, so its controls are never mistaken for the plugin's.
    const refused = await refusedPageError(page, response, target);
    if (refused) {
      console.log(`== ${target}\n  Refused: ${refused}\n`);
      continue;
    }
    // Give JS-built screens a moment to render; some pages never go fully idle.
    await page.waitForLoadState('networkidle', { timeout: 10_000 }).catch(() => {});
    const base = path.join(outDir, slug(target));

    // Redact before anything is read or saved, so secrets reach neither file nor output.
    const redacted = await page.evaluate(redactSecrets);
    const { heading, notices, rows } = await page.evaluate(collectControls);
    const root = (await page.locator('#wpbody-content').count()) ? '#wpbody-content' : 'body';
    writeFileSync(`${base}.aria.yml`, (await page.locator(root).ariaSnapshot()) + '\n');
    await page.screenshot({ path: `${base}.png`, fullPage: true });

    console.log(`== ${target}`);
    console.log(`  URL:     ${page.url()} (HTTP ${response?.status() ?? '?'})`);
    console.log(`  Heading: ${heading || '(none)'}`);
    for (const n of notices) console.log(`  Notice:  ${n}`);
    if (redacted) console.log(`  Secrets: ${redacted} field value(s) blanked before saving`);
    console.log(`  Controls (${rows.length}):`);
    for (const r of rows) {
      const ids = [r.id && `#${r.id}`, r.name && `name=${r.name}`].filter(Boolean).join(' ');
      const flag = r.disabled ? ' [disabled]' : '';
      console.log(
        `    ${r.type.padEnd(9)} ${(r.text || '-').padEnd(32)} ${ids.padEnd(36)} ${r.locator}${flag}`,
      );
    }
    console.log(`  Saved:   ${path.relative(process.cwd(), base)}.aria.yml, .png\n`);
  }

  await context.close();
} finally {
  await browser.close();
}
