#!/usr/bin/env node
// Static checks on a BLUEPRINT.md. No LLM calls, no network.
// Standalone version of eval/check-blueprint.mjs: takes paths, not app names.
//
// Usage: node check-blueprint.mjs <BLUEPRINT.md> [--repo <source repo dir>] [--json]
//   --repo adds route recall and .env.example key recall against the source.
//   Exit 1 if a hard check fails, 2 on bad usage.

import { readFileSync, existsSync, readdirSync, statSync, lstatSync } from 'node:fs';
import { join } from 'node:path';

const SECTIONS = [
  'Project Summary',
  'Tech Stack',
  'Architecture',
  'Auth & State',
  'Folder Structure',
  'Data Models / Schema',
  'API Endpoints',
  'Core Features',
  'UI Structure',
  'Environment Variables',
  'Config Files',
  'Testing & Tooling',
  'Open Questions',
  'Step-by-Step Rebuild Instructions',
];

const usage = (msg) => {
  if (msg) console.error(msg);
  console.error('Usage: node check-blueprint.mjs <BLUEPRINT.md> [--repo <dir>] [--json]');
  process.exit(2);
};
let json = false;
let repo;
let bpPath;
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--json') json = true;
  else if (a === '--repo') repo = argv[++i] ?? usage('--repo needs a directory');
  else if (a.startsWith('--repo=')) repo = a.slice('--repo='.length);
  else if (a.startsWith('-')) usage(`Unknown option: ${a}`);
  else if (bpPath) usage(`Unexpected argument: ${a}`);
  else bpPath = a;
}
const isFile = (p) => existsSync(p) && statSync(p).isFile();
const isDir = (p) => existsSync(p) && statSync(p).isDirectory();
if (!bpPath || !isFile(bpPath)) usage(bpPath ? `Not a file: ${bpPath}` : undefined);
if (repo !== undefined && !isDir(repo)) usage(`Not a directory: ${repo}`);
const md = readFileSync(bpPath, 'utf8');
const hard = {};
const soft = {};

function parseSections(text) {
  const heads = [...text.matchAll(/^## (\d+)\. (.+?)\s*$/gm)];
  return heads.map((m, i) => ({
    num: Number(m[1]),
    title: m[2],
    body: text.slice(m.index + m[0].length, heads[i + 1]?.index ?? text.length),
  }));
}
const section = (title) => parseSections(md).find((s) => s.title === title)?.body ?? '';
const normPath = (p) =>
  p.replace(/\{[A-Za-z0-9_]+\??(?::[^}]*)?\}/g, ':p').replace(/[:<][A-Za-z0-9_]+>?/g, ':p').replace(/\/+$/, '') || '/';
const ratio = (a, b) => (b === 0 ? null : Math.round((a / b) * 100) / 100);
// Join indented continuation lines onto the bullet they belong to.
const bullets = (text) =>
  text.split('\n').reduce((acc, line) => {
    if (/^\s+\S/.test(line) && acc.length && !/^\s*[-*]\s/.test(line)) acc[acc.length - 1] += ' ' + line.trim();
    else acc.push(line);
    return acc;
  }, []);

// Hard: all 14 headings, exact names, in order.
const found = parseSections(md).map((s) => `${s.num}. ${s.title}`);
const expected = SECTIONS.map((t, i) => `${i + 1}. ${t}`);
const missing = expected.filter((h) => !found.includes(h));
const inOrder =
  JSON.stringify(found.filter((h) => expected.includes(h))) === JSON.stringify(expected.filter((h) => found.includes(h)));
hard.headings = { pass: missing.length === 0 && inOrder, missing, extra: found.filter((h) => !expected.includes(h)), inOrder };

// Hard: metadata header.
const meta = md.match(/<!--\s*blueprint-format:\s*(\S+)\s*\|.*scope:\s*([^|]+?)\s*(?:\||-->)/);
hard.metadata = { pass: meta?.[1] === '2', format: meta?.[1] ?? null, scope: meta?.[2] ?? null };

// Hard: secret-looking values. Heuristic; matches are counted with line numbers, never printed.
// Values that reference a secret instead of holding one.
const NOT_A_VALUE = String.raw`(?!\[REDACTED\]|<|\$\{|\$[A-Z_]|process\.env|env\(|getenv|os\.environ|ENV\[|your|change|example|placeholder|xxx|\.\.\.)`;
const SECRET_PATTERNS = [
  /-----BEGIN [A-Z ]*PRIVATE KEY-----/,
  /\b(sk|pk|rk)_(live|test)_[A-Za-z0-9]{16,}/,
  /\bsk-(proj|ant)-[A-Za-z0-9_-]{20,}/,
  /\bgh[pousr]_[A-Za-z0-9]{30,}/,
  /\bAKIA[0-9A-Z]{16}\b/,
  /\bAIza[0-9A-Za-z_-]{35}\b/,
  /\bxox[abprs]-[A-Za-z0-9-]{10,}/,
  /\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/,
  /\bbase64:[A-Za-z0-9+/]{32,}={0,2}/,
  // user:password@host, except placeholders like user:password@ or postgres:postgres@
  /:\/\/[^\s/:@]+:(?!\[REDACTED\]|<|\$\{|(?:password|pass|secret|postgres|root|changeme|example)@)[^\s/@]{6,}@/i,
  // NAME=value / NAME: value. Upper-case names only, so prose like
  // "Token: AES-256" or "Password::fromRequest" does not match.
  new RegExp(
    String.raw`\b([A-Z0-9_]*_)?(SECRET|PASSWORD|PASSWD|PASS|TOKEN|API_?KEY|PRIVATE_?KEY|[A-Z]+_KEY)\s*(=|:(?!:))\s*["'\`]?` +
      NOT_A_VALUE +
      String.raw`[^\s"'\`,;)]{8,}`,
  ),
  // "password": "value" or password: 'value' (JSON / YAML), any case; value must be quoted.
  new RegExp(
    String.raw`(["']|\b)(\w*_)?(secret|password|passwd|pass|token|api_?key|private_?key|\w+_key)["']?\s*:\s*["']` +
      NOT_A_VALUE +
      String.raw`[^"']{8,}["']`,
    'i',
  ),
];
const secretLines = md
  .split('\n')
  .map((l, i) => (SECRET_PATTERNS.some((re) => re.test(l)) ? i + 1 : 0))
  .filter(Boolean);
// With --repo, also check real .env values (only counted).
let realLeaks = 0;
if (repo && existsSync(join(repo, '.env'))) {
  for (const line of readFileSync(join(repo, '.env'), 'utf8').split('\n')) {
    const m = line.match(/^\s*([A-Z_][A-Z0-9_]*)\s*=\s*["']?([^"'\s#]+)/);
    if (m && /(SECRET|PASSWORD|PASS|TOKEN|API_KEY|_KEY$|CLIENT_ID|PRIVATE|HASH)/i.test(m[1]) && m[2].length >= 8 && md.includes(m[2]))
      realLeaks++;
  }
}
hard.secrets = { pass: secretLines.length === 0 && realLeaks === 0, suspectLines: secretLines, realEnvLeaks: realLeaks };

// Soft: version lines in Tech Stack carry a source tag.
const versionLines = bullets(section('Tech Stack')).filter((l) => /\d+\.\d+|\bv?\d{2}\b/.test(l));
const untagged = versionLines.filter((l) => !/\([^)]*\b(lockfile|manifest|inferred|cdn)\b|\b(UNKNOWN|ASSUMPTION):/i.test(l));
soft.versionTags = { score: ratio(versionLines.length - untagged.length, versionLines.length), untagged: untagged.map((l) => l.trim()) };

// Soft: ASSUMPTION:/UNKNOWN: items outside Open Questions also appear inside it.
const oq = section('Open Questions').toLowerCase();
const outside = parseSections(md)
  .filter((s) => s.title !== 'Open Questions')
  .flatMap((s) => [...s.body.matchAll(/(ASSUMPTION|UNKNOWN):\s*(.+)/g)].map((m) => m[2]));
const unlisted = outside.filter((t) => {
  const words = t.toLowerCase().match(/[a-z]{5,}/g) ?? [];
  return words.length && words.filter((w) => oq.includes(w)).length / words.length < 0.3;
});
soft.openQuestions = { score: ratio(outside.length - unlisted.length, outside.length), unlisted };

if (repo) {
  // Soft: route recall vs. routes grepped from source (Express, Slim/PHP routers, Laravel).
  const skip = /^(node_modules|vendor|\.git|dist|build|out|coverage|tests?|__tests__|screenshots|\.worktrees|\.venv|\.next|\.nuxt|storage|cache)$/;
  const files = [];
  const walk = (dir) => {
    let names;
    try {
      names = readdirSync(dir);
    } catch {
      return;
    }
    for (const name of names) {
      if (skip.test(name)) continue;
      const p = join(dir, name);
      let st;
      try {
        st = lstatSync(p);
      } catch {
        continue;
      }
      if (st.isSymbolicLink()) continue;
      if (st.isDirectory()) walk(p);
      else if (/\.(c|m)?js$|\.ts$|\.php$/.test(name) && !/\.min\.js$/.test(name)) files.push(p);
    }
  };
  walk(repo);
  const routes = new Set();
  const add = (method, path) => {
    const p = normPath(path.startsWith('/') ? path : '/' + path);
    if (p !== '/' && p !== '/*') routes.add(`${method.toUpperCase()} ${p}`);
  };
  const routeRe = /(?:\b(?:app|router|[a-z]\w*Router)\.|\$\w+->|\bRoute::)(get|post|put|patch|delete|all|any)\(\s*(['"`])([^'"`]+)\2/g;
  const resourceRe = /\bRoute::(resource|apiResource)\(\s*(['"])([^'"]+)\2/g;
  const RESOURCE = [['GET', ''], ['GET', '/create'], ['POST', ''], ['GET', '/:p'], ['GET', '/:p/edit'], ['PUT', '/:p'], ['DELETE', '/:p']];
  for (const f of files) {
    const src = readFileSync(f, 'utf8');
    for (const m of src.matchAll(routeRe)) add(m[1], m[3]);
    for (const m of src.matchAll(resourceRe)) {
      const base = m[3].split('.').map((seg, i, all) => (i < all.length - 1 ? `${seg}/:p` : seg)).join('/');
      for (const [method, suffix] of RESOURCE) {
        if (m[1] === 'apiResource' && /create|edit/.test(suffix)) continue;
        add(method, base + suffix);
      }
    }
  }
  const apiText = normPath(section('API Endpoints').replace(/[[\]]/g, ''));
  const missingRoutes = [...routes].filter((r) => !apiText.includes(r.split(' ')[1]));
  soft.routeRecall = { score: ratio(routes.size - missingRoutes.length, routes.size), total: routes.size, missing: missingRoutes };

  // Soft: every .env.example key (or .env key name) appears in Environment Variables.
  const envFile = existsSync(join(repo, '.env.example')) ? join(repo, '.env.example') : join(repo, '.env');
  const keys = existsSync(envFile) ? [...readFileSync(envFile, 'utf8').matchAll(/^\s*([A-Z_][A-Z0-9_]*)\s*=/gm)].map((m) => m[1]) : [];
  const envText = section('Environment Variables');
  const missingEnv = keys.filter((k) => !envText.includes(k));
  soft.envRecall = { score: ratio(keys.length - missingEnv.length, keys.length), total: keys.length, missing: missingEnv };
}

const result = { file: bpPath, pass: Object.values(hard).every((h) => h.pass), hard, soft };
if (json) {
  console.log(JSON.stringify(result, null, 2));
} else {
  const fmt = (v) => (v === null ? 'n/a' : `${Math.round(v * 100)}%`);
  console.log(`${bpPath}: ${result.pass ? 'PASS' : 'FAIL'}`);
  for (const [k, v] of Object.entries(hard)) console.log(`  hard ${k.padEnd(14)} ${v.pass ? 'ok' : 'FAIL'}`);
  for (const [k, v] of Object.entries(soft)) console.log(`  soft ${k.padEnd(14)} ${fmt(v.score)}`);
  if (missing.length) console.log(`  missing headings: ${missing.join('; ')}`);
  if (secretLines.length) console.log(`  secret-like values on lines: ${secretLines.join(', ')}`);
  if (untagged.length) console.log(`  untagged versions: ${untagged.length}`);
  if (unlisted.length) console.log(`  tags missing from Open Questions: ${unlisted.length}`);
  if (soft.routeRecall?.missing.length) console.log(`  missing routes: ${soft.routeRecall.missing.join(', ')}`);
  if (soft.envRecall?.missing.length) console.log(`  missing env vars: ${soft.envRecall.missing.join(', ')}`);
}
process.exit(result.pass ? 0 : 1);
