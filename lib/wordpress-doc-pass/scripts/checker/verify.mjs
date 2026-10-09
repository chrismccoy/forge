#!/usr/bin/env node
/**
 * Proves that a documentation pass changed only comments.
 *
 * Usage: node verify.mjs <orig-dir> <current-dir> [relative files...]
 *
 * With no file list, every in-scope file under <orig-dir> is checked. Runs
 * three checks per file (code, layout, comment-is-code) and exits non-zero
 * on any failure. See references/checker-spec.md for the specification.
 */

import { existsSync, readFileSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';
import { PHP_EXT, cliNames, gettextAhead, model, phpTokenize, walk } from './lib.mjs';

const [ origDir, curDir, ...only ] = process.argv.slice( 2 );
if ( ! origDir || ! curDir ) {
	console.error( 'Usage: node verify.mjs <orig-dir> <current-dir> [files...]' );
	process.exit( 2 );
}

const files = only.length ? only : walk( origDir );
const failures = [];
const fail = ( msg ) => failures.push( msg );

// WP-CLI commands can be registered in a different file from their class, so
// collect the names across the whole original tree first.
const cli = new Set();
for ( const f of walk( origDir ) ) {
	if ( PHP_EXT.has( extname( f ) ) ) {
		cliNames( readFileSync( join( origDir, f ), 'utf8' ) ).forEach( ( n ) => cli.add( n ) );
	}
}

const phpPaths = [];
for ( const f of files ) {
	if ( PHP_EXT.has( extname( f ) ) ) {
		phpPaths.push( resolve( origDir, f ) );
		if ( existsSync( join( curDir, f ) ) ) {
			phpPaths.push( resolve( curDir, f ) );
		}
	}
}
const phpTokens = phpPaths.length ? phpTokenize( phpPaths ) : {};

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

const show = ( entry ) => JSON.stringify( entry.split( '\u0000' )[ 1 ].slice( 0, 100 ) );

let frozenCount = 0;
for ( const f of files ) {
	const origPath = join( origDir, f );
	const curPath = join( curDir, f );
	if ( ! existsSync( curPath ) ) {
		fail( `CODE CHANGED: ${ f }: file missing` );
		continue;
	}
	const a = model( f, readFileSync( origPath, 'utf8' ), phpTokens[ resolve( origPath ) ], cli );
	const b = model( f, readFileSync( curPath, 'utf8' ), phpTokens[ resolve( curPath ) ], cli );
	if ( a.error ) {
		fail( `CODE CHANGED: ${ f }: original ${ a.error }` );
		continue;
	}
	if ( b.error ) {
		fail( `CODE CHANGED: ${ f }: ${ b.error }` );
		continue;
	}

	// 1. Code check.
	if ( a.lang === 'php' ) {
		const n = Math.min( a.code.length, b.code.length );
		let i = 0;
		while ( i < n && a.code[ i ].key === b.code[ i ].key ) {
			i++;
		}
		if ( i < n || a.code.length !== b.code.length ) {
			const at = b.code[ Math.min( i, b.code.length - 1 ) ];
			fail( `CODE CHANGED: ${ f }:${ at ? at.line : 0 }` );
			continue;
		}
	} else if ( a.code !== b.code ) {
		fail( `CODE CHANGED: ${ f }` );
		continue;
	}

	// 2. Layout check.
	const la = a.layout;
	const lb = b.layout;
	for ( let i = 0; i < Math.max( la.length, lb.length ); i++ ) {
		if ( ! la[ i ] || ! lb[ i ] || la[ i ].text !== lb[ i ].text ) {
			const at = lb[ i ] || lb[ lb.length - 1 ];
			fail( `LAYOUT CHANGED: ${ f }:${ at ? at.line : 0 }` );
			break;
		}
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
		fail( `FROZEN COMMENT CHANGED: ${ f }: removed or edited ${ show( e ) }` );
	}
	// A new translators comment is allowed when it is the last comment directly
	// before a statement that calls gettext and that statement had none before.
	const lastBy = ( comments ) => {
		const m = new Map();
		comments.forEach( ( c ) => m.set( c.anchor, c ) );
		return m;
	};
	const hadTranslators = new Set( a.comments.filter( ( c ) => /translators:/i.test( c.text ) ).map( ( c ) => c.anchor ) );
	const lastInB = lastBy( b.comments );
	const newTranslatorsOk = ( e ) => {
		const [ anchor, text ] = e.split( '\u0000' );
		const at = Number( anchor );
		return /^(\/\*|\/\/)\s*translators:/i.test( text ) &&
			! hadTranslators.has( at ) &&
			lastInB.get( at )?.text.trim() === text &&
			gettextAhead( b, at );
	};
	for ( const e of missing( wholeB, wholeA ) ) {
		if ( ! newTranslatorsOk( e ) ) {
			fail( `FROZEN COMMENT CHANGED: ${ f }: added ${ show( e ) }` );
		}
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

	// A translators comment that was the last comment before its call must stay last.
	const lastAt = ( comments ) => {
		const m = new Map();
		comments.forEach( ( c ) => m.set( c.anchor, c ) );
		return m;
	};
	const lastA = lastAt( a.comments );
	const lastB = lastAt( b.comments );
	for ( const [ anchor, c ] of lastA ) {
		if ( /translators:/i.test( c.text ) && lastB.get( anchor )?.text.trim() !== c.text.trim() ) {
			fail( `FROZEN COMMENT CHANGED: ${ f }: translators comment no longer directly before its call (line ${ c.line })` );
		}
	}
}

failures.forEach( ( m ) => console.log( m ) );
if ( failures.length ) {
	console.log( `FAILED: ${ failures.length } problem(s) in ${ files.length } files` );
	process.exit( 1 );
}
console.log( `OK: ${ files.length } files, code identical (${ frozenCount } frozen comments/lines protected)` );
