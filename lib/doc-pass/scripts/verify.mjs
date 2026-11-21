#!/usr/bin/env node
/**
 * Proves that a documentation pass changed only comments.
 *
 * Usage: node verify.mjs <orig-dir> <current-dir> [--schema-tags]
 *        [--checked-types [--ts-check-per-file]] [--list-frozen]
 *        [--line-limit <n>] [--terse [--max-doc-lines <n>]]
 *        [--files-from <list>] [relative files...]
 *        node verify.mjs <dir> --list-files [--list-skipped]
 *
 * `--checked-js` is accepted as an alias of `--checked-types`. With
 * --ts-check-per-file, --checked-types applies to a plain JS script (.js,
 * .jsx, .mjs, .cjs, a component script without lang="ts") only when the
 * last `// @ts-check` or `// @ts-nocheck` line in its leading comments is
 * `@ts-check` (block-comment pragmas do not count, as in TypeScript).
 *
 * With no file list, every in-scope file under <orig-dir> is checked. Runs
 * three checks per file (code, layout, comment-is-code) and exits non-zero
 * on any failure. With --list-frozen, also prints each frozen comment and
 * tag line of the original as `FROZEN: <file>:<line> <text>`. With
 * --line-limit, a new or edited comment line wider than <n> columns (tabs
 * count as 4) fails as `LONG COMMENT LINE: <file>:<line>`. With --terse
 * (terse comment style), a new or edited doc comment with more than
 * --max-doc-lines prose lines (default 3; a file header gets twice that)
 * fails as `LONG DOC COMMENT: <file>:<line> (<k> > <n> lines)`, a new
 * parameter, return or error tag line fails as `TERSE TAG ADDED: <file>:<line>
 * <tag>`, and, without --checked-types, `@typedef`, `@callback`, `@property`
 * and `@prop` lines are no longer kept. Where the doc form is a plain line
 * comment (Go, Python, Ruby and others), only a file header or a comment
 * directly above a declaration is a doc comment. With --list-files, prints
 * the in-scope files the walk finds under <dir>, one relative path per line,
 * and checks nothing; --list-skipped adds a `SKIPPED: <file>` line for each
 * source file it left out because it is binary or marked generated, and a
 * `SKIPPED DIR: <dir>/` line for each pruned folder named like build output
 * that holds source files. See references/checker-spec.md for the
 * specification.
 */

import { existsSync, readFileSync } from 'node:fs';
import { extname, join } from 'node:path';
import { LANGS, langFor } from './langs.mjs';
import { JS_EXT, SFC_EXT, layoutMismatch, model, parseArgs, walk } from './lib.mjs';

const { flags, values, rest, listed } = parseArgs( process.argv.slice( 2 ), [ '--schema-tags', '--checked-js', '--checked-types', '--list-frozen', '--list-files', '--list-skipped', '--terse', '--ts-check-per-file' ], [ '--line-limit', '--max-doc-lines' ] );
const checked = !! ( flags[ 'checked-js' ] || flags[ 'checked-types' ] );
const terse = !! flags.terse;
const opts = { schemaTags: !! flags[ 'schema-tags' ], checkedJs: checked, checkedTypes: checked, terse, tsCheckPerFile: !! flags[ 'ts-check-per-file' ] };
const [ origDir, curDir, ...only ] = rest;
const lineLimit = values[ 'line-limit' ] === undefined ? 0 : Number( values[ 'line-limit' ] );
if ( ! Number.isInteger( lineLimit ) || lineLimit < 0 ) {
	console.error( `--line-limit needs a whole number, got ${ values[ 'line-limit' ] }` );
	process.exit( 2 );
}
const maxDoc = values[ 'max-doc-lines' ] === undefined ? 3 : Number( values[ 'max-doc-lines' ] );
if ( ! Number.isInteger( maxDoc ) || maxDoc < 1 ) {
	console.error( `--max-doc-lines needs a whole number of at least 1, got ${ values[ 'max-doc-lines' ] }` );
	process.exit( 2 );
}
const cache = new Map();
const src = ( path ) => cache.get( path ) ?? cache.set( path, readFileSync( path, 'utf8' ) ).get( path );
if ( flags[ 'list-files' ] && origDir ) {
	const skipped = [];
	const skippedDirs = [];
	walk( origDir, skipped, skippedDirs ).forEach( ( f ) => console.log( f ) );
	if ( flags[ 'list-skipped' ] ) {
		skipped.forEach( ( f ) => console.log( `SKIPPED: ${ f }` ) );
		skippedDirs.forEach( ( d ) => console.log( `SKIPPED DIR: ${ d }/` ) );
	}
	process.exit( 0 );
}
if ( ! origDir || ! curDir ) {
	console.error( 'Usage: node verify.mjs <orig-dir> <current-dir> [--schema-tags] [--checked-types [--ts-check-per-file]] [--list-frozen] [--line-limit <n>] [--terse [--max-doc-lines <n>]] [--files-from <list>] [files...]\n       node verify.mjs <dir> --list-files [--list-skipped]' );
	process.exit( 2 );
}

// Directives that act on the next line or node: they must stay the last
// comment before their code.
const NEXT_LINE = /next-line|@ts-(expect-error|ignore)|prettier-ignore|translators:|biome-ignore|deno-lint-ignore|noinspection|(istanbul|c8|v8)\s+ignore\s+(next|start|else|if)/;

const files = only.length || listed ? only : walk( origDir );
const failures = [];
const fail = ( msg ) => failures.push( msg );

/**
 * Groups comment facts by anchor into sorted, comparable strings.
 *
 * @param {Object[]} comments Comments from model().
 * @param {Function} pick     Returns the strings to record for one comment.
 * @return {string[]} Sorted "anchor\u0000value" entries.
 */
function facts( comments, pick ) {
	const out = [];
	for ( const c of comments ) {
		for ( const v of pick( c ) ) {
			out.push( c.anchor + '\u0000' + v );
		}
	}
	return out.sort();
}

/**
 * Lists entries of `a` missing from multiset `b`.
 *
 * @param {string[]} a Entries.
 * @param {string[]} b Entries.
 * @return {string[]} Entries in a but not b, with multiplicity.
 */
function missing( a, b ) {
	const count = new Map();
	b.forEach( ( x ) => count.set( x, ( count.get( x ) || 0 ) + 1 ) );
	return a.filter( ( x ) => {
		const n = count.get( x ) || 0;
		count.set( x, n - 1 );
		return n <= 0;
	} );
}

/**
 * Maps each anchor to the last comment before it.
 *
 * @param {Object[]} comments Comments from model(), in source order.
 * @return {Map<string, Object>} Last comment per anchor.
 */
function lastAt( comments ) {
	const m = new Map();
	comments.forEach( ( c ) => m.set( String( c.anchor ), c ) );
	return m;
}

const show = ( entry ) => JSON.stringify( entry.split( '\u0000' )[ 1 ].slice( 0, 100 ) );

/**
 * Strips comment markers, one entry per line of the comment's text.
 *
 * Unlike the classifiers, a line keeps a leading `#` (Rust's `# Errors`)
 * and loses a leading `*` only inside a block comment.
 *
 * @param {string} text Raw comment or docstring text.
 * @return {string[]} Trimmed lines, internal whitespace collapsed.
 */
function docLines( text ) {
	const block = text.startsWith( '/*' );
	return text
		.replace( /^(<#|\/\*+!?|\/\/[/!]?|#+|;+|%+|--\[=*\[|-{2,}\s*[|^$*]?|\{-\s*[|^$]?|@(module|type)?doc\s+(~[sS])?("""|")|[rRuU]?("""|'''|"|'))/, '' )
		.replace( /(\*\/|-\}|#>|\]=*\]|"""|'''|"|')\s*$/, '' )
		.split( '\n' )
		.map( ( l ) => ( block ? l.replace( /^\s*\*(?!\/)/, '' ) : l ).replace( /\s+/g, ' ' ).trim() );
}

// Doc comment lines that hold no prose: rules (`----------` under a NumPy
// heading), C# XML wrappers on their own line and Perl's `=pod` / `=cut`.
const MARKER_ONLY = /^([-=~*#_]+|<\/?(summary|remarks|para)>|=(pod|cut))$/;

/**
 * Reduces a tag line to its tag and the name after it (skipping a braced
 * type; a return or type tag has no name, so its type stands in), so a kept
 * tag whose description changed is not a new tag.
 *
 * @param {string} l   Tag line.
 * @param {string} tag The matched tag.
 * @return {string} Tag and name.
 */
function tagKey( l, tag ) {
	let rest = l.slice( tag.length ).trim();
	let type = '';
	if ( rest.startsWith( '{' ) ) {
		let depth = 0;
		let i = 0;
		for ( ; i < rest.length; i++ ) {
			depth += rest[ i ] === '{' ? 1 : rest[ i ] === '}' ? -1 : 0;
			if ( depth === 0 ) {
				break;
			}
		}
		type = rest.slice( 0, i + 1 );
		rest = rest.slice( i + 1 ).trim();
	}
	const word = rest.split( /[\s>]/ )[ 0 ];
	// A return or type tag has no name: its type identifies it (braced, or
	// the first word, as in PHP `@return int`).
	return tag + '\u0000' + ( /^@(returns?|type|satisfies|this|enum|augments|extends|implements)$/.test( tag ) ? type || word : word );
}

/**
 * Groups comments into doc blocks: a run of one-line comments on adjacent
 * lines before the same code is one block (`///` lines, `#` lines, Haskell's
 * `-- |` and its `--` lines); any other comment is a block of its own. A
 * docstring never joins the `#` comments next to it.
 *
 * @param {Object[]} comments Comments from model(), in source order.
 * @return {Object[][]} Blocks.
 */
function blocks( comments ) {
	const out = [];
	const single = ( c ) => ! c.text.includes( '\n' );
	for ( const c of comments ) {
		const g = out[ out.length - 1 ];
		const p = g?.[ g.length - 1 ];
		if ( p && single( p ) && single( c ) && ! p.docstring && ! c.docstring && String( p.anchor ) === String( c.anchor ) && ! String( c.anchor ).endsWith( '~' ) && c.line === p.line + 1 ) {
			g.push( c );
		} else {
			out.push( [ c ] );
		}
	}
	return out;
}

let frozenCount = 0;
for ( const f of files ) {
	const origPath = join( origDir, f );
	const curPath = join( curDir, f );
	if ( ! existsSync( origPath ) ) {
		fail( `CODE CHANGED: ${ f }: not in ${ origDir }` );
		continue;
	}
	if ( ! existsSync( curPath ) ) {
		fail( `CODE CHANGED: ${ f }: file missing` );
		continue;
	}
	const a = await model( f, readFileSync( origPath, 'utf8' ), opts );
	if ( a.error ) {
		fail( `CODE CHANGED: ${ f }: original ${ a.error }` );
		continue;
	}
	if ( flags[ 'list-frozen' ] && a.errors ) {
		const at = [ ...new Set( ( a.regions || [] ).map( ( [ s, e ] ) => ( s === e ? `${ s }` : `${ s }-${ e }` ) ) ) ].join( ', ' );
		console.log( `LOCKED: ${ f }: ${ a.errors } region(s) the grammar cannot parse are compared byte for byte${ at ? `: lines ${ at }` : '' }` );
	}
	if ( flags[ 'list-frozen' ] ) {
		for ( const c of a.comments ) {
			for ( const t of c.whole ? [ c.text.split( '\n' )[ 0 ] ] : c.frozen ) {
				console.log( `FROZEN: ${ f }:${ c.line } ${ t.trim().slice( 0, 120 ) }` );
			}
		}
	}
	// Parse the current version with the plugin sets the original needed.
	const b = await model( f, readFileSync( curPath, 'utf8' ), opts, a.cfgs );
	if ( b.error ) {
		fail( `CODE CHANGED: ${ f }: ${ b.error }` );
		continue;
	}

	// 1. Code check.
	if ( a.lang === 'sfc' && a.markup !== b.markup ) {
		fail( `CODE CHANGED: ${ f }: markup outside <script> changed` );
		continue;
	}
	if ( a.code !== b.code ) {
		fail( `CODE CHANGED: ${ f }` );
		continue;
	}

	// 2. Layout check.
	const la = a.layout;
	const lb = b.layout;
	const miss = layoutMismatch( la, lb );
	if ( miss >= 0 ) {
		const at = lb[ miss ] || lb[ lb.length - 1 ];
		fail( `LAYOUT CHANGED: ${ f }:${ at ? at.line : 0 }` );
	}

	// 3. Comment-is-code check. Anchors are comparable because code matched.
	const wholeA = facts( a.comments, ( c ) => ( c.whole ? [ c.text.trim() ] : [] ) );
	const wholeB = facts( b.comments, ( c ) => ( c.whole ? [ c.text.trim() ] : [] ) );
	const lineA = facts( a.comments, ( c ) => c.frozen );
	const lineB = facts( b.comments, ( c ) => c.frozen );
	const keptA = facts( a.comments, ( c ) => c.kept );
	const keptB = facts( b.comments, ( c ) => c.kept );
	frozenCount += wholeA.length + lineA.length;

	for ( const e of missing( wholeA, wholeB ) ) {
		fail( `FROZEN COMMENT CHANGED: ${ f }: removed, moved or edited ${ show( e ) }` );
	}
	for ( const e of missing( wholeB, wholeA ) ) {
		fail( `FROZEN COMMENT CHANGED: ${ f }: added ${ show( e ) }` );
	}
	for ( const e of missing( lineA, lineB ) ) {
		fail( `FROZEN COMMENT CHANGED: ${ f }: removed or edited line ${ show( e ) }` );
	}
	for ( const e of missing( lineB, lineA ) ) {
		fail( `FROZEN COMMENT CHANGED: ${ f }: added line ${ show( e ) }` );
	}
	for ( const e of missing( keptA, keptB ) ) {
		fail( `FROZEN COMMENT CHANGED: ${ f }: kept line lost ${ show( e ) }` );
	}

	// A directive comment that applies to the next line (eslint-disable-next-line,
	// @ts-expect-error, prettier-ignore, translators: …) must stay the last
	// comment before its code.
	const lastA = lastAt( a.comments );
	const lastB = lastAt( b.comments );
	for ( const [ anchor, c ] of lastA ) {
		const nextLine = a.nextLine === undefined ? NEXT_LINE : a.nextLine;
		if ( nextLine && c.whole && nextLine.test( c.text ) &&
			lastB.get( anchor )?.text.trim() !== c.text.trim() ) {
			fail( `FROZEN COMMENT CHANGED: ${ f }: directive no longer directly before its code (line ${ c.line })` );
		}
	}

	// Comments that only work at the top of a file must keep their line: a
	// shebang on line 1, an encoding cookie on line 1 or 2, SwiftPM's
	// `swift-tools-version` on line 1, an escript's `%%!` flags on line 2 or 3.
	// A comment added above them breaks them.
	for ( const c of a.comments ) {
		const top = ( c.line === 1 && c.text.startsWith( '#!' ) ) ||
			( c.line <= 2 && c.whole && /^(#.*coding[:=]|\/\/\s*swift-tools-version)/.test( c.text ) ) ||
			( c.line <= 3 && c.text.startsWith( '%%!' ) );
		if ( top ) {
			const kept = b.comments.find( ( d ) => d.text.trim() === c.text.trim() );
			if ( ! kept || kept.line !== c.line ) {
				fail( `FROZEN COMMENT CHANGED: ${ f }: ${ JSON.stringify( c.text.slice( 0, 60 ) ) } must stay on line ${ c.line }` );
			}
		}
	}

	// Lines of new or edited comments, each marked new unless it repeats a
	// line of an original comment that changed. A line kept from the original
	// comment (a long URL in a block that only gained a summary) is not new.
	let fresh = null;
	if ( lineLimit || terse ) {
		const before = new Set( a.comments.map( ( c ) => c.text ) );
		const after = new Set( b.comments.map( ( c ) => c.text ) );
		const span = ( c, lines ) => lines.slice( c.line - 1, c.line + ( c.text.match( /\n/g ) || [] ).length );
		const origLines = src( origPath ).split( /\r?\n/ );
		const old = new Map();
		for ( const c of a.comments.filter( ( x ) => ! after.has( x.text ) ) ) {
			for ( const l of span( c, origLines ) ) {
				old.set( l.trim(), ( old.get( l.trim() ) || 0 ) + 1 );
			}
		}
		const lines = src( curPath ).split( /\r?\n/ );
		fresh = new Map();
		for ( const c of b.comments.filter( ( x ) => ! before.has( x.text ) ) ) {
			fresh.set( c, span( c, lines ).map( ( text ) => {
				if ( old.get( text.trim() ) > 0 ) {
					old.set( text.trim(), old.get( text.trim() ) - 1 );
					return { text, isNew: false };
				}
				return { text, isNew: true };
			} ) );
		}
	}

	// New or edited comment lines must fit the line limit (tabs count as 4).
	// Lines kept from the original are not checked; nor is a trailing
	// comment whose code before it is already over the limit.
	if ( lineLimit ) {
		const width = ( t ) => [ ...t.replace( /\t/g, '    ' ) ].length;
		for ( const [ c, ls ] of fresh ) {
			ls.forEach( ( { text, isNew }, k ) => {
				if ( ! isNew ) {
					return;
				}
				const at = k === 0 ? text.indexOf( c.text.split( '\n' )[ 0 ] ) : -1;
				if ( at > 0 && text.slice( 0, at ).trim() && width( text.slice( 0, at ).trimEnd() ) > lineLimit ) {
					return;
				}
				const w = width( text );
				if ( w > lineLimit ) {
					fail( `LONG COMMENT LINE: ${ f }:${ c.line + k } (${ w } > ${ lineLimit })` );
				}
			} );
		}
	}

	// Terse style: a new or edited doc block holds at most maxDoc prose lines
	// (a file header twice that) and gains no parameter, return or error tag
	// line. Frozen and kept lines do not count; frozen comments are skipped.
	if ( terse ) {
		const lang = ! JS_EXT.has( extname( f ) ) && ! SFC_EXT.has( extname( f ) ) && langFor( f );
		const L = ( lang && LANGS[ lang ] ) || LANGS.javascript;
		// Where a plain line comment is the doc form, an inline why-comment
		// looks the same: only a line comment directly above a declaration
		// counts. Block docs (Perl POD, PowerShell `<# #>`) count anywhere.
		const lineDoc = !! ( lang && L.line && L.doc?.( `${ L.line } x` ) );
		const slots = lineDoc ? await ( await import( './treesitter.mjs' ) ).declComments( lang, f, src( curPath ) ) : null;
		const marker = L.line?.replace( /;;$/, ';' );
		const isDoc = ( c ) => !! c.docstring || ( !! L.doc?.( c.text ) && ( ! slots || ! c.text.startsWith( marker ) || slots.has( c.line ) ) );
		// Original comment texts per anchor.
		const origAt = new Map();
		for ( const c of a.comments ) {
			origAt.set( String( c.anchor ), ( origAt.get( String( c.anchor ) ) || new Set() ).add( c.text ) );
		}
		// Tag lines of the original, per anchor, reduced to tag and name.
		const origTags = new Map();
		for ( const c of L.terseTags ? a.comments : [] ) {
			for ( const l of docLines( c.text ) ) {
				const m = L.terseTags.exec( l );
				if ( m ) {
					const key = String( c.anchor );
					origTags.set( key, ( origTags.get( key ) || new Set() ).add( tagKey( l, m[ 0 ] ) ) );
				}
			}
		}
		const lines = src( curPath ).split( /\r?\n/ );
		let first = true;
		for ( const g of blocks( b.comments ) ) {
			const live = g.filter( ( c ) => ! c.whole );
			if ( ! live.length ) {
				continue;
			}
			// A file header: the first block, with only a shebang, a PHP open
			// tag and frozen comments (license, directives) before it.
			let header = false;
			if ( first ) {
				first = false;
				const c0 = g[ 0 ];
				const row = lines[ c0.line - 1 ] || '';
				let pre = lines.slice( 0, c0.line - 1 ).join( '\n' ) + '\n' + row.slice( 0, Math.max( 0, row.indexOf( c0.text.split( '\n' )[ 0 ] ) ) );
				for ( const d of b.comments.slice( 0, b.comments.indexOf( c0 ) ) ) {
					pre = pre.replace( d.text, '' );
				}
				header = /^\uFEFF?(#!.*)?\s*(<\?php)?\s*$/.test( pre );
			}
			// The tag check covers every new or edited comment (not identical to
			// an original comment at its anchor); the length check only blocks
			// with a new line.
			const edited = ( c ) => ! origAt.get( String( c.anchor ) )?.has( c.text );
			if ( ! ( g.some( isDoc ) || ( header && slots && g.some( ( c ) => L.doc( c.text ) ) ) ) || ! g.some( edited ) ) {
				continue;
			}
			const grew = g.some( ( c ) => fresh.get( c )?.some( ( x ) => x.isNew ) );
			let k = 0;
			const added = [];
			for ( const c of live ) {
				const tags = [ ...c.frozen, ...c.kept ].filter( Boolean );
				// The rest of a Frozen or Kept tag that spans lines: the lines
				// right after its first line, while they continue its text.
				let rest = null;
				docLines( c.text ).forEach( ( l, i ) => {
					if ( ! l || MARKER_ONLY.test( l ) ) {
						return;
					}
					// Every tag row of a new or edited comment, not only rows marked
					// new: a matching line elsewhere in the file must not hide one.
					const m = edited( c ) && L.terseTags?.exec( l );
					// LuaLS `---@param` lines are type annotations, not boilerplate.
					if ( m && ! /^---@/.test( c.text.split( '\n' )[ i ].trim() ) && ! origTags.get( String( c.anchor ) )?.has( tagKey( l, m[ 0 ] ) ) ) {
						added.push( `TERSE TAG ADDED: ${ f }:${ c.line + i } ${ m[ 0 ] }` );
					}
					if ( rest && rest.startsWith( l ) ) {
						rest = rest.slice( l.length ).trim();
						return;
					}
					rest = null;
					const e = tags.find( ( t ) => l.startsWith( t ) || t.startsWith( l ) );
					if ( e ) {
						rest = e.length > l.length ? e.slice( l.length ).trim() : null;
					} else {
						k++;
					}
				} );
			}
			const limit = header ? 2 * maxDoc : maxDoc;
			if ( grew && k > limit ) {
				fail( `LONG DOC COMMENT: ${ f }:${ g[ 0 ].line } (${ k } > ${ limit } lines)` );
			}
			added.forEach( fail );
		}
	}
}

failures.forEach( ( m ) => console.log( m ) );
if ( failures.length ) {
	console.log( `FAILED: ${ failures.length } problem(s) in ${ files.length } files` );
	process.exit( 1 );
}
console.log( `OK: ${ files.length } files, code identical (${ frozenCount } frozen comments/lines protected)` );
