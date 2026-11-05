<?php
/**
 * Places hand-written descriptions into docblocks, taking types from the declarations.
 *
 * Usage:
 *   php docblocks.php --list <file>...
 *       Prints a JSON skeleton of every description the files still need.
 *   php docblocks.php --apply <descriptions.json> --package <package> [--since <version>] [--map <map-file>] <file>...
 *       Writes the docblocks. Writes nothing if any description is missing or empty.
 *
 * Skeleton sections, with keys built from the file's base name:
 *   files      "class-x.php"               file summary
 *   classes    "class-x.php::Name"         summary of a class with no docblock
 *   consts     "class-x.php::NAME"         summary of a class constant with no docblock
 *   summaries  "class-x.php::func"         summary of a function with no docblock, or
 *                                          one whose docblock holds only annotations
 *   params     "class-x.php::func::$name"  description; [ "type", "description" ] when untyped
 *   returns    "class-x.php::func"         description
 *
 * A function with no return type that returns a value gets no @return, because the
 * script can't know the type. Those are listed under "untyped_returns" by --list, and
 * as ADD @return lines by --apply: write each tag by hand.
 *   props      "class-x.php::$name"        summary; [ "type", "summary" ] when untyped
 *
 * --since adds @since <version> to docblocks the script creates.
 * --map renames "Class Old" headline lines in class docblocks (flatten.php map format).
 * Needs PHP 8.1 or later.
 */

$args = array_slice( $argv, 1 );
$opts = [
	'list'    => false,
	'apply'   => null,
	'package' => null,
	'map'     => null,
	'since'   => null,
];
$files = [];
while ( $args ) {
	$a = array_shift( $args );
	if ( $a === '--list' ) {
		$opts['list'] = true;
	} elseif ( in_array( $a, [ '--apply', '--package', '--map', '--since' ], true ) ) {
		$opts[ substr( $a, 2 ) ] = array_shift( $args );
	} else {
		$files[] = $a;
	}
}
if ( ! $files || ( ! $opts['list'] && ( ! $opts['apply'] || ! $opts['package'] ) ) ) {
	fwrite( STDERR, "Usage: php docblocks.php --list <file>... | --apply <json> --package <package> [--map <map>] <file>...\n" );
	exit( 1 );
}

$desc = $opts['apply'] ? json_decode( file_get_contents( $opts['apply'] ), true ) : [];
if ( $opts['apply'] && ! is_array( $desc ) ) {
	fwrite( STDERR, "Invalid JSON: {$opts['apply']}\n" );
	exit( 1 );
}
$names = [];
if ( $opts['map'] ) {
	foreach ( file( $opts['map'], FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES ) as $line ) {
		$cols = preg_split( '/\s+/', trim( $line ) );
		$segs = explode( '\\', $cols[0] );
		$names[ end( $segs ) ] = $cols[1];
	}
}

$untyped = [];
$need    = [
	'files'     => [],
	'classes'   => [],
	'consts'    => [],
	'summaries' => [],
	'params'    => [],
	'returns'   => [],
	'props'     => [],
];

/** Looks up a description; records it as needed when absent or empty. */
function lookup( string $section, string $key, array $blank = [] ) {
	global $desc, $need;
	$value = $desc[ $section ][ $key ] ?? null;
	$empty = $value === null || $value === '' || ( is_array( $value ) && in_array( '', $value, true ) );
	if ( $empty ) {
		$need[ $section ][ $key ] = $blank ?: '';
		return null;
	}
	return $value;
}

function ptype( string $type ): string {
	$type = trim( $type );
	return $type[0] === '?' ? substr( $type, 1 ) . '|null' : $type;
}

/** Splits a parameter list at top-level commas into [ type|null, $name, default ]. */
function parse_params( string $inner ): array {
	$parts = [];
	$depth = 0;
	$cur   = '';
	foreach ( str_split( $inner ) as $ch ) {
		$depth += ( $ch === '(' || $ch === '[' ) ? 1 : ( ( $ch === ')' || $ch === ']' ) ? -1 : 0 );
		if ( $ch === ',' && $depth === 0 ) {
			$parts[] = $cur;
			$cur     = '';
		} else {
			$cur .= $ch;
		}
	}
	if ( trim( $cur ) !== '' ) {
		$parts[] = $cur;
	}
	$out = [];
	foreach ( $parts as $p ) {
		if ( preg_match( '/^\s*(?:(?:public|private|protected|readonly)\s+)*([?\w\\\\|&]+\s+)?&?(?:\.\.\.)?(\$\w+)(?:\s*=\s*(.+))?$/s', trim( $p ), $m ) ) {
			$out[] = [ isset( $m[1] ) && $m[1] !== '' ? trim( $m[1] ) : null, $m[2], trim( $m[3] ?? '' ) ];
		}
	}
	return $out;
}

/**
 * Whether the function whose signature ends in $text returns a value. Reads tokens, so
 * comments and strings don't count, and a return inside a nested closure, function or
 * anonymous class belongs to that code rather than to this function.
 */
function returns_value( string $text ): bool {
	$t     = token_get_all( "<?php\n" . $text );
	$n     = count( $t );
	$level = 0;
	$skip  = 0; // Level at which a nested body ends, or 0 when not inside one.
	$nest  = false;
	for ( $i = 0; $i < $n; $i++ ) {
		$id = is_array( $t[ $i ] ) ? $t[ $i ][0] : $t[ $i ];
		if ( $level === 0 && $id === ';' ) {
			return false; // Abstract or interface method.
		}
		if ( $id === '{' || $id === T_CURLY_OPEN || $id === T_DOLLAR_OPEN_CURLY_BRACES ) {
			$level++;
			if ( $nest && $skip === 0 && $id === '{' ) {
				$skip = $level;
				$nest = false;
			}
		} elseif ( $id === '}' ) {
			if ( $skip === $level ) {
				$skip = 0;
			}
			$level--;
			if ( $level === 0 ) {
				return false;
			}
		} elseif ( $level > 0 && $skip === 0 && ( $id === T_FUNCTION || $id === T_CLASS ) ) {
			$nest = true;
		} elseif ( $level > 0 && $skip === 0 && $id === T_RETURN ) {
			for ( $j = $i + 1; $j < $n; $j++ ) {
				if ( is_array( $t[ $j ] ) && in_array( $t[ $j ][0], [ T_WHITESPACE, T_COMMENT, T_DOC_COMMENT ], true ) ) {
					continue;
				}
				if ( $t[ $j ] !== ';' ) {
					return true;
				}
				break;
			}
		}
	}
	return false;
}

/** Returns the docblock start line for the block ending at $end. */
function block_start( array $lines, int $end ): int {
	while ( $end > 0 && strpos( ltrim( $lines[ $end ] ), '/**' ) !== 0 ) {
		$end--;
	}
	return $end;
}

function process( string $path, array $names, ?string $package ): string {
	global $opts;
	$since = $opts['since'] ? [ ' *', ' * @since ' . $opts['since'] ] : [];
	$base  = basename( $path );
	$lines = explode( "\n", file_get_contents( $path ) );

	foreach ( $lines as $i => $l ) {
		if ( preg_match( '/^ \* (Class|Interface|Trait|Enum) (\w+)$/', $l, $m ) && isset( $names[ $m[2] ] ) ) {
			$lines[ $i ] = " * {$m[1]} {$names[ $m[2] ]}";
		}
	}

	for ( $i = 0; $i < count( $lines ); $i++ ) {
		$l = $lines[ $i ];
		$section = null;
		if ( preg_match( '/^(\t*)(?:(?:final|abstract|readonly)\s+)*(?:class|interface|trait|enum)\s+(\w+)/', $l, $cm ) ) {
			$section = 'classes';
		} elseif ( preg_match( '/^(\t+)(?:(?:public|protected|private|final)\s+)*const\s+(?:[\w\\\\?|]+\s+)?(\w+)\s*=/', $l, $cm ) ) {
			$section = 'consts';
		}
		if ( $section !== null && ( $i === 0 || trim( $lines[ $i - 1 ] ) !== '*/' ) && ! preg_match( '/^\s*#\[/', $lines[ $i - 1 ] ?? '' ) ) {
			$summary = lookup( $section, "$base::{$cm[2]}" );
			if ( $summary !== null ) {
				$block = array_merge( [ $cm[1] . '/**', $cm[1] . ' * ' . $summary ], array_map( fn( $s ) => $cm[1] . $s, $since ), [ $cm[1] . ' */' ] );
				array_splice( $lines, $i, 0, $block );
				$i += count( $block );
			}
			continue;
		}
		if ( preg_match( '/^(\t*)(?:(?:public|private|protected|static|abstract|final)\s+)*function\s+&?(\w+)\s*\(/', $l, $fm ) ) {
			$ind  = $fm[1];
			$func = $fm[2];
			$sig  = $l;
			$j    = $i;
			while ( substr_count( $sig, '(' ) > substr_count( $sig, ')' ) && $j < count( $lines ) - 1 ) {
				$sig .= "\n" . $lines[ ++$j ];
			}
			$sig_lines = $j - $i;
			// Find the parameter list's closing parenthesis.
			$open  = strpos( $sig, '(', strpos( $sig, 'function' ) );
			$depth = 0;
			$close = $open;
			for ( $k = $open; $k < strlen( $sig ); $k++ ) {
				$depth += $sig[ $k ] === '(' ? 1 : ( $sig[ $k ] === ')' ? -1 : 0 );
				if ( $depth === 0 ) {
					$close = $k;
					break;
				}
			}
			$params = parse_params( substr( $sig, $open + 1, $close - $open - 1 ) );
			$rtype  = preg_match( '/^\s*:\s*([?\w\\\\|]+)/', substr( $sig, $close + 1 ), $rm ) ? ptype( $rm[1] ) : null;

			$k = $i - 1;
			if ( $k < 0 || trim( $lines[ $k ] ) !== '*/' ) {
				$summary = lookup( 'summaries', "$base::$func" );
				if ( $summary === null ) {
					$block = [ $ind . '/**', $ind . ' * TODO', $ind . ' */' ];
				} else {
					$block = array_merge( [ $ind . '/**', $ind . ' * ' . $summary ], array_map( fn( $l ) => $ind . $l, $since ), [ $ind . ' */' ] );
				}
				array_splice( $lines, $i, 0, $block );
				$i += count( $block );
				$k  = $i - 1;
			}
			$start = block_start( $lines, $k );
			// A docblock that holds only annotations still needs a summary.
			if ( preg_match( '/^\*\s*@/', trim( $lines[ $start + 1 ] ?? '' ) ) ) {
				$summary = lookup( 'summaries', "$base::$func" );
				if ( $summary !== null && $summary !== '' ) {
					array_splice( $lines, $start + 1, 0, [ $ind . ' * ' . $summary, $ind . ' *' ] );
					$i += 2;
					$k += 2;
				}
			}
			$body  = implode( "\n", array_slice( $lines, $start, $k - $start + 1 ) );
			preg_match_all( '/@param\s+[^\n$]*?(\$\w+)/', $body, $hm );
			$tags = [];
			foreach ( $params as [ $type, $name, $default ] ) {
				if ( in_array( $name, $hm[1], true ) ) {
					continue;
				}
				$value = lookup( 'params', "$base::$func::$name", $type === null ? [ '', '' ] : [] );
				if ( $value === null ) {
					continue;
				}
				if ( is_array( $value ) ) {
					[ $type, $value ] = $value;
				} else {
					$type = ptype( (string) $type );
					if ( strtolower( $default ) === 'null' && strpos( $type, 'null' ) === false ) {
						$type .= '|null';
					}
				}
				$tags[] = [ '@param', $type, $name, $value ];
			}
			if ( ! $rtype && $func !== '__construct' && strpos( $body, '@return' ) === false ) {
				if ( returns_value( implode( "\n", array_slice( $lines, $i + $sig_lines ) ) ) ) {
					$GLOBALS['untyped'][] = "$base::$func";
				}
			}
			if ( $rtype && $rtype !== 'void' && $rtype !== 'never' && $func !== '__construct' && strpos( $body, '@return' ) === false ) {
				$value = lookup( 'returns', "$base::$func" );
				if ( $value !== null ) {
					$tags[] = [ '@return', $rtype, '', $value ];
				}
			}
			if ( $tags ) {
				$tw = 0;
				$nw = 0;
				foreach ( $tags as $t ) {
					if ( $t[0] === '@param' ) {
						$tw = max( $tw, strlen( $t[1] ) );
						$nw = max( $nw, strlen( $t[2] ) );
					}
				}
				$new = [];
				if ( ! preg_match( '/^\s*\*\s*@(?!since)/', $lines[ $k - 1 ] ) ) {
					$new[] = $ind . ' *';
				}
				foreach ( $tags as $t ) {
					$new[] = $t[0] === '@param'
						? sprintf( '%s * @param %s %s %s', $ind, str_pad( $t[1], $tw ), str_pad( $t[2], $nw ), $t[3] )
						: sprintf( '%s * @return %s %s', $ind, $t[1], $t[3] );
				}
				array_splice( $lines, $k, 0, $new );
				$i += count( $new );
			}
			$i += $sig_lines; // Promoted parameters are not property declarations.
		} elseif ( preg_match( '/^(\t+)(?:public|private|protected)(?:\s+static)?(?:\s+readonly)?(?:\s+([?\w\\\\|]+))?\s+(\$\w+)\s*[;=]/', $l, $pm ) ) {
			$ind   = $pm[1];
			$type  = $pm[2] !== '' ? ptype( $pm[2] ) : null;
			$name  = $pm[3];
			$k     = $i - 1;
			$has   = trim( $lines[ $k ] ) === '*/';
			$start = $has ? block_start( $lines, $k ) : $k;
			if ( $has && strpos( implode( "\n", array_slice( $lines, $start, $k - $start + 1 ) ), '@var' ) !== false ) {
				continue;
			}
			$value = null;
			if ( ! $has || $type === null ) {
				$value = lookup( 'props', "$base::$name", $type === null ? [ '', '' ] : [] );
				if ( $value === null ) {
					continue;
				}
				if ( is_array( $value ) ) {
					[ $type, $value ] = $value;
				}
			}
			if ( $has ) {
				array_splice( $lines, $k, 0, [ $ind . ' *', $ind . ' * @var ' . $type ] );
				$i += 2;
			} else {
				$block = array_merge( [ $ind . '/**', $ind . ' * ' . $value ], array_map( fn( $l ) => $ind . $l, $since ), [ $ind . ' *', $ind . ' * @var ' . $type, $ind . ' */' ] );
				if ( trim( $lines[ $k ] ) !== '' && substr( rtrim( $lines[ $k ] ), -1 ) !== '{' ) {
					array_unshift( $block, '' );
				}
				array_splice( $lines, $i, 0, $block );
				$i += count( $block );
			}
		}
	}

	$text = implode( "\n", $lines );
	// A first docblock counts as the file docblock unless a class follows it directly.
	$has_file_doc = preg_match( '/^<\?php\n\/\*\*(?:(?!\*\/).)*\*\/\n(?!\s*(?:(?:final|abstract|readonly)\s+)*(?:class|interface|trait|enum)\b)/s', $text );
	if ( $has_file_doc ) {
		if ( strpos( substr( $text, 0, strpos( $text, '*/' ) ), '@package' ) === false ) {
			$text = preg_replace( '/\n \*\//', "\n *\n * @package $package\n */", $text, 1 );
		}
	} else {
		$summary = lookup( 'files', $base );
		if ( $summary !== null ) {
			$tag  = empty( $GLOBALS['opts']['since'] ) ? '' : ' * @since ' . $GLOBALS['opts']['since'] . "\n";
				$text = preg_replace( '/^<\?php\n\n?/', "<?php\n/**\n * $summary\n *\n$tag * @package $package\n */\n\n", $text, 1 );
		}
	}
	return $text;
}

$results = [];
foreach ( $files as $f ) {
	$results[ $f ] = process( $f, $names, $opts['package'] ?? 'PACKAGE' );
}

$missing = array_filter( $need );
if ( $opts['list'] ) {
	echo json_encode( $need + [ 'untyped_returns' => $untyped ], JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES ), "\n";
	exit( 0 );
}
if ( $missing ) {
	fwrite( STDERR, "Nothing written. Missing descriptions:\n" . json_encode( $missing, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES ) . "\n" );
	exit( 1 );
}
$changed = 0;
foreach ( $results as $f => $text ) {
	if ( $text !== file_get_contents( $f ) ) {
		file_put_contents( $f, $text );
		$changed++;
	}
}
foreach ( $untyped as $name ) {
	echo "ADD @return: $name\n";
}
echo "Changed $changed of " . count( $results ) . " files.\n";
