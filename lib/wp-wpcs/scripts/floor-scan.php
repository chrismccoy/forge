<?php
/**
 * Lists syntax and functions newer than a target PHP version.
 *
 * PHPCompatibility 9 knows little past PHP 7.4, so a clean run proves nothing about
 * match, enums or union types. This scan covers those by tokens. It runs on the
 * local PHP, which must be at least as new as the code being scanned.
 *
 * Usage: php floor-scan.php <target-version> <path>...
 * Example: php floor-scan.php 7.2 includes tests my-plugin.php
 *
 * Exit code 1 when anything but a REVIEW line is listed. It is a list of known constructs, not proof
 * that the code runs on the target: only `php -l` with a real binary of that version
 * proves it parses. Needs PHP 8.1 or later.
 */

if ( $argc < 3 ) {
	fwrite( STDERR, "Usage: php floor-scan.php <target-version> <path>...\n" );
	exit( 2 );
}
$target = $argv[1];

// Function name => PHP version that added it. WordPress polyfills some of these.
$functions = [
	'str_contains' => '8.0', 'str_starts_with' => '8.0', 'str_ends_with' => '8.0', 'get_debug_type' => '8.0',
	'get_resource_id' => '8.0', 'fdiv' => '8.0', 'array_is_list' => '8.1', 'array_key_first' => '7.3',
	'array_key_last' => '7.3', 'is_countable' => '7.3', 'hrtime' => '7.3', 'mb_str_split' => '7.4',
	'password_algos' => '7.4', 'array_find' => '8.4', 'array_any' => '8.4', 'array_all' => '8.4',
];
// Calls that parse everywhere but act differently below a version: printed as REVIEW
// lines, which aren't hits and don't change the exit code. Read each one, and add a test
// when the floor will drop.
$review = [
	'is_numeric'        => [ '8.0', 'trailing whitespace is not numeric below 8.0' ],
	'substr'            => [ '8.0', 'returns false past the end of the string below 8.0' ],
	'ob_implicit_flush' => [ '8.0', 'takes int below 8.0, so a bool is a TypeError under strict_types' ],
	'strtolower'        => [ '8.2', 'follows the locale below 8.2' ],
	'strtoupper'        => [ '8.2', 'follows the locale below 8.2' ],
];
// Token name => [ version, label ]. Names are checked so older PHP constants don't fatal.
$tokens = [
	'T_MATCH' => [ '8.0', 'match' ], 'T_NULLSAFE_OBJECT_OPERATOR' => [ '8.0', 'nullsafe ?->' ],
	'T_ATTRIBUTE' => [ '8.0', 'attribute' ], 'T_ENUM' => [ '8.1', 'enum' ], 'T_READONLY' => [ '8.1', 'readonly' ],
	'T_FN' => [ '7.4', 'arrow function' ], 'T_COALESCE_EQUAL' => [ '7.4', '??=' ],
];
$map = [];
foreach ( $tokens as $name => $info ) {
	if ( defined( $name ) ) {
		$map[ constant( $name ) ] = $info;
	}
}

function sig( array $t, int $i, int $step ) {
	for ( $i += $step; isset( $t[ $i ] ); $i += $step ) {
		if ( ! is_array( $t[ $i ] ) || ! in_array( $t[ $i ][0], [ T_WHITESPACE, T_COMMENT, T_DOC_COMMENT ], true ) ) {
			return [ $i, $t[ $i ] ];
		}
	}
	return [ -1, null ];
}

/** Index of the token after a function's return colon, or -1 when $i isn't that colon. */
function return_type_start( array $t, int $i ): int {
	[ $k, $close ] = sig( $t, $i, -1 );
	if ( $close !== ')' ) {
		return -1;
	}
	$depth = 0;
	for ( ; $k >= 0; $k-- ) {
		$depth += ( $t[ $k ] === ')' ? 1 : 0 ) - ( $t[ $k ] === '(' ? 1 : 0 );
		if ( $depth === 0 ) {
			break;
		}
	}
	[ $k, $p ] = sig( $t, $k, -1 );
	if ( is_array( $p ) && $p[0] === T_STRING ) {
		[ $k, $p ] = sig( $t, $k, -1 );
	}
	if ( $p === '&' ) {
		[ $k, $p ] = sig( $t, $k, -1 );
	}
	return is_array( $p ) && in_array( $p[0], [ T_FUNCTION, T_FN ], true ) ? sig( $t, $i, 1 )[0] : -1;
}

$files = [];
foreach ( array_slice( $argv, 2 ) as $path ) {
	if ( is_file( $path ) ) {
		$files[] = $path;
		continue;
	}
	foreach ( new RecursiveIteratorIterator( new RecursiveDirectoryIterator( $path, FilesystemIterator::SKIP_DOTS ) ) as $f ) {
		if ( $f->getExtension() === 'php' && ! preg_match( '#/(vendor|node_modules|build|\.wpcs)/#', $f->getPathname() ) ) {
			$files[] = $f->getPathname();
		}
	}
}

$hits = 0;
$say  = function ( string $file, int $line, string $version, string $label ) use ( $target, &$hits ) {
	if ( version_compare( $version, $target, '>' ) ) {
		echo "$file:$line: $label (PHP $version)\n";
		$hits++;
	}
};

foreach ( $files as $file ) {
	$t     = token_get_all( file_get_contents( $file ) );
	$stack = [];
	foreach ( $t as $i => $tok ) {
		if ( $tok === '(' ) {
			$p       = sig( $t, $i, -1 )[1];
			$before  = sig( $t, sig( $t, $i, -1 )[0], -1 )[1];
			$is_decl = ( is_array( $before ) && in_array( $before[0], [ T_FUNCTION, T_FN ], true ) ) || ( is_array( $p ) && in_array( $p[0], [ T_FUNCTION, T_FN ], true ) );
			$is_list = is_array( $p ) && in_array( $p[0], [ T_ARRAY, T_LIST ], true );
			$stack[] = $is_decl ? 'params' : ( $is_list ? 'array' : 'call' );
			continue;
		}
		if ( $tok === ')' ) {
			$kind = array_pop( $stack );
			if ( sig( $t, $i, -1 )[1] === ',' && $kind !== 'array' ) {
				$line = 0;
				for ( $k = $i; $k >= 0 && ! $line; $k-- ) {
					$line = is_array( $t[ $k ] ) ? $t[ $k ][2] : 0;
				}
				$say( $file, $line, $kind === 'params' ? '8.0' : '7.3', $kind === 'params' ? 'trailing comma in parameters' : 'trailing comma in a call' );
			}
			continue;
		}
		if ( $tok === ':' ) {
			$j = return_type_start( $t, $i );
			if ( $j >= 0 ) {
				$parts = [];
				for ( ; isset( $t[ $j ] ) && $t[ $j ] !== '{' && $t[ $j ] !== ';' && $t[ $j ] !== '=' && ! ( is_array( $t[ $j ] ) && $t[ $j ][0] === T_DOUBLE_ARROW ); $j++ ) {
					if ( is_array( $t[ $j ] ) && $t[ $j ][0] !== T_WHITESPACE ) {
						$parts[] = strtolower( $t[ $j ][1] );
						$line_no = $t[ $j ][2];
					}
				}
				if ( count( $parts ) > 1 ) {
					$say( $file, $line_no, '8.0', 'union return type' );
				}
				if ( in_array( 'static', $parts, true ) ) {
					$say( $file, $line_no, '8.0', 'static return type' );
				}
				if ( in_array( '&', $parts, true ) ) {
					$say( $file, $line_no, '8.1', 'intersection type' );
				}
				if ( in_array( 'true', $parts, true ) ) {
					$say( $file, $line_no, '8.2', 'true type' );
				}
				if ( $parts === [ 'false' ] || $parts === [ 'null' ] ) {
					$say( $file, $line_no, '8.2', 'standalone false or null type' );
				}
			}
			continue;
		}
		if ( ! is_array( $tok ) ) {
			continue;
		}
		[ $id, $text, $line ] = $tok;
		$top  = end( $stack );
		$prev = sig( $t, $i, -1 )[1];
		$next = sig( $t, $i, 1 )[1];
		if ( isset( $map[ $id ] ) ) {
			$say( $file, $line, $map[ $id ][0], $map[ $id ][1] );
		}
		if ( $id === T_ELLIPSIS && $next === ')' && $prev === '(' ) {
			$say( $file, $line, '8.1', 'first-class callable' );
		}
		if ( in_array( $id, [ T_LNUMBER, T_DNUMBER ], true ) && strpos( $text, '_' ) !== false ) {
			$say( $file, $line, '7.4', 'numeric separator' );
		}
		if ( $id === T_CATCH ) {
			$j = $i;
			while ( isset( $t[ $j ] ) && $t[ $j ] !== ')' ) {
				$j++;
			}
			$last = sig( $t, $j, -1 )[1];
			if ( ! is_array( $last ) || $last[0] !== T_VARIABLE ) {
				$say( $file, $line, '8.0', 'catch without a variable' );
			}
		}
		if ( $id === T_THROW && ( in_array( $prev, [ '=', '(', ',', '?' ], true ) || ( is_array( $prev ) && in_array( $prev[0], [ T_COALESCE, T_DOUBLE_ARROW, T_BOOLEAN_AND, T_BOOLEAN_OR, T_LOGICAL_AND, T_LOGICAL_OR ], true ) ) ) ) {
			$say( $file, $line, '8.0', 'throw expression' );
		}
		if ( $id === T_CLASS && is_array( $prev ) && $prev[0] === T_DOUBLE_COLON ) {
			$owner = sig( $t, sig( $t, $i, -1 )[0], -1 )[1];
			if ( $owner === ')' || ( is_array( $owner ) && $owner[0] === T_VARIABLE ) ) {
				$say( $file, $line, '8.0', '::class on an object' );
			}
		}
		if ( $top === 'params' && $id === T_NEW ) {
			$say( $file, $line, '8.1', 'new in an initializer' );
		}
		if ( $top === 'params' && defined( 'T_AMPERSAND_NOT_FOLLOWED_BY_VAR_OR_VARARG' ) && $id === T_AMPERSAND_NOT_FOLLOWED_BY_VAR_OR_VARARG ) {
			$say( $file, $line, '8.1', 'intersection type' );
		}
		if ( $id === T_FINAL && is_array( $next ) && $next[0] === T_CONST ) {
			$say( $file, $line, '8.1', 'final class constant' );
		}
		if ( $id === T_READONLY && is_array( $next ) && $next[0] === T_CLASS ) {
			$say( $file, $line, '8.2', 'readonly class' );
		}
		if ( $id === T_CONST && is_array( $next ) && $next[0] === T_STRING ) {
			$after = sig( $t, sig( $t, $i, 1 )[0], 1 )[1];
			if ( is_array( $after ) && $after[0] === T_STRING ) {
				$say( $file, $line, '8.3', 'typed class constant' );
			}
		}
		if ( $top === 'params' && $id === T_STRING && strtolower( $text ) === 'true' && ( is_array( $next ) && $next[0] === T_VARIABLE || $next === '|' || $prev === '|' ) ) {
			$say( $file, $line, '8.2', 'true type' );
		}
		if ( $top === 'params' && in_array( $id, [ T_PUBLIC, T_PROTECTED, T_PRIVATE ], true ) ) {
			$say( $file, $line, '8.0', 'constructor promotion' );
		}
		if ( $id === T_STRING ) {
			$lower = strtolower( $text );
			$after_arrow = is_array( $prev ) && in_array( $prev[0], [ T_OBJECT_OPERATOR, T_DOUBLE_COLON, T_FUNCTION ], true );
			if ( isset( $functions[ $lower ] ) && $next === '(' && ! $after_arrow ) {
				$say( $file, $line, $functions[ $lower ], "$lower()" );
			}
			if ( isset( $review[ $lower ] ) && $next === '(' && ! $after_arrow && version_compare( $target, $review[ $lower ][0], '<' ) ) {
				echo "REVIEW: $file:$line $lower(): {$review[ $lower ][1]}\n";
			}
			if ( $top === 'call' && $next === ':' && in_array( $prev, [ '(', ',' ], true ) ) {
				$say( $file, $line, '8.0', 'named argument' );
			}
			if ( $lower === 'mixed' && is_array( sig( $t, $i, 1 )[1] ) && sig( $t, $i, 1 )[1][0] === T_VARIABLE ) {
				$say( $file, $line, '8.0', 'mixed type' );
			}
			if ( $lower === 'never' && $prev === ':' ) {
				$say( $file, $line, '8.1', 'never return type' );
			}
		}
		// A property type: a visibility or var keyword followed by a type, then a variable.
		if ( in_array( $id, [ T_PUBLIC, T_PROTECTED, T_PRIVATE, T_VAR ], true ) && $top !== 'params' ) {
			$j = $i;
			do {
				[ $j, $n ] = sig( $t, $j, 1 );
			} while ( is_array( $n ) && $n[0] === T_STATIC );
			if ( is_array( $n ) && $n[0] !== T_VARIABLE && $n[0] !== T_FUNCTION && $n[0] !== T_CONST ) {
				$say( $file, $line, '7.4', 'typed property' );
			} elseif ( $n === '?' ) {
				$say( $file, $line, '7.4', 'typed property' );
			}
		}
		// A union type: `|` between a type and a variable in a parameter list.
		if ( $top === 'params' && $id === T_VARIABLE && $prev !== null && is_array( $prev ) ) {
			[ $k, $b ] = sig( $t, $i, -1 );
			[ , $c ]   = sig( $t, $k, -1 );
			if ( $c === '|' ) {
				$say( $file, $line, '8.0', 'union type' );
			}
		}
	}
}
echo $hits ? "$hits found\n" : "none found\n";
exit( $hits ? 1 : 0 );
