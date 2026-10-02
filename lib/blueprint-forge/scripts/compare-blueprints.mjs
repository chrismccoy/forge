#!/usr/bin/env node
// Round-trip check: compare the original blueprint with a blueprint scanned from the rebuilt app.
// Recall = share of the original's endpoints, models, and env vars that survive the rebuild.
// Standalone version of eval/diff.mjs: takes two paths, no LLM calls, no network.
//
// Usage: node compare-blueprints.mjs <original.BLUEPRINT.md> <rebuild.BLUEPRINT.md> [--min <0-1>] [--json]
//   --min  exit 1 when any recall is below this value (e.g. --min 0.9)
//   Exit 0 = compared (and every recall >= --min), 1 = below --min, 2 = bad usage.

import { readFileSync, existsSync, statSync } from 'node:fs';

const usage = (msg) => {
  if (msg) console.error(msg);
  console.error('Usage: node compare-blueprints.mjs <original.BLUEPRINT.md> <rebuild.BLUEPRINT.md> [--min <0-1>] [--json]');
  process.exit(2);
};
let json = false;
let min;
const files = [];
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--json') json = true;
  else if (a === '--min' || a.startsWith('--min=')) {
    const v = a === '--min' ? argv[++i] : a.slice('--min='.length);
    min = Number(v);
    if (v === undefined || !Number.isFinite(min) || min < 0 || min > 1) usage('--min needs a number from 0 to 1');
  } else if (a.startsWith('-')) usage(`Unknown option: ${a}`);
  else files.push(a);
}
if (files.length !== 2) usage();
for (const f of files) if (!existsSync(f) || !statSync(f).isFile()) usage(`Not a file: ${f}`);
const [a, b] = files.map((f) => readFileSync(f, 'utf8'));

// Returns [{ title, body }] for every "## N. Title" heading.
function parseSections(md) {
  const heads = [...md.matchAll(/^## (\d+)\. (.+?)\s*$/gm)];
  return heads.map((m, i) => ({ title: m[2], body: md.slice(m.index + m[0].length, heads[i + 1]?.index ?? md.length) }));
}
const section = (md, title) => parseSections(md).find((s) => s.title === title)?.body ?? '';

// Treat ":id", "{id}", "{id:[0-9]+}", and "<id>" params as the same thing.
const normPath = (p) =>
  p.replace(/\{[A-Za-z0-9_]+\??(?::[^}]*)?\}/g, ':p').replace(/[:<][A-Za-z0-9_]+>?/g, ':p').replace(/\/+$/, '') || '/';

// "| GET | /api/x |" table rows -> ["GET /api/x"]
function endpoints(md) {
  const rows = section(md, 'API Endpoints').matchAll(/^\|\s*(GET|POST|PUT|PATCH|DELETE|ALL|USE)\s*\|\s*`?([^|`\s]+)`?\s*\|/gim);
  return [...new Set([...rows].map((m) => `${m[1].toUpperCase()} ${normPath(m[2])}`))];
}

// Model/table names, lowercased and singularized so "User", "users", "categories"/"category" match.
function models(md) {
  const body = section(md, 'Data Models / Schema');
  const patterns = [
    /\btable\s+\*{0,2}`([A-Za-z]\w*)`/gi,
    /^#{3,4}\s*`?([A-Za-z]\w*)`?/gm,
    /^(?:[-*]\s*)?(?:[A-Za-z]+\s+){0,3}\*\*`?([A-Za-z]\w*)`?\*\*/gm,
    /^`?([A-Z][A-Za-z0-9_]+)`?\s*(?:\(.*\))?:?\s*$/gm,
  ];
  const notModels = /^(table|relationship|relation|migration|index|indice|constraint|note|enum|seed|schema|pragma)$/;
  const singular = (n) => n.toLowerCase().replace(/ies$/, 'y').replace(/([^s])s$/, '$1');
  const names = patterns.flatMap((re) => [...body.matchAll(re)].map((m) => singular(m[1])));
  return [...new Set(names.filter((n) => !notModels.test(n)))];
}

// Env var names that start a list item or table row in Environment Variables.
function envVars(md) {
  const re = /^(?:[-*]\s*|\|\s*)`?([A-Z][A-Z0-9_]{2,})`?/gm;
  return [...new Set([...section(md, 'Environment Variables').matchAll(re)].map((m) => m[1]))];
}

function compare(fn) {
  const before = fn(a);
  const after = new Set(fn(b));
  const lost = before.filter((x) => !after.has(x));
  const added = [...after].filter((x) => !before.includes(x));
  const recall = before.length ? Math.round(((before.length - lost.length) / before.length) * 100) / 100 : null;
  return { recall, before: before.length, after: after.size, lost, added };
}

const result = { original: files[0], rebuild: files[1], endpoints: compare(endpoints), models: compare(models), envVars: compare(envVars) };
const keys = ['endpoints', 'models', 'envVars'];
const below = min === undefined ? [] : keys.filter((k) => result[k].recall !== null && result[k].recall < min);
result.pass = below.length === 0;

if (json) {
  console.log(JSON.stringify(result, null, 2));
} else {
  console.log(`round trip: ${files[0]} -> ${files[1]}`);
  for (const k of keys) {
    const r = result[k];
    const pct = r.recall === null ? 'n/a' : `${Math.round(r.recall * 100)}%`;
    console.log(`  ${k.padEnd(10)} recall ${pct.padStart(4)}  (${r.before} -> ${r.after}, lost ${r.lost.length}, added ${r.added.length})`);
    if (r.lost.length) console.log(`    lost: ${r.lost.join(', ')}`);
  }
  if (below.length) console.log(`  below --min ${min}: ${below.join(', ')}`);
}
process.exit(result.pass ? 0 : 1);
