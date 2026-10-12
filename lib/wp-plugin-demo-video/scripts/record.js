/**
 * @file Records a demo video of a WordPress plugin from a scene file.
 *
 * Logs in outside the recording, runs each scene in one browser tab with a visible cursor,
 * encodes the result to H.264 MP4 and, optionally, cuts one clip per scene. Every step is
 * logged with its time in the final video.
 *
 * Usage: node --env-file=.env record.js <scenes file> [flags]
 *   --split    also cut one MP4 per scene into <out>/scenes/NN-<scene>.mp4
 *   --verbose  forward browser console messages and page errors to the log, and print stack
 *              traces (the browser console can contain plugin config, including nonces)
 *   --fast     no video, no pauses, instant mouse moves: for checking selectors quickly
 *   --only     run only the named scenes, comma separated without spaces (needs --fast or --out)
 *   --out      output directory (default: output)
 *
 * Outputs: <out>/<name>.mp4, <out>/scenes.json, <out>/raw/*.webm, <out>/scenes/ (with
 * --split), and <out>/failure.png when a scene fails.
 */

import { chromium } from 'playwright';
import ffmpegPath from 'ffmpeg-static';
import { execFileSync } from 'node:child_process';
import { mkdirSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
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

// ---------------------------------------------------------------------------------------------
// Types: the scene file format. A scene file default-exports a SceneConfig.
// ---------------------------------------------------------------------------------------------

/**
 * A video size in pixels. Both numbers must be even (H.264 with yuv420p needs that).
 * @typedef {object} Size
 * @property {number} width
 * @property {number} height
 */

/**
 * The default export of a scene file.
 * @typedef {object} SceneConfig
 * @property {string} [name="demo"] - Video file name without extension: output/<name>.mp4.
 *   Lower-case letters, digits and hyphens only. Use "<plugin-slug>-demo".
 * @property {Size} [viewport={width:1920,height:1080}] - Browser size. A smaller viewport makes
 *   the admin text larger relative to the frame.
 * @property {Size} [outputSize] - Final video size; the recording is upscaled to it. Defaults to
 *   the viewport. Do not use deviceScaleFactor instead: Playwright pads the video.
 * @property {number} [timeout=20000] - Default timeout in ms for every Playwright action.
 * @property {number} [pace=1] - Pause multiplier: 1 is normal, 1.5 slower, 0.5 faster.
 * @property {Scene[]} scenes - The scenes, in recording order.
 */

/**
 * One scene: one idea shown in the video ("settings", "search", "import").
 * @typedef {object} Scene
 * @property {string} name - Lower-case letters, digits and hyphens. Used in the log and in clip
 *   file names (NN-<name>.mp4).
 * @property {(context: SceneContext) => Promise<void>} run - Performs the scene. Scenes share
 *   one browser tab, so a scene starts where the previous one ended.
 */

/**
 * What every scene's run() function receives.
 * @typedef {object} SceneContext
 * @property {import('playwright').Page} page - The full Playwright page, for anything the
 *   helpers do not cover. Call log() before using it, so the log stays complete.
 * @property {Demo} demo - Viewer-friendly actions that move the cursor and log each step.
 * @property {(message: string) => void} log - Prints a line with the video time and scene name.
 * @property {string} base - Site URL without a trailing slash.
 * @property {(path: string) => string} url - Turns an admin path into a full URL.
 */

/**
 * Viewer-friendly actions passed to every scene as `demo`. All of them log what they do;
 * pauses scale with the scene file's `pace` and disappear with --fast.
 * @typedef {object} Demo
 * @property {(target: string, options?: { write?: boolean }) => Promise<void>} open - Opens an
 *   admin path or URL. Refuses URLs that match data-changing patterns unless write is true, and
 *   fails when WordPress refuses the page (HTTP 400 or above, or its error page).
 * @property {(locator: import('playwright').Locator) => Promise<void>} glide - Moves the cursor
 *   to the centre of an element, without logging.
 * @property {(locator: import('playwright').Locator, label?: string) => Promise<void>} click -
 *   Glides to an element and clicks it.
 * @property {(locator: import('playwright').Locator, text: string, options?: TypeOptions) => Promise<void>} type -
 *   Clicks a field and types like a person.
 * @property {(locator: import('playwright').Locator, value: string, label?: string) => Promise<void>} select -
 *   Chooses an option in a <select>.
 * @property {(locator: import('playwright').Locator, label?: string, ms?: number) => Promise<void>} hover -
 *   Points at an element and holds still.
 * @property {(dy: number, steps?: number) => Promise<void>} scroll - Smooth wheel scroll by dy
 *   pixels; negative scrolls up.
 * @property {(locator: import('playwright').Locator, what: string, options?: { timeout?: number, state?: 'attached' | 'detached' | 'visible' | 'hidden' }) => Promise<void>} waitFor -
 *   Logs what it waits for, then waits.
 * @property {(ms: number) => Promise<void>} pause - Holds still so viewers can read.
 */

/**
 * Options for demo.type().
 * @typedef {object} TypeOptions
 * @property {string} [label] - Text for the log; defaults to the locator's description.
 * @property {number} [delay=70] - Milliseconds between key presses.
 * @property {boolean} [replace=false] - Select the existing value first, so typing replaces it.
 * @property {boolean} [secret=false] - Log "type [secret, not logged]" instead of the text.
 */

/**
 * When one scene started and ended, in ms from the start of the final MP4.
 * @typedef {object} SceneMark
 * @property {string} name - Scene name.
 * @property {number} start
 * @property {number} end
 */

// ---------------------------------------------------------------------------------------------
// Arguments and scene file
// ---------------------------------------------------------------------------------------------

const { values: flags, positionals } = parseArgs({
  allowPositionals: true,
  options: {
    split: { type: 'boolean', default: false },
    verbose: { type: 'boolean', default: false },
    fast: { type: 'boolean', default: false },
    only: { type: 'string' },
    out: { type: 'string', default: 'output' },
  },
});

/**
 * Stops with a plain message. Used for setup mistakes, where a stack trace adds nothing.
 * @param {string} message - What went wrong and how to fix it.
 * @returns {never}
 */
function fail(message) {
  console.error(message);
  process.exit(1);
}

/** Allowed characters for scene and video names, which become file names. */
const SAFE_NAME = /^[a-z0-9][a-z0-9-]*$/;

const [sceneFile] = positionals;
if (!sceneFile)
  fail(
    'Usage: node --env-file=.env record.js <scenes file> [--split] [--verbose] [--fast] [--only a,b] [--out dir]',
  );

/** @type {import('./wp.js').WpEnv} */
let env;
try {
  env = readEnv();
} catch (error) {
  fail(error.message);
}

/** @type {SceneConfig} */
const config = (await import(pathToFileURL(path.resolve(sceneFile)).href)).default;
if (!config || !Array.isArray(config.scenes) || config.scenes.length === 0)
  fail(`${sceneFile} must export default { scenes: [{ name, run }, ...] }`);
for (const s of config.scenes) {
  if (typeof s.name !== 'string' || typeof s.run !== 'function')
    fail('Every scene needs a string "name" and an async "run" function');
  if (!SAFE_NAME.test(s.name))
    fail(`Scene name "${s.name}" must use only lower-case letters, digits and hyphens`);
}

/** Video file name. Outputs with this name are deleted at the start of a recording run. */
const NAME = config.name ?? 'demo';
if (!SAFE_NAME.test(NAME))
  fail(`Video name "${NAME}" must use only lower-case letters, digits and hyphens`);

/** @type {Size} Browser viewport; also the size of the raw recording. */
const SIZE = config.viewport ?? { width: 1920, height: 1080 };
/** @type {Size} Final video size. */
const OUTPUT_SIZE = config.outputSize ?? SIZE;
/** @type {[string, Size][]} */
const sizes = [
  ['viewport', SIZE],
  ['outputSize', OUTPUT_SIZE],
];
for (const [label, size] of sizes) {
  if (size.width % 2 || size.height % 2)
    fail(`${label} ${size.width}×${size.height} must have even width and height`);
}

/** Default timeout for every Playwright action, in ms. */
const TIMEOUT = config.timeout ?? 20_000;
/** Pause multiplier: 1 is normal speed, 0 removes all pauses. */
const PACE = flags.fast ? 0 : (config.pace ?? 1);
const OUT_DIR = path.resolve(flags.out);
const RAW_DIR = path.join(OUT_DIR, 'raw');
const SCENES_DIR = path.join(OUT_DIR, 'scenes');
/** Extra time kept before and after each scene clip, in ms. */
const CLIP_PAD = 300;

const only = flags.only?.split(',').map((s) => s.trim());
// A partial recording into the default folder would replace the full video.
if (only && !flags.fast && flags.out === 'output')
  fail('--only records a partial video. Add --fast, or --out <dir> to keep the full video.');
const unknown = only?.filter((n) => !config.scenes.some((s) => s.name === n)) ?? [];
if (unknown.length) fail(`Unknown scene(s): ${unknown.join(', ')}`);
/** @type {Scene[]} The scenes this run performs. */
const scenes = only ? config.scenes.filter((s) => only.includes(s.name)) : config.scenes;

// ---------------------------------------------------------------------------------------------
// Logging. Times are offsets into the final MP4. The raw recording starts with a blank page,
// so the MP4 is trimmed to start at the first page load (t0); recordStart is when the raw
// WebM starts.
// ---------------------------------------------------------------------------------------------

/** @type {number | null} When recording started (Date.now()), or null before that. */
let recordStart = null;
/** @type {number | null} When the first page finished loading, or null before that. */
let t0 = null;
/** Name of the current scene, shown in every log line. */
let scene = 'setup';
/** Width of the scene column, so log lines line up. */
const nameWidth = Math.max(8, ...config.scenes.map((s) => s.name.length));

/**
 * Formats a duration as mm:ss.s.
 * @param {number} ms - Milliseconds.
 * @returns {string} For example "01:04.2".
 */
function stamp(ms) {
  // Round to tenths first, so 59.96 s prints as 01:00.0, not 00:60.0.
  const tenths = Math.round(ms / 100);
  const mm = String(Math.floor(tenths / 600)).padStart(2, '0');
  const ss = ((tenths % 600) / 10).toFixed(1).padStart(4, '0');
  return `${mm}:${ss}`;
}

/**
 * Time since the start of the final MP4.
 * @returns {number} Milliseconds; 0 until the first page has loaded.
 */
function elapsed() {
  return t0 === null ? 0 : Math.max(0, Date.now() - t0);
}

/**
 * Prints one log line: "[mm:ss.s] <scene> <message>". Before recording starts the time shows
 * "--:--.-".
 * @param {string} message - What happened. Never pass secrets.
 */
function log(message) {
  const time = recordStart === null ? '--:--.-' : stamp(elapsed());
  console.log(`[${time}] ${scene.padEnd(nameWidth)} ${message}`);
}

/**
 * Waits for a number of milliseconds.
 * @param {number} ms - How long to wait, in milliseconds.
 * @returns {Promise<void>} Resolves when the time has passed.
 */
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// ---------------------------------------------------------------------------------------------
// Cursor overlay
// ---------------------------------------------------------------------------------------------

/**
 * Draws a visible mouse pointer and a ripple on every click, because headless video shows no
 * pointer. Runs in every page through context.addInitScript, so it must be self-contained.
 * The pointer position is kept in sessionStorage, so it does not jump after a page load.
 */
function installDemoCursor() {
  const CURSOR_CSS = `
    #__demo_cursor {
      position: fixed; top: 0; left: 0; width: 22px; height: 22px;
      z-index: 2147483647; pointer-events: none; transform: translate(-100px, -100px);
    }
    #__demo_cursor svg { filter: drop-shadow(0 1px 2px rgba(0, 0, 0, 0.45)); }
    .__demo_ripple {
      position: fixed; width: 34px; height: 34px; margin: -17px 0 0 -17px;
      border-radius: 50%; border: 3px solid rgba(34, 113, 177, 0.9);
      pointer-events: none; z-index: 2147483646;
      animation: __demo_ripple 0.5s ease-out forwards;
    }
    @keyframes __demo_ripple {
      from { transform: scale(0.3); opacity: 1; }
      to { transform: scale(1.4); opacity: 0; }
    }
  `;
  const CURSOR_SVG =
    '<svg width="22" height="22" viewBox="0 0 24 24">' +
    '<path d="M4 2l16 10-7 1.5L9.5 21z" fill="#fff" stroke="#111" stroke-width="1.5" stroke-linejoin="round"/>' +
    '</svg>';

  /**
   * Adds the cursor overlay to the current document. Runs in the browser before page scripts.
   * @returns {void}
   */
  const install = () => {
    // Init scripts can run more than once per document; add the overlay only once.
    if (document.getElementById('__demo_cursor')) return;

    const style = document.createElement('style');
    style.textContent = CURSOR_CSS;
    const cursor = document.createElement('div');
    cursor.id = '__demo_cursor';
    cursor.innerHTML = CURSOR_SVG;
    document.documentElement.append(style, cursor);

    // Put the pointer back where it was before the page load.
    const saved = sessionStorage.getItem('__demo_pos');
    if (saved) cursor.style.transform = `translate(${saved})`;

    document.addEventListener(
      'mousemove',
      (event) => {
        const pos = `${event.clientX}px, ${event.clientY}px`;
        cursor.style.transform = `translate(${pos})`;
        try {
          sessionStorage.setItem('__demo_pos', pos);
        } catch {
          // Storage can be blocked; the pointer then starts off-screen after a load.
        }
      },
      true,
    );

    document.addEventListener(
      'mousedown',
      (event) => {
        const ripple = document.createElement('div');
        ripple.className = '__demo_ripple';
        ripple.style.left = `${event.clientX}px`;
        ripple.style.top = `${event.clientY}px`;
        document.documentElement.append(ripple);
        setTimeout(() => ripple.remove(), 600);
      },
      true,
    );
  };

  // The init script runs before the page's own HTML exists; wait for the body if needed.
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', install);
  } else {
    install();
  }
}

// ---------------------------------------------------------------------------------------------
// Scene helpers
// ---------------------------------------------------------------------------------------------

/**
 * Builds the `demo` helpers for one page.
 * @param {import('playwright').Page} page - The recorded page.
 * @returns {Demo} The helpers.
 */
function createDemo(page) {
  /**
   * Pauses, scaled by the scene file's pace. With --fast, PACE is 0, so no time passes.
   * @param {number} ms - Pause at normal pace, in milliseconds.
   * @returns {Promise<void>} Resolves when the pause is over.
   */
  const pause = (ms) => sleep(ms * PACE);
  /**
   * Mouse movement steps; one step (an instant move) in fast mode.
   * @param {number} n - Steps for a smooth move.
   * @returns {number} The steps to use.
   */
  const steps = (n) => (flags.fast ? 1 : n);

  /** @type {Demo['open']} */
  async function open(target, { write = false } = {}) {
    if (isUnsafeUrl(target) && !write)
      throw new Error(
        `Refusing to open ${target}: it matches a data-changing pattern. ` +
          'Pass { write: true } only for an approved writing scene.',
      );
    log(`open ${target}`);
    const response = await page.goto(adminUrl(env.base, target));
    // Fail here with the real cause, not at the next locator with a timeout.
    const refused = await refusedPageError(page, response, target);
    if (refused) throw new Error(refused);
  }

  /** @type {Demo['glide']} Smooth glide to the element's centre, so viewers can follow it. */
  async function glide(locator) {
    await locator.scrollIntoViewIfNeeded();
    const box = await locator.boundingBox();
    if (!box) throw new Error(`No bounding box for ${locator}`);
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2, { steps: steps(25) });
    await pause(250);
  }

  /** @type {Demo['click']} */
  async function click(locator, label = String(locator)) {
    log(`click ${label}`);
    await glide(locator);
    await locator.click();
    await pause(400);
  }

  /** @type {Demo['type']} */
  async function type(
    locator,
    text,
    { label = String(locator), delay = 70, replace = false, secret = false } = {},
  ) {
    await click(locator, label);
    if (replace) {
      await locator.press('ControlOrMeta+a');
      await pause(300);
    }
    log(secret ? 'type [secret, not logged]' : `type "${text.replace(/\n/g, '\\n')}"`);
    await locator.pressSequentially(text, { delay: flags.fast ? 0 : delay });
    await pause(400);
  }

  /** @type {Demo['select']} */
  async function select(locator, value, label = String(locator)) {
    await glide(locator);
    log(`select "${value}" in ${label}`);
    await locator.selectOption(value);
    await pause(600);
  }

  /** @type {Demo['hover']} */
  async function hover(locator, label = String(locator), ms = 1200) {
    log(`point at ${label}`);
    await glide(locator);
    await pause(ms);
  }

  /** @type {Demo['scroll']} */
  async function scroll(dy, n = 30) {
    log(`scroll ${dy > 0 ? 'down' : 'up'} ${Math.abs(dy)}px`);
    const count = steps(n);
    for (let i = 0; i < count; i++) {
      await page.mouse.wheel(0, dy / count);
      await pause(25);
    }
    await pause(600);
  }

  /** @type {Demo['waitFor']} Logs first, so a stalled run shows what it is waiting for. */
  async function waitFor(locator, what, { timeout = TIMEOUT, state = 'visible' } = {}) {
    log(`waiting for ${what} (up to ${Math.round(timeout / 1000)}s)`);
    await locator.waitFor({ timeout, state });
  }

  return { open, glide, click, type, select, hover, scroll, waitFor, pause };
}

// ---------------------------------------------------------------------------------------------
// Encoding
// ---------------------------------------------------------------------------------------------

/**
 * Encodes the raw WebM recording (Playwright records WebM only) to an H.264 MP4 that plays
 * everywhere, upscaling to OUTPUT_SIZE when it differs from the viewport. ffmpeg prints only
 * errors.
 * @param {string} input - Raw WebM path.
 * @param {string} output - MP4 path.
 * @param {string[]} [trimArgs] - Input options such as ['-ss', '1.200', '-to', '9.000'].
 */
function encode(input, output, trimArgs = []) {
  const upscale = OUTPUT_SIZE.width !== SIZE.width || OUTPUT_SIZE.height !== SIZE.height;
  // Each flag sits with its value; .flat() turns the pairs into one argument list.
  const ffmpegArgs = [
    ['-y', '-hide_banner', '-nostats'],
    ['-loglevel', 'error'],
    // Before -i, -ss and -to seek in the input: fast, and frame-accurate when re-encoding.
    trimArgs,
    ['-i', input],
    upscale ? ['-vf', `scale=${OUTPUT_SIZE.width}:${OUTPUT_SIZE.height}:flags=lanczos`] : [],
    ['-c:v', 'libx264'],
    ['-preset', 'slow'],
    ['-crf', '18'],
    ['-pix_fmt', 'yuv420p'],
    // Moves the index to the start of the file, so players can start before the download ends.
    ['-movflags', '+faststart'],
    [output],
  ].flat();
  execFileSync(ffmpegPath, ffmpegArgs, { stdio: 'inherit' });
}

/**
 * Cuts one clip per scene from the raw recording, so each clip is compressed only once.
 * Clip numbers follow the scene's position in the scene file, also with --only.
 * @param {string} webm - Raw WebM path.
 * @param {SceneMark[]} marks - Scene times, in ms from the start of the MP4.
 * @param {number} lead - Blank time at the start of the raw recording, in ms.
 */
function splitScenes(webm, marks, lead) {
  mkdirSync(SCENES_DIR, { recursive: true });
  for (const { name, start, end } of marks) {
    const number = config.scenes.findIndex((s) => s.name === name) + 1;
    const from = Math.max(0, start - CLIP_PAD);
    const to = end + CLIP_PAD;
    const clip = path.join(SCENES_DIR, `${String(number).padStart(2, '0')}-${name}.mp4`);
    log(`cut ${name} ${stamp(from)}–${stamp(to)}`);
    /**
     * Converts a scene time to a position in the raw recording. Scene times count from the
     * start of the MP4; the raw file starts `lead` ms earlier.
     * @param {number} ms - Time from the start of the MP4, in milliseconds.
     * @returns {string} Seconds into the raw file, with millisecond precision, for ffmpeg.
     */
    const seconds = (ms) => ((lead + ms) / 1000).toFixed(3);
    encode(webm, clip, ['-ss', seconds(from), '-to', seconds(to)]);
    log(`saved ${path.relative(process.cwd(), clip)}`);
  }
}

// ---------------------------------------------------------------------------------------------
// Run
// ---------------------------------------------------------------------------------------------

/**
 * Logs in, runs the scenes, and writes the outputs.
 * @returns {Promise<void>}
 */
async function main() {
  mkdirSync(OUT_DIR, { recursive: true });
  // A failure screenshot from an earlier run must not be mistaken for this run's.
  rmSync(path.join(OUT_DIR, 'failure.png'), { force: true });
  if (!flags.fast) {
    // Outputs from an earlier run must not be mistaken for this run's if this one fails.
    for (const stale of [RAW_DIR, SCENES_DIR, 'scenes.json', `${NAME}.mp4`]) {
      rmSync(path.resolve(OUT_DIR, stale), { recursive: true, force: true });
    }
    // Contact sheets of the old video too, named as references/review.md section 4 names them.
    for (const file of readdirSync(OUT_DIR)) {
      if (/^(contact-sheet|sheet-\d+)\.png$/.test(file)) rmSync(path.join(OUT_DIR, file));
    }
    mkdirSync(RAW_DIR, { recursive: true });
  } else if (flags.split) {
    log('--split is ignored with --fast: no video is recorded');
  }

  const browser = await chromium.launch();
  // Logging in happens in its own context, so the login screen is never recorded.
  const storageState = await login(browser, env, SIZE);
  log(`logged in as ${env.user}`);

  const context = await browser.newContext({
    viewport: SIZE,
    storageState,
    ...contextOptions(env),
    ...(flags.fast ? {} : { recordVideo: { dir: RAW_DIR, size: SIZE } }),
  });
  await context.addInitScript(installDemoCursor);
  const page = await context.newPage();
  // The raw recording starts with the page; the MP4 starts at the first real page load.
  recordStart = Date.now();
  page.on('load', () => {
    if (t0 === null && /^https?:/.test(page.url())) t0 = Date.now();
  });
  page.setDefaultTimeout(TIMEOUT);
  if (flags.verbose) {
    page.on('console', (msg) => log(`browser ${msg.type()}: ${msg.text()}`));
    page.on('pageerror', (error) => log(`browser error: ${error.message}`));
  }
  log(flags.fast ? 'fast run started (no video)' : 'recording started');

  const demo = createDemo(page);
  /** @type {SceneMark[]} */
  const marks = [];
  try {
    for (const s of scenes) {
      scene = s.name;
      const start = elapsed();
      log('start');
      await s.run({
        page,
        demo,
        log,
        base: env.base,
        /**
         * Builds a full URL on the site, as `demo.open` does.
         * @param {string} p - Admin path, site path or full URL.
         * @returns {string} Full URL.
         */
        url: (p) => adminUrl(env.base, p),
      });
      const end = elapsed();
      marks.push({ name: s.name, start, end });
      log(`done (${((end - start) / 1000).toFixed(1)}s)`);
    }
  } catch (error) {
    log(`FAILED: ${error.message.split('\n')[0]}`);
    // Blank secret-looking fields first: this screenshot is read to diagnose the failure.
    await page.evaluate(redactSecrets).catch(() => {});
    await page.screenshot({ path: path.join(OUT_DIR, 'failure.png') }).catch(() => {});
    log(`screenshot saved to ${path.relative(process.cwd(), path.join(OUT_DIR, 'failure.png'))}`);
    throw error;
  } finally {
    // Closing the context finishes writing the raw video file.
    await context.close();
    await browser.close();
  }

  scene = 'done';
  if (flags.fast) {
    log('fast run finished, all scenes passed');
    return;
  }
  scene = 'encode';

  const webm = await page.video().path();
  writeFileSync(path.join(OUT_DIR, 'scenes.json'), JSON.stringify(marks, null, 2) + '\n');

  // Blank time before the first page load, in ms of the raw recording.
  const lead = t0 === null ? 0 : t0 - recordStart;
  const mp4 = path.join(OUT_DIR, `${NAME}.mp4`);
  log('encoding full video');
  encode(webm, mp4, ['-ss', (lead / 1000).toFixed(3)]);
  log(`saved ${path.relative(process.cwd(), mp4)}`);

  if (flags.split) splitScenes(webm, marks, lead);
}

main().catch((error) => {
  // The log already shows where a scene failed; the stack only helps with --verbose.
  console.error(flags.verbose ? error : error.message.split('\n')[0]);
  process.exit(1);
});
