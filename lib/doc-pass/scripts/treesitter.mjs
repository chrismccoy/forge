/**
 * Tree-sitter models and coverage for the languages in langs.mjs.
 *
 * The code check compares a stream built from the syntax tree with comments
 * left out: an open and close marker for every named node, and the type and
 * text of every leaf. A region the grammar cannot parse (an ERROR node) enters
 * the stream as its exact source text, comments included, so nothing inside
 * it may change. Python docstrings are treated as comments.
 */

import { readClojure, cljDocstring, cljForms } from './clojure.mjs';
import { readErlang, readHaskell, readPerl, readLua } from './lexers.mjs';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { GRAMMAR_DIRS, LANGS } from './langs.mjs';
import { joinTagLines, layoutLines } from './lib.mjs';

const HERE = dirname( fileURLToPath( import.meta.url ) );
let runtime = null;
const loaded = new Map();

/**
 * Returns a parser for a language, loading the runtime and grammar once.
 *
 * @param {string} lang Language key from langs.mjs.
 * @return {Promise<Object>} A tree-sitter Parser set to the language.
 */
export async function parserFor( lang ) {
	if ( ! runtime ) {
		const m = await import( '@vscode/tree-sitter-wasm' );
		runtime = { Parser: m.Parser || m.default.Parser, Language: m.Language || m.default.Language };
		await runtime.Parser.init();
	}
	if ( ! loaded.has( lang ) ) {
		const [ source, name ] = LANGS[ lang ].grammar;
		const wasm = join( HERE, 'node_modules', GRAMMAR_DIRS[ source ], `tree-sitter-${ name }.wasm` );
		loaded.set( lang, await runtime.Language.load( readFileSync( wasm ) ) );
	}
	// One parser per language: each Parser holds wasm memory that is never
	// garbage-collected.
	if ( ! parsers.has( lang ) ) {
		const parser = new runtime.Parser();
		parser.setLanguage( loaded.get( lang ) );
		parsers.set( lang, parser );
	}
	return parsers.get( lang );
}

const parsers = new Map();

const warmed = new Set();

/**
 * Parses a source with a language's grammar. The first parse in a process
 * can differ from every later one for the same text (seen with the Swift
 * grammar's external scanner), so the first source per language is parsed
 * once and thrown away, and every result comes from the same scanner state.
 *
 * @param {string} lang Language key from langs.mjs.
 * @param {string} src  Source text.
 * @return {Promise<Object>} The tree-sitter tree.
 */
async function parse( lang, src ) {
	const reader = { clojure: readClojure, erlang: readErlang, haskell: readHaskell, perl: readPerl, lua: readLua }[ LANGS[ lang ].reader ];
	if ( reader ) {
		return reader( src );
	}
	const parser = await parserFor( lang );
	if ( ! warmed.has( lang ) ) {
		warmed.add( lang );
		parser.parse( src ).delete();
	}
	if ( LANGS[ lang ].grammar[ 0 ] !== 'wasms' ) {
		return parser.parse( src );
	}
	const tree = stableParse( parser, src );
	if ( tree ) {
		return tree;
	}
	// A long run can leave the grammar's scanner in a state where parses stop
	// agreeing (seen with Swift after ~14,000 files of cmux). Start a fresh
	// parser, warm it up, and try once more before giving up on the file.
	parser.delete();
	parsers.delete( lang );
	const fresh = await parserFor( lang );
	fresh.parse( src ).delete();
	const retry = stableParse( fresh, src );
	if ( retry ) {
		return retry;
	}
	throw new Error( 'the grammar gives a different tree on each parse' );
}

/**
 * Parses until two consecutive parses agree, at most five times. The older
 * tree-sitter-wasms grammars can read uninitialized scanner memory, so one
 * parse alone is not trusted.
 *
 * @param {Object} parser Tree-sitter parser.
 * @param {string} src    Source text.
 * @return {Object|null} The agreed tree, or null when no two parses agreed.
 */
function stableParse( parser, src ) {
	let prev = parser.parse( src );
	let text = fingerprint( prev );
	for ( let k = 0; k < 4; k++ ) {
		const again = parser.parse( src );
		const t = fingerprint( again );
		if ( t === text ) {
			again.delete();
			return prev;
		}
		prev.delete();
		prev = again;
		text = t;
	}
	prev.delete();
	return null;
}

/**
 * A cheap fingerprint of a tree's shape: the node count and a 32-bit FNV-1a
 * hash over every node's type, range and missing flag, walked with a cursor.
 * Comparing two of these costs no memory, unlike comparing `toString()`
 * output, which runs to hundreds of megabytes for large files.
 *
 * @param {Object} tree Tree-sitter tree.
 * @return {string} `count:hash`.
 */
function fingerprint( tree ) {
	const c = tree.walk();
	let h = 0x811c9dc5;
	let count = 0;
	const mix = ( v ) => {
		h = Math.imul( h ^ ( v & 0xffff ), 16777619 );
		h = Math.imul( h ^ ( v >>> 16 ), 16777619 );
	};
	for ( ;; ) {
		count++;
		mix( c.nodeTypeId );
		mix( c.startIndex );
		mix( c.endIndex );
		if ( c.nodeIsMissing ) {
			mix( 1 );
		}
		if ( c.gotoFirstChild() ) {
			continue;
		}
		while ( ! c.gotoNextSibling() ) {
			if ( ! c.gotoParent() ) {
				c.delete();
				return `${ count }:${ h >>> 0 }`;
			}
		}
	}
}

const isComment = ( n ) => /comment/.test( n.type ) && n.type !== 'ERROR';

// Nodes that bound a locked region: the smallest enclosing declaration of a
// parse error is compared byte for byte, not just the ERROR node itself,
// because the grammar's recovery may mis-classify code next to the error.
const LOCK_BOUNDARY = /(^|_)(function|method|item|definition|declaration|class|module|singleton_method|impl|trait|struct|enum|interface|namespace|lambda|closure)($|_)/;

// Nodes that hold a list of declarations or statements (namespace, class and
// enum bodies, preprocessor conditionals, statement blocks). An error directly
// inside one locks only the broken statement and its nearest code neighbours,
// not the whole container: otherwise one bad line in a namespace, an
// include-guarded header or a long function would lock all of it.
const CONTAINER = /^(declaration_list|field_declaration_list|enumerator_list|preproc_(if|ifdef|ifndef|elif|elifdef|elifndef|else)|statements|statement_list|compound_statement|block|body_statement)$|^(class|enum|enum_class|interface|struct|protocol|object|trait|impl|module)_body$/;

/**
 * Finds the regions to lock: for each parse error, its smallest enclosing
 * declaration; or, when the error sits directly in a container or at the top
 * level, the statement that holds it and its nearest non-comment siblings.
 *
 * @param {Object} root Tree-sitter root node.
 * @return {Set<string>} `start:end` keys of the nodes to compare as raw text.
 */
export function lockedRegions( root ) {
	const keys = new Set();
	const add = ( n ) => keys.add( n.startIndex + ':' + n.endIndex );
	// The comments between the statement and its neighbours are locked too:
	// next to a parse error, a "comment" may be code or string text that the
	// grammar misread.
	const addWithNeighbours = ( n ) => {
		add( n );
		for ( const step of [ 'previousSibling', 'nextSibling' ] ) {
			let s = n[ step ];
			while ( s && isComment( s ) ) {
				add( s );
				s = s[ step ];
			}
			if ( s ) {
				add( s );
			}
		}
	};
	const visit = ( n ) => {
		// A root that is itself an ERROR (the whole file failed to parse as
		// one unit) acts as the container: its broken children lock, the
		// well-formed ones are compared as usual.
		if ( ( n.type === 'ERROR' && n.parent ) || n.isMissing ) {
			let lock = n;
			for ( let p = n.parent; ; p = p.parent ) {
				if ( ! p || ! p.parent || CONTAINER.test( p.type ) ) {
					// A missing token (`;` after a macro call such as
					// `ZTEST(suite, name) { … }`) is a zero-width insertion: the
					// code around it parses normally, so only its statement locks.
					if ( n.isMissing ) {
						add( lock );
					} else {
						addWithNeighbours( lock );
					}
					break;
				}
				lock = p;
				if ( LOCK_BOUNDARY.test( p.type ) ) {
					add( lock );
					break;
				}
			}
			return;
		}
		if ( ! n.hasError ) {
			return;
		}
		for ( let i = 0; i < n.childCount; i++ ) {
			visit( n.child( i ) );
		}
	};
	visit( root );
	return keys;
}

/**
 * Tells whether an Elixir node is a doc attribute with text: `@moduledoc`,
 * `@doc` or `@typedoc` followed by a string or a `~s` / `~S` sigil. The
 * attribute is documentation, like a Python docstring; `@doc false` stays
 * code.
 *
 * @param {Object} n Tree-sitter node.
 * @return {boolean} True for a doc attribute.
 */
function exDocstring( n ) {
	if ( n.type !== 'unary_operator' || ! n.text.startsWith( '@' ) ) {
		return false;
	}
	const call = n.namedChildren[ 0 ];
	const name = call?.type === 'call' ? call.namedChildren[ 0 ]?.text : '';
	const arg = call?.namedChildren[ 1 ]?.namedChildren;
	return /^(moduledoc|doc|typedoc)$/.test( name ) && arg?.length === 1 &&
		( arg[ 0 ].type === 'string' || ( arg[ 0 ].type === 'sigil' && /^~[sS]/.test( arg[ 0 ].text ) ) );
}

/**
 * Tells whether a Python node is a docstring: a plain string expression that
 * is the first statement of a module, class or function body.
 *
 * @param {Object} n Tree-sitter node.
 * @return {boolean} True for a docstring.
 */
function isDocstring( n ) {
	if ( n.type !== 'expression_statement' || n.namedChildCount !== 1 || n.namedChild( 0 ).type !== 'string' ) {
		return false;
	}
	const start = n.namedChild( 0 ).child( 0 );
	if ( ! start || ! /^[rRuU]?("""|'''|"|')$/.test( start.text ) ) {
		return false;
	}
	const p = n.parent;
	if ( ! p || ! ( p.type === 'module' || ( p.type === 'block' && /^(class|function)_definition$/.test( p.parent?.type ) ) ) ) {
		return false;
	}
	for ( let i = 0; i < p.namedChildCount; i++ ) {
		const c = p.namedChild( i );
		if ( ! isComment( c ) ) {
			return c.startIndex === n.startIndex;
		}
	}
	return false;
}

/**
 * Strips comment markers and returns the content lines.
 *
 * @param {string} text Raw comment or docstring text.
 * @return {string[]} Trimmed lines (empty lines kept, so doctest blocks can end).
 */
function bodyLines( text ) {
	return text
		.replace( /^(<#|\/\*+!?|\/\/[/!]?|#+|;+|%+|-{2,}|\{-|@(module|type)?doc\s+(~[sS])?("""|")|[rRuU]?("""|'''|"|'))/, '' )
		.replace( /(\*\/|-\}|#>|"""|'''|"|')\s*$/, '' )
		.split( '\n' )
		.map( ( l ) => l.replace( /^\s*(\*(?!\/)|\/\/[/!]?|#+|;+|%+|-{2,})?\s?/, '' ).replace( /\s+/g, ' ' ).trim() );
}

/**
 * Reduces a typed PHPDoc tag line to the parts that must survive.
 *
 * @param {string} line Trimmed line such as `@param int $id The ID.`.
 * @return {string[]} Keys such as `@param int $id` (and `@param $id`, so an
 *                    untyped original is satisfied when a type is added).
 */
function phpTypedKeys( line ) {
	const tag = /^@\S+/.exec( line )[ 0 ];
	// Tags whose whole signature is the type: a `@method` declaration (up to
	// its closing parenthesis), and type aliases and template bounds, which
	// survive whole.
	if ( /^@(method|(phpstan|psalm)-(type|import-type)|template\S*)$/.test( tag ) ) {
		const open = line.indexOf( '(' );
		if ( tag === '@method' && open > 0 ) {
			let depth = 0;
			for ( let k = open; k < line.length; k++ ) {
				depth += line[ k ] === '(' ? 1 : line[ k ] === ')' ? -1 : 0;
				if ( depth === 0 ) {
					return [ line.slice( 0, k + 1 ) ];
				}
			}
		}
		return [ line ];
	}
	// LDoc `@tparam type name`: the type and the name both survive.
	if ( tag === '@tparam' ) {
		return [ line.split( ' ' ).slice( 0, 3 ).join( ' ' ) ];
	}
	let i = tag.length;
	while ( line[ i ] === ' ' ) {
		i++;
	}
	// The type runs to the first space outside <>, {}, () and [] (array<string, int>, array{id: int}).
	// A callable type's `:` is followed by its return type (`callable(int): bool`).
	let type = '';
	let depth = 0;
	for ( ; i < line.length; i++ ) {
		const ch = line[ i ];
		if ( '<{(['.includes( ch ) ) {
			depth++;
		} else if ( '>})]'.includes( ch ) ) {
			depth--;
		} else if ( ch === ' ' && depth <= 0 ) {
			if ( ! type.endsWith( ':' ) ) {
				break;
			}
		}
		type += ch;
	}
	if ( type.startsWith( '$' ) || type.startsWith( '&$' ) || type.startsWith( '...$' ) ) {
		// No type: `@param $id`. Only the name must survive, so a type may be added.
		return [ `${ tag } ${ type }` ];
	}
	const rest = line.slice( i ).trim();
	const v = /^[&.]*\$\w+/.exec( rest );
	const typed = [ tag, type, ...( v ? [ v[ 0 ] ] : [] ) ].join( ' ' );
	// A typed line also satisfies the untyped form, so adding a type passes.
	return v ? [ typed, `${ tag } ${ v[ 0 ] }` ] : [ typed ];
}

/**
 * Classifies one comment for a language.
 *
 * @param {Object}  L         Language settings.
 * @param {string}  text      Raw comment text.
 * @param {Object}  opts      Options: `checkedTypes` keeps typed tag lines.
 * @param {boolean} docstring Whether the text is a Python docstring.
 * @return {{whole: boolean, frozen: string[], kept: string[]}} Classification.
 */
function classifyTs( L, text, opts, docstring ) {
	const lines = bodyLines( text );
	const first = lines.find( Boolean ) || '';
	// A shebang (`#!` at the very start of the comment) is code in every language that has one.
	const whole = ( ! docstring && ( L.whole.some( ( re ) => re.test( first ) ) || !! L.wholeRaw?.test( text ) || text.startsWith( '#!' ) ) ) || lines.some( ( l ) => L.wholeLine.test( l ) );
	const frozen = [];
	const kept = [];
	if ( whole ) {
		return { whole, frozen, kept };
	}
	// A one-line comment whose raw text marks it as a type annotation
	// (LuaLS `---@param x string`) survives whole.
	if ( L.keptRaw?.test( text ) && lines.length === 1 ) {
		kept.push( lines[ 0 ] );
		return { whole, frozen, kept };
	}
	let doctest = false;
	for ( const l of joinTagLines( lines ) ) {
		// Doctests: a `>>>` (Python) or `iex>` (Elixir) line, its continuations
		// and the expected output up to the next blank line all run as tests.
		if ( ( L.docstrings && docstring ) || L.doctestComments ) {
			if ( ( L.doctest || /^>>>/ ).test( l ) ) {
				doctest = true;
			} else if ( l === '' ) {
				doctest = false;
			}
			if ( doctest ) {
				frozen.push( l );
				continue;
			}
		}
		if ( ! l ) {
			continue;
		}
		if ( L.frozenLine?.test( l ) ) {
			frozen.push( l );
		} else if ( L.keptWhole?.test( l ) ) {
			kept.push( l );
		} else if ( L.keptTyped?.test( l ) || ( opts.checkedTypes && L.checkedTyped?.test( l ) ) ) {
			kept.push( ...phpTypedKeys( l ) );
		}
	}
	return { whole, frozen, kept };
}

/**
 * Builds the comparison model for one file.
 *
 * @param {string} lang Language key.
 * @param {string} src  Source text.
 * @param {Object} opts Options for classifyTs().
 * @return {Promise<Object>} {lang, code, layout, comments, errors, nextLine}.
 */
export async function tsModel( lang, src, opts = {} ) {
	const L = LANGS[ lang ];
	const tree = await parse( lang, src );
	const tokens = [];
	const comments = [];
	// Comment anchors count leaf tokens only: grammars differ in which node a comment
	// joins (tree-sitter-python puts comments that open a body before its `block`
	// node, and inside it once a docstring comes first), but the leaves around it do not.
	let leaves = 0;
	let lastLeafRow = -1;
	let errors = 0;
	// Line ranges of the locked regions, for `LOCKED:` lines.
	const regions = [];
	const context = [];
	const locked = tree.rootNode.hasError ? lockedRegions( tree.rootNode ) : new Set();
	// Python docstrings that are code: PLY reads each rule's docstring as its
	// token regex or grammar production, and docopt parses the module
	// docstring as the command-line spec.
	// PLY may be vendored (`from .ply import yacc`, `from mypkg.ply import lex`).
	const plyDocs = lang === 'python' && ( /^\s*(?:from\s+[\w.]*\bply\b|import\s+(?:[\w.]+\.)?ply\b)/m.test( src ) || /\b(?:lex\.lex|yacc\.yacc|TOKEN)\s*\(/.test( src ) );
	const docoptDocs = lang === 'python' && /^\s*(from|import)\s+docopt\b/m.test( src );

	const addComment = ( n, docstring ) => {
		let text = src.slice( n.startIndex, n.endIndex );
		// Some grammars include the line break that ends a line comment.
		const trimmed = text.replace( /\r?\n$/, '' );
		const end = n.startIndex + trimmed.length;
		text = trimmed;
		const trailing = n.startPosition.row === lastLeafRow;
		comments.push( {
			text,
			start: n.startIndex,
			end,
			line: n.startPosition.row + 1,
			endLine: n.startPosition.row + 1 + ( text.match( /\n/g ) || [] ).length,
			anchor: trailing ? `${ leaves }~` : `${ leaves }`,
			docstring,
			context: [ ...context ],
			...( opts.classify ? opts.classify( text ) : classifyTs( L, text, opts, docstring ) ),
		} );
		if ( docstring && ( plyDocs || ( docoptDocs && n.parent?.type === 'module' ) ) ) {
			Object.assign( comments[ comments.length - 1 ], { whole: true, frozen: [], kept: [] } );
		}
	};

	const visit = ( n ) => {
		if ( n.type === 'ERROR' && ! n.parent ) {
			errors++;
		} else if ( n.type === 'ERROR' || n.isMissing || ( locked.size && locked.has( n.startIndex + ':' + n.endIndex ) && n.parent ) ) {
			errors++;
			regions.push( [ n.startPosition.row + 1, n.endPosition.row + 1 ] );
			tokens.push( 'ERR\u0000' + src.slice( n.startIndex, n.endIndex ) );
			leaves++;
			lastLeafRow = n.endPosition.row;
			return;
		}
		if ( isComment( n ) ) {
			addComment( n, false );
			return;
		}
		if ( L.docstrings && ( lang === 'clojure' ? cljDocstring( n ) : lang === 'elixir' ? exDocstring( n ) : isDocstring( n ) ) ) {
			addComment( n, true );
			return;
		}
		// An empty node (the module of an empty file) is the same code as one whose only
		// children are comments or docstrings: both are an open and a close.
		if ( n.childCount === 0 && n.startIndex === n.endIndex && n.isNamed ) {
			tokens.push( '(' + n.type, ')' );
			return;
		}
		if ( n.childCount === 0 ) {
			tokens.push( n.type + '\u0000' + n.text );
			leaves++;
			lastLeafRow = n.endPosition.row;
			return;
		}
		// Go: comments inside an Example function are its expected output.
		const ctx = lang === 'go' && n.type === 'function_declaration' && /^Example/.test( n.childForFieldName( 'name' )?.text || '' ) ? 'example' : null;
		if ( ctx ) {
			context.push( ctx );
		}
		if ( n.isNamed ) {
			tokens.push( '(' + n.type );
		}
		// Some grammars (Dart) keep string contents as text between child
		// nodes rather than as a node, so that text is code too. Inside a
		// string even whitespace counts.
		const keepSpace = /string|template|heredoc/.test( n.type );
		let at = n.startIndex;
		const gap = ( end ) => {
			const text = src.slice( at, end );
			if ( keepSpace ? text.length : /\S/.test( text ) ) {
				tokens.push( 'text\u0000' + ( keepSpace ? text : text.trim() ) );
				leaves++;
			}
		};
		for ( let i = 0; i < n.childCount; i++ ) {
			const c = n.child( i );
			gap( c.startIndex );
			at = c.endIndex;
			visit( c );
		}
		gap( n.endIndex );
		if ( n.isNamed ) {
			tokens.push( ')' );
		}
		if ( ctx ) {
			context.pop();
		}
	};
	visit( tree.rootNode );
	// Trees live in wasm memory: free each one, or a large repository
	// exhausts the heap (`Aborted()` in ts_malloc).
	tree.delete();

	postProcess( lang, src, comments );
	return {
		lang: 'ts:' + lang,
		code: tokens.join( '\u0001' ),
		// A Clojure docstring sits inside its form, so the layout may rejoin the code around it.
		layout: layoutLines( src, comments.map( ( c ) => ( { start: c.start, end: c.end, join: lang === 'clojure' && c.docstring } ) ) ),
		comments,
		errors,
		regions,
		nextLine: L.nextLine,
		cfgs: [],
	};
}

/**
 * Applies the comment rules that depend on neighbouring comments or code.
 *
 * - Rust: lines inside a fenced block in a doc comment are doctests.
 * - Go: comments in an Example function, and the cgo preamble directly
 *   before `import "C"`, are code.
 *
 * @param {string}   lang     Language key.
 * @param {string}   src      Source text.
 * @param {Object[]} comments Comments from tsModel(), in source order.
 */
function postProcess( lang, src, comments ) {
	if ( lang === 'rust' ) {
		let fence = false;
		let prevLine = -2;
		for ( const c of comments ) {
			const isDoc = /^(\/\/\/|\/\/!|\/\*\*|\/\*!)/.test( c.text );
			if ( ! isDoc || c.line !== prevLine + 1 ) {
				fence = false;
			}
			if ( isDoc ) {
				const body = bodyLines( c.text ).join( '\n' );
				const marker = /^```/.test( body );
				// A fence inside one block doc comment, or a line indented four
				// spaces past the marker's own space (an indented code block), is a doctest too.
				if ( ( /^\/\*/.test( c.text ) && /(^|\n)\s*\*?\s*```/.test( c.text ) ) || /^\/\/[/!] {5,}\S/.test( c.text ) ) {
					c.whole = true;
				}
				if ( fence || marker ) {
					c.whole = true;
				}
				if ( marker ) {
					fence = ! fence;
				}
			}
			prevLine = c.endLine;
		}
	}
	if ( LANGS[ lang ].doctestComments ) {
		// A doctest spans consecutive line comments (`-- >>> add 1 2` then
		// `-- 3`): the expected output up to a blank comment line runs too.
		const start = LANGS[ lang ].doctest;
		let open = false;
		let prevLine = -2;
		for ( const c of comments ) {
			const body = bodyLines( c.text );
			if ( c.line !== prevLine + 1 || body.length > 1 ) {
				open = false;
			}
			if ( body.length === 1 ) {
				if ( start.test( body[ 0 ] ) ) {
					open = true;
				} else if ( body[ 0 ] === '' ) {
					open = false;
				}
				if ( open && body[ 0 ] && ! c.whole && ! c.frozen.includes( body[ 0 ] ) ) {
					c.frozen.push( body[ 0 ] );
				}
			}
			prevLine = c.endLine;
		}
	}
	if ( lang === 'go' ) {
		const lines = src.split( '\n' );
		for ( const c of comments ) {
			if ( c.context.includes( 'example' ) ) {
				c.whole = true;
			}
		}
		lines.forEach( ( l, i ) => {
			if ( /^import\s+"C"/.test( l ) ) {
				// The comment block that ends on the line just above is C code.
				let row = i;
				for ( let k = comments.length - 1; k >= 0; k-- ) {
					if ( comments[ k ].endLine === row ) {
						comments[ k ].whole = true;
						row = comments[ k ].line - 1;
					}
				}
			}
		} );
	}
}

// --- Coverage ----------------------------------------------------------------

/**
 * Collects the comment siblings directly before a node.
 *
 * Skips over the node types in `skip` (attributes, decorators). Stops at
 * any other node, or at a blank line between the comment and what follows.
 *
 * @param {Object} n    Tree-sitter node.
 * @param {RegExp} skip Node types to look past.
 * @return {Object[]} Comment nodes, nearest first.
 */
function leadingComments( n, skip ) {
	const out = [];
	let top = n.startPosition.row;
	// The first statement of a body can sit in a wrapper node that starts where it
	// starts (tree-sitter-ruby's `body_statement`), with the comment above it left in
	// the enclosing class or module: look before the wrapper too.
	let first = n;
	while ( ! first.previousSibling && first.parent && first.parent.parent && first.parent.startIndex === first.startIndex ) {
		first = first.parent;
	}
	for ( let s = first.previousSibling; s; s = s.previousSibling ) {
		if ( isComment( s ) ) {
			if ( s.endPosition.row < top - 1 ) {
				break;
			}
			out.push( s );
			top = s.startPosition.row;
		} else if ( skip && skip.test( s.type ) ) {
			top = s.startPosition.row;
		} else {
			// Kotlin's grammar ends the package line and the last import at the next token,
			// so a doc comment above the first declaration is that node's last child.
			const h = s.type === 'import_list' ? s.lastNamedChild : s;
			if ( /^(import_header|package_header)$/.test( h?.type ) ) {
				for ( let i = h.namedChildCount - 1; i >= 0; i-- ) {
					const c = h.namedChild( i );
					if ( ! isComment( c ) || c.endPosition.row < top - 1 ) {
						break;
					}
					out.push( c );
					top = c.startPosition.row;
				}
			}
			break;
		}
	}
	return out;
}

/**
 * Leading comments that carry prose: directives, magic comments, license
 * blocks and other frozen comments do not count as documentation.
 *
 * @param {Object} n    Tree-sitter node.
 * @param {RegExp} skip Node types to look past.
 * @param {Object} L    Language settings.
 * @return {Object[]} Comment nodes, nearest first.
 */
function proseComments( n, skip, L ) {
	return leadingComments( n, skip ).filter( ( c ) => ! classifyTs( L, c.text, {}, false ).whole && ! L.nextLine?.test( c.text ) && ! /^#:|^#\s*@(rbs|!)/.test( c.text ) );
}

const hasModifier = ( n, word ) => new RegExp( `\\b${ word }\\b` ).test( n.text.slice( 0, n.text.indexOf( '{' ) >= 0 ? n.text.indexOf( '{' ) : 200 ).split( '\n' )[ 0 ] );

/**
 * Coverage rules per language: which nodes need a doc comment, and how.
 *
 * `need( n, f )` returns the declaration's name when the node needs a doc
 * comment, or null. `documented( n, L )` checks for one. `header( root, f )`
 * returns false when the file lacks its header comment.
 *
 * @type {Object<string, Object>}
 */
const COVER = {
	php: {
		need: ( n, f ) => {
			if ( ! /^(class|interface|trait|enum)_declaration$|^function_definition$|^method_declaration$|^property_declaration$|^const_declaration$/.test( n.type ) ) {
				return null;
			}
			const name = n.childForFieldName( 'name' )?.text || n.namedChildren.find( ( c ) => /element$/.test( c.type ) )?.text || n.type;
			if ( n.type === 'method_declaration' && name === '__construct' ) {
				const params = n.childForFieldName( 'parameters' );
				const body = n.childForFieldName( 'body' );
				if ( params && params.namedChildren.every( ( p ) => p.type === 'property_promotion_parameter' || isComment( p ) ) && body && body.namedChildCount === 0 ) {
					return null;
				}
			}
			if ( /(^|\/)tests?\/|Test\.php$/.test( f ) && n.type === 'method_declaration' &&
				( /^(test|setUp|tearDown|setUpBeforeClass|tearDownAfterClass)|Provider$/.test( name ) || /#\[Test\]|@test\b/.test( n.text.slice( 0, 200 ) + ( n.previousSibling?.text || '' ) ) ) ) {
				return null;
			}
			// Framework configuration properties whose meaning the framework defines.
			if ( n.type === 'property_declaration' && /\$(table|fillable|guarded|hidden|visible|casts|with|withCount|appends|primaryKey|timestamps|connection|keyType|incrementing|perPage|dates|touches|signature|description|middleware|middlewareGroups|middlewareAliases|commands|listen|subscribe|policies|dontReport|dontFlash|except|namespace|model)\b/.test( n.text ) ) {
				return null;
			}
			return name;
		},
		documented: ( n, L ) => proseComments( n, /^attribute_list$/, L ).some( ( c ) => L.doc( c.text ) ),
		header: ( root, L ) => {
			// A template (inline HTML around PHP) needs no file docblock.
			if ( root.namedChildren.some( ( c ) => c.type === 'text' || c.type === 'text_interpolation' ) ) {
				return true;
			}
			// The header may follow `namespace`, `use` and `declare` statements.
			const kids = root.namedChildren.filter( ( c ) => ! /^(php_tag|text|namespace_use_declaration|declare_statement)$/.test( c.type ) && ! ( c.type === 'namespace_definition' && ! c.childForFieldName( 'body' ) ) );
			const first = kids.findIndex( ( c ) => ! isComment( c ) );
			const docs = kids.slice( 0, first < 0 ? kids.length : first ).filter( ( c ) => L.doc( c.text ) );
			const decl = first >= 0 && /declaration|definition/.test( kids[ first ].type ) && ! /namespace/.test( kids[ first ].type );
			return docs.length > ( decl ? 1 : 0 );
		},
	},
	python: {
		need: ( n, f ) => {
			if ( ! /^(class|function)_definition$/.test( n.type ) ) {
				return null;
			}
			const name = n.childForFieldName( 'name' )?.text || '';
			const outer = n.parent?.type === 'decorated_definition' ? n.parent : n;
			const decorators = outer === n ? '' : outer.namedChildren.filter( ( c ) => c.type === 'decorator' ).map( ( c ) => c.text ).join( ' ' );
			if ( /^__(?!init__|call__).+__$/.test( name ) || /@([\w.]+\.)?overload\b|@\w+\.(setter|deleter)\b/.test( decorators ) ) {
				return null;
			}
			if ( n.type === 'class_definition' && name === 'Meta' ) {
				return null;
			}
			if ( /(^|\/)(tests?|testing)\/|(^|\/)test_[^/]*\.py$|_test\.py$|(^|\/)tests\.py$|conftest\.py$/.test( f ) && /^(test_|Test|setUp|tearDown|asyncSetUp|asyncTearDown|setUpClass|tearDownClass|setUpTestData)/.test( name ) ) {
				return null;
			}
			return name;
		},
		documented: ( n ) => {
			const body = n.childForFieldName( 'body' );
			const first = body?.namedChildren.find( ( c ) => ! isComment( c ) );
			if ( first && isDocstring( first ) ) {
				return true;
			}
			// A nested function, or a one-line definition (where a docstring would
			// move code), may be explained by a comment above it instead.
			const outer = n.parent?.type === 'decorated_definition' ? n.parent : n;
			let nested = false;
			for ( let p = outer.parent; p; p = p.parent ) {
				if ( p.type === 'function_definition' ) {
					nested = true;
					break;
				}
			}
			const oneLine = body && body.startPosition.row === n.startPosition.row;
			return ( nested || oneLine ) && proseComments( outer, null, LANGS.python ).length > 0;
		},
		// With --line-docs (PLY or docopt files, whose docstrings are frozen),
		// a prose `#` block before the first statement is the header too.
		header: ( root, L, lineDocs ) => {
			const first = root.namedChildren.find( ( c ) => ! isComment( c ) );
			if ( first && isDocstring( first ) ) {
				return true;
			}
			return !! lineDocs && root.namedChildren.some( ( c ) => isComment( c ) && ( ! first || c.startIndex < first.startIndex ) &&
				! classifyTs( L, c.text, {}, false ).whole && ! L.nextLine?.test( c.text ) );
		},
	},
	go: {
		need: ( n, f ) => {
			const top = n.parent?.type === 'source_file';
			if ( ( n.type === 'function_declaration' || n.type === 'method_declaration' ) && top ) {
				const name = n.childForFieldName( 'name' )?.text || '';
				if ( name === 'main' || name === 'init' || ( /_test\.go$/.test( f ) && /^(Test|Benchmark|Fuzz|Example)/.test( name ) ) ) {
					return null;
				}
				return name;
			}
			if ( /^(type|const|var)_declaration$/.test( n.type ) && top ) {
				return n.namedChild( 0 )?.namedChild( 0 )?.text || n.type;
			}
			return null;
		},
		documented: ( n, L ) => proseComments( n, null, L ).length > 0,
		header: null,
	},
	rust: {
		need: ( n, f, chain ) => {
			if ( ! /^(function_item|function_signature_item|struct_item|enum_item|union_item|trait_item|type_item|const_item|static_item|mod_item|macro_definition|field_declaration|enum_variant)$/.test( n.type ) ) {
				return null;
			}
			const attrs = leadingAttrs( n );
			if ( /#\[(\w+::)*(test|bench)\b/.test( attrs ) ) {
				return null;
			}
			if ( n.type === 'mod_item' && ! n.childForFieldName( 'body' ) ) {
				return null;
			}
			// Methods of a trait implementation inherit the trait's docs.
			if ( /^(function|type|const)_item$/.test( n.type ) && chain.some( ( c ) => c.type === 'impl_item' && c.childForFieldName( 'trait' ) ) ) {
				return null;
			}
			return n.childForFieldName( 'name' )?.text || n.type;
		},
		skipSubtree: ( n ) => n.type === 'mod_item' && /#\[cfg\((all|any)?\(?[^\]]*\btest\b/.test( leadingAttrs( n ) ),
		documented: ( n, L ) => proseComments( n, /^attribute_item$/, L ).some( ( c ) => L.doc( c.text ) ) || /#\[doc\s*=/.test( leadingAttrs( n ) ),
		header: ( root ) => root.namedChildren.some( ( c ) => ( isComment( c ) && /^(\/\/!|\/\*!)/.test( c.text ) ) || ( c.type === 'inner_attribute_item' && /doc/.test( c.text ) ) ),
	},
	ruby: {
		need: ( n, f ) => {
			if ( ! /^(class|module|method|singleton_method)$/.test( n.type ) ) {
				return null;
			}
			const name = n.childForFieldName( 'name' )?.text || n.type;
			if ( n.type === 'method' && /(^|\/)(test|tests|spec)\//.test( f ) && /^test_/.test( name ) ) {
				return null;
			}
			return name;
		},
		documented: ( n, L ) => proseComments( n, null, L ).length > 0,
		header: ( root ) => {
			const stmts = root.namedChildren.filter( ( c ) => ! isComment( c ) );
			if ( stmts.length === 1 && /^(class|module)$/.test( stmts[ 0 ].type ) ) {
				return true;
			}
			const first = root.namedChildren.findIndex( ( c ) => ! isComment( c ) );
			return root.namedChildren.slice( 0, first < 0 ? undefined : first ).some( ( c ) => isComment( c ) && ! classifyTs( LANGS.ruby, c.text, {}, false ).whole && ! LANGS.ruby.nextLine.test( c.text ) );
		},
	},
	java: {
		need: ( n ) => {
			if ( ! /^(class|interface|enum|record|annotation_type)_declaration$|^(method|constructor|field)_declaration$/.test( n.type ) ) {
				return null;
			}
			const mods = n.namedChildren.find( ( c ) => c.type === 'modifiers' )?.text || '';
			if ( /@(Override|Test|ParameterizedTest|RepeatedTest|TestFactory|BeforeEach|AfterEach|BeforeAll|AfterAll|Before|After)\b/.test( mods ) ) {
				return null;
			}
			// A constructor that only stores injected dependencies (`this.repo = repo;`).
			if ( n.type === 'constructor_declaration' ) {
				const params = ( n.childForFieldName( 'parameters' )?.namedChildren || [] ).map( ( p ) => p.childForFieldName( 'name' )?.text );
				const stmts = ( n.childForFieldName( 'body' )?.namedChildren || [] ).filter( ( c ) => ! isComment( c ) );
				if ( params.length && stmts.length && stmts.every( ( st ) => /^this\.(\w+)\s*=\s*(\w+)\s*;$/.test( st.text ) && params.includes( /=\s*(\w+)/.exec( st.text )[ 1 ] ) ) ) {
					return null;
				}
			}
			return n.childForFieldName( 'name' )?.text || n.namedChildren.find( ( c ) => c.type === 'variable_declarator' )?.text || n.type;
		},
		documented: ( n, L ) => proseComments( n, null, L ).some( ( c ) => L.doc( c.text ) ),
		header: null,
	},
	kotlin: {
		need: ( n ) => {
			if ( ! /^(class|object|function|property)_declaration$/.test( n.type ) ) {
				return null;
			}
			if ( n.type === 'property_declaration' && ! /^(source_file|class_body)$/.test( n.parent?.type ) ) {
				return null;
			}
			if ( hasModifier( n, 'override' ) || /@Test\b/.test( n.text.split( '\n' )[ 0 ] ) ) {
				return null;
			}
			return n.namedChildren.find( ( c ) => /identifier|variable_declaration/.test( c.type ) )?.text || n.type;
		},
		documented: ( n, L ) => proseComments( n, null, L ).some( ( c ) => L.doc( c.text ) ),
		header: null,
	},
	csharp: {
		need: ( n ) => {
			if ( ! /^(class|struct|interface|enum|record|delegate|method|constructor|property|field|event|event_field)_declaration$/.test( n.type ) ) {
				return null;
			}
			if ( n.namedChildren.some( ( c ) => c.type === 'modifier' && c.text === 'override' ) || /\[(Fact|Theory|Test|TestMethod|TestCase)\b/.test( n.text.split( '\n' )[ 0 ] ) ) {
				return null;
			}
			return n.childForFieldName( 'name' )?.text || n.type;
		},
		documented: ( n, L ) => proseComments( n, null, L ).some( ( c ) => L.doc( c.text ) ),
		header: null,
	},
	swift: {
		need: ( n, f ) => {
			if ( ! /^(class|protocol|function|property|init|typealias|protocol_function)_declaration$/.test( n.type ) ) {
				return null;
			}
			// `extension`, also after attributes and access modifiers (`public extension`, `@MainActor extension`).
			if ( n.type === 'class_declaration' && /^(@\w+(\([^)]*\))?\s+)*((public|internal|package|private|fileprivate|open)\s+)*extension\b/.test( n.text ) ) {
				return null;
			}
			if ( n.type === 'property_declaration' && ! /^(source_file|class_body|protocol_body|enum_class_body)$/.test( n.parent?.type ) ) {
				return null;
			}
			const name = n.namedChildren.find( ( c ) => /identifier|pattern/.test( c.type ) )?.text || n.type;
			if ( hasModifier( n, 'override' ) || ( /Tests?\.swift$/.test( f ) && /^test/.test( name ) ) ) {
				return null;
			}
			return name;
		},
		documented: ( n, L ) => proseComments( n, null, L ).some( ( c ) => L.doc( c.text ) ),
		header: null,
	},
	dart: {
		// Top-level functions and variables are flat siblings in this grammar
		// (`annotation`, `final`, a type, then the declaration list), so the
		// doc comment is found by looking past them.
		need: ( n, f ) => {
			const test = /_test\.dart$/.test( f );
			const top = n.parent?.type === 'program';
			if ( /^(class_definition|mixin_declaration|extension_declaration|extension_type_declaration|enum_declaration)$/.test( n.type ) ) {
				return n.childForFieldName( 'name' )?.text || n.namedChildren.find( ( c ) => c.type === 'identifier' )?.text || n.type;
			}
			if ( n.type === 'type_alias' ) {
				return n.namedChildren.find( ( c ) => /identifier$/.test( c.type ) )?.text || n.type;
			}
			if ( top && n.type === 'function_signature' ) {
				const name = n.namedChildren.find( ( c ) => c.type === 'identifier' )?.text || n.type;
				return test && name === 'main' ? null : name;
			}
			if ( top && /^(static_final_declaration_list|initialized_identifier_list)$/.test( n.type ) ) {
				return n.text.split( /[=,]/ )[ 0 ].trim();
			}
			if ( ! /^(class_body|extension_body|enum_body)$/.test( n.parent?.type ) || ! /^(method_signature|declaration)$/.test( n.type ) ) {
				return null;
			}
			const before = dartAnnotations( n );
			if ( /@override\b/.test( before ) || ( test && /@(isTest|isTestGroup)\b/.test( before ) ) ) {
				return null;
			}
			const sig = n.namedChildren.find( ( c ) => /signature$|identifier_list$|declaration_list$/.test( c.type ) );
			if ( ! sig ) {
				return null;
			}
			const name = sig.type === 'operator_signature'
				? sig.text.slice( sig.text.indexOf( 'operator' ), sig.text.indexOf( '(' ) ).trim()
				: /_list$/.test( sig.type ) ? sig.text.split( /[=,]/ )[ 0 ].trim()
				: sig.namedChildren.find( ( c ) => c.type === 'identifier' )?.text || sig.text.split( /[(\s]/ )[ 0 ];
			if ( /constructor_signature$/.test( sig.type ) && sig.type !== 'factory_constructor_signature' ) {
				// A constructor that only stores its arguments (`this.x`, `super.key`).
				const params = sig.text.slice( sig.text.indexOf( '(' ) + 1, sig.text.lastIndexOf( ')' ) ).replace( /[{}[\]]/g, '' ).split( ',' ).map( ( p ) => p.trim() ).filter( Boolean );
				if ( params.every( ( p ) => /^(required\s+)?(this|super)\.\w+(\s*=.*)?$/.test( p ) ) && n.nextSibling?.type !== 'function_body' && ! /:\s*\S/.test( n.text.slice( sig.text.length ) ) ) {
					return null;
				}
			}
			if ( sig.type === 'setter_signature' && n.parent.namedChildren.some( ( c ) => c.type === 'method_signature' && c.firstNamedChild?.type === 'getter_signature' && c.firstNamedChild.namedChildren.some( ( i ) => i.type === 'identifier' && i.text === name ) ) ) {
				return null;
			}
			return name;
		},
		documented: ( n, L ) => proseComments( n, DART_SKIP, L ).some( ( c ) => L.doc( c.text ) ),
		header: ( root, L ) => {
			const kids = root.namedChildren;
			const first = kids.findIndex( ( c ) => ! isComment( c ) );
			if ( first < 0 ) {
				return true;
			}
			const prose = kids.slice( 0, first ).filter( ( c ) => ! classifyTs( L, c.text, {}, false ).whole && ! L.nextLine?.test( c.text ) );
			// A library doc on a `library` directive, or a comment block that a
			// blank line separates from the first import or declaration.
			if ( kids[ first ].type === 'library_name' ) {
				return prose.length > 0;
			}
			return prose.some( ( c ) => {
				const next = c.nextSibling;
				return next && next.startPosition.row > c.endPosition.row + 1;
			} );
		},
	},
	elixir: {
		// Public functions, macros and callbacks take `@doc`, modules
		// `@moduledoc`, public types `@typedoc`; private functions a `#`
		// comment (Elixir discards `@doc` on `defp`). Only the first clause of
		// a multi-clause function needs one.
		//
		// `defimpl` bodies implement a protocol that documents them.
		skipSubtree: ( n ) => n.type === 'call' && n.namedChildren[ 0 ]?.type === 'identifier' && n.namedChildren[ 0 ].text === 'defimpl',
		need: ( n ) => {
			if ( n.type === 'unary_operator' ) {
				const m = /^@(type|opaque|callback|macrocallback)\s+([\w?!]+)/.exec( n.text );
				return m ? m[ 2 ] : null;
			}
			if ( n.type !== 'call' ) {
				return null;
			}
			const head = n.namedChildren[ 0 ];
			if ( head?.type !== 'identifier' || ! /^(defmodule|defprotocol|def|defp|defmacro|defmacrop|defguard|defguardp|defdelegate)$/.test( head.text ) ) {
				return null;
			}
			const name = exDefName( n );
			if ( head.text !== 'defmodule' && head.text !== 'defprotocol' ) {
				if ( exEarlierClause( n, head.text, name ) ) {
					return null;
				}
				if ( /@impl\b/.test( exAttrs( n ) ) ) {
					return null;
				}
			}
			return name;
		},
		documented: ( n, L ) => {
			if ( n.type === 'unary_operator' ) {
				// Callbacks take `@doc`; types take `@typedoc`.
				const attr = /^@(callback|macrocallback)\b/.test( n.text ) ? /@doc\b/ : /@typedoc\b/;
				return attr.test( exAttrs( n ) ) || proseComments( n, /^unary_operator$/, L ).length > 0;
			}
			const head = n.namedChildren[ 0 ].text;
			if ( head === 'defmodule' || head === 'defprotocol' ) {
				const block = n.namedChildren.find( ( c ) => c.type === 'do_block' );
				// `@moduledoc` often follows `use` or `@external_resource`, and its value may be
				// computed (`File.read!` of the README, a call that returns help text).
				return !! block?.namedChildren.some( ( c ) => c.type === 'unary_operator' && /^@moduledoc\b/.test( c.text ) );
			}
			if ( /^(defp|defmacrop|defguardp)$/.test( head ) ) {
				return proseComments( n, /^unary_operator$/, L ).length > 0;
			}
			return /@doc\b/.test( exAttrs( n ) );
		},
		// A file with a module is headed by its `@moduledoc`; a script
		// (`mix.exs`, config, test helpers) by a comment at the top.
		header: ( root, L ) => {
			const mod = root.namedChildren.some( ( c ) => c.type === 'call' && /^(defmodule|defprotocol|defimpl)$/.test( c.namedChildren[ 0 ]?.text ) );
			const first = root.namedChildren.find( ( c ) => c.type !== 'comment' );
			return mod || ! first || proseComments( first, null, L ).length > 0;
		},
	},
	erlang: {
		// Functions (first form of each name), and `-type`, `-opaque`,
		// `-callback` and `-record` attributes. The doc comment may sit above
		// the `-spec`; an OTP 27 `-doc` attribute counts too.
		need: ( n, f ) => {
			if ( n.parent?.type !== 'program' ) {
				return null;
			}
			const tok = ( k ) => n.children[ k ]?.text;
			if ( n.type === 'attribute_type' ) {
				return tok( 2 ) === '(' ? tok( 3 ) : tok( 2 );
			}
			if ( n.type !== 'function' ) {
				return null;
			}
			const name = tok( 0 );
			let s = n.previousSibling;
			while ( s && ( isComment( s ) || /^attribute_(spec|doc)$/.test( s.type ) ) ) {
				s = s.previousSibling;
			}
			if ( s?.type === 'function' && s.children[ 0 ]?.text === name ) {
				return null;
			}
			if ( /_(SUITE|tests?)\.erl$/.test( f ) && ( /^(t_|prop_)|_test_?$/.test( name ) || /^(all|groups|suite|init_per_(suite|group|testcase)|end_per_(suite|group|testcase))$/.test( name ) ) ) {
				return null;
			}
			return name;
		},
		documented: ( n, L ) => {
			for ( let s = n.previousSibling; s && ( isComment( s ) || /^attribute_(spec|doc)$/.test( s.type ) ); s = s.previousSibling ) {
				if ( s.type === 'attribute_doc' ) {
					return true;
				}
			}
			return proseComments( n, /^attribute_(spec|doc)$/, L ).length > 0;
		},
		header: ( root, L ) => {
			const forms = root.namedChildren.filter( ( c ) => ! isComment( c ) );
			if ( forms.some( ( c ) => c.type === 'attribute_doc' && c.children[ 1 ]?.text === 'moduledoc' ) ) {
				return true;
			}
			const mod = forms.find( ( c ) => c.type === 'attribute' && c.children[ 1 ]?.text === 'module' ) || forms[ 0 ];
			return ! mod || root.namedChildren.slice( 0, root.namedChildren.indexOf( mod ) ).some( ( c ) => isComment( c ) && ! classifyTs( L, c.text, {}, false ).whole );
		},
	},
	haskell: {
		// Top-level type signatures and `data` / `newtype` / `type` / `class`
		// declarations take a Haddock comment (`-- |` or `{- | -}`).
		need: ( n, f ) => {
			if ( n.parent?.type !== 'program' ) {
				return null;
			}
			const toks = n.children.filter( ( c ) => ! isComment( c ) ).map( ( c ) => c.text );
			let name = null;
			if ( n.type === 'signature' ) {
				name = toks.slice( 0, toks.findIndex( ( t ) => t === '::' || t === '∷' ) ).join( ' ' );
			} else if ( n.type === 'type_declaration' ) {
				if ( /^(family|instance)$/.test( toks[ 1 ] ) ) {
					return null;
				}
				name = toks.slice( 1 ).find( ( t ) => /^\p{Lu}/u.test( t ) ) || toks[ 1 ];
			} else {
				return null;
			}
			if ( /(^|\/)tests?\/|Spec\.hs$/.test( f ) && /^(main|spec|tests)$/.test( name ) ) {
				return null;
			}
			return name;
		},
		documented: ( n, L ) => leadingComments( n, null ).some( ( c ) => L.doc( c.text ) ),
		// A Haddock module header before `module` (often a frozen block
		// with the copyright and license fields), or a comment at the top.
		header: ( root, L ) => {
			const mod = root.namedChildren.find( ( c ) => c.type === 'module' );
			const before = root.namedChildren.slice( 0, mod ? root.namedChildren.indexOf( mod ) : root.namedChildren.findIndex( ( c ) => ! isComment( c ) ) );
			return before.some( ( c ) => isComment( c ) && ( L.doc( c.text ) || ! classifyTs( L, c.text, {}, false ).whole ) );
		},
	},
	powershell: {
		// Functions, filters, classes, enums and class members. Comment-based
		// help may sit before the function or first inside its body.
		need: ( n ) => {
			if ( /^(function_statement|class_statement|enum_statement)$/.test( n.type ) ) {
				return n.namedChildren.find( ( c ) => /name$/.test( c.type ) )?.text || n.type;
			}
			if ( /^class_(method|property)_definition$/.test( n.type ) ) {
				return ( /\$?[\w-]+(?=\s*(\(|=|$))/m.exec( n.text.split( '\n' )[ 0 ].replace( /\[[^\]]*\]/g, '' ) ) || [ n.type ] )[ 0 ];
			}
			return null;
		},
		documented: ( n, L ) => {
			if ( proseComments( n, null, L ).length ) {
				return true;
			}
			// `function F ($x) {` puts the parameter list before the body's first comment.
			const inner = n.namedChildren.find( ( c ) => ! /(name|parameter_declaration)$/.test( c.type ) );
			return !! inner && isComment( inner ) && ! classifyTs( L, inner.text, {}, false ).whole;
		},
		header: ( root, L ) => {
			const first = root.namedChildren.findIndex( ( c ) => ! isComment( c ) );
			return root.namedChildren.slice( 0, first < 0 ? undefined : first ).some( ( c ) => ! classifyTs( L, c.text, {}, false ).whole ) ||
				( first >= 0 && root.namedChildren[ first ].namedChildren.findIndex( ( c ) => ! isComment( c ) ) > 0 );
		},
	},
	lua: {
		// Top-level functions (`function M.f()`, `local function f()`,
		// `M.f = function …`). Nested functions are checked by reading.
		need: ( n ) => {
			if ( n.parent?.type !== 'program' || ! /^function_(definition|assignment)$/.test( n.type ) ) {
				return null;
			}
			const words = n.children.filter( ( c ) => ! isComment( c ) ).map( ( c ) => c.text );
			if ( n.type === 'function_assignment' ) {
				return words.slice( words[ 0 ] === 'local' ? 1 : 0, words.indexOf( '=' ) ).join( '' );
			}
			const k = words.indexOf( 'function' ) + 1;
			return words.slice( k, words.indexOf( '(', k ) ).join( '' ) || 'function';
		},
		documented: ( n, L ) => proseComments( n, null, L ).length > 0,
		header: ( root, L ) => {
			const first = root.namedChildren.findIndex( ( c ) => ! isComment( c ) );
			return root.namedChildren.slice( 0, first < 0 ? undefined : first ).some( ( c ) => ! classifyTs( L, c.text, {}, false ).whole );
		},
	},
	perl: {
		// Every top-level `sub`. It is documented by a `#` comment or POD block
		// directly above it, or by a POD `=head` / `=item` line naming it
		// anywhere in the file (POD after `__END__` is common).
		need: ( n ) => ( n.type === 'sub_declaration' && n.parent?.type === 'program' ? n.namedChildren.find( ( c ) => c.type === 'identifier' && c.text !== 'sub' )?.text || 'sub' : null ),
		documented: ( n, L ) => {
			if ( proseComments( n, null, L ).length ) {
				return true;
			}
			const name = n.namedChildren.find( ( c ) => c.type === 'identifier' && c.text !== 'sub' )?.text.split( '::' ).pop();
			const re = new RegExp( `^=(head\\d|item)\\b.*\\b${ ( name || '' ).replace( /\W/g, '' ) }\\b`, 'm' );
			return !! name && n.parent.namedChildren.some( ( c ) => isComment( c ) && c.text.startsWith( '=' ) && re.test( c.text ) );
		},
		// The header is POD anywhere, or `#` prose before the first statement other than `use`
		// and `package` (many modules start with `package`, then the license, then the header).
		header: ( root, L ) => root.namedChildren.some( ( c ) => isComment( c ) && c.text.startsWith( '=' ) ) ||
			root.namedChildren.slice( 0, Math.max( 0, root.namedChildren.findIndex( ( c ) => ! isComment( c ) && c.type !== 'use' && c.type !== 'package' ) ) ).some( ( c ) => isComment( c ) && ! classifyTs( L, c.text, {}, false ).whole ),
	},
	clojure: {
		// Top-level definition forms. Function-like forms take a docstring
		// after the name; records and types, which cannot, take a `;;`
		// comment above.
		need: ( n ) => {
			if ( n.type !== 'list' || ! /^(program|reader_conditional)$/.test( n.parent?.type ) ) {
				return null;
			}
			const forms = cljForms( n );
			const head = forms[ 0 ]?.type === 'symbol' ? forms[ 0 ].text : '';
			if ( ! /^(defn-?|defmacro|defmulti|defprotocol|definterface|defrecord|deftype|([\w.-]+\/)?(defn-?|defc|defcs|defcc|defmacro))$/.test( head ) ) {
				return null;
			}
			return forms[ 1 ]?.text || head;
		},
		documented: ( n, L ) => {
			const forms = cljForms( n );
			if ( forms[ 2 ] && cljDocstring( forms[ 2 ] ) ) {
				return true;
			}
			const meta = n.namedChildren.filter( ( c ) => c.type === 'meta' ).map( ( c ) => c.text ).join( ' ' );
			return /:doc\s+"/.test( meta ) || proseComments( n, null, L ).length > 0;
		},
		header: ( root, L ) => {
			const ns = root.namedChildren.find( ( c ) => c.type === 'list' && cljForms( c )[ 0 ]?.text === 'ns' );
			if ( ns ) {
				const forms = cljForms( ns );
				return !! ( forms[ 2 ] && cljDocstring( forms[ 2 ] ) ) || proseComments( ns, null, L ).length > 0;
			}
			const first = root.namedChildren.find( ( c ) => c.type !== 'comment' );
			return ! first || proseComments( first, null, L ).length > 0;
		},
	},
};

/**
 * Name of an Elixir definition: `def add(a, b) when …` gives `add`.
 *
 * @param {Object} n `call` node of a `def…` form.
 * @return {string} The defined name, or the form's text.
 */
function exDefName( n ) {
	let a = n.namedChildren.find( ( c ) => c.type === 'arguments' )?.namedChildren[ 0 ];
	if ( a?.type === 'binary_operator' ) {
		a = a.namedChildren[ 0 ];
	}
	if ( a?.type === 'call' ) {
		a = a.namedChildren[ 0 ];
	}
	return a?.text || n.text.split( '\n' )[ 0 ];
}

/**
 * Text of the module attributes directly before an Elixir definition
 * (`@doc`, `@spec`, `@impl` …), skipping comments and stopping at the
 * previous `@type` / `@callback` declaration.
 *
 * @param {Object} n Tree-sitter node.
 * @return {string} Joined attribute source.
 */
function exAttrs( n ) {
	const out = [];
	// A definition that opens a conditional block (`if Code.ensure_loaded?(X) do def ...`)
	// takes the attributes written before the `if`.
	while ( ! n.previousNamedSibling && exCondBlock( n.parent ) ) {
		n = n.parent.parent;
	}
	for ( let s = n.previousSibling; s && ( s.type === 'unary_operator' || isComment( s ) ); s = s.previousSibling ) {
		// A type or callback declaration ends the run: its `@doc` /
		// `@typedoc` belongs to it, not to the next one.
		if ( s.type === 'unary_operator' && /^@(type|typep|opaque|callback|macrocallback)\b/.test( s.text ) ) {
			break;
		}
		if ( s.type === 'unary_operator' ) {
			out.push( s.text.split( '\n' )[ 0 ] );
		}
	}
	return out.join( ' ' );
}

/**
 * Tells whether an Elixir node is the `do` block of an `if` or `unless` call,
 * the usual way to define clauses only when an optional dependency is loaded.
 *
 * @param {Object} b Tree-sitter node.
 * @return {boolean} True for a conditional block.
 */
function exCondBlock( b ) {
	const call = b?.type === 'do_block' ? b.parent : null;
	return !! call && call.type === 'call' && /^(if|unless)$/.test( call.namedChildren[ 0 ]?.text || '' );
}

/**
 * Tells whether an earlier clause of the same function exists in the module,
 * looking into conditional blocks before it and out of the one it sits in.
 *
 * @param {Object} n    The `def` call.
 * @param {string} kind `def`, `defmacro` and so on.
 * @param {string} name Name and arity key from exDefName().
 * @return {boolean} True when n is not the first clause.
 */
function exEarlierClause( n, kind, name ) {
	const same = ( c ) => c.type === 'call' && c.namedChildren[ 0 ]?.text === kind && exDefName( c ) === name;
	for ( let at = n; at; at = exCondBlock( at.parent ) ? at.parent.parent : null ) {
		for ( let s = at.previousSibling; s; s = s.previousSibling ) {
			if ( same( s ) ) {
				return true;
			}
			const block = s.type === 'call' && /^(if|unless)$/.test( s.namedChildren[ 0 ]?.text || '' ) ? s.namedChildren.find( ( c ) => c.type === 'do_block' ) : null;
			if ( block?.namedChildren.some( same ) ) {
				return true;
			}
		}
	}
	return false;
}

// Dart: what may sit between a declaration and its doc comment.
const DART_SKIP = /^(annotation|final_builtin|const_builtin|inferred_type|type_identifier|type_arguments|nullable_type|function_type|void_type|record_type|late|external|static)$/;

/**
 * Text of the annotations directly before a Dart declaration.
 *
 * @param {Object} n Tree-sitter node.
 * @return {string} Joined annotation source.
 */
function dartAnnotations( n ) {
	const out = [];
	for ( let s = n.previousSibling; s && ( s.type === 'annotation' || isComment( s ) ); s = s.previousSibling ) {
		if ( s.type === 'annotation' ) {
			out.push( s.text );
		}
	}
	return out.join( ' ' );
}

/**
 * Text of the attribute items directly before a Rust node.
 *
 * @param {Object} n Tree-sitter node.
 * @return {string} Joined attribute source.
 */
function leadingAttrs( n ) {
	const out = [];
	for ( let s = n.previousSibling; s && ( s.type === 'attribute_item' || isComment( s ) ); s = s.previousSibling ) {
		if ( s.type === 'attribute_item' ) {
			out.push( s.text );
		}
	}
	return out.join( ' ' );
}

// C and C++: functions, prototypes, types, macros and struct members. A
// definition is exempt when a documented prototype of the same name exists
// in a header (collected by the caller in `known`).
COVER.c = {
	need: ( n, f, chain, known ) => {
		const top = /^(translation_unit|declaration_list|preproc_\w+)$/.test( n.parent?.type || '' ) || n.parent?.type === 'template_declaration';
		const fname = ( d ) => {
			const decl = d.descendantsOfType( 'function_declarator' )[ 0 ];
			return decl ? decl.childForFieldName( 'declarator' )?.text : null;
		};
		if ( n.type === 'function_definition' && top ) {
			const name = fname( n ) || 'function';
			return known.has( name.split( '::' ).pop() ) ? null : name;
		}
		if ( n.type === 'declaration' && top && n.descendantsOfType( 'function_declarator' ).length && /\.(h|hh|hpp|hxx)$/.test( f ) ) {
			return fname( n );
		}
		if ( /^(struct|union|enum|class)_specifier$/.test( n.type ) && n.childForFieldName( 'body' ) && top ) {
			return n.childForFieldName( 'name' )?.text || n.type;
		}
		if ( n.type === 'type_definition' && top ) {
			return n.childForFieldName( 'declarator' )?.text || 'typedef';
		}
		if ( ( n.type === 'preproc_def' || n.type === 'preproc_function_def' ) && top ) {
			const name = n.childForFieldName( 'name' )?.text || '';
			// An include guard (`#define FOO_H` with no value) needs no doc.
			return ! n.childForFieldName( 'value' ) && /_H(PP)?_?$|_INCLUDED$/.test( name ) ? null : name;
		}
		if ( n.type === 'field_declaration' && n.parent?.type === 'field_declaration_list' ) {
			return n.childForFieldName( 'declarator' )?.text || 'field';
		}
		return null;
	},
	documented: ( n, L ) => {
		const target = n.parent?.type === 'template_declaration' ? n.parent : n;
		if ( proseComments( target, null, L ).some( ( c ) => L.doc( c.text ) ) ) {
			return true;
		}
		// Doxygen trailing member docs: `int a; ///< Meaning.`
		const next = target.nextSibling;
		return !! next && isComment( next ) && next.startPosition.row === target.endPosition.row && /^(\/\/\/<|\/\*\*<|\/\/!<)/.test( next.text );
	},
	header: null,
};
COVER.cpp = COVER.c;

/**
 * Finds documented function prototypes in a C / C++ header.
 *
 * @param {string} src Header source.
 * @param {string} lang c or cpp.
 * @return {Promise<string[]>} Function names whose prototype has a doc comment.
 */
export async function documentedPrototypes( src, lang ) {
	const tree = await parse( lang, src );
	const out = [];
	// Free function prototypes are `declaration`s; member prototypes inside a class body
	// are `field_declaration`s (their out-of-line definitions are `Class::name`).
	for ( const d of tree.rootNode.descendantsOfType( [ 'declaration', 'field_declaration' ] ) ) {
		const fd = d.descendantsOfType( 'function_declarator' )[ 0 ];
		if ( fd && COVER.c.documented( d, LANGS[ lang ] ) ) {
			out.push( fd.childForFieldName( 'declarator' )?.text.split( '::' ).pop() );
		}
	}
	tree.delete();
	return out;
}

// Languages whose doc dialect has an `@since` tag that `--since` checks.
const SINCE_LANGS = /^(php|java|kotlin)$/;

/**
 * Lists coverage gaps in one file.
 *
 * @param {string}      lang     Language key.
 * @param {string}      f        Relative path, for messages and test-file rules.
 * @param {string}      src      Source text.
 * @param {Set<string>} known    Documented C / C++ prototype names.
 * @param {boolean}     since    Whether every documented declaration must carry `@since` (PHP, Java, Kotlin).
 * @param {boolean}     lineDocs Whether plain line comments directly above a declaration count as its doc.
 * @return {Promise<{gaps: string[], packageDoc: boolean, locked: string[]}>} Gap lines, (Go) whether the
 *         file has a package doc, and the undocumented declarations inside locked regions.
 */
export async function tsCoverage( lang, f, src, known = new Set(), since = false, lineDocs = false ) {
	const L = LANGS[ lang ];
	const C = COVER[ lang ];
	const tree = await parse( lang, src );
	try {
		const root = tree.rootNode;
		const gaps = [];
		const empty = ! root.namedChildren.some( ( c ) => ! isComment( c ) && ! /^(php_tag|text)$/.test( c.type ) );
		if ( C.header && ! empty && ! C.header( root, L, lineDocs ) ) {
			gaps.push( `MISSING FILE HEADER: ${ f }` );
		}
		// A declaration inside a locked region cannot take a new doc comment: the
		// region is compared byte for byte. Those are listed apart, not as gaps.
		const keys = root.hasError ? lockedRegions( root ) : new Set();
		const spans = [ ...keys ].map( ( k ) => k.split( ':' ).map( Number ) );
		const locked = [];
		// A declaration locked as the neighbour of a broken statement before it
		// shares that region: a comment added between them joins the region.
		const slotLocked = ( n ) => {
			const outer = n.parent?.type === 'decorated_definition' ? n.parent : n;
			if ( ! keys.has( `${ outer.startIndex }:${ outer.endIndex }` ) ) {
				return false;
			}
			let p = outer.previousNamedSibling;
			while ( p && isComment( p ) ) {
				p = p.previousNamedSibling;
			}
			return !! p && keys.has( `${ p.startIndex }:${ p.endIndex }` );
		};
		// With --line-docs, a plain comment above the declaration counts, looking
		// past its decorators (Python) and attributes (Rust `#[derive]`, C# `[Attr]`).
		const lineDoc = ( n ) => lineDocs && proseComments( n.parent?.type === 'decorated_definition' ? n.parent : n, /^(attribute_item|attribute_list|attribute|decorator)$/, L ).length > 0;
		// An explicit stack: deeply nested code (large C initializers) overflows
		// the call stack of a recursive walk.
		const stack = [ [ root, [] ] ];
		while ( stack.length ) {
			const [ n, chain ] = stack.pop();
			if ( ( n.type === 'ERROR' && n.parent ) || isComment( n ) || C.skipSubtree?.( n ) ) {
				continue;
			}
			const name = C.need( n, f, chain, known );
			// A declaration that starts inside a locked region, or shares one with
			// the broken statement before it, is locked. When the declaration alone
			// is the locked node, its doc comment sits before the region and may be
			// written.
			if ( name && ! C.documented( n, L ) && ! lineDoc( n ) && ( spans.some( ( [ s, e ] ) => n.startIndex > s && n.startIndex < e ) || slotLocked( n ) ) ) {
				locked.push( `LOCKED DOC: ${ f }:${ n.startPosition.row + 1 } ${ n.type } ${ String( name ).split( '\n' )[ 0 ].slice( 0, 60 ) }` );
			} else if ( name && ! C.documented( n, L ) && ! lineDoc( n ) ) {
				gaps.push( `MISSING DOCBLOCK: ${ f }:${ n.startPosition.row + 1 } ${ n.type } ${ String( name ).split( '\n' )[ 0 ].slice( 0, 60 ) }` );
			} else if ( name && since && SINCE_LANGS.test( lang ) && ! leadingComments( n, /^(attribute_list|attribute_item|attribute)$/ ).some( ( c ) => /@since\b/.test( c.text ) ) ) {
				gaps.push( `MISSING @since: ${ f }:${ n.startPosition.row + 1 } ${ n.type } ${ String( name ).split( '\n' )[ 0 ].slice( 0, 60 ) }` );
			}
			const next = [ ...chain, n ];
			for ( let i = n.namedChildCount - 1; i >= 0; i-- ) {
				stack.push( [ n.namedChild( i ), next ] );
			}
		}
		let packageDoc = false;
		if ( lang === 'go' ) {
			const pkg = root.namedChildren.find( ( c ) => c.type === 'package_clause' );
			packageDoc = !! pkg && proseComments( pkg, null, L ).length > 0;
		}
		return { gaps, packageDoc, locked };
	} finally {
		// Freed even when a rule throws: wasm memory is not garbage-collected.
		tree.delete();
	}
}

// --- Self-test mutations -----------------------------------------------------

/**
 * Finds the edits the self-test applies to one file of a tree-sitter language.
 *
 * Each edit is `{start, end, text}` on the source, or null when the file has
 * nothing to test it with.
 *
 * @param {string} lang Language key.
 * @param {string} src  Source text.
 * @return {Promise<Object>} {prefix, insert, codeEdit, joinEdit, blankEdit, indentSensitive}.
 */
export async function tsMutations( lang, src ) {
	const tree = await parse( lang, src );
	const root = tree.rootNode;
	const leaves = [];
	// Docstrings count as comments: blank lines next to them may change.
	const docstring = ( n ) => LANGS[ lang ].docstrings && ( lang === 'clojure' ? cljDocstring( n ) : lang === 'elixir' ? exDocstring( n ) : isDocstring( n ) );
	const walk = ( n ) => {
		if ( isComment( n ) || ( n.type === 'ERROR' && n.parent ) || docstring( n ) ) {
			leaves.push( { comment: true, n } );
			return;
		}
		if ( n.childCount === 0 ) {
			if ( n.endIndex > n.startIndex ) {
				leaves.push( { n } );
			}
			return;
		}
		for ( let i = 0; i < n.childCount; i++ ) {
			walk( n.child( i ) );
		}
	};
	walk( root );
	// Whitespace inside a locked region is compared as code, so layout
	// mutations must land outside every locked region.
	const spans = root.hasError ? [ ...lockedRegions( root ) ].map( ( k ) => k.split( ':' ).map( Number ) ) : [];
	const inLocked = ( n ) => spans.some( ( [ s, e ] ) => n.startIndex >= s && n.endIndex <= e );
	const inString = ( n ) => {
		for ( let p = n; p; p = p.parent ) {
			if ( /string|heredoc|template|raw|char|text$|^data$/.test( p.type ) ) {
				return true;
			}
		}
		return false;
	};

	// A top-level statement that starts its line, with no comment directly above.
	let insert = null;
	const tops = root.namedChildren.filter( ( c ) => ! isComment( c ) && ! /^(php_tag|text|text_interpolation|ERROR)$/.test( c.type ) );
	for ( const c of tops.slice( 1 ).concat( tops.slice( 0, 1 ) ) ) {
		// Not next to a locked statement: a comment there can change how the
		// grammar recovers from the error.
		if ( inLocked( c ) || ( c.previousSibling && inLocked( c.previousSibling ) ) ) {
			continue;
		}
		const lineStart = src.lastIndexOf( '\n', c.startIndex - 1 ) + 1;
		const indent = src.slice( lineStart, c.startIndex );
		const prev = c.previousSibling;
		if ( lineStart > 0 && /^[ \t]*$/.test( indent ) && ! ( prev && isComment( prev ) && prev.endPosition.row >= c.startPosition.row - 1 ) && ! ( lang === 'python' && isDocstring( c ) ) ) {
			insert = { lineStart, indent };
			break;
		}
	}

	let codeEdit = null;
	const num = leaves.find( ( l ) => ! l.comment && /^(integer|int_literal|integer_literal|number_literal|decimal_integer_literal|number|float)$/.test( l.n.type ) && /^\d+$/.test( l.n.text ) );
	if ( num ) {
		codeEdit = { start: num.n.startIndex, end: num.n.endIndex, text: String( Number( num.n.text ) + 1 ) };
	} else {
		const id = leaves.find( ( l ) => ! l.comment && /identifier|^name$|^constant$/.test( l.n.type ) && ! inString( l.n ) );
		if ( id ) {
			codeEdit = { start: id.n.endIndex, end: id.n.endIndex, text: 'X' };
		}
	}

	let joinEdit = null;
	let blankEdit = null;
	for ( let i = 0; i < leaves.length - 1; i++ ) {
		const a = leaves[ i ];
		const b = leaves[ i + 1 ];
		if ( a.comment || b.comment || inString( a.n ) || inString( b.n ) || inLocked( a.n ) || inLocked( b.n ) ) {
			continue;
		}
		const gap = src.slice( a.n.endIndex, b.n.startIndex );
		if ( ! joinEdit && /^[({[,]$/.test( a.n.text ) && /^[ \t]*\n[ \t]*$/.test( gap ) ) {
			joinEdit = { start: a.n.endIndex, end: b.n.startIndex, text: ' ' };
		}
		if ( ! blankEdit && /^[ \t]*\n[ \t]*\n[ \t]*$/.test( gap ) ) {
			const nl = a.n.endIndex + gap.indexOf( '\n' );
			blankEdit = { start: nl, end: nl + 1, text: '' };
		}
	}
	tree.delete();
	// In Python and Haskell indentation is syntax; the Lua reader groups
	// statements by column 0.
	return { prefix: LANGS[ lang ].line, insert, codeEdit, joinEdit, blankEdit, indentSensitive: /^(python|haskell|lua)$/.test( lang ) };
}
