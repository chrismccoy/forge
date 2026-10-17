<?php
/**
 * Classify PHP files as executing code at load or definition-only.
 *
 * Tokenizes each file (never includes or runs it) and looks for code outside
 * every function, class, interface, trait, and enum body. Inline HTML,
 * statements, and calls at that level run when the file is requested directly.
 *
 * Transparent wrappers (their bodies still count as top level):
 *   - namespace blocks
 *   - if ( ! function_exists( ... ) ) / class_exists / defined ... guards
 * Ignored at top level: namespace/use/declare/const statements, return.
 *
 * Usage: php toplevel.php <file>...
 * Output: one line per file: "<file>\texecutes\t<line>", "<file>\tdefinition",
 *         or "<file>\tunknown" when the tokenizer throws
 * Exit 3 when the tokenizer extension is unavailable (caller falls back).
 */

ini_set( 'display_errors', 'stderr' );

if ( ! function_exists( 'token_get_all' ) ) {
	exit( 3 );
}

const GUARD_FUNCS = array( 'function_exists', 'class_exists', 'interface_exists', 'trait_exists', 'enum_exists', 'defined' );
const SKIP        = array( T_WHITESPACE, T_COMMENT, T_DOC_COMMENT, T_OPEN_TAG, T_CLOSE_TAG );

function wpr_next_index( array $t, int $i ): int {
	$n = count( $t );
	for ( $i++; $i < $n; $i++ ) {
		if ( ! is_array( $t[ $i ] ) || ! in_array( $t[ $i ][0], SKIP, true ) ) {
			return $i;
		}
	}
	return $n;
}

function wpr_line_at( array $t, int $i ): int {
	for ( ; $i >= 0; $i-- ) {
		if ( is_array( $t[ $i ] ) ) {
			return $t[ $i ][2];
		}
	}
	return 1;
}

/** Index just past the ')' matching the '(' at $i, plus the identifiers inside. */
function wpr_paren_end( array $t, int $i ): array {
	$depth = 0;
	$names = array();
	$n     = count( $t );
	for ( ; $i < $n; $i++ ) {
		$tok = $t[ $i ];
		if ( '(' === $tok ) {
			$depth++;
		} elseif ( ')' === $tok ) {
			$depth--;
			if ( 0 === $depth ) {
				return array( $i + 1, $names );
			}
		} elseif ( is_array( $tok ) && T_STRING === $tok[0] ) {
			$names[] = strtolower( $tok[1] );
		}
	}
	return array( $n, $names );
}

/** Index of the token after the '}' matching the '{' at $i. */
function wpr_brace_end( array $t, int $i ): int {
	$depth = 0;
	$n     = count( $t );
	for ( ; $i < $n; $i++ ) {
		$tok = $t[ $i ];
		if ( '{' === $tok || ( is_array( $tok ) && in_array( $tok[0], array( T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES ), true ) ) ) {
			$depth++;
		} elseif ( '}' === $tok ) {
			$depth--;
			if ( 0 === $depth ) {
				return $i + 1;
			}
		}
	}
	return $n;
}

/** Returns the line of the first executing token, or 0 if definition-only. */
function wpr_first_exec_line( array $t ): int {
	$n = count( $t );
	$i = 0;
	while ( $i < $n ) {
		$tok = $t[ $i ];

		if ( is_array( $tok ) ) {
			$id = $tok[0];

			if ( in_array( $id, SKIP, true ) ) {
				$i++;
				continue;
			}
			if ( T_INLINE_HTML === $id ) {
				if ( '' !== trim( $tok[1] ) ) {
					return $tok[2];
				}
				$i++;
				continue;
			}
			if ( in_array( $id, array( T_NAMESPACE, T_USE, T_DECLARE, T_CONST, T_RETURN ), true ) ) {
				// Skip the statement header; a following '{' (namespace block) stays transparent.
				// Only a namespace header stops at '{'; a grouped use (use Foo\{Bar, Baz};) runs to ';'.
				for ( ; $i < $n && ';' !== $t[ $i ] && ( T_NAMESPACE !== $id || '{' !== $t[ $i ] ); $i++ ) {
					if ( '(' === $t[ $i ] ) {
						$i = wpr_paren_end( $t, $i )[0] - 1;
					}
				}
				$i++;
				continue;
			}
			if ( in_array( $id, array( T_ABSTRACT, T_FINAL ), true ) || ( defined( 'T_READONLY' ) && T_READONLY === $id ) ) {
				$i++;
				continue;
			}
			if ( in_array( $id, array( T_FUNCTION, T_CLASS, T_INTERFACE, T_TRAIT ), true )
				|| ( defined( 'T_ENUM' ) && T_ENUM === $id ) ) {
				// Named declaration: skip to its body and past it.
				for ( ; $i < $n && '{' !== $t[ $i ]; $i++ ) {
					if ( '(' === $t[ $i ] ) {
						$i = wpr_paren_end( $t, $i )[0] - 1;
					}
				}
				$i = wpr_brace_end( $t, $i );
				continue;
			}
			if ( T_IF === $id ) {
				$open = wpr_next_index( $t, $i );
				if ( $open < $n && '(' === $t[ $open ] ) {
					list( $after, $names ) = wpr_paren_end( $t, $open );
					$names = array_diff( $names, GUARD_FUNCS );
					if ( empty( $names ) ) {
						// Existence-check wrapper: treat its body as top level.
						$body = wpr_next_index( $t, $after - 1 );
						$i    = ( $body < $n && ( '{' === $t[ $body ] || ':' === $t[ $body ] ) ) ? $body + 1 : $after;
						continue;
					}
				}
				return $tok[2];
			}
			if ( in_array( $id, array( T_ENDIF, T_ELSE ), true ) ) {
				$i = wpr_next_index( $t, $i );
				if ( $i < $n && ( ';' === $t[ $i ] || ':' === $t[ $i ] || '{' === $t[ $i ] ) ) {
					$i++;
				}
				continue;
			}
			if ( defined( 'T_ATTRIBUTE' ) && T_ATTRIBUTE === $id ) {
				for ( $depth = 0; $i < $n; $i++ ) {
					if ( is_array( $t[ $i ] ) && T_ATTRIBUTE === $t[ $i ][0] || '[' === $t[ $i ] ) {
						$depth++;
					} elseif ( ']' === $t[ $i ] && 0 === --$depth ) {
						break;
					}
				}
				$i++;
				continue;
			}
			return $tok[2];
		}

		// Single-character tokens: closing braces of transparent blocks, stray ';'.
		if ( '}' === $tok || ';' === $tok ) {
			$i++;
			continue;
		}
		return wpr_line_at( $t, $i );
	}
	return 0;
}

$status = 0;
foreach ( array_slice( $argv, 1 ) as $file ) {
	$code = @file_get_contents( $file );
	if ( false === $code ) {
		fwrite( STDERR, "unreadable: $file\n" );
		$status = 1;
		continue;
	}
	try {
		$line = wpr_first_exec_line( token_get_all( $code ) );
	} catch ( Throwable $e ) {
		echo "$file\tunknown\n";
		continue;
	}
	echo $line ? "$file\texecutes\t$line\n" : "$file\tdefinition\n";
}
exit( $status );
