/**
 * @file Checks that this machine can record a demo: Node.js version, the .env keys, the
 * bundled ffmpeg binary, that Chromium starts, that the site's login page answers, and (without
 * --site) that the login works.
 *
 * Prints one line per check ("ok", "FAIL" or "note") and exits with 1 when any check fails.
 * Never prints a value from .env: the .env line names keys only.
 *
 * Usage: node --env-file=.env check-env.js [--site]
 *   --site  require only WP_URL, to check the site before the user enters a login
 */

import { existsSync, statSync } from 'node:fs';

const siteOnly = process.argv.includes('--site');

/** @type {boolean[]} Result of every check that can fail. */
const results = [];

/**
 * Prints one check result and records it.
 * @param {boolean} ok - Whether the check passed.
 * @param {string} name - Short check name, such as "node" or "site".
 * @param {string} detail - What was found, and how to fix it on failure.
 */
function report(ok, name, detail) {
  results.push(ok);
  console.log(`${ok ? 'ok  ' : 'FAIL'}  ${name.padEnd(9)} ${detail}`);
}

/**
 * Prints advice that does not fail the run.
 * @param {string} name - Short check name.
 * @param {string} detail - The advice.
 */
function note(name, detail) {
  console.log(`note  ${name.padEnd(9)} ${detail}`);
}

// ---------------------------------------------------------------------------------------------
// Node.js: 20.6 is the first version with --env-file. An older Node.js usually fails before this
// script runs ("bad option: --env-file"), but the check also covers runs without --env-file.
// ---------------------------------------------------------------------------------------------

const [major, minor] = process.versions.node.split('.').map(Number);
report(
  major > 20 || (major === 20 && minor >= 6),
  'node',
  `${process.versions.node} (needs 20.6 or later)`,
);

// ---------------------------------------------------------------------------------------------
// .env keys: names only, never values.
// ---------------------------------------------------------------------------------------------

const keys = siteOnly ? ['WP_URL'] : ['WP_URL', 'WP_USER', 'WP_PASS'];
const missing = keys.filter((k) => !process.env[k]);
const optional = ['WP_LOGIN_PATH', 'WP_HTTP_USER', 'WP_HTTP_PASS', 'WP_IGNORE_HTTPS_ERRORS'].filter(
  (k) => process.env[k],
);
report(
  missing.length === 0,
  '.env',
  (missing.length ? `missing: ${missing.join(', ')}` : `${keys.join(', ')} set`) +
    (optional.length ? `; also set: ${optional.join(', ')}` : ''),
);

// The file mode is metadata; reading it does not read the password.
if (existsSync('.env') && process.platform !== 'win32' && statSync('.env').mode & 0o077) {
  note('.env', 'readable by other users on this machine: run chmod 600 .env');
}

// ---------------------------------------------------------------------------------------------
// ffmpeg: ffmpeg-static downloads its binary in an npm install script, which can be skipped
// (ignore-scripts, proxies). Without it, a run fails only at the encode step.
// ---------------------------------------------------------------------------------------------

try {
  const { default: ffmpegPath } = await import('ffmpeg-static');
  const found = Boolean(ffmpegPath) && existsSync(ffmpegPath);
  report(
    found,
    'ffmpeg',
    found ? 'bundled binary present' : 'binary missing: run npm install again',
  );
} catch (error) {
  report(false, 'ffmpeg', `ffmpeg-static not installed (${error.code ?? error.message})`);
}

// ---------------------------------------------------------------------------------------------
// Chromium: actually start it. A clean install can still fail at launch on Linux when system
// libraries are missing.
// ---------------------------------------------------------------------------------------------

/** @type {typeof import('playwright') | null} */
let playwright = null;
try {
  playwright = await import('playwright');
  const browser = await playwright.chromium.launch();
  report(true, 'chromium', `${browser.version()} starts`);
  await browser.close();
} catch (error) {
  const hint = playwright
    ? 'run: npx playwright install --with-deps chromium'
    : 'playwright not installed: run npm install';
  report(false, 'chromium', `${error.message.split('\n')[0]} (${hint})`);
}

// ---------------------------------------------------------------------------------------------
// Site: request the login page with the same options the recorder uses (certificates, HTTP
// basic auth, custom login path). Only HTTP 200 passes.
// ---------------------------------------------------------------------------------------------

/** Whether the login page answered HTTP 200; the login check runs only then. */
let siteOk = false;
if (process.env.WP_URL && playwright) {
  const { readEnv, contextOptions } = await import('./wp.js');
  const env = readEnv({ siteOnly: true });
  const url = `${env.base}/${env.loginPath}`;
  const api = await playwright.request.newContext(contextOptions(env));
  try {
    const response = await api.get(url, { timeout: 20_000, maxRedirects: 5 });
    const status = response.status();
    /** @type {Record<number, string>} What to do for common failing statuses. */
    const hints = {
      401: 'HTTP basic auth: add WP_HTTP_USER and WP_HTTP_PASS to .env',
      403: 'blocked by a firewall or security plugin: ask the user to allow this machine',
      404: 'login page not found: check WP_URL, or set WP_LOGIN_PATH for a custom login URL',
    };
    const hint =
      status === 200 ? '' : ` (${hints[status] ?? 'unexpected status: report it to the user'})`;
    report(status === 200, 'site', `${url} answered HTTP ${status}${hint}`);
    siteOk = status === 200;
  } catch (error) {
    const message = error.message.split('\n')[0];
    // A certificate problem means the site is reachable; say how to accept it.
    const certificate = /CERT|SSL|TLS|self[- ]signed/i.test(message);
    report(
      false,
      'site',
      certificate && !env.ignoreHTTPSErrors
        ? `certificate error (${message}). For a local dev site, add WP_IGNORE_HTTPS_ERRORS=1 to .env`
        : `unreachable (${message})`,
    );
  } finally {
    await api.dispose();
  }
} else {
  report(false, 'site', 'not checked (needs WP_URL and playwright)');
}

// ---------------------------------------------------------------------------------------------
// Login: log in once with the same code the recorder uses, so a wrong password, two-factor
// authentication or the admin email screen shows up now instead of at the first recording.
// Skipped with --site. The error message comes from WordPress and never contains the password.
// ---------------------------------------------------------------------------------------------

if (!siteOnly) {
  if (siteOk && missing.length === 0) {
    const { readEnv, login } = await import('./wp.js');
    const browser = await playwright.chromium.launch();
    try {
      await login(browser, readEnv(), { width: 1280, height: 720 });
      report(true, 'login', 'logged in, admin page reached');
    } catch (error) {
      report(false, 'login', error.message.split('\n')[0]);
    } finally {
      await browser.close();
    }
  } else {
    report(false, 'login', 'not checked (needs the .env keys and a reachable site)');
  }
}

// ---------------------------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------------------------

const failed = results.filter((ok) => !ok).length;
const done = siteOnly ? 'Site reachable. Add WP_USER and WP_PASS next.' : 'Ready to record.';
console.log(failed ? `\n${failed} check(s) failed.` : `\nAll checks passed. ${done}`);
process.exit(failed ? 1 : 0);
