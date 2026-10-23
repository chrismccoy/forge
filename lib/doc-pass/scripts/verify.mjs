#!/usr/bin/env node
/**
 * Proves that a documentation pass changed only comments.
 *
 * Usage: node verify.mjs <orig-dir> <current-dir> [--schema-tags] [--checked-types]
 *        [--list-frozen] [--line-limit <n>] [--files-from <list>] [relative files...]
 *        node verify.mjs <dir> --list-files [--list-skipped]
 *
 * `--checked-js` is accepted as an alias of `--checked-types`.
 *
 * With no file list, every in-scope file under <orig-dir> is checked. Runs
 * three checks per file (code, layout, comment-is-code) and exits non-zero
 * on any failure. With --list-frozen, also prints each frozen comment and
 * tag line of the original as `FROZEN: <file>:<line> <text>`. With
 * --line-limit, a new or edited comment line wider than <n> columns (tabs
 * count as 4) fails as `LONG COMMENT LINE: <file>:<line>`. With
 * --list-files, prints the in-scope files the walk finds under <dir>, one
 * relative path per line, and checks nothing; --list-skipped adds a
 * `SKIPPED: <file>` line for each source file it left out because it is
 * binary or marked generated, and a `SKIPPED DIR: <dir>/` line for each
 * pruned folder named like build output that holds source files. See
 * references/checker-spec.md for the specification.
 */

import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { layoutMismatch, model, parseArgs, walk } from './lib.mjs';

const { flags, values, rest, listed } = parseArgs( process.argv.slice( 2 ), [ '--schema-tags', '--checked-js', '--checked-types', '--list-frozen', '--list-files', '--list-skipped' ], [ '--line-limit' ] );
const checked = !! ( flags[ 'checked-js' ] || flags[ 'checked-types' ] );
const opts = { schemaTags: !! flags[ 'schema-tags' ], checkedJs: checked, checkedTypes: checked };
const [ origDir, curDir, ...only ] = rest;
const lineLimit = values[ 'line-limit' ] === undefined ? 0 : Number( values[ 'line-limit' ] );
if ( ! Number.isInteger( lineLimit ) || lineLimit < 0 ) {
	console.error( `--line-limit needs a whole number, got ${ values[ 'line-limit' ] }` );
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
	console.error( 'Usage: node verify.mjs <orig-dir> <current-dir> [--schema-tags] [--checked-types] [--list-frozen] [--line-limit <n>] [--files-from <list>] [files...]\n       node verify.mjs <dir> --list-files [--list-skipped]' );
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

	// New or edited comment lines must fit the line limit (tabs count as 4).
	// A line kept from the original comment (a long URL in a block that only
	// gained a summary) is not new, so it is not checked; nor is a trailing
	// comment whose code before it is already over the limit.
	if ( lineLimit ) {
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
		const width = ( t ) => [ ...t.replace( /\t/g, '    ' ) ].length;
		for ( const c of b.comments.filter( ( x ) => ! before.has( x.text ) ) ) {
			span( c, lines ).forEach( ( text, k ) => {
				if ( old.get( text.trim() ) > 0 ) {
					old.set( text.trim(), old.get( text.trim() ) - 1 );
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
}

failures.forEach( ( m ) => console.log( m ) );
if ( failures.length ) {
	console.log( `FAILED: ${ failures.length } problem(s) in ${ files.length } files` );
	process.exit( 1 );
}
console.log( `OK: ${ files.length } files, code identical (${ frozenCount } frozen comments/lines protected)` );
