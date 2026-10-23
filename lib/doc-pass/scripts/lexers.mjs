/**
 * Lexer-based readers for languages with no wasm tree-sitter grammar that
 * the checker can load (or whose bundled grammar is unreliable): Erlang,
 * Haskell, Perl and Lua.
 *
 * Each reader splits the source into tokens (comments, strings, characters,
 * atoms, numbers, names, punctuation) and groups them into top-level forms:
 * Erlang forms end with a `.`; a Haskell declaration starts at column 0.
 * Comments between forms are children of the program, so a form's leading
 * comments are its previous siblings, as with tree-sitter. The nodes come
 * from clojure.mjs and have the tree-sitter Node API that treesitter.mjs uses.
 */

import { nodeClass } from './clojure.mjs';

const ERL_PUNCT = [ '<<', '>>', '->', '<-', '<=', '=>', ':=', '::', '=:=', '=/=', '==', '/=', '=<', '>=', '++', '--', '||', '...', '..' ];
const HS_SYMBOL = /[!#$%&*+./<=>?@\\^|~:-]/;

/**
 * Splits Erlang source into tokens.
 *
 * @param {string} src Source text.
 * @return {Object[]} Tokens `{type, start, end}`.
 */
function lexErlang( src ) {
	const out = [];
	let i = 0;
	const push = ( type, start ) => out.push( { type, start, end: i } );
	// An escript's `#!` first line is a comment to the compiler.
	if ( src.startsWith( '#!' ) ) {
		i = src.indexOf( '\n' ) < 0 ? src.length : src.indexOf( '\n' );
		push( 'comment', 0 );
	}
	while ( i < src.length ) {
		const ch = src[ i ];
		const start = i;
		if ( /\s/.test( ch ) ) {
			i++;
			continue;
		}
		if ( ch === '%' ) {
			while ( i < src.length && src[ i ] !== '\n' ) {
				i++;
			}
			push( 'comment', start );
			continue;
		}
		if ( ch === '"' || ch === "'" ) {
			// Strings and quoted atoms; triple-quoted strings (OTP 27) too,
			// opened by three or more `"` and closed by the same number on a
			// line of their own, indented or not.
			const quotes = ch === '"' ? /^"{3,}/.exec( src.slice( i, i + 16 ) )?.[ 0 ] : null;
			if ( quotes ) {
				const m = new RegExp( `\\n[ \\t]*${ quotes }(?!")` ).exec( src.slice( i + quotes.length ) );
				i = m ? i + quotes.length + m.index + m[ 0 ].length : src.length;
				push( m ? 'string' : 'ERROR', start );
				continue;
			}
			i++;
			while ( i < src.length && src[ i ] !== ch ) {
				i += src[ i ] === '\\' ? 2 : 1;
			}
			if ( i >= src.length ) {
				push( 'ERROR', start );
				continue;
			}
			i++;
			push( ch === '"' ? 'string' : 'atom', start );
			continue;
		}
		if ( ch === '$' ) {
			// A character literal: `$a`, `$\n`, `$\x{1F600}`, `$%`.
			i += 2;
			if ( src[ i - 1 ] === '\\' ) {
				if ( src[ i ] === 'x' && src[ i + 1 ] === '{' ) {
					i = src.indexOf( '}', i ) + 1 || src.length;
				} else if ( /[0-7]/.test( src[ i ] ) ) {
					while ( /[0-7]/.test( src[ i ] ) && i - start < 5 ) {
						i++;
					}
				} else {
					i += src[ i ] === '^' ? 2 : 1;
				}
			}
			push( 'char', start );
			continue;
		}
		if ( /\d/.test( ch ) ) {
			while ( i < src.length && /[\w#]/.test( src[ i ] ) ) {
				i++;
			}
			let type = 'integer';
			if ( src[ i ] === '.' && /\d/.test( src[ i + 1 ] || '' ) ) {
				i++;
				while ( i < src.length && /[\w]/.test( src[ i ] ) || ( /[eE]/.test( src[ i - 1 ] ) && /[-+]/.test( src[ i ] ) ) ) {
					i++;
				}
				type = 'float';
			}
			push( type, start );
			continue;
		}
		if ( /[A-Za-z_]/.test( ch ) ) {
			while ( i < src.length && /[\w@]/.test( src[ i ] ) ) {
				i++;
			}
			push( /^[A-Z_]/.test( ch ) ? 'variable' : 'atom', start );
			continue;
		}
		const p = ERL_PUNCT.find( ( t ) => src.startsWith( t, i ) );
		i += p ? p.length : 1;
		push( p || ch, start );
	}
	return out;
}

/**
 * Splits Haskell source into tokens. CPP lines (`#if`, `#include` at
 * column 0) are one token each.
 *
 * @param {string} src Source text.
 * @return {Object[]} Tokens `{type, start, end}`.
 */
function lexHaskell( src ) {
	const out = [];
	let i = 0;
	const push = ( type, start ) => out.push( { type, start, end: i } );
	const bol = ( k ) => k === 0 || src[ k - 1 ] === '\n';
	// A script's `#!` first line (runghc, stack, cabal) is a comment to GHC.
	if ( src.startsWith( '#!' ) ) {
		i = src.indexOf( '\n' ) < 0 ? src.length : src.indexOf( '\n' );
		push( 'comment', 0 );
	}
	while ( i < src.length ) {
		const ch = src[ i ];
		const start = i;
		if ( /\s/.test( ch ) ) {
			i++;
			continue;
		}
		if ( ch === '#' && bol( i ) && /^#\s*[a-z]/.test( src.slice( i, i + 12 ) ) ) {
			// A CPP directive, with `\` continuation lines.
			while ( i < src.length && ( src[ i ] !== '\n' || src[ i - 1 ] === '\\' ) ) {
				i++;
			}
			push( 'cpp', start );
			continue;
		}
		if ( src.startsWith( '{-', i ) ) {
			// Block comments nest; `{-# … #-}` pragmas are block comments too.
			let depth = 0;
			while ( i < src.length ) {
				if ( src.startsWith( '{-', i ) ) {
					depth++;
					i += 2;
				} else if ( src.startsWith( '-}', i ) ) {
					depth--;
					i += 2;
					if ( ! depth ) {
						break;
					}
				} else {
					i++;
				}
			}
			push( depth ? 'ERROR' : 'comment', start );
			continue;
		}
		if ( src.startsWith( '--', i ) ) {
			let k = i;
			while ( src[ k ] === '-' ) {
				k++;
			}
			// `-->` and `--|` are operators, not comments.
			if ( k >= src.length || ! HS_SYMBOL.test( src[ k ] ) ) {
				while ( i < src.length && src[ i ] !== '\n' ) {
					i++;
				}
				push( 'comment', start );
				continue;
			}
		}
		if ( ch === '"' ) {
			i++;
			while ( i < src.length && src[ i ] !== '"' && src[ i ] !== '\n' ) {
				i += src[ i ] === '\\' ? 2 : 1;
			}
			// A string gap (`\` newline … `\`) continues the string.
			while ( src[ i ] === '\n' && /\\\s*$/.test( src.slice( src.lastIndexOf( '\n', i - 1 ) + 1, i ) ) ) {
				i++;
				while ( i < src.length && src[ i ] !== '"' && src[ i ] !== '\n' ) {
					i += src[ i ] === '\\' ? 2 : 1;
				}
			}
			if ( src[ i ] !== '"' ) {
				push( 'ERROR', start );
				continue;
			}
			i++;
			push( 'string', start );
			continue;
		}
		if ( ch === "'" && ! /[\w']/.test( src[ i - 1 ] || '' ) ) {
			// A character literal, unless it is a promoted constructor
			// (`'Just`) or a Template Haskell name quote (`'name`, `''Type`).
			const m = /^'(\\(\^.|[^'\s]+)|[^'\\\n])'/u.exec( src.slice( i, i + 16 ) );
			if ( m ) {
				i += m[ 0 ].length;
				push( 'char', start );
				continue;
			}
		}
		if ( /\d/.test( ch ) ) {
			while ( i < src.length && /[\w.]/.test( src[ i ] ) && ! ( src[ i ] === '.' && ! /\d/.test( src[ i + 1 ] || '' ) ) ) {
				i++;
			}
			push( /[.eE]/.test( src.slice( start, i ) ) && ! /^0x/i.test( src.slice( start, i ) ) ? 'float' : 'integer', start );
			continue;
		}
		if ( /[\p{L}_]/u.test( ch ) ) {
			while ( i < src.length && /[\p{L}\p{N}_']/u.test( src[ i ] ) ) {
				i++;
			}
			push( /\p{Lu}/u.test( ch ) ? 'constructor' : 'variable', start );
			continue;
		}
		if ( HS_SYMBOL.test( ch ) ) {
			while ( i < src.length && HS_SYMBOL.test( src[ i ] ) && ! src.startsWith( '--', i ) && ! src.startsWith( '{-', i ) ) {
				i++;
			}
			if ( i === start ) {
				i++;
			}
			push( src.slice( start, i ), start );
			continue;
		}
		i++;
		push( ch, start );
	}
	return out;
}

/**
 * Groups tokens into a program of forms.
 *
 * @param {string}   src     Source text.
 * @param {Object[]} tokens  Tokens from a lexer.
 * @param {Function} starts  `( tok, prev ) => bool`: whether a token begins a new form.
 * @param {Function} ends    `( tok ) => bool`: whether a token ends its form.
 * @param {Function} kind    `( form ) => string`: the form's node type.
 * @return {{rootNode: Object}} Tree with the program node as its root.
 */
function group( src, tokens, starts, ends, kind ) {
	const Node = nodeClass( src );
	const root = new Node( 'program', 0, src.length, true );
	const named = /^(comment|string|char|atom|integer|float|variable|constructor|identifier|cpp|heredoc|data|ERROR)$/;
	let form = null;
	let prev = null;
	const close = () => {
		if ( form ) {
			form.endIndex = form.children[ form.children.length - 1 ].endIndex;
			form.type = kind( form );
			form = null;
		}
	};
	for ( let k = 0; k < tokens.length; k++ ) {
		const t = tokens[ k ];
		const leaf = new Node( t.type, t.start, t.end, named.test( t.type ) );
		if ( t.type === 'comment' ) {
			// A comment belongs to the program when the next code token starts
			// a new form (or there is none); otherwise to the open form.
			const next = tokens.slice( k + 1 ).find( ( x ) => x.type !== 'comment' );
			if ( ! form || ! next || starts( next, prev ) ) {
				close();
				root.add( leaf );
				continue;
			}
		} else if ( ! form || starts( t, prev ) ) {
			close();
			form = root.add( new Node( 'form', t.start, t.end, true ) );
		}
		form.add( leaf );
		if ( t.type !== 'comment' ) {
			prev = t;
			if ( ends( t ) ) {
				close();
			}
		}
	}
	close();
	return { rootNode: root, delete() {} };
}

/**
 * Reads Erlang source (`.erl`, `.hrl`, `.escript`) into forms: attributes
 * (`attribute_spec`, `attribute_doc`, `attribute_type`, `attribute`) and
 * `function` forms.
 *
 * @param {string} src Source text.
 * @return {{rootNode: Object}} Tree.
 */
export function readErlang( src ) {
	const text = ( n ) => n.text;
	const tokens = lexErlang( src );
	// A form ends with `.` followed by whitespace, a comment or the end.
	const ends = ( t ) => t.type === '.' && ( t.end >= src.length || /[\s%]/.test( src[ t.end ] ) );
	return group( src, tokens, () => false, ends, ( f ) => {
		const [ a, b ] = f.namedChildren.length ? [ f.children[ 0 ], f.children[ 1 ] ] : [];
		if ( a?.type === '-' && b ) {
			const name = text( b );
			if ( /^(spec)$/.test( name ) ) {
				return 'attribute_spec';
			}
			if ( /^(doc|moduledoc)$/.test( name ) ) {
				return 'attribute_doc';
			}
			if ( /^(type|opaque|callback|record|nominal)$/.test( name ) ) {
				return 'attribute_type';
			}
			return 'attribute';
		}
		return a?.type === 'atom' ? 'function' : 'form';
	} );
}

/**
 * Reads Haskell source into declarations: each starts at column 0.
 * Types: `signature`, `type_declaration`, `module`, `import`, `pragma`
 * (`{-# … #-}` at the top level is a comment), `cpp`, or `declaration`.
 *
 * @param {string} src Source text.
 * @return {{rootNode: Object}} Tree.
 */
export function readHaskell( src ) {
	const text = ( n ) => n.text;
	const tokens = lexHaskell( src );
	const col0 = ( t ) => t.start === 0 || src[ t.start - 1 ] === '\n';
	return group( src, tokens, ( t ) => col0( t ), () => false, ( f ) => {
		const kids = f.children;
		const first = kids[ 0 ] ? text( kids[ 0 ] ) : '';
		if ( kids[ 0 ]?.type === 'cpp' ) {
			return 'cpp';
		}
		if ( /^(module|import)$/.test( first ) ) {
			return first;
		}
		if ( /^(data|newtype|type|class)$/.test( first ) ) {
			return 'type_declaration';
		}
		// `name, other :: Type`, `(<+>) :: …`, `pattern P :: …`.
		let depth = 0;
		for ( const k of kids ) {
			const s = text( k );
			if ( s === '(' || s === '[' || s === '{' ) {
				depth++;
			} else if ( s === ')' || s === ']' || s === '}' ) {
				depth--;
			} else if ( depth === 0 && ( s === '=' || s === '|' || s === '<-' ) ) {
				break;
			} else if ( depth === 0 && ( s === '::' || s === '∷' ) ) {
				return 'signature';
			}
		}
		return 'declaration';
	} );
}

// Perl words after which a term (and so a regex) is expected, not an operator.
const PERL_TERM_WORDS = /^(split|grep|map|join|if|elsif|unless|while|until|and|or|not|xor|return|push|unshift|when|lt|gt|le|ge|eq|ne|cmp|x|print|die|warn|croak|confess)$/;
const PERL_PAIRS = { '(': ')', '[': ']', '{': '}', '<': '>' };

/**
 * Splits Perl source into tokens. POD blocks (`=head1` … `=cut`) are
 * comments. After `__END__`, POD blocks are comments and other text is
 * data; after `__DATA__`, all of it is data.
 *
 * @param {string} src Source text.
 * @return {Object[]} Tokens `{type, start, end}`.
 */
function lexPerl( src ) {
	const out = [];
	let i = 0;
	let term = true;
	const braces = [];
	const heredocs = [];
	const push = ( type, start, isTerm ) => {
		out.push( { type, start, end: i } );
		term = isTerm;
	};
	const bol = ( k ) => k === 0 || src[ k - 1 ] === '\n';
	const lineEnd = ( k ) => {
		const e = src.indexOf( '\n', k );
		return e < 0 ? src.length : e;
	};
	// Reads a delimited body starting at the opening delimiter; returns the
	// index after the closing one.
	const delimited = ( k ) => {
		const open = src[ k ];
		const close = PERL_PAIRS[ open ] || open;
		let depth = 1;
		k++;
		while ( k < src.length ) {
			const ch = src[ k ];
			if ( ch === '\\' ) {
				k += 2;
				continue;
			}
			if ( ch === close && open !== close ) {
				depth--;
			} else if ( ch === open && open !== close ) {
				depth++;
			} else if ( ch === close ) {
				depth = 0;
			}
			k++;
			if ( ! depth ) {
				return k;
			}
		}
		return -1;
	};
	const pod = ( start ) => {
		let k = start;
		for ( ;; ) {
			const e = lineEnd( k );
			if ( /^=cut\b/.test( src.slice( k, e ) ) || e >= src.length ) {
				i = e;
				break;
			}
			k = e + 1;
		}
		push( 'comment', start, term );
	};
	while ( i < src.length ) {
		const ch = src[ i ];
		const start = i;
		if ( ch === '\n' && heredocs.length ) {
			// Heredoc bodies start on the line after their operator.
			i++;
			for ( const h of heredocs.splice( 0 ) ) {
				const bodyStart = i;
				for ( ;; ) {
					const e = lineEnd( i );
					const line = src.slice( i, e );
					if ( ( h.indent ? line.trim() : line ) === h.tag ) {
						i = e;
						break;
					}
					if ( e >= src.length ) {
						i = e;
						break;
					}
					i = e + 1;
				}
				out.push( { type: 'heredoc', start: bodyStart, end: i } );
			}
			continue;
		}
		if ( /\s/.test( ch ) ) {
			i++;
			continue;
		}
		if ( ch === '=' && bol( i ) && /^=[A-Za-z]/.test( src.slice( i, i + 2 ) ) ) {
			pod( i );
			continue;
		}
		if ( bol( i ) && /^__(END|DATA)__\b/.test( src.slice( i, i + 8 ) ) ) {
			const data = src.startsWith( '__DATA__', i );
			i += 7;
			push( 'data_marker', start, true );
			// The rest: POD blocks (after __END__) and data lines.
			while ( i < src.length ) {
				while ( i < src.length && /\s/.test( src[ i ] ) ) {
					i++;
				}
				if ( i >= src.length ) {
					break;
				}
				const s = i;
				if ( ! data && /^=[A-Za-z]/.test( src.slice( i, i + 2 ) ) && bol( i ) ) {
					pod( i );
				} else {
					i = lineEnd( i );
					out.push( { type: 'data', start: s, end: i } );
				}
			}
			break;
		}
		if ( ch === '#' ) {
			i = lineEnd( i );
			push( 'comment', start, term );
			continue;
		}
		if ( ch === '"' || ch === "'" || ch === '`' ) {
			const e = delimited( i );
			i = e < 0 ? src.length : e;
			push( e < 0 ? 'ERROR' : 'string', start, false );
			continue;
		}
		if ( ch === '$' || ch === '@' || ch === '%' || ch === '&' || ch === '*' ) {
			const next = src[ i + 1 ] || '';
			if ( ch === '$' && next === '#' ) {
				// `$#array`, `$#{…}`, `$#$ref`: the last index, not a comment.
				i += 2;
				while ( i < src.length && /[\w:]/.test( src[ i ] ) ) {
					i++;
				}
				push( 'variable', start, false );
				continue;
			}
			if ( /[A-Za-z_:]/.test( next ) && ( ch === '$' || ch === '@' || term || ch === '&' ) && ! ( ch === '%' && ! term ) && ! ( ch === '*' && ! term ) ) {
				i++;
				while ( i < src.length && /[\w]|::/.test( src[ i ] + ( src[ i + 1 ] || '' ) ) && ( /\w/.test( src[ i ] ) || src.startsWith( '::', i ) ) ) {
					i += src.startsWith( '::', i ) ? 2 : 1;
				}
				push( 'variable', start, false );
				continue;
			}
			if ( ch === '$' && /[^\s\w{]/.test( next ) ) {
				// Punctuation variables: `$_`, `$@`, `$/`, `$"`, `$'`, `$;` …
				i += 2;
				push( 'variable', start, false );
				continue;
			}
			if ( ch === '$' && /\d/.test( next ) ) {
				i++;
				while ( /\d/.test( src[ i ] || '' ) ) {
					i++;
				}
				push( 'variable', start, false );
				continue;
			}
		}
		if ( ch === '<' && src[ i + 1 ] === '<' && term && /^<<(~?)(\s*["']|[A-Za-z_])/.test( src.slice( i, i + 5 ) ) ) {
			const m = /^<<(~?)\s*(?:"([^"\n]*)"|'([^'\n]*)'|([A-Za-z_]\w*))/.exec( src.slice( i, i + 200 ) );
			if ( m ) {
				heredocs.push( { tag: m[ 2 ] ?? m[ 3 ] ?? m[ 4 ], indent: !! m[ 1 ] } );
				i += m[ 0 ].length;
				push( 'heredoc_start', start, false );
				continue;
			}
		}
		if ( /\d/.test( ch ) ) {
			while ( i < src.length && /[\w.]/.test( src[ i ] ) && ! ( src[ i ] === '.' && src[ i + 1 ] === '.' ) ) {
				i++;
			}
			push( /[.eE]/.test( src.slice( start, i ) ) && ! /^0x/i.test( src.slice( start, i ) ) ? 'float' : 'integer', start, false );
			continue;
		}
		if ( /[A-Za-z_]/.test( ch ) ) {
			while ( i < src.length && ( /\w/.test( src[ i ] ) || ( src.startsWith( '::', i ) && /\w/.test( src[ i + 2 ] || '' ) ) ) ) {
				i += src.startsWith( '::', i ) ? 2 : 1;
			}
			const word = src.slice( start, i );
			const prev = out[ out.length - 1 ];
			const after = /^\s*/.exec( src.slice( i, i + 40 ) )[ 0 ];
			const d = src[ i + after.length ];
			const isKey = /^\s*=>/.test( src.slice( i, i + 40 ) ) || src[ i ] === '}' || prev?.type === '->';
			// `-s $file` is a file test; `,` delimits only right after the word
			// (`m,^/,`); after a space, `#`, `$`, `@` and `%` are not delimiters.
			const fileTest = prev?.type === '-' && prev.end === start;
			const delim = d && ( /[^\w\s,;)=]/.test( d ) || ( d === ',' && ! after && term ) ) && ! ( after && /[#$@%]/.test( d ) );
			if ( /^(q|qq|qw|qr|m|s|tr|y)$/.test( word ) && ! isKey && ! fileTest && delim ) {
				// A quote-like operator: one delimited part, two for s / tr / y.
				let k = i + after.length;
				let e = delimited( k );
				if ( e > 0 && /^(s|tr|y)$/.test( word ) ) {
					if ( PERL_PAIRS[ src[ k ] ] ) {
						const gap = /^\s*/.exec( src.slice( e ) )[ 0 ];
						e = delimited( e + gap.length );
					} else {
						e = delimited( e - 1 );
					}
				}
				if ( e < 0 ) {
					i = src.length;
					push( 'ERROR', start, false );
					continue;
				}
				i = e;
				while ( /[a-z]/.test( src[ i ] || '' ) ) {
					i++;
				}
				push( 'string', start, false );
				continue;
			}
			push( 'identifier', start, PERL_TERM_WORDS.test( word ) );
			continue;
		}
		if ( ch === '/' && term ) {
			const e = delimited( i );
			if ( e > 0 ) {
				i = e;
				while ( /[a-z]/.test( src[ i ] || '' ) ) {
					i++;
				}
				push( 'string', start, false );
				continue;
			}
		}
		if ( ch === '{' ) {
			const prev = out[ out.length - 1 ];
			braces.push( prev && prev.end === i && /^(variable|->|}|])$/.test( prev.type ) ? 'subscript' : 'block' );
			i++;
			push( '{', start, true );
			continue;
		}
		if ( ch === '}' ) {
			const kind = braces.pop();
			i++;
			push( '}', start, kind !== 'subscript' );
			continue;
		}
		const op = [ '->', '=>', '=~', '!~', '::', '...', '..', '**', '++', '--', '&&', '||', '//', '<=>', '<=', '>=', '==', '!=' ].find( ( t ) => src.startsWith( t, i ) );
		i += op ? op.length : 1;
		const tok = op || ch;
		push( tok, start, ! /^[)\]]$/.test( tok ) && tok !== '++' && tok !== '--' );
	}
	return out;
}

/**
 * Reads Perl source into statements: `sub_declaration`, `package`, `use`,
 * or `statement`. A statement ends with `;` at depth 0, or with the `}`
 * that closes a top-level `sub`, `package`, `BEGIN` or control block.
 *
 * @param {string} src Source text.
 * @return {{rootNode: Object}} Tree.
 */
export function readPerl( src ) {
	const tokens = lexPerl( src );
	let depth = 0;
	let first = null;
	const ends = ( t ) => {
		const text = src.slice( t.start, t.end );
		if ( first === null ) {
			first = text;
		}
		if ( text === '{' ) {
			depth++;
		} else if ( text === '}' ) {
			depth--;
		}
		// A heredoc body follows the statement that opened it, which has
		// already ended: the body is a form of its own.
		const done = ( t.type === 'heredoc' && first === text ) || depth <= 0 && ( text === ';' || ( text === '}' && /^(sub|package|BEGIN|END|INIT|CHECK|UNITCHECK|if|unless|for|foreach|while|until)$/.test( first ) ) || t.type === 'data_marker' );
		if ( done ) {
			depth = 0;
			first = null;
		}
		return done;
	};
	return group( src, tokens, () => false, ends, ( f ) => {
		const word = f.children.find( ( c ) => c.type !== 'comment' )?.text;
		if ( word === 'sub' ) {
			return 'sub_declaration';
		}
		if ( word === 'package' ) {
			return 'package';
		}
		return /^(use|no|require)$/.test( word ) ? 'use' : 'statement';
	} );
}

/**
 * Splits Lua source into tokens: `--` and `--[==[ … ]==]` comments,
 * quoted and long-bracket strings, numbers, names and punctuation.
 *
 * @param {string} src Source text.
 * @return {Object[]} Tokens `{type, start, end}`.
 */
function lexLua( src ) {
	const out = [];
	let i = 0;
	const push = ( type, start ) => out.push( { type, start, end: i } );
	// A long bracket `[==[` at k: returns the index after its `]==]`, or -1.
	const longBracket = ( k ) => {
		const m = /^\[(=*)\[/.exec( src.slice( k, k + 64 ) );
		if ( ! m ) {
			return 0;
		}
		const close = src.indexOf( `]${ m[ 1 ] }]`, k + m[ 0 ].length );
		return close < 0 ? -1 : close + m[ 1 ].length + 2;
	};
	if ( src.startsWith( '#!' ) ) {
		i = src.indexOf( '\n' ) < 0 ? src.length : src.indexOf( '\n' );
		push( 'comment', 0 );
	}
	while ( i < src.length ) {
		const ch = src[ i ];
		const start = i;
		if ( /\s/.test( ch ) ) {
			i++;
			continue;
		}
		if ( src.startsWith( '--', i ) ) {
			const e = longBracket( i + 2 );
			if ( e ) {
				i = e < 0 ? src.length : e;
				push( e < 0 ? 'ERROR' : 'comment', start );
				continue;
			}
			i = src.indexOf( '\n', i );
			i = i < 0 ? src.length : i;
			push( 'comment', start );
			continue;
		}
		if ( ch === '[' && /^\[=*\[/.test( src.slice( i, i + 64 ) ) ) {
			const e = longBracket( i );
			i = e < 0 ? src.length : e;
			push( e < 0 ? 'ERROR' : 'string', start );
			continue;
		}
		if ( ch === '"' || ch === "'" ) {
			i++;
			while ( i < src.length && src[ i ] !== ch && src[ i ] !== '\n' ) {
				if ( src[ i ] === '\\' && src[ i + 1 ] === 'z' ) {
					// `\z` skips the line break and spaces that follow.
					i += 2;
					while ( /\s/.test( src[ i ] || '' ) ) {
						i++;
					}
					continue;
				}
				i += src[ i ] === '\\' ? 2 : 1;
			}
			if ( src[ i ] !== ch ) {
				push( 'ERROR', start );
				continue;
			}
			i++;
			push( 'string', start );
			continue;
		}
		if ( /\d/.test( ch ) || ( ch === '.' && /\d/.test( src[ i + 1 ] || '' ) ) ) {
			while ( i < src.length && ( /[\w.]/.test( src[ i ] ) || ( /[eEpP]/.test( src[ i - 1 ] ) && /[-+]/.test( src[ i ] ) ) ) && ! src.startsWith( '..', i ) ) {
				i++;
			}
			push( /[.eE]/.test( src.slice( start, i ) ) && ! /^0x/i.test( src.slice( start, i ) ) ? 'float' : 'integer', start );
			continue;
		}
		if ( /[A-Za-z_]/.test( ch ) ) {
			while ( i < src.length && /\w/.test( src[ i ] ) ) {
				i++;
			}
			push( 'identifier', start );
			continue;
		}
		const op = [ '...', '..', '==', '~=', '<=', '>=', '//', '::', '<<', '>>' ].find( ( t ) => src.startsWith( t, i ) );
		i += op ? op.length : 1;
		push( op || ch, start );
	}
	return out;
}

/**
 * Reads Lua source into top-level statements, each starting at column 0:
 * `function_definition` (`function a.b()`, `local function f()`),
 * `function_assignment` (`M.f = function`), `return_statement`,
 * `local_declaration` or `statement`.
 *
 * @param {string} src Source text.
 * @return {{rootNode: Object}} Tree.
 */
export function readLua( src ) {
	const tokens = lexLua( src );
	const col0 = ( t ) => t.start === 0 || src[ t.start - 1 ] === '\n';
	return group( src, tokens, ( t ) => col0( t ), () => false, ( f ) => {
		const words = f.children.filter( ( c ) => c.type !== 'comment' ).slice( 0, 6 ).map( ( c ) => c.text );
		if ( words[ 0 ] === 'function' || ( words[ 0 ] === 'local' && words[ 1 ] === 'function' ) ) {
			return 'function_definition';
		}
		const eq = words.indexOf( '=' );
		if ( eq > 0 && words[ eq + 1 ] === 'function' ) {
			return 'function_assignment';
		}
		if ( words[ 0 ] === 'return' ) {
			return 'return_statement';
		}
		return words[ 0 ] === 'local' ? 'local_declaration' : 'statement';
	} );
}
