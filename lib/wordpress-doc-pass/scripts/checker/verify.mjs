#!/usr/bin/env node
/**
 * Proves that a documentation pass changed only comments.
 *
 * Usage: node verify.mjs <orig-dir> <current-dir> [relative files...]
 *        [--terse [--max-doc-lines <n>] [--checked-php] [--checked-js]]
 *
 * With no file list, every in-scope file under <orig-dir> is checked. Runs
 * three checks per file (code, layout, comment-is-code) and exits non-zero
 * on any failure. With --terse (terse comment style) it also fails a new or
 * edited doc comment with more than --max-doc-lines prose lines (default 3,
 * a file header twice that) as `LONG DOC COMMENT`, and a new `@param`,
 * `@return`, `@throws` or `@var` line as `TERSE TAG ADDED`. --checked-php
 * and --checked-js say that a tool reads the doc types of PHP or JS files
 * (--checked-types means both). See
 * references/checker-spec.md for the specification.
 */

import { existsSync, readFileSync } from 'node:fs';
import { basename, extname, join, resolve } from 'node:path';
import { PHP_EXT, cliNames, commentRows, gettextAhead, model, phpTokenize, walk } from './lib.mjs';

// Terse flags; without --terse the run is the full style, unchanged.
const argv = process.argv.slice( 2 );
const terse = argv.includes( '--terse' );
const checkedPhp = argv.includes( '--checked-php' ) || argv.includes( '--checked-types' );
const checkedJs = argv.includes( '--checked-js' ) || argv.includes( '--checked-types' );
const BARE_FLAGS = new Set( [ '--terse', '--checked-types', '--checked-php', '--checked-js' ] );
// `--max-doc-lines <n>` or `--max-doc-lines=<n>`.
const maxAt = argv.findIndex( ( a ) => a === '--max-doc-lines' || a.startsWith( '--max-doc-lines=' ) );
const maxJoined = maxAt >= 0 && argv[ maxAt ].includes( '=' );
const maxRaw = maxAt < 0 ? undefined : ( maxJoined ? argv[ maxAt ].slice( argv[ maxAt ].indexOf( '=' ) + 1 ) : argv[ maxAt + 1 ] );
const maxDoc = maxAt < 0 ? 3 : Number( maxRaw );
if ( maxAt >= 0 && ( maxRaw === undefined || maxRaw === '' || ! Number.isInteger( maxDoc ) || maxDoc < 1 ) ) {
	console.error( `--max-doc-lines needs a whole number of at least 1, got ${ maxRaw }` );
	process.exit( 2 );
}
const [ origDir, curDir, ...only ] = argv.filter( ( a, i ) => ! BARE_FLAGS.has( a ) && i !== maxAt && ( maxAt < 0 || maxJoined || i !== maxAt + 1 ) );
if ( ! origDir || ! curDir ) {
	console.error( 'Usage: node verify.mjs <orig-dir> <current-dir> [files...] [--terse [--max-doc-lines <n>] [--checked-php] [--checked-js]]' );
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

// --- Terse checks ----------------------------------------------------------

// Tags terse never adds; `@global` is tracked only so a kept one does not count.
const TERSE_TAG = /^@(param|returns?|throws|var|global)\b/;
// Rows that carry no prose: rules and lone markers.
const MARKER_ONLY = /^([-=~*#_/]+|[{}])$/;
// Hook calls whose docblock keeps its full form in terse.
const HOOK_CALLS = new Set( [
	'do_action', 'do_action_ref_array', 'do_action_deprecated',
	'apply_filters', 'apply_filters_ref_array', 'apply_filters_deprecated',
] );
// Code that starts a declaration, so the doc comment above it is its own.
const DECL_START = /^(T_CLASS|T_INTERFACE|T_TRAIT|T_ENUM|T_FUNCTION|T_ABSTRACT|T_FINAL|T_READONLY|T_ATTRIBUTE|T_CONST)\u0000/;
// Words allowed before a hook call in a hook docblock's statement: an
// assignment target (`$x =`, `$this->x =`), a cast, `return`, `echo`, `!`.
const HOOK_PREFIX = new Set( [ '=', '.=', '+=', '??=', '->', '?->', 'return', 'echo', 'print', '!', '(int)', '(integer)', '(bool)', '(boolean)', '(string)', '(array)', '(float)', '(double)' ] );
// Folders whose PHP files are templates or views.
const TEMPLATE_DIR = /(^|\/)(template-parts|templates|views|partials)\//;

/**
 * Reduces a tag line to tag plus name, or tag plus type for a nameless tag.
 *
 * `@param int $id Note ID.` gives `@param $id`; `@param {number} [id=1]`
 * gives `@param id`; `@return int The total.` and `@var int` give the type.
 *
 * @param {string} l   Normalized comment row.
 * @param {string} tag The matched tag.
 * @return {string} Key.
 */
function tagKey( l, tag ) {
	const t = tag === '@returns' ? '@return' : tag;
	let rest = l.slice( tag.length ).trim();
	let type = '';
	let braced = false;
	if ( ! /^[$&.]/.test( rest ) ) {
		// A type: braced (JS) or a PHP type, whose brackets may hold spaces.
		let depth = 0;
		let i = 0;
		for ( ; i < rest.length; i++ ) {
			const ch = rest[ i ];
			if ( '{<([' .includes( ch ) ) {
				depth++;
			} else if ( '}>)]'.includes( ch ) ) {
				depth--;
			} else if ( /\s/.test( ch ) && depth <= 0 ) {
				break;
			}
		}
		braced = rest.startsWith( '{' );
		type = rest.slice( 0, i ).replace( /\s+/g, '' );
		rest = rest.slice( i ).trim();
	}
	const word = rest.split( /\s/ )[ 0 ];
	if ( /^@(param|var|global)$/.test( t ) ) {
		const php = word.match( /^[&.]*\$(\w+)/ );
		if ( php ) {
			return `${ t } $${ php[ 1 ] }`;
		}
		const js = braced && word.match( /^\[?([\w$.]+)/ );
		if ( js ) {
			return `${ t } ${ js[ 1 ] }`;
		}
	}
	return `${ t } {${ type }}`;
}

/**
 * Tells whether a hook call starts within the statement after a comment.
 *
 * @param {Object} m      Model from model().
 * @param {number} anchor Index of the first code token after the comment.
 * @return {boolean} True when the comment documents a hook.
 */
function hookAhead( m, anchor ) {
	const w = m.words;
	let seenIf = false;
	for ( let i = anchor; i < w.length - 1; i++ ) {
		const word = w[ i ].replace( /\s+/g, '' );
		const prev = i > anchor ? w[ i - 1 ].trim() : '';
		if ( HOOK_CALLS.has( word.replace( /^\\/, '' ) ) && w[ i + 1 ].trim() === '(' ) {
			return ! [ '->', '?->', '::' ].includes( prev );
		}
		if ( /^\$\w+$/.test( word ) || HOOK_PREFIX.has( word ) || ( /^\w+$/.test( word ) && ( prev === '->' || prev === '?->' ) ) ) {
			continue;
		}
		// `self::$x`, `static::$x`, `Foo::$x`: a class name, `::`, then a variable.
		if ( /^\\?[\w\\]+$/.test( word ) && w[ i + 1 ].trim() === '::' && /^\$\w+$/.test( w[ i + 2 ]?.trim() || '' ) ) {
			i++;
			continue;
		}
		// A balanced index after a variable or property: `$q['k']`, `$a[ $k ]`.
		if ( word === '[' && ( /^\$\w+$/.test( prev ) || prev === ']' || /^\w+$/.test( prev ) ) ) {
			let depth = 0;
			for ( ; i < w.length - 1; i++ ) {
				const t = w[ i ].trim();
				if ( t === '[' ) {
					depth++;
				} else if ( t === ']' && --depth === 0 ) {
					break;
				} else if ( t === ';' || t === '{' || t === '}' ) {
					return false;
				}
			}
			continue;
		}
		// One `if (` may open the statement: `if ( apply_filters( … ) )`.
		if ( word === 'if' && ! seenIf && i === anchor && w[ i + 1 ].trim() === '(' ) {
			seenIf = true;
			i++;
			continue;
		}
		return false;
	}
	return false;
}

/**
 * Tells whether a PHP file is a template or view, whose file header lists
 * the variables it reads: a file in a template folder, a theme root file
 * other than functions.php, a file with HTML outside `<?php ?>`, or a file
 * with no class or named function.
 *
 * @param {string} f Relative path.
 * @param {Object} m Model from model().
 * @return {boolean} True for a template.
 */
function isTemplate( f, m ) {
	if ( m.lang !== 'php' ) {
		return false;
	}
	if ( TEMPLATE_DIR.test( f ) ) {
		return true;
	}
	if ( ! f.includes( '/' ) && basename( f ) !== 'functions.php' ) {
		const css = join( curDir, 'style.css' );
		if ( existsSync( css ) && /Theme Name\s*:/i.test( readFileSync( css, 'utf8' ) ) ) {
			return true;
		}
	}
	if ( m.code.some( ( c ) => c.key.startsWith( 'T_INLINE_HTML\u0000' ) && c.key.split( '\u0000' )[ 1 ].trim() ) ) {
		return true;
	}
	return ! m.decls.some( ( d ) => /^(class|interface|trait|enum|function|method)$/.test( d.type ) );
}

/**
 * Finds the file header doc comments of a file.
 *
 * PHP: doc comments between the first `<?php` and the first statement,
 * except the last one when that statement is a declaration (it is the
 * declaration's own), or, outside templates, a variable assignment. JS: doc
 * comments before the first token, with the same exception.
 *
 * @param {Object}  m        Model from model().
 * @param {boolean} template Whether the file is a template.
 * @return {Set<Object>} Header comments.
 */
function headerComments( m, template ) {
	let at = 0;
	let decl = false;
	if ( m.lang === 'php' ) {
		const open = m.code.findIndex( ( c ) => c.key.startsWith( 'T_OPEN_TAG\u0000' ) );
		if ( open < 0 ) {
			return new Set();
		}
		at = open + 1;
		// Outside templates, a doc above a first `$var = …` documents that variable.
		decl = DECL_START.test( m.code[ at ]?.key || '' ) || ( ! template && /^T_VARIABLE\u0000/.test( m.code[ at ]?.key || '' ) );
	} else {
		decl = /^(FunctionDeclaration|ClassDeclaration|Export(Named|Default)Declaration)$/.test( m.ast.program.body[ 0 ]?.type || '' );
	}
	const docs = m.comments.filter( ( c ) => c.anchor === at && c.text.startsWith( '/**' ) );
	if ( decl && docs.length ) {
		const last = docs[ docs.length - 1 ];
		const endLine = last.line + ( last.text.match( /\n/g ) || [] ).length;
		// Outside templates, a doc above a first `$var = …` is still the file
		// header when a blank line follows it or it names the `@package`.
		const varFirst = m.lang === 'php' && /^T_VARIABLE\u0000/.test( m.code[ at ]?.key || '' );
		const fileDoc = varFirst && ( m.code[ at ].line > endLine + 1 || /@(sub)?package\b/.test( last.text ) );
		if ( ! fileDoc ) {
			docs.pop();
		}
	}
	return new Set( docs );
}

/**
 * Runs the terse checks on one file whose code matched.
 *
 * Only new or edited doc comments are checked. A row counts toward the
 * limit unless it is blank, marker-only, a Frozen or Kept line, a
 * `This … is documented in …` line, a `@var` line of the file header
 * (template variables), a carried-over `@global` line or, with
 * --checked-php (PHP files) or --checked-js (JS files), a carried-over
 * typed tag; the rows that continue one of those (up to a blank row or the
 * next tag) do not count either. A docblock whose next code is a hook
 * call is exempt.
 *
 * @param {string} f        Relative path, for messages.
 * @param {Object} a        Original model.
 * @param {Object} b        Current model.
 * @param {string} origSrc  Original source.
 * @param {string} curSrc   Current source.
 * @return {string[]} Failure lines.
 */
function terseCheck( f, a, b, origSrc, curSrc ) {
	const out = [];
	// Lines of new or edited comments, each marked new unless it repeats a
	// line of an original comment that changed.
	// A comment is unchanged only when the same text sits at the same anchor,
	// so a copy of another comment moved above new code counts as new.
	const at = ( c ) => c.anchor + '\u0000' + c.text;
	const before = new Set( a.comments.map( at ) );
	const after = new Set( b.comments.map( at ) );
	const span = ( c, lines ) => lines.slice( c.line - 1, c.line + ( c.text.match( /\n/g ) || [] ).length );
	const origLines = origSrc.split( /\r?\n/ );
	const old = new Map();
	for ( const c of a.comments.filter( ( x ) => ! after.has( at( x ) ) ) ) {
		for ( const l of span( c, origLines ) ) {
			old.set( l.trim(), ( old.get( l.trim() ) || 0 ) + 1 );
		}
	}
	const curLines = curSrc.split( /\r?\n/ );
	// Tag keys of the original comments, per anchor.
	const origTags = new Map();
	for ( const c of a.comments ) {
		for ( const l of commentRows( c.text ) ) {
			const m = TERSE_TAG.exec( l );
			if ( m ) {
				origTags.set( c.anchor, ( origTags.get( c.anchor ) || new Set() ).add( tagKey( l, m[ 0 ] ) ) );
			}
		}
	}
	const template = isTemplate( f, b );
	const header = headerComments( b, template );
	for ( const c of b.comments ) {
		if ( c.whole || ! c.text.startsWith( '/**' ) || before.has( at( c ) ) || hookAhead( b, c.anchor ) ) {
			continue;
		}
		const fresh = span( c, curLines ).map( ( text ) => {
			if ( old.get( text.trim() ) > 0 ) {
				old.set( text.trim(), old.get( text.trim() ) - 1 );
				return false;
			}
			return true;
		} );
		// The limit applies only when a line is new; the tag rule applies to
		// every edited comment, because a tag line can repeat the text of a
		// line in another changed comment.
		const countLines = fresh.some( Boolean );
		const isHeader = header.has( c );
		const had = origTags.get( c.anchor ) || new Set();
		let k = 0;
		let carry = false;
		// Open braces of a carried tag's hash (`@var array $args {`), so the
		// carry lasts to the matching `}` across blank rows.
		let braces = 0;
		const added = [];
		commentRows( c.text ).forEach( ( l, i ) => {
			const opened = ( l.match( /{/g ) || [] ).length - ( l.match( /}/g ) || [] ).length;
			const tagRow = TERSE_TAG.exec( l );
			if ( carry && braces > 0 ) {
				// An unclosed hash ends at the next parameter, return, error or variable tag.
				if ( ! tagRow || tagRow[ 1 ] === 'global' ) {
					braces += opened;
					return;
				}
				carry = false;
				braces = 0;
			}
			if ( ! l || MARKER_ONLY.test( l ) ) {
				carry = false;
				return;
			}
			const m = TERSE_TAG.exec( l );
			const key = m && tagKey( l, m[ 0 ] );
			const templateVar = template && isHeader && m?.[ 1 ] === 'var';
			if ( m && m[ 1 ] !== 'global' && ! templateVar && ! had.has( key ) ) {
				added.push( `TERSE TAG ADDED: ${ f }:${ c.line + i } ${ m[ 0 ] }` );
			}
			if ( l.startsWith( '@' ) || /\bis documented in\b/.test( l ) ) {
				carry = c.frozen.includes( l ) || c.kept.includes( l ) || templateVar ||
					/^This\b.*\bis documented in\b/.test( l ) ||
					( m && had.has( key ) && ( m[ 1 ] === 'global' || ( PHP_EXT.has( extname( f ) ) ? checkedPhp : checkedJs ) ) );
				braces = carry ? Math.max( 0, opened ) : 0;
				if ( ! carry ) {
					k++;
				}
				return;
			}
			if ( carry ) {
				return;
			}
			if ( ! c.frozen.includes( l ) && ! c.kept.includes( l ) ) {
				k++;
			}
		} );
		const limit = isHeader ? 2 * maxDoc : maxDoc;
		if ( countLines && k > limit ) {
			out.push( `LONG DOC COMMENT: ${ f }:${ c.line } (${ k } > ${ limit } lines)` );
		}
		out.push( ...added );
	}
	return out;
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
	// A new translators comment is allowed when it is the last comment before
	// code that reaches a gettext call within the same statement, and no
	// translators comment sat there before.
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

	if ( terse ) {
		terseCheck( f, a, b, readFileSync( origPath, 'utf8' ), readFileSync( curPath, 'utf8' ) ).forEach( fail );
	}
}

failures.forEach( ( m ) => console.log( m ) );
if ( failures.length ) {
	console.log( `FAILED: ${ failures.length } problem(s) in ${ files.length } files` );
	process.exit( 1 );
}
console.log( `OK: ${ files.length } files, code identical (${ frozenCount } frozen comments/lines protected)` );
