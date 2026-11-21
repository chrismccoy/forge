#!/usr/bin/env node
/**
 * Lists declarations that lack the docblock the doc-pass rules require.
 *
 * Usage: node coverage.mjs <dir> [--no-since] [--terse] [relative files...]
 *
 * Prints one "MISSING ..." line per gap and exits non-zero when any exist.
 * WP-CLI command docblocks are frozen, so their declarations are skipped.
 * Arrow functions are not scanned: their rule needs judgement. With --terse
 * (terse comment style) only public declarations are reported: private and
 * protected members, closures not passed to a registration call, and JS
 * declarations that are not exported or attached to a namespace are skipped.
 */

import { readFileSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';
import { JS_EXT, PHP_EXT, cliNames, jsParse, phpDecls, phpTokenize, walk } from './lib.mjs';

const args = process.argv.slice( 2 );
const noSince = args.includes( '--no-since' );
const terse = args.includes( '--terse' );
const [ dir, ...only ] = args.filter( ( a ) => a !== '--no-since' && a !== '--terse' );
if ( ! dir ) {
	console.error( 'Usage: node coverage.mjs <dir> [--no-since] [--terse] [files...]' );
	process.exit( 2 );
}

const files = only.length ? only : walk( dir );
const gaps = [];

const cli = new Set();
for ( const f of walk( dir ) ) {
	if ( PHP_EXT.has( extname( f ) ) ) {
		cliNames( readFileSync( join( dir, f ), 'utf8' ) ).forEach( ( n ) => cli.add( n ) );
	}
}

const phpFiles = files.filter( ( f ) => PHP_EXT.has( extname( f ) ) );
const tokensByPath = phpFiles.length ? phpTokenize( phpFiles.map( ( f ) => resolve( dir, f ) ) ) : {};

const DECL_KW = new Set( [ 'T_CLASS', 'T_INTERFACE', 'T_TRAIT', 'T_ENUM', 'T_FUNCTION', 'T_ABSTRACT', 'T_FINAL', 'T_READONLY', 'T_ATTRIBUTE', 'T_CONST' ] );
const SINCE_TYPES = new Set( [ 'class', 'interface', 'trait', 'enum', 'function', 'method', 'const', 'property', 'hook' ] );

for ( const f of phpFiles ) {
	const tokens = tokensByPath[ resolve( dir, f ) ];
	if ( ! tokens ) {
		gaps.push( `UNREADABLE: ${ f }` );
		continue;
	}

	// File docblock: a doc comment in the first PHP block that is not the one
	// attached to the first declaration.
	const open = tokens.findIndex( ( t ) => t[ 1 ] === 'T_OPEN_TAG' );
	let docs = 0;
	const lead = [];
	for ( let i = open + 1; open >= 0 && i < tokens.length && lead.length < 4; i++ ) {
		if ( tokens[ i ][ 0 ] === 'doc' && ! lead.length ) {
			docs++;
		} else if ( tokens[ i ][ 0 ] === 'code' ) {
			// The first statement (declare, namespace or a declaration) ends the count.
			lead.push( tokens[ i ][ 1 ] );
		}
	}
	// A closure stored in a variable (`$cb = [static] function`) takes the doc above it.
	const closureVar = lead[ 0 ] === 'T_VARIABLE' && lead[ 1 ] === '=' && ( lead[ 2 ] === 'T_FUNCTION' || ( lead[ 2 ] === 'T_STATIC' && lead[ 3 ] === 'T_FUNCTION' ) );
	if ( open >= 0 && ( docs === 0 || ( docs === 1 && ( DECL_KW.has( lead[ 0 ] ) || closureVar ) ) ) ) {
		gaps.push( `MISSING FILE DOCBLOCK: ${ f }` );
	}

	for ( const d of phpDecls( tokens, cli ) ) {
		if ( d.cli || ( terse && ! d.pub ) ) {
			continue;
		}
		if ( d.docIdx < 0 ) {
			gaps.push( `MISSING DOCBLOCK: ${ f }:${ d.line } ${ d.type } ${ d.name }` );
			continue;
		}
		const doc = tokens[ d.docIdx ][ 2 ];
		if ( ! noSince && SINCE_TYPES.has( d.type ) && ! /is documented in/.test( doc ) && ! /@since\b/.test( doc ) ) {
			gaps.push( `MISSING @since: ${ f }:${ d.line } ${ d.type } ${ d.name }` );
		}
	}
}

// Nodes whose leading doc also documents the declaration inside them.
const JSDOC_WRAPPER = /^(Export\w+Declaration|VariableDeclaration|VariableDeclarator|ExpressionStatement|AssignmentExpression|TS\w+)$/;

/**
 * Whether a node, or the statement wrapping it, has a leading JSDoc block.
 *
 * @param {Object[]} chain Nodes from the root down to the node.
 * @return {boolean} True when documented.
 */
function hasJsDoc( chain ) {
	for ( let i = chain.length - 1; i >= 0; i-- ) {
		const n = chain[ i ];
		if ( ( n.leadingComments || [] ).some( ( c ) => c.type === 'CommentBlock' && c.value.startsWith( '*' ) ) ) {
			return true;
		}
		if ( ! JSDOC_WRAPPER.test( n.type ) && i < chain.length - 1 ) {
			return false;
		}
	}
	return false;
}

const isFn = ( n ) => n && /^(FunctionExpression|ArrowFunctionExpression|ClassExpression)$/.test( n.type );

/**
 * Dotted text of a member expression (`window.acme.open`), or '' when it has
 * a computed part.
 *
 * @param {Object} n Babel node.
 * @return {string} Dotted name.
 */
function memberText( n ) {
	if ( n?.type === 'Identifier' ) {
		return n.name;
	}
	if ( n?.type === 'ThisExpression' ) {
		return 'this';
	}
	if ( n?.type === 'MemberExpression' && ! n.computed ) {
		const o = memberText( n.object );
		return o && n.property.name ? `${ o }.${ n.property.name }` : '';
	}
	return '';
}

const CJS_EXPORT = /^(module\.exports|exports)(\.\w+)?$/;
const GLOBAL_EXPORT = /^(window|globalThis|self)\.\w+$/;

/**
 * Local names a script exports: `export { a }`, `export default a`,
 * `module.exports = a` or `{ a }`, `exports.x = a`, `window.x = a`. A wrapper
 * call (`memo( Comp )`) exports every identifier in it.
 *
 * @param {Object} program Babel Program node.
 * @return {Set<string>} Exported local names.
 */
function exportedNames( program ) {
	const names = new Set();
	const add = ( n ) => {
		if ( n?.type === 'Identifier' ) {
			names.add( n.name );
		} else if ( n?.type === 'CallExpression' ) {
			add( n.callee );
			n.arguments.forEach( add );
		}
	};
	for ( const s of program.body ) {
		if ( s.type === 'ExportNamedDeclaration' && ! s.source ) {
			s.specifiers.forEach( ( sp ) => add( sp.local ) );
			( s.declaration?.declarations || [] ).forEach( ( d ) => add( d.init ) );
		} else if ( s.type === 'ExportDefaultDeclaration' ) {
			add( s.declaration );
		} else if ( s.type === 'TSExportAssignment' ) {
			add( s.expression );
		} else if ( s.type === 'ExpressionStatement' && s.expression.type === 'AssignmentExpression' &&
			( CJS_EXPORT.test( memberText( s.expression.left ) ) || GLOBAL_EXPORT.test( memberText( s.expression.left ) ) ) ) {
			const r = s.expression.right;
			add( r );
			if ( r.type === 'ObjectExpression' ) {
				r.properties.forEach( ( p ) => p.type === 'ObjectProperty' && add( p.value ) );
			}
		}
	}
	return names;
}

const CLASS_MEMBER = /^(ClassMethod|ClassPrivateMethod|TSDeclareMethod|ClassProperty|ClassPrivateProperty|TSAbstract\w+)$/;
const FUNCTION_NODE = /^(FunctionDeclaration|FunctionExpression|ArrowFunctionExpression|ClassMethod|ClassPrivateMethod|ObjectMethod)$/;

/**
 * Whether a JS declaration is public, so the terse style still needs its doc.
 *
 * An `ns.member = function` assignment is public unless it sets `this.x`
 * (WordPress scripts publish through globals and namespaces such as
 * `window.acme.open` or `$.fn.card`, often inside an IIFE). Any other
 * declaration's top-level statement must be exported, and nothing between
 * that statement and the declaration may be a function body or a `private`,
 * `protected` or `#name` class member. Every declaration in a `.d.ts` is public.
 *
 * @param {Object[]} here  Nodes from the Program down to the declaration.
 * @param {Set}      names Local names the script exports.
 * @param {boolean}  dts   Whether the file is a declaration file.
 * @return {boolean} True when public.
 */
function isPublic( here, names, dts ) {
	const node = here[ here.length - 1 ];
	if ( dts ) {
		return true;
	}
	if ( node.type === 'AssignmentExpression' ) {
		const root = memberText( node.left ).split( '.' )[ 0 ];
		return root !== '' && root !== 'this';
	}
	const s = here[ 1 ];
	if ( ! s ) {
		return true;
	}
	let pub = false;
	if ( /^(Export(Named|Default)Declaration|TSExportAssignment)$/.test( s.type ) || s.declare ) {
		pub = true;
	} else if ( s.type === 'ExpressionStatement' && s.expression.type === 'AssignmentExpression' ) {
		const t = memberText( s.expression.left );
		pub = /^(module\.exports|exports)(\.|$)/.test( t ) || GLOBAL_EXPORT.test( t ) || names.has( t.split( '.' )[ 0 ] );
	} else if ( s.type === 'VariableDeclaration' ) {
		pub = names.has( here[ 2 ]?.id?.name );
	} else {
		pub = names.has( s.id?.name );
	}
	if ( ! pub ) {
		return false;
	}
	for ( let i = 2; i < here.length; i++ ) {
		const n = here[ i ];
		if ( CLASS_MEMBER.test( n.type ) && ( /^ClassPrivate/.test( n.type ) || n.key?.type === 'PrivateName' || /^(private|protected)$/.test( n.accessibility || '' ) ) ) {
			return false;
		}
		if ( i < here.length - 1 && FUNCTION_NODE.test( n.type ) ) {
			return false;
		}
	}
	return true;
}

for ( const f of files.filter( ( x ) => JS_EXT.has( extname( x ) ) ) ) {
	let ast;
	try {
		ast = jsParse( readFileSync( join( dir, f ), 'utf8' ), f );
	} catch ( e ) {
		gaps.push( `UNPARSABLE: ${ f }: ${ e.message }` );
		continue;
	}
	const first = ast.program.body[ 0 ];
	const headerAt = gaps.length;
	// Set when the first statement holds a declaration that needs its own doc
	// and would take the doc above that statement.
	let firstNeeds = false;
	const names = terse ? exportedNames( ast.program ) : null;
	const dts = /\.d\.[cm]?ts$/.test( f );
	const visit = ( node, chain ) => {
		if ( ! node || typeof node.type !== 'string' ) {
			return;
		}
		const here = [ ...chain, node ];
		const parent = chain[ chain.length - 1 ];
		const top = chain.length <= 3;
		let need = null;
		if ( node.type === 'FunctionDeclaration' || node.type === 'ClassDeclaration' ) {
			need = node.id?.name || 'default';
		} else if ( /^(ClassMethod|ClassPrivateMethod|TSDeclareMethod)$/.test( node.type ) ) {
			need = node.key?.name || node.key?.value || 'method';
		} else if ( node.type === 'VariableDeclarator' && isFn( node.init ) && top ) {
			need = node.id?.name;
		} else if ( node.type === 'AssignmentExpression' && isFn( node.right ) && parent?.type === 'ExpressionStatement' && node.left.type === 'MemberExpression' ) {
			need = 'assignment';
		}
		if ( need && terse && ! isPublic( here, names, dts ) ) {
			need = null;
		}
		if ( need && here[ 1 ] === first && here.slice( 1, -1 ).every( ( n ) => JSDOC_WRAPPER.test( n.type ) ) ) {
			firstNeeds = true;
		}
		if ( need && ! hasJsDoc( here ) ) {
			gaps.push( `MISSING DOCBLOCK: ${ f }:${ node.loc.start.line } ${ node.type } ${ need }` );
		}
		for ( const [ k, v ] of Object.entries( node ) ) {
			if ( k === 'loc' || k.endsWith( 'Comments' ) ) {
				continue;
			}
			if ( Array.isArray( v ) ) {
				v.forEach( ( c ) => visit( c, here ) );
			} else if ( v && typeof v === 'object' ) {
				visit( v, here );
			}
		}
	};
	visit( ast.program, [] );
	// One doc above a first declaration that needs its own is that declaration's,
	// not the file header.
	const docs = ast.comments.filter( ( c ) => c.type === 'CommentBlock' && c.value.startsWith( '*' ) && c.loc.start.line <= ( first?.loc.start.line ?? 1 ) );
	if ( firstNeeds && ! ast.program.directives.length && docs.length && docs[ docs.length - 1 ].end <= first.start ) {
		docs.pop();
	}
	if ( ! docs.length ) {
		gaps.splice( headerAt, 0, `MISSING FILE HEADER: ${ f }` );
	}
}

gaps.forEach( ( g ) => console.log( g ) );
if ( gaps.length ) {
	console.log( `GAPS: ${ gaps.length }` );
	process.exit( 1 );
}
console.log( `OK: ${ files.length } files fully documented` );
