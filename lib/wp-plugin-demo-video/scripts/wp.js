/**
 * @file Shared WordPress helpers for record.js, inspect-page.js and check-env.js: reading the
 * site settings from the environment, building admin URLs, spotting URLs that can change data
 * when loaded, spotting WordPress error pages, blanking secrets on a page, and logging in.
 */

/**
 * Site settings, read from the environment (normally from .env via `node --env-file=.env`).
 * @typedef {object} WpEnv
 * @property {string} base - Site URL without a trailing slash, from WP_URL.
 * @property {string | undefined} user - Admin user name, from WP_USER.
 * @property {string | undefined} pass - Admin password, from WP_PASS. Never log it.
 * @property {string} loginPath - Login page path without a leading slash, from WP_LOGIN_PATH
 *   (default "wp-login.php"). Security plugins often move the login page.
 * @property {boolean} ignoreHTTPSErrors - True when WP_IGNORE_HTTPS_ERRORS is "1". For local
 *   development sites with self-signed certificates only.
 * @property {{ username: string, password: string } | undefined} httpCredentials - HTTP basic
 *   auth in front of the site, from WP_HTTP_USER and WP_HTTP_PASS. Common on staging sites.
 */

/**
 * Reads the site settings from the environment.
 * @param {object} [options] - What to require.
 * @param {boolean} [options.siteOnly=false] - Require only WP_URL. Used by `check-env.js --site`
 *   to check that the site is reachable before the user enters a login.
 * @returns {WpEnv} The settings.
 * @throws {Error} When a required variable is missing. The message names the variables but
 *   never shows any value.
 */
export function readEnv({ siteOnly = false } = {}) {
  const e = process.env;
  const required = siteOnly ? ['WP_URL'] : ['WP_URL', 'WP_USER', 'WP_PASS'];
  const missing = required.filter((k) => !e[k]);
  if (missing.length)
    throw new Error(`${missing.join(', ')} must be set in .env (run with node --env-file=.env)`);
  return {
    base: e.WP_URL.replace(/\/+$/, ''),
    user: e.WP_USER,
    pass: e.WP_PASS,
    loginPath: (e.WP_LOGIN_PATH || 'wp-login.php').replace(/^\/+/, ''),
    ignoreHTTPSErrors: e.WP_IGNORE_HTTPS_ERRORS === '1',
    httpCredentials:
      e.WP_HTTP_USER && e.WP_HTTP_PASS
        ? { username: e.WP_HTTP_USER, password: e.WP_HTTP_PASS }
        : undefined,
  };
}

/**
 * Options that every Playwright browser context and request context needs to reach the site.
 * @param {WpEnv} env - Site settings.
 * @returns {{ ignoreHTTPSErrors: boolean, httpCredentials: WpEnv['httpCredentials'] }}
 *   Options to spread into `browser.newContext()` or `request.newContext()`.
 */
export function contextOptions(env) {
  return { ignoreHTTPSErrors: env.ignoreHTTPSErrors, httpCredentials: env.httpCredentials };
}

/**
 * Turns a path into a full URL on the site.
 *
 * - A full URL (`https://...`) is returned unchanged.
 * - `wp-admin/...`, `wp-login.php` and the empty string are resolved from the site root.
 * - Anything else is treated as an admin path: `admin.php?page=foo` becomes
 *   `<base>/wp-admin/admin.php?page=foo`. Front-end pages therefore need a full URL.
 * @param {string} base - Site URL without a trailing slash.
 * @param {string} target - Admin path, site path or full URL.
 * @returns {string} Full URL.
 */
export function adminUrl(base, target) {
  if (/^https?:\/\//.test(target)) return target;
  const clean = target.replace(/^\/+/, '');
  return clean.startsWith('wp-admin/') || clean.startsWith('wp-login.php') || clean === ''
    ? `${base}/${clean}`
    : `${base}/wp-admin/${clean}`;
}

/**
 * Tells whether loading a URL is likely to change data on the site. Many plugins, and
 * WordPress itself, act on a plain GET request. This is a heuristic, not a guarantee.
 *
 * A URL counts as unsafe when it:
 * - is `post-new.php` (WordPress saves an auto-draft on every load),
 * - has a parameter whose name contains "nonce",
 * - has an `action` parameter other than `edit`,
 * - has a parameter name or value containing delete, trash, remove, reset, empty or purge.
 *
 * The `page` and `post_type` parameters are not checked, so a plugin page named
 * "trash-manager" still opens. `post.php?action=edit` is allowed, although opening the editor
 * writes an edit lock (post meta).
 * @param {string} target - Admin path or URL.
 * @returns {boolean} True when the URL should not be opened without approval.
 */
export function isUnsafeUrl(target) {
  const DANGER = /delete|trash|remove|reset|empty|purge/i;
  const [pathPart, query = ''] = target.split('?');
  if (/(^|\/)post-new\.php$/.test(pathPart)) return true;
  for (const [key, value] of new URLSearchParams(query)) {
    if (key === 'page' || key === 'post_type') continue;
    if (/nonce/i.test(key) || DANGER.test(key)) return true;
    if (key === 'action' && value !== 'edit') return true;
    if (DANGER.test(value)) return true;
  }
  return false;
}

/**
 * Tells whether WordPress refused to show a page, and why. Playwright's `page.goto` does not
 * throw on HTTP errors, so without this check a refused page looks like a normal load and the
 * next step fails with an unrelated locator timeout.
 *
 * A page counts as refused when it answered HTTP 400 or above, or when it is a WordPress error
 * page (`wp_die()` renders `<body id="error-page">`, often with status 200 or 403). The usual
 * cause on `admin.php?page=...` is an inactive plugin: its page slug then does not exist, and
 * WordPress answers "Sorry, you are not allowed to access this page."
 * @param {import('playwright').Page} page - Page after navigation.
 * @param {import('playwright').Response | null} response - What `page.goto` returned.
 * @param {string} target - The path or URL that was opened, for the message.
 * @returns {Promise<string | null>} A message for the user, or null when the page loaded.
 */
export async function refusedPageError(page, response, target) {
  const status = response?.status() ?? 0;
  const errorPage = (await page.locator('body#error-page').count()) > 0;
  if (status < 400 && !errorPage) return null;
  const text = errorPage
    ? ((await page.locator('body#error-page').innerText()).trim().split('\n')[0] ?? '')
    : '';
  return (
    `WordPress refused ${target} (HTTP ${status || '?'})${text ? `: "${text}"` : '.'} ` +
    'The plugin may be inactive, or this user lacks the capability. Check plugins.php.'
  );
}

/**
 * Blanks the values of fields that look like secrets, so they stay out of screenshots and
 * accessibility snapshots. Runs inside the page (pass it to `page.evaluate`). Only the browser
 * tab changes; nothing is submitted or saved to the site.
 *
 * A field looks secret when it is a password field, or when its id, name or label matches key,
 * token, secret, pass, auth, licence/license or credential. Secrets shown as plain text outside
 * input fields are not touched.
 * @returns {number} How many field values were blanked.
 */
export function redactSecrets() {
  const SECRET = /key|token|secret|pass|auth|licen[cs]e|credential/i;
  let count = 0;
  /** @type {NodeListOf<HTMLInputElement | HTMLTextAreaElement>} */
  const fields = document.querySelectorAll('input:not([type=hidden]), textarea');
  for (const el of fields) {
    const label = el.labels?.[0]?.textContent ?? '';
    const looksSecret =
      el.type === 'password' || SECRET.test(`${el.id} ${el.getAttribute('name') ?? ''} ${label}`);
    if (looksSecret && el.value) {
      el.value = '[redacted]';
      count++;
    }
  }
  return count;
}

/**
 * Logs in to WordPress once, in a separate context that is never recorded, and returns the
 * session (cookies and storage) for reuse in the recording context.
 *
 * Fails fast with a specific message when the login form is missing (wrong WP_LOGIN_PATH),
 * when WordPress shows a login error (for example a wrong password), when login stops at the
 * "Administration email verification" screen, or when no admin page loads within 30 seconds
 * (two-factor authentication, CAPTCHA, redirect plugins).
 * @param {import('playwright').Browser} browser - Launched Chromium browser.
 * @param {WpEnv} env - Site settings, including user and password.
 * @param {{ width: number, height: number }} viewport - Viewport for the login page.
 * @returns {Promise<Awaited<ReturnType<import('playwright').BrowserContext['storageState']>>>}
 *   The logged-in storage state, for `browser.newContext({ storageState })`.
 * @throws {Error} When login does not reach an admin page.
 */
export async function login(browser, env, viewport) {
  const context = await browser.newContext({ viewport, ...contextOptions(env) });
  const page = await context.newPage();
  await page.goto(`${env.base}/${env.loginPath}`);

  // The standard WordPress form uses these IDs in every language, unlike its labels.
  try {
    await page.locator('#user_login').waitFor({ timeout: 10_000 });
  } catch {
    throw new Error(
      `WordPress login form not found at /${env.loginPath}. ` +
        'Set WP_LOGIN_PATH to the login page path, or check WP_URL.',
    );
  }
  await page.locator('#user_login').fill(env.user);
  await page.locator('#user_pass').fill(env.pass);
  await page.locator('#wp-submit').click();

  // Wait for whichever comes first: an admin page, the admin email screen, or a login error.
  // A wrong password then fails at once instead of after the full timeout.
  const outcome = await Promise.race([
    page
      .waitForURL(
        (url) =>
          /\/wp-admin\//.test(url.pathname) ||
          url.searchParams.get('action') === 'confirm_admin_email',
        { timeout: 30_000 },
      )
      .then(() => 'navigated'),
    page
      .locator('#login_error')
      .waitFor({ timeout: 30_000 })
      .then(() => 'error'),
  ]).catch(() => 'timeout');

  if (outcome !== 'navigated') {
    const notice = page.locator('#login_error');
    const error = (await notice.count()) ? (await notice.textContent()).trim() : '';
    throw new Error(`Login failed${error ? `: ${error}` : ' (no redirect to /wp-admin/)'}`);
  }

  // Confirming the admin email writes an option, so leave this screen to a person.
  if (new URL(page.url()).searchParams.get('action') === 'confirm_admin_email') {
    throw new Error(
      'Login stopped at the "Administration email verification" screen. ' +
        'Log in once in a browser and confirm the email, then run again.',
    );
  }

  const state = await context.storageState();
  await context.close();
  return state;
}
