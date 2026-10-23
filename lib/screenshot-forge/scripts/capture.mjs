#!/usr/bin/env node
// Capture desktop + mobile screenshots of live URLs using the Playwright CLI.
// Cross-platform (Linux, macOS, Windows); needs only Node.js 20+ and network access.

import { spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { parseArgs } from "node:util";

const USAGE = `Usage: capture.mjs <url> [options]
       capture.mjs --list FILE [options]
  -l, --list FILE       read URLs from a text file, one per line
                        (blank lines and lines starting with # are skipped)
  -c, --concurrency N   URLs captured at once with --list (default: 2)
  -o, --out DIR         output directory (default: ./screenshots)
  -n, --name NAME       filename prefix (default: derived from URL; single URL only)
  -f, --full-page       capture the entire scrollable page (files end in -full.png)
  -d, --desktop WxH     desktop viewport (default: 1440x900)
  -m, --device NAME     Playwright device for mobile (default: "Pixel 7";
                        iPhone/iPad and some legacy devices render in WebKit)
      --tablet          also capture a tablet view (<name>-tablet.png)
      --tablet-device NAME  Playwright device for the tablet (default: "Galaxy Tab S4")
  -w, --wait MS         extra wait before capture, for lazy content (default: 2000)
  -s, --selector SEL    wait for this CSS selector before capture
      --dark            emulate prefers-color-scheme: dark
      --only LIST       capture only these views, comma-separated from desktop,
                        tablet, mobile (default: desktop,mobile)
      --frame           also write transparent PNGs in device frames: <name>-desktop-framed.png
                        (laptop), -tablet-framed.png (tablet), -mobile-framed.png (phone)
      --combo           also write <name>-combo.png, all captured devices together
                        (implies --frame; needs desktop plus tablet or mobile)
      --combo-layout L  "overlap" (default): laptop behind, handhelds in front;
                        "row": side by side, nothing hidden
      --frames-only     skip capturing; frame the PNGs an earlier run wrote. Repeat that
                        run's URL or --list, --out, --name, -f, -d, -m, --tablet,
                        --tablet-device, --only

Prints the absolute path of each PNG written, one per line.
Exit codes: 0 all ok; 1 a capture or frame failed, a list entry was invalid, or Playwright
could not run or install; 2 nothing ran (bad arguments, invalid URL, unknown device,
unreadable list or output directory).`;

// Pinned so CLI flags and browser revisions stay stable across runs.
const PW = "playwright@1.64.1";

// Snippets run as `node -e` inside `npx -p playwright@...`. They find the pinned
// playwright-core via the node_modules/.bin that npx puts on PATH. Inputs travel in
// env vars or files, so npx's shell on Windows never sees a device name or path.
const FIND_PW = `
const p = require("path"), fs = require("fs");
const bin = process.env.PATH.split(p.delimiter)
  .find((d) => fs.existsSync(p.join(d, "..", "playwright-core", "package.json")));
const pw = require(p.join(bin, "..", "playwright-core"));
`;

// Takes a JSON list of device names; prints a JSON map of name to browser and viewport,
// with null for an unknown name.
const DEVICE_LOOKUP = `${FIND_PW}
const result = {};
for (const name of JSON.parse(process.env.SF_DEVICES)) {
  const d = pw.devices[name];
  result[name] = d ? { browser: d.defaultBrowserType, width: d.viewport.width, height: d.viewport.height } : null;
}
console.log(JSON.stringify(result));
`;

// Renders every frame in one Chromium session and screenshots #out with a transparent
// background, which the screenshot CLI cannot do. Prints each PNG path written.
const FRAME_RENDER = `${FIND_PW}
const job = JSON.parse(fs.readFileSync(process.env.SF_JOB, "utf8"));
(async () => {
  const browser = await pw.chromium.launch(job.channel ? { channel: job.channel } : {});
  const page = await browser.newPage({ deviceScaleFactor: 2, viewport: { width: 1200, height: 1000 } });
  await page.goto(job.template);
  let failed = 0;
  // Images go in as data: URLs so the page can read their pixels to tint status bars.
  const cache = new Map();
  const dataUrl = (file) => {
    if (!cache.has(file)) cache.set(file, "data:image/png;base64," + fs.readFileSync(file).toString("base64"));
    return cache.get(file);
  };
  for (const f of job.frames) {
    try {
      const data = { ...f.data };
      for (const key of ["desktop", "tablet", "mobile"]) if (data[key]) data[key] = dataUrl(data[key]);
      await page.evaluate(([kind, d]) => window.render(kind, d), [f.kind, data]);
      await page.locator("#out").screenshot({ path: f.out, omitBackground: true });
      console.log(f.out);
    } catch (err) {
      failed++;
      console.error("[frame] " + f.out + " failed: " + err.message.split("\\n")[0]);
    }
  }
  await browser.close();
  process.exitCode = failed ? 1 : 0;
})().catch((err) => { console.error("[frame] " + err.message); process.exitCode = 1; });
`;

const FRAME_TEMPLATE = fileURLToPath(new URL("../assets/frame.html", import.meta.url));

// Filenames above ~255 bytes fail on most filesystems; leave room for the suffix.
const MAX_SLUG = 150;

function die(msg) {
  console.error(`${msg}\n\n${USAGE}`);
  process.exit(2);
}

let parsed;
try {
  parsed = parseArgs({
    allowPositionals: true,
    options: {
      list: { type: "string", short: "l" },
      concurrency: { type: "string", short: "c", default: "2" },
      out: { type: "string", short: "o", default: "./screenshots" },
      name: { type: "string", short: "n" },
      "full-page": { type: "boolean", short: "f", default: false },
      desktop: { type: "string", short: "d", default: "1440x900" },
      device: { type: "string", short: "m", default: "Pixel 7" },
      wait: { type: "string", short: "w", default: "2000" },
      selector: { type: "string", short: "s" },
      dark: { type: "boolean", default: false },
      tablet: { type: "boolean", default: false },
      "tablet-device": { type: "string", default: "Galaxy Tab S4" },
      only: { type: "string" },
      frame: { type: "boolean", default: false },
      combo: { type: "boolean", default: false },
      "combo-layout": { type: "string", default: "overlap" },
      "frames-only": { type: "boolean", default: false },
      help: { type: "boolean", short: "h", default: false },
    },
  });
} catch (err) {
  die(err.message);
}

const opts = parsed.values;
if (opts.help) {
  console.log(USAGE);
  process.exit(0);
}
if (opts.list && parsed.positionals.length > 0) die("Pass either a URL or --list, not both");
if (!opts.list && parsed.positionals.length === 0) die("Missing URL");
if (parsed.positionals.length > 1) die("Only one URL allowed; use --list for several");
if (opts.list && opts.name) die("--name works with a single URL only");
if (!/^[1-9]\d*x[1-9]\d*$/.test(opts.desktop)) die(`Bad --desktop '${opts.desktop}', expected WxH`);
if (!/^\d+$/.test(opts.wait)) die(`Bad --wait '${opts.wait}', expected milliseconds`);
if (!/^[1-9]\d*$/.test(opts.concurrency)) die(`Bad --concurrency '${opts.concurrency}', expected a positive number`);
// The views to capture, always in desktop, tablet, mobile order.
const VIEWS = ["desktop", "tablet", "mobile"];
const wanted = new Set(opts.only ? opts.only.split(",").map((v) => v.trim()) : ["desktop", "mobile"]);
for (const v of wanted) if (!VIEWS.includes(v)) die(`Bad --only '${opts.only}', expected a comma list of ${VIEWS.join(", ")}`);
if (opts.tablet) wanted.add("tablet");
const labels = VIEWS.filter((v) => wanted.has(v));
if (!["overlap", "row"].includes(opts["combo-layout"])) die(`Bad --combo-layout '${opts["combo-layout"]}', expected overlap or row`);
if (opts["frames-only"] || opts.combo) opts.frame = true;
if (opts.combo && !(wanted.has("desktop") && (wanted.has("tablet") || wanted.has("mobile")))) {
  die("--combo needs the desktop view plus tablet or mobile");
}
if (opts.frame && !existsSync(FRAME_TEMPLATE)) die(`Frame template missing: ${FRAME_TEMPLATE}`);

// Returns an http(s) URL, or null when the input is not one (other schemes, spaces, junk).
function normalizeUrl(raw) {
  raw = raw.trim();
  let url;
  if (/^https?:\/\//i.test(raw)) url = raw;
  else if (/^[a-z][a-z0-9+.-]*:\/\//i.test(raw)) return null;
  else {
    // Local and LAN dev servers rarely serve TLS.
    const local =
      /^(localhost|127\.\d+\.\d+\.\d+|0\.0\.0\.0|\[::1\]|10\.\d+\.\d+\.\d+|192\.168\.\d+\.\d+|172\.(1[6-9]|2\d|3[01])\.\d+\.\d+|[^/:?#]+\.local|host\.docker\.internal)(:\d+)?([/?#]|$)/i.test(raw);
    url = `${local ? "http" : "https"}://${raw}`;
  }
  try {
    return new URL(url).host ? url : null;
  } catch {
    return null;
  }
}

// Slug keeps the query string so ?id=1 and ?id=2 do not overwrite each other.
function slugFor(url) {
  let slug = url
    .replace(/^https?:\/\//i, "")
    .replace(/#.*$/, "")
    .replace(/\/+$/, "")
    .replace(/[^A-Za-z0-9.-]+/g, "_")
    .replace(/_+$/, "");
  if (slug.length > MAX_SLUG) {
    const hash = createHash("sha1").update(url).digest("hex").slice(0, 8);
    slug = `${slug.slice(0, MAX_SLUG - 9)}_${hash}`;
  }
  return slug || "capture";
}

let rawUrls;
if (opts.list) {
  let text;
  try {
    text = readFileSync(opts.list, "utf8");
  } catch (err) {
    die(`Cannot read --list '${opts.list}': ${err.code || err.message}`);
  }
  rawUrls = text
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith("#"));
  if (rawUrls.length === 0) die(`No URLs found in '${opts.list}'`);
} else {
  rawUrls = parsed.positionals;
}

// Drop duplicates; two URLs that map to the same filename would overwrite each other.
// Compare case-insensitively: macOS and Windows filesystems treat A.png and a.png as one file.
const targets = [];
const seen = new Map();
let invalid = 0;
for (const raw of rawUrls) {
  const url = normalizeUrl(raw);
  if (!url) {
    if (!opts.list) die(`Not a valid http(s) URL: '${raw}'`);
    console.error(`Skipping ${raw}: not a valid http(s) URL`);
    invalid++;
    continue;
  }
  // Separators would write outside --out, Windows rejects :*?"<>| and control characters,
  // and leading dots hide the file.
  let name = opts.name ? opts.name.replace(/[\x00-\x1f/\\:*?"<>|]+/g, "_").replace(/^\.+/, "_") : slugFor(url);
  // Windows refuses these as file names, with or without an extension.
  if (/^(con|prn|aux|nul|com\d|lpt\d)$/i.test(name)) name = `_${name}`;
  const key = name.toLowerCase();
  if (seen.has(key)) {
    if (seen.get(key) !== url) console.error(`Skipping ${url}: same filename as ${seen.get(key)}`);
    continue;
  }
  seen.set(key, url);
  targets.push({ url, name });
}

if (targets.length === 0) die(`No valid URLs in '${opts.list}'`);

// Full-page files get their own suffix so a viewport capture never overwrites them.
const suffix = opts["full-page"] ? "-full" : "";
const outDir = path.resolve(opts.out);

// Use system Chrome when it is where Playwright's "chrome" channel looks; else bundled Chromium.
function hasSystemChrome() {
  const candidates = {
    linux: ["/opt/google/chrome/chrome"],
    darwin: ["/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"],
    win32: [process.env.LOCALAPPDATA, process.env.PROGRAMFILES, process.env["PROGRAMFILES(X86)"]]
      .filter(Boolean)
      .map((base) => path.join(base, "Google", "Chrome", "Application", "chrome.exe")),
  }[process.platform] || [];
  return candidates.some((p) => existsSync(p));
}

// Run npx through the current Node binary, never through a shell: on Windows,
// npx.cmd needs cmd.exe, which cannot safely quote URLs or selectors.
function npxCommand() {
  const bin = path.dirname(process.execPath);
  const cli = [
    path.join(bin, "node_modules", "npm", "bin", "npx-cli.js"), // Windows layout
    path.join(bin, "..", "lib", "node_modules", "npm", "bin", "npx-cli.js"), // Unix layout
  ].find((p) => existsSync(p));
  if (cli) return { cmd: process.execPath, pre: [cli] };
  if (process.platform === "win32") {
    console.error(`Cannot find npm's npx-cli.js next to ${process.execPath}. Reinstall Node.js with npm included.`);
    process.exit(1);
  }
  return { cmd: "npx", pre: [] };
}
const NPX = npxCommand();

function runNpx(args, { inheritOutput = false, env } = {}) {
  return new Promise((resolve) => {
    const child = spawn(NPX.cmd, [...NPX.pre, ...args], {
      stdio: inheritOutput ? ["ignore", process.stderr, process.stderr] : ["ignore", "pipe", "pipe"],
      env: env ? { ...process.env, ...env } : process.env,
    });
    let out = "";
    let log = "";
    child.stdout?.on("data", (d) => ((out += d), (log += d)));
    child.stderr?.on("data", (d) => (log += d));
    child.on("error", (err) => resolve({ code: 1, out, log: String(err) }));
    child.on("close", (code) => resolve({ code, out, log }));
  });
}
const npx = (args, options) => runNpx(["-y", PW, ...args], options);

// First npx call, run alone: it fetches the Playwright package into the npx cache, so the
// parallel captures never race on it. With a mobile view it also resolves the device.
const runSnippet = (code, env) =>
  runNpx(["-y", "-p", PW, "--", "node", "-e", "eval(process.env.SF_CODE)"], { env: { SF_CODE: code, ...env } });

// Device per handheld view, resolved to its browser and viewport.
const deviceFor = { tablet: opts["tablet-device"], mobile: opts.device };
const handhelds = labels.filter((v) => v !== "desktop");
const devices = {};
if (handhelds.length > 0) {
  const names = handhelds.map((v) => deviceFor[v]);
  const { code, out, log } = await runSnippet(DEVICE_LOOKUP, { SF_DEVICES: JSON.stringify(names) });
  if (code !== 0) {
    console.error(`Cannot run ${PW}:\n${log}`);
    process.exit(1);
  }
  let found;
  try {
    found = JSON.parse(out.trim().split(/\r?\n/).pop());
  } catch {
    console.error(`Cannot run ${PW}: unexpected device lookup output:\n${log}`);
    process.exit(1);
  }
  for (const v of handhelds) {
    const info = found[deviceFor[v]];
    if (!info) die(`Unknown device '${deviceFor[v]}'. Names are case-sensitive, e.g. "iPhone 15", "Pixel 7", "Galaxy Tab S4".`);
    devices[v] = info;
  }
} else {
  const { code, log } = await npx(["--version"]);
  if (code !== 0) {
    console.error(`Cannot run ${PW}:\n${log}`);
    process.exit(1);
  }
}

// Devices that force WebKit or Firefox reject --channel, so only Chromium may use system Chrome.
const chromium = ["-b", "chromium", ...(hasSystemChrome() ? ["--channel", "chrome"] : [])];
const engineArgs = (browser) => (browser === "chromium" ? chromium : ["-b", browser]);

const views = labels.map((label) =>
  label === "desktop"
    ? { label, args: [...chromium, "--viewport-size", opts.desktop.replace("x", ",")] }
    : { label, args: [...engineArgs(devices[label].browser), "--device", deviceFor[label]] },
);

// Install any missing bundled browsers once, serially, so the captures never race on a download.
const engines = new Set();
for (const view of opts["frames-only"] ? [] : views) {
  if (view.args.includes("--channel")) continue;
  engines.add(view.args[view.args.indexOf("-b") + 1]);
}
// Frames always render in Chromium.
if (opts.frame && !chromium.includes("--channel")) engines.add("chromium");
if (engines.size > 0) {
  const { code } = await npx(["install", ...engines], { inheritOutput: true });
  if (code !== 0) {
    console.error(`Browser install failed: ${[...engines].join(" ")}`);
    process.exit(1);
  }
}

// Created only now, so a run that exits 2 on a bad device leaves no empty folder behind.
try {
  mkdirSync(outDir, { recursive: true });
} catch (err) {
  die(`Cannot create output directory '${outDir}': ${err.code || err.message}`);
}

const common = ["--wait-for-timeout", opts.wait, "--timeout", "60000"];
if (opts["full-page"]) common.push("--full-page");
if (opts.selector) common.push("--wait-for-selector", opts.selector);
if (opts.dark) common.push("--color-scheme", "dark");

async function shoot({ url, name }, view) {
  const file = path.join(outDir, `${name}-${view.label}${suffix}.png`);
  const { code, log } = await npx(["screenshot", ...common, ...view.args, url, file]);
  if (code === 0) {
    console.log(file);
    return file;
  }
  const tail = log.split(/\r?\n/).filter((l) => l.trim()).slice(-5).join("\n");
  console.error(`[${view.label}] ${url} capture failed:\n${tail}`);
  return null;
}

// Each worker takes the next URL and captures its viewports in parallel.
let next = 0;
let ok = invalid === 0;
async function worker() {
  while (next < targets.length) {
    const target = targets[next++];
    const files = await Promise.all(views.map((view) => shoot(target, view)));
    if (files.includes(null)) ok = false;
    target.files = Object.fromEntries(views.map((view, i) => [view.label, files[i]]));
  }
}
if (opts["frames-only"]) {
  // Reuse the files an earlier run wrote, at the same paths shoot() would have used.
  for (const target of targets) {
    target.files = {};
    for (const view of views) {
      const file = path.join(outDir, `${target.name}-${view.label}${suffix}.png`);
      if (existsSync(file)) target.files[view.label] = file;
      else {
        ok = false;
        console.error(`[frame] no ${view.label} capture for ${target.url}: ${file} not found`);
      }
    }
  }
} else {
  const workers = Math.min(Number(opts.concurrency), targets.length);
  await Promise.all(Array.from({ length: workers }, worker));
}

// Device frames: rendered after all captures, from whichever captures succeeded.
if (opts.frame) {
  const desktopSize = opts.desktop.split("x").map(Number);
  const frames = [];
  for (const { url, name, files = {} } of targets) {
    // Plain paths; the render snippet turns them into data: URLs.
    const fileFor = (label) => files[label];
    const size = (label) => devices[label] && [devices[label].width, devices[label].height];
    const data = {
      host: new URL(url).host,
      layout: opts["combo-layout"],
      desktop: fileFor("desktop"),
      tablet: fileFor("tablet"),
      mobile: fileFor("mobile"),
      desktopSize,
      tabletSize: size("tablet"),
      mobileSize: size("mobile"),
    };
    const out = (kind) => path.join(outDir, `${name}-${kind}.png`);
    if (data.desktop) frames.push({ kind: "laptop", out: out("desktop-framed"), data });
    if (data.tablet) frames.push({ kind: "tablet", out: out("tablet-framed"), data });
    if (data.mobile) frames.push({ kind: "phone", out: out("mobile-framed"), data });
    if (opts.combo && data.desktop && (data.tablet || data.mobile)) frames.push({ kind: "combo", out: out("combo"), data });
  }
  if (frames.length > 0) {
    // The job goes in a file: a long list would overflow Windows' 32 KB environment limit.
    // A private temp folder, so no other user can predict or pre-create the path.
    const jobDir = mkdtempSync(path.join(os.tmpdir(), "screenshot-forge-"));
    const jobFile = path.join(jobDir, "job.json");
    writeFileSync(jobFile, JSON.stringify({
      template: pathToFileURL(FRAME_TEMPLATE).href,
      channel: chromium.includes("--channel") ? "chrome" : undefined,
      frames,
    }));
    const { code, out, log } = await runSnippet(FRAME_RENDER, { SF_JOB: jobFile });
    rmSync(jobDir, { recursive: true, force: true });
    process.stdout.write(out);
    if (code !== 0) {
      ok = false;
      const errors = log.split(/\r?\n/).filter((l) => l.startsWith("[frame]"));
      console.error(errors.length ? errors.join("\n") : `[frame] rendering failed:\n${log.trim()}`);
    }
  }
}

// exitCode, not exit(): exit() can cut off stdout still flushing to a pipe.
process.exitCode = ok ? 0 : 1;
