#!/usr/bin/env node
/**
 * Lists declarations that lack the doc comment the doc-pass rules require.
 *
 * Usage: node coverage.mjs <dir> [--since] [--files-from <list>] [--context-from <list>] [--line-docs] [--terse] [relative files...]
 *
 * `--context-from <list>` names files that are read but not reported on: the
 * C / C++ headers whose documented prototypes exempt a definition, and the Go
 * files that may hold a directory's package doc. An agent passes the whole
 * project's file list there, so a gap in another group's file is not its own.
 *
 * `--line-docs` accepts plain line comments (`//`, `#`) directly above a
 * declaration as its doc, for files whose doc comments a tool would publish
 * when the user declined that (NestJS Swagger `introspectComments`, graphene).
 *
 * `--terse` reports only public declarations (the terse comment style). In JS /
 * TS that is anything exported (`export`, `export { a }`, `module.exports`,
 * `exports.x`, `window.x`, a wrapped `export default memo( Comp )`), everything
 * in a `.d.ts`, and the members of an exported class,
 * interface, type or object literal, except `private`, `protected` and `#name`
 * members. Handler registrations and the file header stay required.
 *
 * An undocumented declaration inside a region the grammar could not parse is
 * printed as `LOCKED DOC: …` instead: its doc slot is compared byte for byte,
 * so it cannot be documented, and it is not a gap.
 *
 * Prints one "MISSING ..." line per gap and exits non-zero when any exist.
 * With --since, the doc comment on every top-level JS / TS declaration, and
 * on every PHP, Java and Kotlin declaration that needs one, must also carry
 * @since. Other languages' version tags are not checked.
 * Rules that need judgement (inline arrows, `useEffect` bodies, inline
 * comments) are not scanned.
 */

import { readFileSync } from 'node:fs';
import { dirname, extname, join } from 'node:path';
import { JS_EXT, SFC_EXT, isSource, isTestFile, jsParse, langOf, parseArgs, readList, splitSfc, walk } from './lib.mjs';
import { langFor } from './langs.mjs';

const { flags, values, rest, listed } = parseArgs( process.argv.slice( 2 ), [ '--since', '--line-docs', '--terse' ], [ '--context-from' ] );
const context = values[ 'context-from' ] ? readList( values[ 'context-from' ] ) : [];
const since = !! flags.since;
const lineDocs = !! flags[ 'line-docs' ];
const terse = !! flags.terse;
const [ dir, ...only ] = rest;
if ( ! dir ) {
	console.error( 'Usage: node coverage.mjs <dir> [--since] [--files-from <list>] [--context-from <list>] [--line-docs] [--terse] [files...]' );
	process.exit( 2 );
}

const files = ( only.length || listed ? only : walk( dir ) ).filter( isSource );
const gaps = [];
// Undocumented declarations inside locked regions: reported, never gaps.
const lockedDocs = [];

// Methods whose call registers a route, middleware, event or job handler.
const REGISTER = new Set( [
	'get', 'post', 'put', 'patch', 'delete', 'del', 'head', 'options', 'all', 'use', 'route', 'param',
	'on', 'once', 'addListener', 'addHook', 'register', 'handle', 'process', 'subscribe', 'pre', 'method', 'static',
	'decorate', 'decorateRequest', 'decorateReply',
] );
// Nodes a declaration's doc comment may sit in front of.
const WRAPPER = /^(Export\w+Declaration|VariableDeclaration|VariableDeclarator|ExpressionStatement|AssignmentExpression|TS\w+)$/;
// Nodes an exported object literal's members may be nested in.
const API_PATH = /^(ObjectExpression|ObjectProperty|CallExpression|TSAsExpression|TSSatisfiesExpression|ParenthesizedExpression|VariableDeclarator|VariableDeclaration|AssignmentExpression|ExpressionStatement)$/;
const DOCUMENTABLE = /^(FunctionDeclaration|ClassDeclaration|TSDeclareFunction|TSInterfaceDeclaration|TSTypeAliasDeclaration|TSEnumDeclaration|Export\w+Declaration)$/;

const isDoc = ( c ) => c.type === 'CommentBlock' && c.value.startsWith( '*' );
// With --line-docs, `//` comments directly above a declaration count too
// (NestJS Swagger `introspectComments` declined: `/** */` text would be published).
const isDeclDoc = ( c ) => isDoc( c ) || ( lineDocs && c.type === 'CommentLine' );
const isFn = ( n ) => n && /^(FunctionExpression|ArrowFunctionExpression|ClassExpression)$/.test( n.type );
const hasFnArg = ( n ) => n?.type === 'CallExpression' && n.arguments.some( isFn );
// An object-form route: `fastify.route( { method, url, handler() {…} } )`, Hapi `server.route( { handler } )`.
const HANDLER_KEY = /^(handler|preHandler|preValidation|onRequest|preParsing|preSerialization)$/;
const hasHandlerObject = ( args ) => args.some( ( a ) => a.type === 'ObjectExpression' && a.properties.some( ( p ) =>
	HANDLER_KEY.test( p.key?.name || p.key?.value || '' ) && ( p.type === 'ObjectMethod' || isFn( p.value ) ) ) );
// CommonJS export targets: `module.exports`, `module.exports.x`, `exports.x`.
const CJS_EXPORT = /^(module\.exports|exports)(\.\w+)?$/;
// Browser globals a script publishes through: `window.x`, `globalThis.x`, `self.x`.
const GLOBAL_EXPORT = /^(window|globalThis|self)\.\w+$/;
const CLASS_MEMBER = /^(ClassMethod|ClassPrivateMethod|TSDeclareMethod|ClassProperty|ClassPrivateProperty|ClassAccessorProperty|TSAbstract\w+)$/;
const FUNCTION_NODE = /^(FunctionDeclaration|FunctionExpression|ArrowFunctionExpression|ClassMethod|ClassPrivateMethod|ObjectMethod)$/;
const keyName = ( n ) => n.key?.name || n.key?.value || n.key?.id?.name || '(computed)';

/**
 * Whether a node, or the statement wrapping it, has a leading doc comment.
 *
 * @param {Object[]} chain Nodes from the root down to the node.
 * @return {boolean} True when documented.
 */
function hasJsDoc( chain ) {
	for ( let i = chain.length - 1; i >= 0; i-- ) {
		const n = chain[ i ];
		if ( ( n.leadingComments || [] ).some( isDeclDoc ) ) {
			return true;
		}
		if ( ! WRAPPER.test( n.type ) && i < chain.length - 1 ) {
			return false;
		}
	}
	return false;
}

/**
 * Whether the doc comment on a node, or on its wrappers, has @since.
 *
 * @param {Object[]} chain Nodes from the root down to the node.
 * @return {boolean} True when a wrapping doc comment has @since.
 */
function docHasSince( chain ) {
	return chain.slice( -4 ).some( ( n ) => ( n.leadingComments || [] ).some( ( c ) => isDoc( c ) && /@since\b/.test( c.value ) ) );
}

/**
 * Whether an object member belongs to an exported object literal.
 *
 * @param {Object[]} chain Ancestors of the member, root first.
 * @return {boolean} True when every ancestor up to an export is a plain wrapper.
 */
function inExportedObject( chain ) {
	for ( let i = chain.length - 1; i >= 0; i-- ) {
		const n = chain[ i ];
		if ( /^Export(Default|Named)Declaration$/.test( n.type ) ) {
			return true;
		}
		if ( n.type === 'AssignmentExpression' && /^(module\.exports|exports\.\w+)$/.test( memberText( n.left ) ) ) {
			return true;
		}
		if ( ! API_PATH.test( n.type ) ) {
			return false;
		}
	}
	return false;
}

/**
 * Renders a member expression such as `module.exports` as text.
 *
 * @param {Object} n AST node.
 * @return {string} Dotted name, or an empty string for anything else.
 */
function memberText( n ) {
	if ( n?.type === 'Identifier' ) {
		return n.name;
	}
	if ( n?.type === 'MemberExpression' && ! n.computed ) {
		const obj = memberText( n.object );
		return obj ? obj + '.' + n.property.name : '';
	}
	return '';
}

/**
 * Marks overload implementations and setters paired with a getter.
 *
 * Their doc comment lives on the overload signatures or the getter.
 *
 * @param {Object[]} body Statements or class members, in order.
 * @param {Set}      skip Receives the nodes that need no doc comment.
 */
function markPaired( body, skip ) {
	const inner = ( n ) => ( /^Export(Named|Default)Declaration$/.test( n?.type ) ? n.declaration : n );
	for ( let i = 1; i < body.length; i++ ) {
		const prev = inner( body[ i - 1 ] );
		const cur = inner( body[ i ] );
		if ( cur?.type === 'FunctionDeclaration' && prev?.type === 'TSDeclareFunction' && prev.id?.name === cur.id?.name ) {
			skip.add( cur );
		}
		if ( /^Class(Private)?Method$/.test( cur?.type ) && prev?.type === 'TSDeclareMethod' && keyName( prev ) === keyName( cur ) ) {
			skip.add( cur );
		}
	}
	for ( const m of body ) {
		if ( m.kind === 'set' && body.some( ( g ) => g.kind === 'get' && keyName( g ) === keyName( m ) && g.static === m.static ) ) {
			skip.add( m );
		}
	}
}

/**
 * Collects the local bindings a script exports by name.
 *
 * Covers `export { a, b as c }` (without `from`), `export default a`,
 * `export = a`, CommonJS `module.exports = a`, `exports.x = a` and
 * `module.exports = { a, b: c }`, and browser globals (`window.x = a`). A
 * wrapper call (`memo( Comp )`, `connect( a, b )( Comp )`) exports every
 * identifier in it.
 *
 * @param {Object} program Babel Program node.
 * @return {Set<string>} Exported local names.
 */
function exportedNames( program ) {
	const names = new Set();
	// A wrapper call exports what it wraps: `memo( Comp )`, `connect( a, b )( Comp )`.
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
			// `export const Connected = connect( … )( List )` exports `List` too.
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

/**
 * Whether a declaration is public, so the terse style still needs its doc comment.
 *
 * Its top-level statement must be exported, and nothing between that statement
 * and the declaration may be a function body, a non-exported namespace member,
 * or a `private`, `protected` or `#name` class member.
 *
 * @param {Object[]} here  Nodes from the Program down to the declaration.
 * @param {Set}      names Local names the script exports (from exportedNames).
 * @param {boolean}  dts   Whether the file is a declaration file (`.d.ts`).
 * @return {boolean} True when public.
 */
function isPublic( here, names, dts ) {
	if ( dts ) {
		return true;
	}
	const s = here[ 1 ];
	if ( ! s ) {
		return true;
	}
	let pub = false;
	if ( /^(Export(Named|Default)Declaration|TSExportAssignment)$/.test( s.type ) || s.declare ) {
		pub = true;
	} else if ( s.type === 'ExpressionStatement' && s.expression.type === 'AssignmentExpression' ) {
		// `exports.x = …`, `window.x = …`, or `Foo.prototype.bar = …` on an exported `Foo`.
		const text = memberText( s.expression.left );
		pub = /^(module\.exports|exports)(\.|$)/.test( text ) || GLOBAL_EXPORT.test( text ) || names.has( text.split( '.' )[ 0 ] );
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
		if ( n.type === 'TSModuleBlock' && ! s.declare && ! /^Export/.test( here[ i + 1 ]?.type || '' ) ) {
			return false;
		}
	}
	return true;
}

/**
 * Whether a statement is a declaration that needs its own doc comment.
 *
 * With --terse, a private declaration needs none, so a doc comment above it
 * is the file header.
 *
 * @param {Object}   n     First statement of a script.
 * @param {Function} [pub] With --terse, tells whether a node chain is public.
 * @return {boolean} True when a single doc comment above it is its own, not a file header.
 */
function needsOwnDoc( n, pub ) {
	if ( ! n ) {
		return false;
	}
	// isPublic reads only here[ 1 ] (the top-level statement) and later entries,
	// so a chain of [ Program placeholder, statement, declarator ] is enough here.
	if ( pub && ! ( n.type === 'VariableDeclaration' ? n.declarations.some( ( d ) => pub( [ null, n, d ] ) ) : pub( [ null, n ] ) ) ) {
		return false;
	}
	if ( DOCUMENTABLE.test( n.type ) ) {
		return true;
	}
	return n.type === 'VariableDeclaration' && n.declarations.some( ( d ) => isFn( d.init ) || hasFnArg( d.init ) );
}

/**
 * Scans one script for gaps.
 *
 * @param {string}  f        Relative path, for messages.
 * @param {Object}  ast      Babel File node.
 * @param {number}  offset   Line offset of the script in the file.
 * @param {boolean} header   Whether this script must carry the file header.
 */
function scan( f, ast, offset, header ) {
	const line = ( n ) => n.loc.start.line + offset;
	const test = isTestFile( f );
	// With --terse, only public declarations need a doc comment.
	const names = terse ? exportedNames( ast.program ) : null;
	const dts = /\.d\.[cm]?ts$/.test( f );
	const pub = terse ? ( here ) => isPublic( here, names, dts ) : null;

	if ( header ) {
		const first = [ ast.program.directives[ 0 ], ast.program.body[ 0 ] ].filter( Boolean ).sort( ( x, y ) => x.start - y.start )[ 0 ];
		const docs = ast.comments.filter( ( c ) => isDoc( c ) && ( ! first || c.end <= first.start ) );
		// The last doc belongs to a first-statement declaration that needs its own.
		if ( docs.length && first === ast.program.body[ 0 ] && ! ast.program.directives.length && needsOwnDoc( first, pub ) ) {
			docs.pop();
		}
		// A docblock of tags only (`/** @vitest-environment jsdom */`) is no header.
		const prose = ( c ) => c.value.split( '\n' ).some( ( l ) => /^\s*\*?\s*[^\s*@]/.test( l ) );
		if ( ! docs.some( prose ) ) {
			gaps.push( `MISSING FILE HEADER: ${ f }` );
		}
	}

	const skip = new Set();
	const visit = ( node, chain ) => {
		if ( ! node || typeof node.type !== 'string' ) {
			return;
		}
		const here = [ ...chain, node ];
		const parent = chain[ chain.length - 1 ];
		const grand = chain[ chain.length - 2 ];
		const top = chain.length <= 3;
		if ( Array.isArray( node.body ) ) {
			markPaired( node.body, skip );
		}
		let need = null;
		// Handler registrations need a doc comment in every style.
		let handler = false;
		const t = node.type;
		if ( skip.has( node ) ) {
			need = null;
		} else if ( t === 'FunctionDeclaration' || t === 'ClassDeclaration' || t === 'TSDeclareFunction' ) {
			need = node.id?.name || 'default';
		} else if ( /^(TSInterfaceDeclaration|TSTypeAliasDeclaration|TSEnumDeclaration)$/.test( t ) ) {
			need = node.id.name;
		} else if ( t === 'TSModuleDeclaration' && node.id.type === 'Identifier' && node.kind !== 'global' && parent?.type !== 'TSModuleDeclaration' ) {
			need = node.id.name;
		} else if ( ( t === 'TSPropertySignature' || t === 'TSMethodSignature' ) &&
			( parent?.type === 'TSInterfaceBody' || ( parent?.type === 'TSTypeLiteral' && grand?.type === 'TSTypeAliasDeclaration' ) ) ) {
			need = keyName( node );
		} else if ( /^(ClassMethod|ClassPrivateMethod|TSDeclareMethod)$/.test( t ) ) {
			// A constructor that only receives injected dependencies needs no doc comment.
			const diOnly = node.kind === 'constructor' &&
				node.params.every( ( p ) => p.type === 'TSParameterProperty' ) &&
				! ( node.body?.body || [] ).length;
			need = diOnly ? null : keyName( node );
		} else if ( /^(ClassProperty|ClassPrivateProperty|ClassAccessorProperty|TSAbstractPropertyDefinition)$/.test( t ) ) {
			// A field that only receives an injected dependency (Angular `inject( Http )`)
			// is exempt, like a constructor that only declares injected parameters.
			const injected = node.value?.type === 'CallExpression' && node.value.callee.type === 'Identifier' && node.value.callee.name === 'inject';
			need = injected ? null : keyName( node );
		} else if ( t === 'VariableDeclarator' && top && ( isFn( node.init ) || hasFnArg( node.init ) || chain.some( ( c ) => c.type === 'ExportNamedDeclaration' ) ) ) {
			need = node.id?.name || '(pattern)';
		} else if ( t === 'ExportDefaultDeclaration' && ( isFn( node.declaration ) || hasFnArg( node.declaration ) ) ) {
			need = 'default';
		} else if ( t === 'AssignmentExpression' && parent?.type === 'ExpressionStatement' && node.left.type === 'MemberExpression' &&
			( isFn( node.right ) || hasFnArg( node.right ) ) ) {
			need = memberText( node.left ) || 'assignment';
		} else if ( ( t === 'ObjectMethod' || ( t === 'ObjectProperty' && isFn( node.value ) && node.value.body?.type === 'BlockStatement' ) ) &&
			inExportedObject( chain ) ) {
			need = keyName( node );
		} else if ( t === 'CallExpression' && parent?.type === 'ExpressionStatement' && ! test &&
			node.callee.type === 'MemberExpression' && REGISTER.has( node.callee.property?.name ) &&
			( node.arguments.some( ( a ) => isFn( a ) && a.body?.type === 'BlockStatement' ) || hasHandlerObject( node.arguments ) ||
				/^decorate(Request|Reply)?$/.test( node.callee.property.name ) ) ) {
			const what = node.arguments[ 0 ]?.type === 'StringLiteral' ? ` '${ node.arguments[ 0 ].value }'` : '';
			need = `${ memberText( node.callee ) || node.callee.property.name }${ what }`;
			handler = true;
		}
		if ( need && pub && ! handler && ! pub( here ) ) {
			need = null;
		}

		if ( need ) {
			if ( ! hasJsDoc( here ) ) {
				gaps.push( `MISSING DOCBLOCK: ${ f }:${ line( node ) } ${ t } ${ need }` );
			} else if ( since && chain.every( ( c ) => c.type === 'Program' || WRAPPER.test( c.type ) ) && ! docHasSince( here ) ) {
				gaps.push( `MISSING @since: ${ f }:${ line( node ) } ${ t } ${ need }` );
			}
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

// Tree-sitter languages. C / C++ definitions are exempt when a header
// prototype of the same name is documented, so headers are read first. Go
// needs one package doc comment per directory.
const tsFiles = files.filter( ( f ) => ! JS_EXT.has( extname( f ) ) && ! SFC_EXT.has( extname( f ) ) && langFor( f ) );
if ( tsFiles.length ) {
	const ts = await import( './treesitter.mjs' );
	const known = new Set();
	const hidden = new Set();
	const ctx = context.filter( ( f ) => isSource( f ) && langFor( f ) && ! tsFiles.includes( f ) );
	// A file a grammar or reader cannot handle is reported, and the run goes
	// on. A context file is never reported as a gap: its failure goes to stderr.
	const attempt = async ( f, run ) => {
		try {
			return await run();
		} catch ( e ) {
			const msg = `UNPARSABLE: ${ f }: ${ String( e.message ).split( '\n' )[ 0 ] }`;
			if ( tsFiles.includes( f ) ) {
				gaps.push( msg );
			} else {
				console.error( `${ msg } (context file, not reported)` );
			}
			return null;
		}
	};
	for ( const f of [ ...new Set( [ ...tsFiles, ...ctx ] ) ].filter( ( x ) => /\.(h|hh|hpp|hxx|ipp|inl|h\+\+)$/.test( x ) ) ) {
		const documented = await attempt( f, () => ts.documentedPrototypes( readFileSync( join( dir, f ), 'utf8' ), langFor( f ) ) );
		( documented || [] ).forEach( ( n ) => known.add( n ) );
		// With --terse, private member prototypes exempt their `Class::name`
		// definitions. A header that failed above is not reported twice.
		if ( terse && documented ) {
			( await attempt( f, () => ts.privatePrototypes( readFileSync( join( dir, f ), 'utf8' ), langFor( f ) ) ) || [] ).forEach( ( n ) => hidden.add( n ) );
		}
	}
	const goDirs = new Map();
	for ( const f of tsFiles ) {
		const r = await attempt( f, () => ts.tsCoverage( langFor( f ), f, readFileSync( join( dir, f ), 'utf8' ), known, since, lineDocs, terse, dir, hidden ) );
		if ( ! r ) {
			continue;
		}
		gaps.push( ...r.gaps );
		lockedDocs.push( ...r.locked );
		if ( langFor( f ) === 'go' && ! /_test\.go$/.test( f ) ) {
			goDirs.set( dirname( f ), ( goDirs.get( dirname( f ) ) || false ) || r.packageDoc );
		}
	}
	// Context files can supply a directory's package doc, never a gap.
	for ( const f of ctx.filter( ( x ) => langFor( x ) === 'go' && ! /_test\.go$/.test( x ) && goDirs.has( dirname( x ) ) && ! goDirs.get( dirname( x ) ) ) ) {
		if ( ( await attempt( f, () => ts.tsCoverage( 'go', f, readFileSync( join( dir, f ), 'utf8' ), known ) ) )?.packageDoc ) {
			goDirs.set( dirname( f ), true );
		}
	}
	for ( const [ d, ok ] of goDirs ) {
		if ( ! ok ) {
			gaps.push( `MISSING PACKAGE DOC: ${ d } (no file has a comment directly before \`package\`)` );
		}
	}
}

const readByHand = [];
for ( const f of files.filter( ( x ) => ! tsFiles.includes( x ) ) ) {
	const src = readFileSync( join( dir, f ), 'utf8' );
	const scripts = SFC_EXT.has( extname( f ) )
		? splitSfc( src, f ).blocks.map( ( b ) => ( { src: b.content, lang: b.lang, offset: b.line - 1, frontmatter: b.frontmatter } ) )
		: [ { src, lang: langOf( f ), offset: 0 } ];
	scripts.forEach( ( s, i ) => {
		let ast;
		try {
			ast = jsParse( s.src, s.lang ).ast;
		} catch ( e ) {
			// verify checks a plain JS / TS file Babel cannot parse with tree-sitter, so
			// it stays in scope; its docs are read by hand, not counted as a gap.
			( SFC_EXT.has( extname( f ) ) ? gaps : readByHand ).push( `${ SFC_EXT.has( extname( f ) ) ? 'UNPARSABLE' : 'READ BY HAND' }: ${ f }: ${ e.message }` );
			return;
		}
		// A component's header lives in its first script block that has code.
		// An Astro component's header lives in its frontmatter (none without one).
		const headerHere = f.endsWith( '.astro' ) ? !! s.frontmatter : i === scripts.findIndex( ( x ) => x.src.trim() !== '' );
		scan( f, ast, s.offset, headerHere );
	} );
}

lockedDocs.forEach( ( g ) => console.log( g ) );
readByHand.forEach( ( g ) => console.log( g ) );
gaps.forEach( ( g ) => console.log( g ) );
if ( gaps.length ) {
	console.log( `GAPS: ${ gaps.length }` );
	process.exit( 1 );
}
console.log( `OK: ${ files.length } files fully documented` );
