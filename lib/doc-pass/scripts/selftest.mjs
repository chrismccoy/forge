#!/usr/bin/env node
/**
 * Tests verify.mjs on deliberately broken copies of real project files.
 *
 * Usage: node selftest.mjs <project> <work-dir> [--schema-tags] [--checked-types] [--files-from <list>] [relative files...]
 *
 * `--checked-js` is accepted as an alias of `--checked-types`.
 *
 * Copies a sample of the project's files (or the given ones) into
 * <work-dir>, applies one mutation per case, and runs verify.mjs on each
 * copy. Every case must produce its expected result: a comment-only edit
 * passes, a code edit fails the code check, a re-indent or joined line fails
 * the layout check, and edits to frozen or kept comments fail the
 * comment-is-code check. Prints PASS / FAIL / SKIPPED per case and exits
 * non-zero on any FAIL. Nothing is written outside <work-dir>.
 */

import { execFileSync } from 'node:child_process';
import { cpSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { dirname, extname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { JS_EXT, SFC_EXT, isTestFile, jsParse, langOf, model, parseArgs, splitSfc, walk } from './lib.mjs';
import { LANGS, langFor } from './langs.mjs';

const HERE = dirname( fileURLToPath( import.meta.url ) );
const { flags, rest, listed } = parseArgs( process.argv.slice( 2 ), [ '--schema-tags', '--checked-js', '--checked-types' ] );
const checked = !! ( flags[ 'checked-js' ] || flags[ 'checked-types' ] );
const passFlags = [ ...( flags[ 'schema-tags' ] ? [ '--schema-tags' ] : [] ), ...( checked ? [ '--checked-types' ] : [] ) ];
const [ project, work, ...given ] = rest;
// Directives that act on the next line, as in verify.mjs.
const NEXT_LINE = /next-line|@ts-(expect-error|ignore)|prettier-ignore|translators:|biome-ignore|deno-lint-ignore|noinspection|(istanbul|c8|v8)\s+ignore\s+(next|start|else|if)/;
if ( ! project || ! work ) {
	console.error( 'Usage: node selftest.mjs <project> <work-dir> [--schema-tags] [--checked-types] [--files-from <list>] [files...]' );
	process.exit( 2 );
}

/**
 * Lists the scripts in a file with their offsets.
 *
 * @param {string} f   Relative path.
 * @param {string} src File source.
 * @return {Array<{ast: Object, start: number}>} Parsed scripts; empty when unparsable.
 */
function scripts( f, src ) {
	const parts = SFC_EXT.has( extname( f ) )
		? splitSfc( src, f ).blocks.map( ( b ) => ( { src: b.content, lang: b.lang, start: b.start } ) )
		: [ { src, lang: langOf( f ), start: 0 } ];
	try {
		return parts.map( ( p ) => ( { ast: jsParse( p.src, p.lang ).ast, start: p.start } ) );
	} catch {
		return [];
	}
}

/**
 * Finds a top-level statement that starts its line and has no comment before it.
 *
 * @param {string} src File source.
 * @param {Array}  sc  Scripts from scripts().
 * @return {{lineStart: number, indent: string}|null} Where to insert before it.
 */
function bareStatement( src, sc ) {
	for ( const s of sc ) {
		for ( const n of s.ast.program.body ) {
			const at = s.start + n.start;
			const lineStart = src.lastIndexOf( '\n', at - 1 ) + 1;
			const indent = src.slice( lineStart, at );
			if ( /^[ \t]*$/.test( indent ) && ! ( n.leadingComments || [] ).length && lineStart > 0 ) {
				return { lineStart, indent };
			}
		}
	}
	return null;
}

/**
 * Finds the first numeric literal, or else the first identifier after the imports.
 *
 * @param {Array} sc Scripts from scripts().
 * @return {{start: number, end: number, text: string}|null} Replacement that changes code.
 */
function codeEdit( sc ) {
	let found = null;
	const visit = ( n, base ) => {
		if ( found || ! n || typeof n.type !== 'string' ) {
			return;
		}
		if ( n.type === 'NumericLiteral' ) {
			found = { start: base + n.start, end: base + n.end, text: String( n.value + 1 ) };
			return;
		}
		for ( const [ k, v ] of Object.entries( n ) ) {
			if ( k !== 'loc' && ! k.endsWith( 'Comments' ) && v && typeof v === 'object' ) {
				( Array.isArray( v ) ? v : [ v ] ).forEach( ( c ) => visit( c, base ) );
			}
		}
	};
	sc.forEach( ( s ) => visit( s.ast.program, s.start ) );
	if ( found ) {
		return found;
	}
	for ( const s of sc ) {
		for ( const t of s.ast.tokens ) {
			if ( t.type.label === 'name' && s.ast.program.body.some( ( n ) => n.type !== 'ImportDeclaration' && n.start <= t.start && t.end <= n.end ) ) {
				return { start: s.start + t.end, end: s.start + t.end, text: 'X' };
			}
		}
	}
	return null;
}

/**
 * Finds a line break right after `{`, `(`, `[` or `,` that can be joined.
 *
 * @param {string} src File source.
 * @param {Array}  sc  Scripts from scripts().
 * @return {{start: number, end: number, text: string}|null} Replacement that joins two code lines.
 */
function joinEdit( src, sc ) {
	for ( const s of sc ) {
		const tk = s.ast.tokens;
		for ( let i = 0; i < tk.length - 1; i++ ) {
			const a = tk[ i ];
			const b = tk[ i + 1 ];
			const label = a.type.label;
			if ( [ '{', '(', '[', ',' ].includes( label ) && b.loc.start.line === a.loc.end.line + 1 &&
				! /jsx|template|Comment/i.test( b.type.label || b.type ) && /^\s*$/.test( src.slice( s.start + a.end, s.start + b.start ) ) ) {
				return { start: s.start + a.end, end: s.start + b.start, text: ' ' };
			}
		}
	}
	return null;
}

/**
 * Finds a single blank line between two code tokens with no comment in between.
 *
 * @param {string} src File source.
 * @param {Array}  sc  Scripts from scripts().
 * @return {{start: number, end: number, text: string}|null} Replacement that deletes the blank line.
 */
function blankEdit( src, sc ) {
	for ( const s of sc ) {
		const tk = s.ast.tokens;
		for ( let i = 0; i < tk.length - 1; i++ ) {
			const a = tk[ i ];
			const b = tk[ i + 1 ];
			const gap = src.slice( s.start + a.end, s.start + b.start );
			// Not before `eof`: trailing blank lines have no following code line to compare.
			if ( ! /Comment|template|jsx|eof/i.test( ( a.type.label || a.type ) + ( b.type.label || b.type ) ) && /^[ \t]*\n[ \t]*\n[ \t]*$/.test( gap ) ) {
				const nl = s.start + a.end + gap.indexOf( '\n' );
				return { start: nl, end: nl + 1, text: '' };
			}
		}
	}
	return null;
}

const apply = ( src, e ) => src.slice( 0, e.start ) + e.text + src.slice( e.end );

// Pick sample files: per extension the first, the largest and a test file, plus
// the first files with frozen, kept and directive comments.
const all = given.length || listed ? given : walk( project );
const sample = new Map();
const largest = new Map();
const opts = { schemaTags: !! flags[ 'schema-tags' ], checkedJs: checked, checkedTypes: checked };
for ( const f of all ) {
	const src = readFileSync( join( project, f ), 'utf8' );
	const m = await model( f, src, opts );
	if ( m.error ) {
		continue;
	}
	const ext = extname( f );
	if ( src.length > ( largest.get( ext )?.size ?? -1 ) ) {
		largest.set( ext, { f, size: src.length } );
	}
	const tags = [ 'ext' + ext, ...( isTestFile( f ) ? [ 'test' + ext ] : [] ) ];
	if ( m.comments.some( ( c ) => c.whole ) ) {
		tags.push( 'frozen' );
	}
	if ( m.comments.some( ( c ) => c.kept.length ) ) {
		tags.push( 'kept' );
	}
	if ( m.comments.some( ( c ) => c.whole && ( m.nextLine === undefined ? NEXT_LINE : m.nextLine )?.test( c.text ) ) ) {
		tags.push( 'directive' );
	}
	for ( const t of tags ) {
		if ( ! sample.has( t ) ) {
			sample.set( t, f );
		}
	}
}
largest.forEach( ( v, ext ) => sample.set( 'largest' + ext, v.f ) );
const files = [ ...new Set( sample.values() ) ];
if ( ! files.length ) {
	console.log( 'FAIL: no parsable in-scope files to test with' );
	process.exit( 1 );
}

rmSync( work, { recursive: true, force: true } );
const orig = join( work, 'orig' );
for ( const f of files ) {
	mkdirSync( dirname( join( orig, f ) ), { recursive: true } );
	cpSync( join( project, f ), join( orig, f ) );
}

let failed = 0;
let n = 0;

/**
 * Runs verify.mjs on one mutated copy and checks the result.
 *
 * @param {string}      name   Case name.
 * @param {string}      f      Relative file.
 * @param {string|null} next   Mutated source, or null to skip the case.
 * @param {RegExp}      expect Pattern the verify output must match.
 * @param {RegExp}      [not]  Pattern the output must not match.
 */
function run( name, f, next, expect, not ) {
	if ( next === null ) {
		console.log( `SKIPPED ${ name }: ${ f }: nothing in the file to test with` );
		return;
	}
	const dir = join( work, `case-${ ++n }` );
	mkdirSync( dirname( join( dir, f ) ), { recursive: true } );
	writeFileSync( join( dir, f ), next );
	let out;
	try {
		out = execFileSync( 'node', [ join( HERE, 'verify.mjs' ), orig, dir, ...passFlags, f ], { encoding: 'utf8' } );
	} catch ( e ) {
		out = e.stdout || String( e );
	}
	const ok = expect.test( out ) && ! ( not && not.test( out ) );
	failed += ok ? 0 : 1;
	console.log( `${ ok ? 'PASS' : 'FAIL' } ${ name }: ${ f }${ ok ? '' : `\n  expected ${ expect }${ not ? ` and not ${ not }` : '' }, got:\n  ${ out.trim().split( '\n' ).join( '\n  ' ) }` }` );
}

for ( const f of files ) {
	const src = readFileSync( join( orig, f ), 'utf8' );
	const m = await model( f, src, opts );
	// A JS / TS file Babel cannot parse is checked with a tree-sitter grammar (model() in lib.mjs).
	const fallback = m.fallback ? m.lang.replace( /^ts:/, '' ) : null;
	const tsLang = ( ! JS_EXT.has( extname( f ) ) && ! SFC_EXT.has( extname( f ) ) && langFor( f ) ) || fallback;
	let mut;
	if ( tsLang ) {
		const { tsMutations } = await import( './treesitter.mjs' );
		mut = await tsMutations( tsLang, src );
	} else {
		const sc = scripts( f, src );
		mut = { prefix: '//', insert: bareStatement( src, sc ), codeEdit: codeEdit( sc ), joinEdit: joinEdit( src, sc ), blankEdit: blankEdit( src, sc ), indentSensitive: false };
	}
	const stmt = mut.insert;
	const ins = ( text ) => ( stmt ? src.slice( 0, stmt.lineStart ) + stmt.indent + text + '\n' + src.slice( stmt.lineStart ) : null );
	// A comment in the language's own form: `/** … */` where `//` is the line marker, else `# …` or `;; …`.
	const note = ( text ) => ( mut.prefix === '//' ? `/** ${ text } */` : `${ mut.prefix } ${ text }` );
	const docComment = note( 'Self-test comment.' );
	// Re-indenting a line changes the code itself in an indentation-sensitive language.
	const layoutOnly = mut.indentSensitive ? [ /^(LAYOUT|CODE) CHANGED/m ] : [ /^LAYOUT CHANGED/m, /^CODE CHANGED/m ];

	run( 'unchanged file passes', f, src, /^OK: 1 files/m );
	run( 'added doc comment passes', f, ins( docComment ), /^OK: 1 files/m );
	run( 'code edit is flagged', f, mut.codeEdit ? apply( src, mut.codeEdit ) : null, /^CODE CHANGED/m );
	run( 'reindented line is flagged', f, stmt ? src.slice( 0, stmt.lineStart ) + ' ' + src.slice( stmt.lineStart ) : null, ...layoutOnly );
	run( 'joined lines are flagged', f, mut.joinEdit ? apply( src, mut.joinEdit ) : null, /^LAYOUT CHANGED/m, /^CODE CHANGED/m );
	run( 'new lint directive is flagged', f, ins( `${ mut.prefix } cspell:disable-next-line` ), /^FROZEN COMMENT CHANGED/m );
	run( 'deleted blank line is flagged', f, mut.blankEdit ? apply( src, mut.blankEdit ) : null, /^LAYOUT CHANGED/m, /^CODE CHANGED/m );
	// A deprecation in the language's own form: a tag line no agent may add.
	const frozenTag = tsLang && ! fallback
		? [ '@deprecated Self-test.', 'Deprecated: Self-test.', '.. deprecated:: 1.0' ].find( ( t ) => LANGS[ tsLang ].frozenLine?.test( t ) )
		: '@deprecated Self-test.';
	run( 'new frozen tag line is flagged', f, frozenTag ? ins( note( frozenTag ) ) : null, /^FROZEN COMMENT CHANGED/m );

	const frozen = m.comments.find( ( c ) => c.whole );
	const at = ( c ) => {
		const lines = src.split( '\n' );
		const start = lines.slice( 0, c.line - 1 ).join( '\n' ).length + ( c.line > 1 ? 1 : 0 );
		return src.indexOf( c.text, start );
	};
	run( 'deleted frozen comment is flagged', f, frozen && at( frozen ) >= 0
		? src.slice( 0, at( frozen ) ) + src.slice( at( frozen ) + frozen.text.length )
		: null, /^FROZEN COMMENT CHANGED/m );

	// Only a directive that is already the last comment before its code.
	const lastBefore = new Map();
	m.comments.forEach( ( c ) => lastBefore.set( String( c.anchor ), c ) );
	const nextLine = m.nextLine === undefined ? NEXT_LINE : m.nextLine;
	// Trailing directives (anchor ending in `~`) apply to their own line, so nothing can wedge in.
	const directive = nextLine && m.comments.find( ( c ) => c.whole && nextLine.test( c.text ) && ! String( c.anchor ).endsWith( '~' ) && lastBefore.get( String( c.anchor ) ) === c );
	if ( directive && at( directive ) >= 0 ) {
		const end = at( directive ) + directive.text.length;
		const indent = /[ \t]*$/.exec( src.slice( 0, at( directive ) ) )[ 0 ];
		run( 'comment between directive and its code is flagged', f, src.slice( 0, end ) + '\n' + indent + note( 'Wedged in.' ) + src.slice( end ), /^FROZEN COMMENT CHANGED/m );
	} else {
		run( 'comment between directive and its code is flagged', f, null );
	}

	const kept = m.comments.find( ( c ) => c.kept.length && ! c.whole );
	let keptEdit = null;
	if ( kept && at( kept ) >= 0 ) {
		const tag = kept.kept[ 0 ].split( ' ' )[ 0 ];
		const body = kept.text.split( '\n' ).filter( ( l ) => ! l.includes( tag ) ).join( '\n' );
		const whole = body.trimStart().startsWith( '/*' ) && body.includes( '*/' );
		keptEdit = src.slice( 0, at( kept ) ) + ( whole ? body : note( 'Kept line removed.' ) ) + src.slice( at( kept ) + kept.text.length );
	}
	run( 'removed kept tag line is flagged', f, keptEdit, /^FROZEN COMMENT CHANGED/m );

	if ( SFC_EXT.has( extname( f ) ) ) {
		// After the first closing `</script>`, or after an Astro frontmatter's closing fence.
		const close = /<\/script\s*>|(?<=^\uFEFF?---[ \t]*\r?\n[\s\S]*?\n)---[ \t]*(?=\r?\n)/;
		run( 'blank line in component markup is flagged', f, close.test( src ) ? src.replace( close, ( t ) => t + '\n' ) : null, /^CODE CHANGED: .*markup/m );
	}
}

console.log( failed ? `SELFTEST FAILED: ${ failed } case(s)` : `SELFTEST OK: ${ files.length } sample files` );
process.exit( failed ? 1 : 0 );
