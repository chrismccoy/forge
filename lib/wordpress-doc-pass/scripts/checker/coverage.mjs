#!/usr/bin/env node
/**
 * Lists declarations that lack the docblock the doc-pass rules require.
 *
 * Usage: node coverage.mjs <dir> [--no-since] [relative files...]
 *
 * Prints one "MISSING ..." line per gap and exits non-zero when any exist.
 * WP-CLI command docblocks are frozen, so their declarations are skipped.
 * Arrow functions are not scanned: their rule needs judgement.
 */

import { readFileSync } from 'node:fs';
import { extname, join, resolve } from 'node:path';
import { JS_EXT, PHP_EXT, cliNames, jsParse, phpDecls, phpTokenize, walk } from './lib.mjs';

const args = process.argv.slice( 2 );
const noSince = args.includes( '--no-since' );
const [ dir, ...only ] = args.filter( ( a ) => a !== '--no-since' );
if ( ! dir ) {
	console.error( 'Usage: node coverage.mjs <dir> [--no-since] [files...]' );
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

const DECL_KW = new Set( [ 'T_CLASS', 'T_INTERFACE', 'T_TRAIT', 'T_ENUM', 'T_FUNCTION', 'T_ABSTRACT', 'T_FINAL', 'T_READONLY', 'T_ATTRIBUTE' ] );
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
	let nextCode = null;
	for ( let i = open + 1; open >= 0 && i < tokens.length; i++ ) {
		if ( tokens[ i ][ 0 ] === 'doc' ) {
			docs++;
		} else if ( tokens[ i ][ 0 ] === 'code' ) {
			// The first statement (declare, namespace or a declaration) ends the search.
			nextCode = tokens[ i ][ 1 ];
			break;
		}
	}
	if ( open >= 0 && ( docs === 0 || ( docs === 1 && DECL_KW.has( nextCode ) ) ) ) {
		gaps.push( `MISSING FILE DOCBLOCK: ${ f }` );
	}

	for ( const d of phpDecls( tokens, cli ) ) {
		if ( d.cli ) {
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
		if ( ! /^(Export\w+Declaration|VariableDeclaration|VariableDeclarator|ExpressionStatement|AssignmentExpression|TS\w+)$/.test( n.type ) && i < chain.length - 1 ) {
			return false;
		}
	}
	return false;
}

const isFn = ( n ) => n && /^(FunctionExpression|ArrowFunctionExpression|ClassExpression)$/.test( n.type );

for ( const f of files.filter( ( x ) => JS_EXT.has( extname( x ) ) ) ) {
	let ast;
	try {
		ast = jsParse( readFileSync( join( dir, f ), 'utf8' ), f );
	} catch ( e ) {
		gaps.push( `UNPARSABLE: ${ f }: ${ e.message }` );
		continue;
	}
	if ( ! ast.comments.some( ( c ) => c.type === 'CommentBlock' && c.value.startsWith( '*' ) && c.loc.start.line <= ( ast.program.body[ 0 ]?.loc.start.line ?? 1 ) ) ) {
		gaps.push( `MISSING FILE HEADER: ${ f }` );
	}
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
}

gaps.forEach( ( g ) => console.log( g ) );
if ( gaps.length ) {
	console.log( `GAPS: ${ gaps.length }` );
	process.exit( 1 );
}
console.log( `OK: ${ files.length } files fully documented` );
