/**
 * @file Scans a WordPress plugin's source and prints what a demo video can show: admin pages,
 * settings, post types, REST and AJAX endpoints, scripts, UI extras, string constants, and the
 * DOM hooks (IDs, names, selectors) used by its PHP views and JavaScript.
 *
 * Only reads files; it never runs plugin code and needs no site access.
 *
 * Usage: node scan-plugin.js "<plugin dir>" [--include-tests] [--include-build]
 *   --include-tests  also scan tests/ and test/ (fixtures can hold sample API responses)
 *   --include-build  also scan build/ (for plugins whose block.json exists only there)
 *
 * Scans .php, .js, .jsx, .ts, .tsx and .json files. Skips symlinks, vendor/, node_modules/,
 * .git/, languages/, dist/, tests/, test/, build/, *.min.js, and JS or TS files with a line
 * longer than 1,000 characters (minified code).
 */

import { lstatSync, readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

/**
 * One output section: its title and the regular expression that finds a matching line.
 * @typedef {[title: string, pattern: RegExp]} Pattern
 */

/**
 * The plugin header found in the main plugin file.
 * @typedef {object} PluginHeader
 * @property {string} file - Path of the file, relative to the plugin root.
 * @property {Record<string, string>} fields - Header fields such as "Plugin Name" and "Version".
 */

// ---------------------------------------------------------------------------------------------
// Arguments
// ---------------------------------------------------------------------------------------------

const args = process.argv.slice(2);
const root = args.find((a) => !a.startsWith('--'));
const includeTests = args.includes('--include-tests');
const includeBuild = args.includes('--include-build');
if (!root) {
  console.error('Usage: node scan-plugin.js "<plugin dir>" [--include-tests] [--include-build]');
  process.exit(1);
}

// ---------------------------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------------------------

/** Directory names that are never scanned. */
const SKIP_DIRS = new Set(['node_modules', 'vendor', '.git', 'languages', 'dist']);
if (!includeTests) SKIP_DIRS.add('tests').add('test');
// Compiled @wordpress/scripts output: minified, and it repeats what the src/ files say.
if (!includeBuild) SKIP_DIRS.add('build');

/**
 * In a JS or TS file, a line this long means generated or minified code. PHP files are never
 * skipped: plugins often pass add_menu_page() a long inline base64 SVG icon.
 */
const MINIFIED_LINE = 1000;

/** Longest call shown, in lines. Long enough for add_menu_page() with one argument per line. */
const MAX_CALL_LINES = 12;

/** Longest call shown, in characters, so a base64 icon does not flood the output. */
const MAX_CALL_CHARS = 400;

/**
 * Header field names to report, as WordPress reads them from the main plugin file.
 * @type {string[]}
 */
const HEADER_FIELDS = ['Plugin Name', 'Version', 'Text Domain', 'Requires at least', 'Description'];

/**
 * Matches a header field line the way WordPress does (get_file_data): any mix of spaces, tabs,
 * "/", "*", "#" and "@" may come before the field name.
 * @param {string} field - Header field name, such as "Plugin Name".
 * @returns {RegExp} Pattern whose first group is the field value.
 */
const headerLine = (field) => new RegExp(`^[ \\t/*#@]*${field}:(.*)$`, 'mi');

/** @type {Pattern[]} Patterns searched in PHP files. */
const PHP_PATTERNS = [
  [
    'Admin pages',
    /\badd_(menu|submenu|options|management|theme|users|dashboard|posts|media|pages|comments|plugins)_page\s*\(/,
  ],
  ['Settings', /\b(register_setting|add_settings_section|add_settings_field)\s*\(/],
  ['Post types and taxonomies', /\b(register_post_type|register_taxonomy)\s*\(/],
  ['REST routes', /\bregister_rest_route\s*\(/],
  ['AJAX and admin-post actions', /\badd_action\s*\(\s*['"](wp_ajax_|admin_post_)/],
  [
    'Scripts and localized data',
    /\b(wp_register_script|wp_enqueue_script|wp_enqueue_script_module|wp_register_script_module|wp_localize_script|wp_add_inline_script|wp_set_script_translations)\s*\(/,
  ],
  [
    'UI extras',
    /\b(add_meta_box|wp_add_dashboard_widget|add_shortcode|register_block_type)\s*\(|plugin_action_links|admin_notices|manage_[\w{}$]*_columns/,
  ],
  [
    'String constants',
    /^\s*(public\s+|private\s+|protected\s+)?const\s+\w+\s*=\s*['"]|\bdefine\s*\(\s*['"]/,
  ],
];

/** @type {Pattern[]} Patterns searched in JS and TS files. */
const JS_PATTERNS = [
  [
    'JS requests',
    /\bapiFetch\s*\(|\bfetch\s*\(|\bajaxurl\b|\bwp\.ajax\.|\$\.(post|ajax|get|getJSON)\s*\(|\bpath\s*:\s*['"`]\/|admin-ajax\.php|\/wp-json\//,
  ],
];

/** Title of the section filled from block.json files. */
const BLOCKS_SECTION = 'Blocks (block.json)';

// ---------------------------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------------------------

/**
 * Lists the source files to scan, depth first. Symlinks are skipped, because they can loop or
 * point outside the plugin. Files in a directory come before its subdirectories, so the main
 * plugin file in the root is found before PHP files deeper in the tree.
 * @param {string} dir - Directory to list.
 * @param {string[]} [files] - Accumulator for the recursion.
 * @returns {string[]} Absolute paths of the files to scan.
 */
function walk(dir, files = []) {
  let names;
  try {
    names = readdirSync(dir).sort();
  } catch {
    // Unreadable directory: skip it rather than stop the scan.
    return files;
  }
  const subdirs = [];
  for (const name of names) {
    const full = path.join(dir, name);
    let stat;
    try {
      stat = lstatSync(full);
    } catch {
      continue;
    }
    if (stat.isSymbolicLink()) continue;
    if (stat.isDirectory()) {
      if (!SKIP_DIRS.has(name)) subdirs.push(full);
    } else if (/\.(php|js|jsx|ts|tsx|json)$/.test(name) && !/\.min\.js$/.test(name)) {
      files.push(full);
    }
  }
  for (const sub of subdirs) walk(sub, files);
  return files;
}

/**
 * Returns the call that starts at line `i`, joined onto one line. Registration calls often put
 * one argument per line, so following lines are added until the parentheses balance (or
 * MAX_CALL_LINES is reached). Parentheses inside strings are counted too; this is a heuristic.
 * @param {string[]} lines - All lines of the file.
 * @param {number} i - Index of the line where the call starts.
 * @returns {string} The call with whitespace collapsed.
 */
function callAt(lines, i) {
  let depth = 0;
  const out = [];
  for (let j = i; j < lines.length && out.length < MAX_CALL_LINES; j++) {
    const line = lines[j];
    out.push(line);
    for (const ch of line) {
      if (ch === '(') depth++;
      else if (ch === ')') depth--;
    }
    if (depth <= 0) break;
  }
  return out
    .map((l) => l.trim())
    .join(' ')
    .replace(/\s+/g, ' ');
}

/**
 * Makes a path relative to the plugin root, for shorter output.
 * @param {string} file - Absolute path.
 * @returns {string} Path relative to the plugin root.
 */
function rel(file) {
  return path.relative(root, file);
}

/**
 * Reads the plugin header from a PHP file, if it has one in its first 8 KB (WordPress reads
 * the same amount). Trailing comment markers such as "*\/" are removed from values.
 * @param {string} text - File contents.
 * @param {string} file - Absolute path of the file.
 * @returns {PluginHeader | null} The header, or null when the file has no "Plugin Name:" line.
 */
function readHeader(text, file) {
  const head = text.slice(0, 8192);
  if (!headerLine('Plugin Name').test(head)) return null;
  /** @type {Record<string, string>} */
  const fields = {};
  for (const key of HEADER_FIELDS) {
    const m = head.match(headerLine(key));
    const value = m?.[1].replace(/\s*(\*\/|\?>).*$/, '').trim();
    if (value) fields[key] = value;
  }
  return { file: rel(file), fields };
}

/**
 * Collects the DOM hooks a scene can target: id, name and data-* attributes in PHP views, and
 * selector-like string literals ("#id", ".class ...") and data-* attributes in JS.
 * @param {string} text - File contents.
 * @param {boolean} isPhp - Whether the file is PHP.
 * @returns {string[]} Sorted, unique hooks.
 */
function domHooks(text, isPhp) {
  const found = new Set();
  if (isPhp) {
    for (const m of text.matchAll(/\b(id|name|data-[\w-]+)=["']([^"'<>]{1,80})["']/g)) {
      found.add(`${m[1]}=${m[2]}`);
    }
  } else {
    for (const m of text.matchAll(/['"`]([#.][a-zA-Z][\w-]*(?:[ >.#[\]="'\w:-]*)?)['"`]/g)) {
      found.add(m[1].trim());
    }
    for (const m of text.matchAll(/data-([\w-]+)=/g)) found.add(`[data-${m[1]}]`);
  }
  return [...found].sort();
}

// ---------------------------------------------------------------------------------------------
// Scan
// ---------------------------------------------------------------------------------------------

const files = walk(path.resolve(root));

/** @type {Map<string, string[]>} Output lines per section title. */
const sections = new Map();

/**
 * Adds one output line to a section.
 * @param {string} section - Section title.
 * @param {string} entry - Line to add.
 */
const add = (section, entry) => {
  if (!sections.has(section)) sections.set(section, []);
  sections.get(section).push(entry);
};

/** @type {PluginHeader | null} */
let header = null;
/** @type {Map<string, string[]>} DOM hooks per file. */
const selectorsByFile = new Map();
/** @type {string[]} JS or TS files skipped as minified. */
const skippedMinified = [];

for (const file of files) {
  let text;
  try {
    text = readFileSync(file, 'utf8');
  } catch {
    continue;
  }
  const lines = text.split('\n');
  const ext = path.extname(file);
  const isPhp = ext === '.php';

  if (/\.(js|jsx|ts|tsx)$/.test(ext) && lines.some((l) => l.length > MINIFIED_LINE)) {
    skippedMinified.push(rel(file));
    continue;
  }

  // The first PHP file with a header is the main plugin file (root files come first).
  if (isPhp && !header) header = readHeader(text, file);

  if (path.basename(file) === 'block.json') {
    try {
      const block = JSON.parse(text);
      add(BLOCKS_SECTION, `${rel(file)}: ${block.name} "${block.title ?? ''}"`);
    } catch {
      // Not valid JSON: nothing to report.
    }
    continue;
  }
  if (ext === '.json') continue;

  const patterns = isPhp ? PHP_PATTERNS : JS_PATTERNS;
  lines.forEach((line, i) => {
    // Skip comment lines. "#" starts a comment only in PHP; in JS it marks a private field.
    if (/^\s*(\*|\/\/)/.test(line) || (isPhp && /^\s*#/.test(line))) return;
    for (const [section, re] of patterns) {
      if (re.test(line)) {
        add(section, `${rel(file)}:${i + 1}  ${callAt(lines, i).slice(0, MAX_CALL_CHARS)}`);
      }
    }
  });

  const hooks = domHooks(text, isPhp);
  if (hooks.length) selectorsByFile.set(rel(file), hooks);
}

// ---------------------------------------------------------------------------------------------
// Report
// ---------------------------------------------------------------------------------------------

if (header) {
  console.log(`== Plugin header (${header.file})`);
  for (const [k, v] of Object.entries(header.fields)) console.log(`  ${k}: ${v}`);
  console.log();
} else {
  console.log('== No "Plugin Name:" header found. Is this the plugin root?\n');
}

// Sections print in a fixed order, so outputs from different plugins are easy to compare.
const order = [...PHP_PATTERNS, ...JS_PATTERNS].map(([s]) => s).concat(BLOCKS_SECTION);
for (const section of order) {
  const entries = sections.get(section);
  if (!entries) continue;
  console.log(`== ${section} (${entries.length})`);
  for (const e of entries) console.log(`  ${e}`);
  console.log();
}

console.log('== DOM hooks per file');
for (const [file, list] of selectorsByFile) {
  console.log(`  ${file}`);
  console.log(`    ${list.join('  ')}`);
}
if (skippedMinified.length) {
  console.log('\n== Skipped as minified (JS or TS with a line over 1,000 characters)');
  for (const f of skippedMinified) console.log(`  ${f}`);
}
console.log(`\nScanned ${files.length} files under ${path.resolve(root)}`);
