/**
 * Shared parsing and comment classification for the doc-pass checker.
 *
 * PHP is tokenized by php-tokens.php (PHP's own token_get_all), so the
 * checker sees exactly what the PHP engine sees. JS / TS is parsed with
 * @babel/parser.
 */

import { execFileSync } from 'node:child_process';
import { readdirSync, statSync } from 'node:fs';
import { dirname, extname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { parse as babelParse } from '@babel/parser';

const HERE = dirname( fileURLToPath( import.meta.url ) );

export const PHP_EXT = new Set( [ '.php', '.inc', '.phtml' ] );
export const JS_EXT = new Set( [ '.js', '.jsx', '.mjs', '.cjs', '.ts', '.tsx' ] );
const SKIP_DIRS = new Set( [ 'vendor', 'node_modules', 'build', 'dist', '.git' ] );

/**
 * Lists in-scope source files under a directory, as paths relative to it.
 *
 * @param {string} root Directory to walk.
 * @return {string[]} Relative paths, sorted.
 */
export function walk( root ) {
	const out = [];
	const visit = ( dir ) => {
		for ( const name of readdirSync( dir ) ) {
			const full = join( dir, name );
			if ( statSync( full ).isDirectory() ) {
				if ( ! SKIP_DIRS.has( name ) && ! name.startsWith( '.' ) ) {
					visit( full );
				}
				continue;
			}
			const ext = extname( name );
			if ( name.endsWith( '.min.js' ) ) {
				continue;
			}
			if ( PHP_EXT.has( ext ) || JS_EXT.has( ext ) ) {
				out.push( relative( root, full ) );
			}
		}
	};
	visit( root );
	return out.sort();
}

/**
 * Tokenizes PHP files with the PHP engine, in batches.
 *
 * @param {string[]} files Absolute paths.
 * @return {Object<string, Array|null>} Tokens per path; null when unreadable.
 */
export function phpTokenize( files ) {
	const out = {};
	for ( let i = 0; i < files.length; i += 100 ) {
		const batch = files.slice( i, i + 100 );
		const json = execFileSync( 'php', [ join( HERE, 'php-tokens.php' ), ...batch ], {
			maxBuffer: 1024 * 1024 * 512,
		} );
		Object.assign( out, JSON.parse( json ) );
	}
	return out;
}

/**
 * Parses JS / TS source with Babel.
 *
 * @param {string} src  Source text.
 * @param {string} file Path, used to pick parser plugins.
 * @return {Object} Babel File node, with tokens.
 */
export function jsParse( src, file ) {
	const ext = extname( file );
	const plugins = [];
	if ( ext === '.ts' ) {
		plugins.push( 'typescript' );
	} else if ( ext === '.tsx' ) {
		plugins.push( 'typescript', 'jsx' );
	} else {
		plugins.push( 'jsx' );
	}
	return babelParse( src, {
		sourceType: 'unambiguous',
		plugins,
		tokens: true,
		errorRecovery: false,
		allowReturnOutsideFunction: true,
	} );
}

const AST_DROP = new Set( [
	'start', 'end', 'loc', 'range', 'comments', 'leadingComments', 'trailingComments',
	'innerComments', 'extra', 'tokens', 'errors',
] );

/**
 * Serializes a Babel AST with positions and comments removed.
 *
 * @param {Object} ast Babel File node.
 * @return {string} Canonical JSON.
 */
export function jsCanonical( ast ) {
	return JSON.stringify( ast, ( k, v ) => ( AST_DROP.has( k ) ? undefined : v ) );
}

// --- Comment classes -------------------------------------------------------

// Whole comment frozen: lint / tool directives, translator comments, bundler
// hints, license headers and WP-CLI help docblocks.
const FROZEN_WHOLE = [
	/phpcs:(ignore|disable|enable)/i,
	/@codingStandardsIgnore/,
	/eslint-(disable|enable)/,
	/^\/\*\s*(global|globals|eslint-env)\s/,
	/^\/\/\s*@ts-/,
	/prettier-ignore/,
	/istanbul ignore/,
	/c8 ignore/,
	/translators:/i,
	/[#@]__PURE__/,
	/webpack[A-Z]\w*\s*:/,
	/@jsx(Runtime|ImportSource|Frag)?\b/,
	/^(\/\/|\/\*)\s*@flow\b/,
	/^\/\*!/,
	/@preserve\b/,
	/##\s+(OPTIONS|EXAMPLES|GLOBAL PARAMETERS)/,
	/^\s*\*\s*@(subcommand|alias|when)\b/m,
];

// License text: frozen whole, unless the comment is a plugin / template header,
// where only the matching lines are frozen.
const LICENSE = /(Copyright|©|SPDX-License-Identifier|GNU General Public License|@license\b)/;

// Single lines frozen wherever they appear: behavior annotations read by
// PHPUnit / Doctrine, and file header fields read by WordPress.
const FROZEN_LINE = [
	/^@(test|dataProvider|depends|group|ticket|covers\w*|uses|requires|runInSeparateProcess|runTestsInSeparateProcesses|preserveGlobalState|backupGlobals|backupStaticAttributes|doesNotPerformAssertions|expectedException\w*|expectedDeprecated|expectedIncorrectUsage|before\w*|after\w*|testWith|noinspection|codeCoverageIgnore\w*)\b/,
	/^@([A-Z]\w*|\w+\\)/,
	/^(Plugin Name|Plugin URI|Description|Version|Requires at least|Requires PHP|Tested up to|Author|Author URI|License|License URI|Text Domain|Domain Path|Network|Update URI|Requires Plugins|Template Name|Template Post Type|WC requires at least|WC tested up to)\s*:/,
];
const HEADER_FIELD = FROZEN_LINE[ 2 ];

// Lines that must survive but may gain siblings.
const KEPT_LINE = [
	/^@(since|deprecated|see|link|internal|ignore)\b/,
	/^@(phpstan|psalm)-\S+/,
	/^@template\S*/,
	/^@var\s+\S*[<{]/,
];

/**
 * Splits a comment into trimmed content lines with comment markers removed.
 *
 * @param {string} text Raw comment text.
 * @return {string[]} Non-empty lines, internal whitespace collapsed.
 */
function commentLines( text ) {
	return text
		.replace( /^\/\*\*?|\*\/$/g, '' )
		.split( '\n' )
		.map( ( l ) => l.replace( /^\s*(\*|\/\/|#)?\s*/, '' ).replace( /\s+/g, ' ' ).trim() )
		.filter( Boolean );
}

/**
 * Classifies one comment.
 *
 * @param {string}  text      Raw comment text.
 * @param {boolean} cliFrozen Whether structure marks it as a WP-CLI docblock.
 * @return {{whole: boolean, frozen: string[], kept: string[]}} Classification.
 */
export function classify( text, cliFrozen = false ) {
	const lines = commentLines( text );
	const isHeader = lines.some( ( l ) => HEADER_FIELD.test( l ) );
	const whole = cliFrozen ||
		FROZEN_WHOLE.some( ( re ) => re.test( text ) ) ||
		( ! isHeader && LICENSE.test( text ) );
	const frozen = [];
	const kept = [];
	if ( ! whole ) {
		for ( const l of lines ) {
			if ( FROZEN_LINE.some( ( re ) => re.test( l ) ) || ( isHeader && LICENSE.test( l ) ) ) {
				frozen.push( l );
			} else if ( KEPT_LINE.some( ( re ) => re.test( l ) ) ) {
				kept.push( l );
			}
		}
	}
	return { whole, frozen, kept };
}

// --- PHP structure ----------------------------------------------------------

const MODIFIERS = new Set( [
	'T_ABSTRACT', 'T_FINAL', 'T_PUBLIC', 'T_PROTECTED', 'T_PRIVATE', 'T_STATIC', 'T_READONLY', 'T_VAR',
	'T_PUBLIC_SET', 'T_PROTECTED_SET', 'T_PRIVATE_SET',
] );
const TYPE_TOKENS = new Set( [
	'T_STRING', 'T_NAME_QUALIFIED', 'T_NAME_FULLY_QUALIFIED', 'T_NAME_RELATIVE', 'T_ARRAY', 'T_CALLABLE',
	'?', '|', '&', '(', ')', 'T_AMPERSAND_FOLLOWED_BY_VAR_OR_VARARG', 'T_AMPERSAND_NOT_FOLLOWED_BY_VAR_OR_VARARG',
] );
const CLASS_KW = new Set( [ 'T_CLASS', 'T_INTERFACE', 'T_TRAIT', 'T_ENUM' ] );
const OPEN_BRACE = new Set( [ '{', 'T_CURLY_OPEN', 'T_DOLLAR_OPEN_CURLY_BRACES' ] );
const STMT_BOUNDARY = new Set( [ ';', '{', '}', 'T_OPEN_TAG', 'T_CLOSE_TAG', 'T_INLINE_HTML' ] );
export const HOOK_FUNCS = new Set( [ 'apply_filters', 'apply_filters_ref_array', 'do_action', 'do_action_ref_array' ] );

const bare = ( name ) => name.replace( /^\\/, '' ).split( '\\' ).pop();

/**
 * Collects names registered with WP_CLI::add_command, from raw source.
 *
 * @param {string} src PHP source.
 * @return {string[]} Class or function names, without namespace.
 */
export function cliNames( src ) {
	const out = [];
	const re = /WP_CLI::add_command\(\s*['"][^'"]+['"]\s*,\s*(?:['"]\\?([\w\\]+)(?:::\w+)?['"]|\\?([\w\\]+)::class|array\(\s*['"]?\\?([\w\\]+)|\[\s*['"]?\\?([\w\\]+))/g;
	let m;
	while ( ( m = re.exec( src ) ) ) {
		out.push( bare( m[ 1 ] || m[ 2 ] || m[ 3 ] || m[ 4 ] ) );
	}
	return out;
}

/**
 * Finds declarations, hook calls and their docblocks in a PHP token list.
 *
 * @param {Array}       tokens PHP tokens from php-tokens.php.
 * @param {Set<string>} cli    WP-CLI command class / function names.
 * @return {Object[]} Declarations: {type, name, line, docIdx, cli, start}.
 */
export function phpDecls( tokens, cli = new Set() ) {
	const code = [];
	tokens.forEach( ( t, i ) => {
		if ( t[ 0 ] === 'code' ) {
			code.push( i );
		}
	} );
	const name = ( ci ) => ( ci >= 0 && ci < code.length ? tokens[ code[ ci ] ][ 1 ] : null );
	const text = ( ci ) => ( ci >= 0 && ci < code.length ? tokens[ code[ ci ] ][ 2 ] : null );

	// Walks back over modifiers, types and attributes to the declaration start.
	const declStart = ( ci, withTypes ) => {
		let j = ci - 1;
		for ( ;; ) {
			const n = name( j );
			if ( MODIFIERS.has( n ) || ( withTypes && TYPE_TOKENS.has( n ) ) ) {
				j--;
			} else if ( n === ']' ) {
				let k = j;
				while ( k >= 0 && name( k ) !== 'T_ATTRIBUTE' ) {
					k--;
				}
				if ( k < 0 ) {
					break;
				}
				j = k - 1;
			} else {
				break;
			}
		}
		return j + 1;
	};
	// Doc comment directly before a token, allowing whitespace and plain comments.
	const docBefore = ( tokIdx ) => {
		for ( let i = tokIdx - 1; i >= 0; i-- ) {
			const k = tokens[ i ][ 0 ];
			if ( k === 'doc' ) {
				return i;
			}
			if ( k !== 'ws' && k !== 'comment' ) {
				return -1;
			}
		}
		return -1;
	};
	// Any doc comment between the statement start and a token.
	const docInStatement = ( ci ) => {
		for ( let i = code[ ci ] - 1; i >= 0; i-- ) {
			const [ k, n ] = tokens[ i ];
			if ( k === 'doc' ) {
				return i;
			}
			if ( k === 'code' && STMT_BOUNDARY.has( n ) ) {
				return -1;
			}
		}
		return -1;
	};

	const decls = [];
	const classes = [];
	let pendingClass = null;
	let depth = 0;
	let paren = 0;

	for ( let ci = 0; ci < code.length; ci++ ) {
		const n = name( ci );
		const top = classes[ classes.length - 1 ];
		const inClassBody = top && depth === top.bodyDepth && paren === 0;

		if ( n === '(' ) {
			paren++;
		} else if ( n === ')' ) {
			paren--;
		} else if ( OPEN_BRACE.has( n ) ) {
			depth++;
			if ( pendingClass && n === '{' ) {
				classes.push( { ...pendingClass, bodyDepth: depth } );
				pendingClass = null;
			}
		} else if ( n === '}' ) {
			depth--;
			if ( top && depth < top.bodyDepth ) {
				classes.pop();
			}
		}

		if ( CLASS_KW.has( n ) ) {
			const prev = name( ci - 1 );
			if ( prev === 'T_DOUBLE_COLON' || prev === 'T_NEW' || name( ci + 1 ) !== 'T_STRING' ) {
				if ( prev === 'T_NEW' ) {
					pendingClass = { name: '(anonymous)', cli: false };
				}
				continue;
			}
			const cname = text( ci + 1 );
			let extendsCli = false;
			for ( let k = ci + 2; k < code.length && name( k ) !== '{'; k++ ) {
				if ( /^\\?WP_CLI_Command$/.test( text( k ) ) ) {
					extendsCli = true;
				}
			}
			const isCli = extendsCli || cli.has( cname );
			pendingClass = { name: cname, cli: isCli };
			const start = declStart( ci, false );
			decls.push( {
				type: n.slice( 2 ).toLowerCase(), name: cname, line: tokens[ code[ ci ] ][ 3 ],
				docIdx: docBefore( code[ start ] ), cli: isCli, start: code[ start ],
			} );
		} else if ( n === 'T_FUNCTION' ) {
			let k = ci + 1;
			if ( name( k ) === '&' || /^T_AMPERSAND/.test( name( k ) ) ) {
				k++;
			}
			if ( name( k ) === 'T_STRING' || ( inClassBody && name( k ) !== '(' ) ) {
				const fname = text( k );
				const start = declStart( ci, false );
				let isPublic = true;
				for ( let m = start; m < ci; m++ ) {
					if ( name( m ) === 'T_PRIVATE' || name( m ) === 'T_PROTECTED' ) {
						isPublic = false;
					}
				}
				const isCli = inClassBody ? top.cli && isPublic : cli.has( fname );
				decls.push( {
					type: inClassBody ? 'method' : 'function', name: fname, line: tokens[ code[ ci ] ][ 3 ],
					docIdx: docBefore( code[ start ] ), cli: isCli, start: code[ start ],
				} );
			} else {
				decls.push( {
					type: 'closure', name: '{closure}', line: tokens[ code[ ci ] ][ 3 ],
					docIdx: docInStatement( ci ), cli: false, start: code[ ci ],
				} );
			}
		} else if ( n === 'T_CONST' && ( inClassBody || depth === 0 ) ) {
			const start = declStart( ci, false );
			let k = ci + 1;
			while ( k < code.length && name( k + 1 ) !== '=' ) {
				k++;
			}
			decls.push( {
				type: 'const', name: text( k ), line: tokens[ code[ ci ] ][ 3 ],
				docIdx: docBefore( code[ start ] ), cli: false, start: code[ start ],
			} );
		} else if ( n === 'T_VARIABLE' && inClassBody ) {
			const prev = name( ci - 1 );
			if ( MODIFIERS.has( prev ) || TYPE_TOKENS.has( prev ) ) {
				const start = declStart( ci, true );
				decls.push( {
					type: 'property', name: text( ci ), line: tokens[ code[ ci ] ][ 3 ],
					docIdx: docBefore( code[ start ] ), cli: false, start: code[ start ],
				} );
			}
		} else if ( ( n === 'T_STRING' || n === 'T_NAME_FULLY_QUALIFIED' ) && HOOK_FUNCS.has( bare( text( ci ) ) ) ) {
			const prev = name( ci - 1 );
			if ( name( ci + 1 ) === '(' && ! [ 'T_FUNCTION', 'T_OBJECT_OPERATOR', 'T_NULLSAFE_OBJECT_OPERATOR', 'T_DOUBLE_COLON' ].includes( prev ) ) {
				const hook = text( ci + 2 ) || '';
				decls.push( {
					type: 'hook', name: hook, line: tokens[ code[ ci ] ][ 3 ],
					docIdx: docInStatement( ci ), cli: false, start: code[ ci ],
				} );
			}
		}
	}
	return decls;
}

// --- Per-file model ---------------------------------------------------------

/**
 * Removes comments and returns the remaining non-blank lines.
 *
 * Each comment is removed together with the spaces or tabs that follow it,
 * so a docblock opened mid-line (`<?php /** … *\/ esc_html_e(…)`) leaves the
 * code line exactly as it was. A newline that ends a comment token is kept.
 *
 * @param {string}                              src    Source text.
 * @param {Array<{start: number, end: number}>} ranges Comment ranges, sorted.
 * @return {Array<{line: number, text: string}>} Non-blank lines, right-trimmed,
 *                                               with their line in src.
 */
function layoutLines( src, ranges ) {
	const lines = [];
	let text = '';
	let startLine = 1;
	let line = 1;
	let pos = 0;
	const keep = ( from, to ) => {
		for ( let k = from; k < to; k++ ) {
			if ( src[ k ] === '\n' ) {
				lines.push( { line: startLine, text } );
				text = '';
				line++;
				startLine = line;
			} else {
				text += src[ k ];
			}
		}
	};
	for ( const r of ranges ) {
		keep( pos, r.start );
		let end = r.end;
		const body = src.slice( r.start, r.end );
		if ( body.endsWith( '\n' ) ) {
			end--;
		}
		line += ( src.slice( r.start, end ).match( /\n/g ) || [] ).length;
		while ( src[ end ] === ' ' || src[ end ] === '\t' ) {
			end++;
		}
		pos = end;
	}
	keep( pos, src.length );
	lines.push( { line: startLine, text } );
	return lines
		.map( ( l ) => ( { line: l.line, text: l.text.replace( /\s+$/, '' ) } ) )
		.filter( ( l ) => l.text !== '' );
}

/**
 * Builds the comparison model for one file.
 *
 * @param {string}      file   Path (for the extension).
 * @param {string}      src    Source text.
 * @param {Array|null}  tokens PHP tokens, or null for JS.
 * @param {Set<string>} cli    WP-CLI command names.
 * @return {Object} {code, layout, comments, decls} or {error}.
 */
export function model( file, src, tokens, cli ) {
	if ( PHP_EXT.has( extname( file ) ) ) {
		if ( ! tokens ) {
			return { error: 'unreadable' };
		}
		const decls = phpDecls( tokens, cli );
		const cliDocs = new Set( decls.filter( ( d ) => d.cli && d.docIdx >= 0 ).map( ( d ) => d.docIdx ) );
		const code = [];
		const comments = [];
		const ranges = [];
		let offset = 0;
		tokens.forEach( ( [ kind, name, text, line ], i ) => {
			if ( kind === 'code' ) {
				code.push( { key: name + '\u0000' + text, line } );
			} else if ( kind === 'comment' || kind === 'doc' ) {
				comments.push( { text, line, anchor: code.length, ...classify( text, cliDocs.has( i ) ) } );
				ranges.push( { start: offset, end: offset + text.length } );
			}
			offset += text.length;
		} );
		// Ranges are offsets into the joined token text, so it must equal src.
		const joined = tokens.map( ( t ) => t[ 2 ] ).join( '' );
		if ( joined !== src ) {
			return { error: 'token text does not round-trip' };
		}
		const words = code.map( ( c ) => c.key.split( '\u0000' )[ 1 ] );
		return { lang: 'php', code, words, layout: layoutLines( src, ranges ), comments, decls };
	}

	let ast;
	try {
		ast = jsParse( src, file );
	} catch ( e ) {
		return { error: 'parse error: ' + e.message };
	}
	const comments = [];
	const words = [];
	let anchor = 0;
	for ( const t of ast.tokens ) {
		const label = typeof t.type === 'string' ? t.type : t.type.label;
		if ( label === 'CommentBlock' || label === 'CommentLine' ) {
			const text = src.slice( t.start, t.end );
			comments.push( { text, line: t.loc.start.line, anchor, ...classify( text ) } );
		} else if ( label !== 'eof' ) {
			words.push( src.slice( t.start, t.end ) );
			anchor++;
		}
	}
	return {
		lang: 'js',
		ast,
		words,
		code: jsCanonical( ast ),
		layout: layoutLines( src, ast.comments.map( ( c ) => ( { start: c.start, end: c.end } ) ) ),
		comments,
	};
}

// Gettext functions whose strings a translators comment may describe.
const GETTEXT = new Set( [
	'__', '_e', '_x', '_ex', '_n', '_nx', '_n_noop', '_nx_noop',
	'esc_html__', 'esc_html_e', 'esc_html_x', 'esc_attr__', 'esc_attr_e', 'esc_attr_x',
] );

/**
 * Tells whether a gettext call starts within the statement after a comment.
 *
 * Scans the code tokens from the comment's anchor up to the end of the
 * statement (`;`, `{` or `}`) for a gettext function name followed by `(`.
 *
 * @param {Object} m      Model from model().
 * @param {number} anchor Index of the first code token after the comment.
 * @return {boolean} True when a gettext call follows.
 */
export function gettextAhead( m, anchor ) {
	const w = m.words;
	for ( let i = anchor; i < w.length - 1; i++ ) {
		if ( w[ i ] === ';' || w[ i ] === '{' || w[ i ] === '}' ) {
			return false;
		}
		if ( GETTEXT.has( w[ i ].trim() ) && w[ i + 1 ].trim() === '(' ) {
			return true;
		}
	}
	return false;
}
