<?php
/**
 * Check add_action()/add_filter() registrations against their callbacks.
 *
 * Tokenizes every file (never includes or runs them), indexes named functions
 * and class methods, then resolves each hook callback and reports:
 *   - accepted_args lower than the callback's required parameters
 *     (ArgumentCountError when the hook fires)
 *   - filter callbacks with a bare "return;" or no "return <value>" at all
 *     (the filter yields null)
 *   - admin-only Settings API calls in callbacks on hooks that also fire on the
 *     front end (fatal error: wp-admin/includes/template.php is not loaded)
 *
 * Resolved callback forms: 'func', 'Class::method', array( $this|__CLASS__|
 * self::class|static::class|'Class'|Class::class, 'method' ), [ ... ], closures.
 * Unresolved callbacks (variables, core functions) are skipped silently.
 * Names are indexed without their namespace, so same-named functions or
 * classes in different namespaces collide (the last one wins).
 *
 * Usage: php hooks.php <file>...   or   php hooks.php - < NUL-separated list
 * (stdin keeps one index across all files; xargs could split the list).
 * Output: "<file>:<line>\t<message>" per candidate.
 * Exit 3 when the tokenizer extension is unavailable.
 */

ini_set( 'display_errors', 'stderr' );

if ( ! function_exists( 'token_get_all' ) ) {
	exit( 3 );
}

const WPR_SKIP = array( T_WHITESPACE, T_COMMENT, T_DOC_COMMENT, T_OPEN_TAG, T_CLOSE_TAG );

// Functions defined only in wp-admin/includes, and hooks that also fire outside wp-admin.
const WPR_ADMIN_ONLY  = array( 'add_settings_section', 'add_settings_field', 'settings_fields', 'do_settings_sections' );
const WPR_FRONT_HOOKS = array( 'init', 'plugins_loaded', 'wp_loaded', 'after_setup_theme', 'setup_theme', 'muplugins_loaded', 'wp', 'template_redirect', 'wp_enqueue_scripts', 'wp_head', 'wp_footer', 'rest_api_init' );

function wpr_sig( array $t, int $i ): int {
	$n = count( $t );
	for ( ; $i < $n; $i++ ) {
		if ( ! is_array( $t[ $i ] ) || ! in_array( $t[ $i ][0], WPR_SKIP, true ) ) {
			return $i;
		}
	}
	return $n;
}

function wpr_prev_sig( array $t, int $i ): int {
	for ( $i--; $i >= 0; $i-- ) {
		if ( ! is_array( $t[ $i ] ) || ! in_array( $t[ $i ][0], WPR_SKIP, true ) ) {
			return $i;
		}
	}
	return -1;
}

function wpr_is( $tok, $id ): bool {
	return is_array( $tok ) ? $tok[0] === $id : $tok === $id;
}

function wpr_opens( $tok ): bool {
	return in_array( $tok, array( '(', '[', '{' ), true )
		|| ( is_array( $tok ) && in_array( $tok[0], array( T_CURLY_OPEN, T_DOLLAR_OPEN_CURLY_BRACES ), true ) );
}

/** Index of the bracket matching the one at $i. */
function wpr_match( array $t, int $i ): int {
	$depth = 0;
	$n     = count( $t );
	for ( ; $i < $n; $i++ ) {
		if ( wpr_opens( $t[ $i ] ) ) {
			$depth++;
		} elseif ( in_array( $t[ $i ], array( ')', ']', '}' ), true ) && 0 === --$depth ) {
			return $i;
		}
	}
	return $n - 1;
}

/** Split the bracket group opened at $i into top-level comma-separated token ranges. */
function wpr_split( array $t, int $i ): array {
	$end   = wpr_match( $t, $i );
	$parts = array();
	$start = $i + 1;
	for ( $j = $i + 1; $j < $end; $j++ ) {
		if ( wpr_opens( $t[ $j ] ) ) {
			$j = wpr_match( $t, $j );
		} elseif ( ',' === $t[ $j ] ) {
			$parts[] = array( $start, $j );
			$start   = $j + 1;
		}
	}
	if ( wpr_sig( $t, $start ) < $end ) {
		$parts[] = array( $start, $end );
	}
	return $parts;
}

/** Significant tokens of a range. */
function wpr_toks( array $t, array $r ): array {
	$out = array();
	for ( $j = $r[0]; $j < $r[1]; $j++ ) {
		if ( ! is_array( $t[ $j ] ) || ! in_array( $t[ $j ][0], WPR_SKIP, true ) ) {
			$out[] = $t[ $j ];
		}
	}
	return $out;
}

/** Lowercase function name of a T_STRING or PHP 8 fully qualified name token, else ''. */
function wpr_fname( $tok ): string {
	if ( is_array( $tok ) && ( T_STRING === $tok[0] || ( defined( 'T_NAME_FULLY_QUALIFIED' ) && T_NAME_FULLY_QUALIFIED === $tok[0] ) ) ) {
		return strtolower( ltrim( $tok[1], '\\' ) );
	}
	return '';
}

function wpr_short( string $name ): string {
	$name = ltrim( $name, '\\' );
	$pos  = strrpos( $name, '\\' );
	return strtolower( false === $pos ? $name : substr( $name, $pos + 1 ) );
}

/** Required parameter count of the parameter list opened at $i. */
function wpr_required( array $t, int $i ): int {
	$req = 0;
	foreach ( wpr_split( $t, $i ) as $r ) {
		$optional = false;
		for ( $j = $r[0]; $j < $r[1]; $j++ ) {
			if ( '=' === $t[ $j ] || wpr_is( $t[ $j ], T_ELLIPSIS ) ) {
				$optional = true;
			}
		}
		if ( ! $optional ) {
			$req++;
		}
	}
	return $req;
}

/** Return statements and called function names in the body {..} at $i, skipping nested closures and classes. */
function wpr_returns( array $t, int $open ): array {
	$end    = wpr_match( $t, $open );
	$bare   = array();
	$values = 0;
	$calls  = array();
	for ( $j = $open + 1; $j < $end; $j++ ) {
		if ( is_array( $t[ $j ] ) && in_array( $t[ $j ][0], array( T_FUNCTION, T_CLASS ), true )
			&& ! wpr_is( $t[ wpr_prev_sig( $t, $j ) ], T_DOUBLE_COLON ) ) {
			$k = $j;
			while ( $k < $end && '{' !== $t[ $k ] && ';' !== $t[ $k ] ) {
				$k++;
			}
			$j = '{' === $t[ $k ] ? wpr_match( $t, $k ) : $k;
			continue;
		}
		if ( '' !== wpr_fname( $t[ $j ] ) && '(' === $t[ wpr_sig( $t, $j + 1 ) ] ) {
			$prev = $t[ wpr_prev_sig( $t, $j ) ];
			if ( ! wpr_is( $prev, T_OBJECT_OPERATOR ) && ! wpr_is( $prev, T_DOUBLE_COLON ) && ! wpr_is( $prev, T_NEW ) ) {
				$calls[ wpr_fname( $t[ $j ] ) ] = $t[ $j ][2];
			}
		}
		if ( wpr_is( $t[ $j ], T_RETURN ) ) {
			$next = wpr_sig( $t, $j + 1 );
			if ( ';' === $t[ $next ] ) {
				$bare[] = $t[ $j ][2];
			} else {
				$values++;
			}
		}
	}
	return array( $bare, $values, $calls );
}

/** Parse a declaration starting at T_FUNCTION/T_FN index $i. */
function wpr_decl( array $t, int $i ): array {
	$n = count( $t );
	for ( $p = $i; $p < $n && '(' !== $t[ $p ]; $p++ ) {
	}
	$info = array(
		'required' => wpr_required( $t, $p ),
		'line'     => $t[ $i ][2],
		'bare'     => array(),
		'values'   => -1, // Unknown: abstract method or arrow function.
		'calls'    => array(),
	);
	$k = wpr_match( $t, $p ) + 1;
	while ( $k < $n && '{' !== $t[ $k ] && ';' !== $t[ $k ] && ! wpr_is( $t[ $k ], T_DOUBLE_ARROW ) ) {
		$k++;
	}
	if ( $k < $n && '{' === $t[ $k ] ) {
		list( $info['bare'], $info['values'], $info['calls'] ) = wpr_returns( $t, $k );
	}
	return $info;
}

$index = array(); // "class::method" or "function" => info.
$hooks = array();

$files = array_slice( $argv, 1 );
if ( array( '-' ) === $files ) {
	$files = array_filter( explode( "\0", stream_get_contents( STDIN ) ) );
}

foreach ( $files as $file ) {
	$code = @file_get_contents( $file );
	if ( false === $code ) {
		continue;
	}
	try {
		$t = token_get_all( $code );
	} catch ( Throwable $e ) {
		continue;
	}
	$n       = count( $t );
	$classes = array(); // Stack of array( name, end index ).

	for ( $i = 0; $i < $n; $i++ ) {
		while ( $classes && $i > end( $classes )[1] ) {
			array_pop( $classes );
		}
		$tok = $t[ $i ];
		if ( ! is_array( $tok ) ) {
			continue;
		}
		$prev = wpr_prev_sig( $t, $i );

		if ( in_array( $tok[0], array( T_CLASS, T_TRAIT, T_INTERFACE ), true ) || ( defined( 'T_ENUM' ) && T_ENUM === $tok[0] ) ) {
			if ( $prev >= 0 && ( wpr_is( $t[ $prev ], T_DOUBLE_COLON ) || wpr_is( $t[ $prev ], T_NEW ) ) ) {
				continue;
			}
			$name = wpr_sig( $t, $i + 1 );
			for ( $b = $name; $b < $n && '{' !== $t[ $b ]; $b++ ) {
			}
			$classes[] = array( wpr_short( $t[ $name ][1] ), wpr_match( $t, $b ) );
			continue;
		}

		if ( T_FUNCTION === $tok[0] ) {
			$name = wpr_sig( $t, $i + 1 );
			if ( '(' !== $t[ $name ] && ( ! is_array( $t[ $name ] ) || T_STRING !== $t[ $name ][0] ) ) {
				$name = wpr_sig( $t, $name + 1 ); // Skip a by-reference '&'.
			}
			// Named only when the name is followed by '(': closures and type hints are not names.
			if ( is_array( $t[ $name ] ) && T_STRING === $t[ $name ][0] && '(' === $t[ wpr_sig( $t, $name + 1 ) ] ) {
				$key           = ( $classes ? end( $classes )[0] . '::' : '' ) . strtolower( $t[ $name ][1] );
				$index[ $key ] = wpr_decl( $t, $i ) + array( 'file' => $file );
			}
			continue;
		}

		if ( ! in_array( wpr_fname( $tok ), array( 'add_action', 'add_filter' ), true ) ) {
			continue;
		}
		if ( $prev >= 0 && ( wpr_is( $t[ $prev ], T_OBJECT_OPERATOR ) || wpr_is( $t[ $prev ], T_DOUBLE_COLON ) || wpr_is( $t[ $prev ], T_FUNCTION ) ) ) {
			continue;
		}
		$open = wpr_sig( $t, $i + 1 );
		if ( '(' !== $t[ $open ] ) {
			continue;
		}
		$args = wpr_split( $t, $open );
		if ( count( $args ) < 2 ) {
			continue;
		}
		$accepted = 1;
		if ( isset( $args[3] ) ) {
			$a        = wpr_toks( $t, $args[3] );
			$accepted = ( 1 === count( $a ) && wpr_is( $a[0], T_LNUMBER ) ) ? (int) $a[0][1] : null;
		}
		$hook = wpr_toks( $t, $args[0] );
		$hook = ( 1 === count( $hook ) && wpr_is( $hook[0], T_CONSTANT_ENCAPSED_STRING ) ) ? trim( $hook[0][1], '\'"' ) : '(dynamic)';

		$cb     = wpr_toks( $t, $args[1] );
		$here   = $classes ? end( $classes )[0] : '';
		$target = null;
		$inline = null;
		$first  = $cb[0] ?? null;

		if ( wpr_is( $first, T_STATIC ) ) {
			array_shift( $cb );
			$first = $cb[0] ?? null;
		}
		$fn_id = defined( 'T_FN' ) ? T_FN : -1;
		if ( wpr_is( $first, T_FUNCTION ) || wpr_is( $first, $fn_id ) ) {
			for ( $j = $args[1][0]; ! wpr_is( $t[ $j ], T_FUNCTION ) && ! wpr_is( $t[ $j ], $fn_id ); $j++ ) {
			}
			$inline = wpr_decl( $t, $j );
		} elseif ( 3 === count( $cb ) && wpr_is( $first, T_NS_C ) && '.' === $cb[1] && wpr_is( $cb[2], T_CONSTANT_ENCAPSED_STRING ) ) {
			$target = wpr_short( trim( $cb[2][1], '\'"' ) );
		} elseif ( 1 === count( $cb ) && wpr_is( $first, T_CONSTANT_ENCAPSED_STRING ) ) {
			$s      = trim( $first[1], '\'"' );
			$parts  = explode( '::', $s );
			$target = 2 === count( $parts ) ? wpr_short( $parts[0] ) . '::' . strtolower( $parts[1] ) : wpr_short( $s );
		} elseif ( wpr_is( $first, T_ARRAY ) || '[' === $first ) {
			for ( $j = $args[1][0]; ! wpr_is( $t[ $j ], T_ARRAY ) && '[' !== $t[ $j ]; $j++ ) {
			}
			if ( wpr_is( $t[ $j ], T_ARRAY ) ) {
				$j = wpr_sig( $t, $j + 1 );
			}
			$pair = wpr_split( $t, $j );
			if ( 2 === count( $pair ) ) {
				$obj  = wpr_toks( $t, $pair[0] );
				$meth = wpr_toks( $t, $pair[1] );
				if ( 1 === count( $meth ) && wpr_is( $meth[0], T_CONSTANT_ENCAPSED_STRING ) ) {
					$m     = strtolower( trim( $meth[0][1], '\'"' ) );
					$class = null;
					$o0    = $obj[0] ?? null;
					if ( 1 === count( $obj ) && ( ( wpr_is( $o0, T_VARIABLE ) && '$this' === $o0[1] ) || wpr_is( $o0, T_CLASS_C ) ) ) {
						$class = $here;
					} elseif ( 1 === count( $obj ) && wpr_is( $o0, T_CONSTANT_ENCAPSED_STRING ) ) {
						$class = wpr_short( trim( $o0[1], '\'"' ) );
					} elseif ( 3 === count( $obj ) && wpr_is( $obj[2], T_CLASS ) ) {
						$c     = strtolower( $o0[1] );
						$class = in_array( $c, array( 'self', 'static' ), true ) ? $here : wpr_short( $o0[1] );
					}
					if ( null !== $class ) {
						$target = $class . '::' . $m;
					}
				}
			}
		}
		$hooks[] = array( $file, $tok[2], wpr_fname( $tok ), $hook, $accepted, $target, $inline );
	}
}

foreach ( $hooks as list( $file, $line, $fn, $hook, $accepted, $target, $inline ) ) {
	$info = $inline ?? ( null !== $target ? ( $index[ $target ] ?? null ) : null );
	if ( null === $info ) {
		continue;
	}
	$label = $inline ? 'closure' : $target . '()';
	$where = $inline ? '' : ' (' . basename( $info['file'] ) . ':' . $info['line'] . ')';
	if ( null !== $accepted && $info['required'] > $accepted ) {
		echo "$file:$line\t$fn '$hook': accepted_args $accepted but $label$where requires {$info['required']} (ArgumentCountError)\n";
	}
	if ( in_array( $hook, WPR_FRONT_HOOKS, true ) ) {
		foreach ( array_intersect_key( $info['calls'], array_flip( WPR_ADMIN_ONLY ) ) as $call => $cl ) {
			echo "$file:$line\t'$hook' callback $label calls admin-only $call() at line $cl$where (fatal on the front end)\n";
		}
	}
	if ( 'add_filter' === $fn ) {
		foreach ( $info['bare'] as $bl ) {
			echo "$file:$line\tfilter '$hook': $label has a bare 'return;' at line $bl$where (filter yields null)\n";
		}
		if ( 0 === $info['values'] && ! $info['bare'] ) {
			echo "$file:$line\tfilter '$hook': $label never returns a value$where (filter yields null)\n";
		}
	}
}
