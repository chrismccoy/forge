/**
 * A Clojure reader for the checker: no maintained tree-sitter grammar ships
 * as wasm, and Clojure's reader syntax is small enough to read directly.
 *
 * `readClojure( src )` returns a tree whose nodes have the parts of the
 * tree-sitter Node API that treesitter.mjs uses (type, text, positions,
 * children, siblings, isNamed, hasError …), so the code stream, locked
 * regions, self-test mutations and coverage work unchanged.
 *
 * Node types: program, list, vector, map, set, anon_fn, reader_conditional,
 * namespaced_map, tagged, quote, syntax_quote, unquote, unquote_splicing,
 * deref, var_quote, meta, discard, eval; leaves string, regex, char,
 * number, keyword, symbol, comment; ERROR for unbalanced input. Delimiters
 * and prefix markers are anonymous leaves.
 */

const DELIM = /[\s,()[\]{}";]/;

/**
 * Builds a node class bound to one source text.
 *
 * @param {string} src Source text.
 * @return {Function} Node constructor `( type, start, end, named )`.
 */
export function nodeClass( src ) {
	const starts = [ 0 ];
	for ( let i = 0; i < src.length; i++ ) {
		if ( src[ i ] === '\n' ) {
			starts.push( i + 1 );
		}
	}
	const position = ( index ) => {
		let lo = 0;
		let hi = starts.length - 1;
		while ( lo < hi ) {
			const mid = ( lo + hi + 1 ) >> 1;
			if ( starts[ mid ] <= index ) {
				lo = mid;
			} else {
				hi = mid - 1;
			}
		}
		return { row: lo, column: index - starts[ lo ] };
	};

	return class Node {
		constructor( type, start, end, named ) {
			this.type = type;
			this.startIndex = start;
			this.endIndex = end;
			this.isNamed = named;
			this.isMissing = false;
			this.children = [];
			this.parent = null;
			this.index = 0;
		}

		get text() {
			return src.slice( this.startIndex, this.endIndex );
		}

		get startPosition() {
			return position( this.startIndex );
		}

		get endPosition() {
			return position( this.endIndex );
		}

		get childCount() {
			return this.children.length;
		}

		child( i ) {
			return this.children[ i ] || null;
		}

		get namedChildren() {
			return this.children.filter( ( c ) => c.isNamed );
		}

		get namedChildCount() {
			return this.namedChildren.length;
		}

		namedChild( i ) {
			return this.namedChildren[ i ] || null;
		}

		get firstNamedChild() {
			return this.namedChild( 0 );
		}

		get previousSibling() {
			return this.parent?.children[ this.index - 1 ] || null;
		}

		get nextSibling() {
			return this.parent?.children[ this.index + 1 ] || null;
		}

		get hasError() {
			return this.type === 'ERROR' || this.children.some( ( c ) => c.hasError );
		}

		childForFieldName() {
			return null;
		}

		add( c ) {
			c.parent = this;
			c.index = this.children.length;
			this.children.push( c );
			return c;
		}

		toString() {
			return this.children.length ? `(${ this.type } ${ this.children.map( String ).join( ' ' ) })` : `(${ this.type })`;
		}
	};
}

/**
 * Reads a Clojure, ClojureScript or ClojureDart source into a node tree.
 *
 * @param {string} src Source text.
 * @return {{rootNode: Object}} Tree with the program node as its root.
 */
export function readClojure( src ) {
	const Node = nodeClass( src );
	let i = 0;

	const skipSpace = () => {
		while ( i < src.length && /[\s,]/.test( src[ i ] ) ) {
			i++;
		}
	};
	const leaf = ( parent, type, start, end, named = true ) => parent.add( new Node( type, start, end, named ) );

	// Reads the comments and the next form into `parent`; returns false at
	// the end of input or at a closing delimiter (left unread).
	const readInto = ( parent ) => {
		for ( ;; ) {
			skipSpace();
			if ( i >= src.length ) {
				return false;
			}
			const ch = src[ i ];
			if ( ch === ';' || ( ch === '#' && src[ i + 1 ] === '!' ) ) {
				const end = src.indexOf( '\n', i );
				leaf( parent, 'comment', i, end < 0 ? src.length : end );
				i = end < 0 ? src.length : end;
				continue;
			}
			if ( /[)\]}]/.test( ch ) ) {
				return false;
			}
			readForm( parent );
			return true;
		}
	};

	// Reads forms into `node` up to the closing delimiter `close`.
	const readSeq = ( node, close ) => {
		while ( readInto( node ) ) {
			// Keep reading.
		}
		if ( src[ i ] === close ) {
			leaf( node, close, i, i + 1, false );
			i++;
		} else {
			// Unclosed, or closed with the wrong delimiter.
			node.add( Object.assign( new Node( close, i, i, false ), { isMissing: true } ) );
		}
		node.endIndex = i;
	};

	// A prefix form: the marker, then the forms it applies to.
	const readPrefix = ( parent, type, marker, forms = 1 ) => {
		const node = parent.add( new Node( type, i, i, true ) );
		leaf( node, marker, i, i + marker.length, false );
		i += marker.length;
		for ( let k = 0; k < forms; k++ ) {
			if ( ! readInto( node ) ) {
				node.add( Object.assign( new Node( 'form', i, i, true ), { isMissing: true } ) );
				break;
			}
		}
		node.endIndex = i;
	};

	const readCollection = ( parent, type, open, close ) => {
		const node = parent.add( new Node( type, i, i, true ) );
		leaf( node, open, i, i + open.length, false );
		i += open.length;
		readSeq( node, close );
	};

	const readString = ( parent, type, skip ) => {
		const start = i;
		i += skip;
		while ( i < src.length && src[ i ] !== '"' ) {
			i += src[ i ] === '\\' ? 2 : 1;
		}
		if ( i >= src.length ) {
			leaf( parent, 'ERROR', start, src.length );
			i = src.length;
			return;
		}
		i++;
		leaf( parent, type, start, i );
	};

	const readToken = ( parent ) => {
		const start = i;
		while ( i < src.length && ! DELIM.test( src[ i ] ) ) {
			i++;
		}
		const text = src.slice( start, i );
		const type = /^[-+]?\d/.test( text ) || /^##/.test( text ) ? 'number' : text.startsWith( ':' ) ? 'keyword' : 'symbol';
		leaf( parent, type, start, i );
	};

	function readForm( parent ) {
		const ch = src[ i ];
		const two = src.slice( i, i + 2 );
		if ( ch === '(' ) {
			return readCollection( parent, 'list', '(', ')' );
		}
		if ( ch === '[' ) {
			return readCollection( parent, 'vector', '[', ']' );
		}
		if ( ch === '{' ) {
			return readCollection( parent, 'map', '{', '}' );
		}
		if ( ch === '"' ) {
			return readString( parent, 'string', 1 );
		}
		if ( ch === '\\' ) {
			// A character literal: `\a`, `\(`, `\newline`, `é`.
			const start = i;
			i += 2;
			if ( /[A-Za-z0-9]/.test( src[ i - 1 ] ) ) {
				while ( i < src.length && /[A-Za-z0-9]/.test( src[ i ] ) ) {
					i++;
				}
			}
			return leaf( parent, 'char', start, Math.min( i, src.length ) );
		}
		if ( ch === "'" ) {
			return readPrefix( parent, 'quote', "'" );
		}
		if ( ch === '`' ) {
			return readPrefix( parent, 'syntax_quote', '`' );
		}
		if ( two === '~@' ) {
			return readPrefix( parent, 'unquote_splicing', '~@' );
		}
		if ( ch === '~' ) {
			return readPrefix( parent, 'unquote', '~' );
		}
		if ( ch === '@' ) {
			return readPrefix( parent, 'deref', '@' );
		}
		if ( ch === '^' ) {
			return readPrefix( parent, 'meta', '^' );
		}
		if ( ch === '#' ) {
			const next = src[ i + 1 ];
			if ( next === '{' ) {
				return readCollection( parent, 'set', '#{', '}' );
			}
			if ( next === '(' ) {
				return readCollection( parent, 'anon_fn', '#(', ')' );
			}
			if ( next === '"' ) {
				return readString( parent, 'regex', 2 );
			}
			if ( next === "'" ) {
				return readPrefix( parent, 'var_quote', "#'" );
			}
			if ( next === '_' ) {
				return readPrefix( parent, 'discard', '#_' );
			}
			if ( next === '=' ) {
				return readPrefix( parent, 'eval', '#=' );
			}
			if ( next === '^' ) {
				return readPrefix( parent, 'meta', '#^' );
			}
			if ( next === '?' ) {
				const marker = src[ i + 2 ] === '@' ? '#?@(' : '#?(';
				return readCollection( parent, 'reader_conditional', marker, ')' );
			}
			if ( next === ':' ) {
				// `#:ns{…}` and `#::{…}`: a namespaced map.
				const brace = src.indexOf( '{', i );
				if ( brace > 0 && ! /[\s,]/.test( src.slice( i, brace ) ) ) {
					return readCollection( parent, 'namespaced_map', src.slice( i, brace + 1 ), '}' );
				}
			}
			if ( next === '#' ) {
				return readToken( parent );
			}
			if ( next && /[A-Za-z]/.test( next ) ) {
				// A tagged literal: `#inst "…"`, `#js {…}`, `#uuid "…"`.
				const node = parent.add( new Node( 'tagged', i, i, true ) );
				readToken( node );
				if ( ! readInto( node ) ) {
					node.add( Object.assign( new Node( 'form', i, i, true ), { isMissing: true } ) );
				}
				node.endIndex = i;
				return node;
			}
		}
		return readToken( parent );
	}

	const root = new Node( 'program', 0, src.length, true );
	while ( i < src.length ) {
		readInto( root );
		if ( i < src.length && /[)\]}]/.test( src[ i ] ) ) {
			// A closing delimiter with nothing open.
			leaf( root, 'ERROR', i, i + 1 );
			i++;
		}
	}
	return { rootNode: root, delete() {} };
}

// Heads whose third form is a docstring (`(defn name "Doc." [args] …)`).
const DOC_HEAD = /^(defn-?|defmacro|defmulti|defprotocol|definterface|ns|([\w.-]+\/)?(defn-?|defc|defcs|defcc|defmacro|defkeyframes|defstyled))$/;

/**
 * Forms of a list that count as its arguments: comments, metadata and
 * discarded forms are skipped.
 *
 * @param {Object} list List node.
 * @return {Object[]} Argument nodes, head first.
 */
export function cljForms( list ) {
	return list.namedChildren.filter( ( c ) => ! /^(comment|meta|discard)$/.test( c.type ) );
}

/**
 * Tells whether a node is a docstring: the string after the name in a
 * `defn`-style form, after the name in `def` / `defonce` when a value
 * follows it, or the last form of a method signature in `defprotocol`.
 *
 * @param {Object} n Node.
 * @return {boolean} True for a docstring.
 */
export function cljDocstring( n ) {
	const p = n.parent;
	if ( n.type !== 'string' || p?.type !== 'list' ) {
		return false;
	}
	const forms = cljForms( p );
	const head = forms[ 0 ]?.type === 'symbol' ? forms[ 0 ].text : '';
	const at = forms.indexOf( n );
	if ( at === 2 && forms[ 1 ]?.type === 'symbol' ) {
		if ( DOC_HEAD.test( head ) ) {
			return true;
		}
		if ( /^(def|defonce)$/.test( head ) && forms.length >= 4 ) {
			return true;
		}
	}
	// (defprotocol P (method [this] "Doc."))
	const outer = p.parent?.type === 'list' ? cljForms( p.parent ) : [];
	return outer[ 0 ]?.text === 'defprotocol' && at === forms.length - 1 && at >= 2 && forms[ 0 ]?.type === 'symbol' && forms.slice( 1, at ).every( ( f ) => f.type === 'vector' );
}
