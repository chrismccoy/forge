<?php
/**
 * Removes namespaces by tokens: drops `namespace` and import `use` statements, and
 * rewrites every class reference through an old-to-new map.
 *
 * Usage: php flatten.php [--keep-namespaces] [--functions <function-map>] <map-file> <file>...
 * Needs PHP 8.1 or later.
 * Map lines: "Old\Namespace\Class New_Class includes/class-new-class.php".
 *
 * With --keep-namespaces, the second column is the new full name, for example
 * "Old\Admin\ImportPage Old\Admin\Import_Page includes/admin/class-import-page.php".
 * `namespace` lines stay, imports are rewritten one per line, and an explicit alias stays.
 *
 * Rewrites code only, not strings, comments or the autoloader: grep for leftovers
 * afterwards. --functions takes lines "Old\Namespace\func new_func": it renames global
 * function definitions and calls, unqualified, imported or qualified, and never a method of
 * the same name. A `use function` outside that map, and any `use const`, is removed and
 * reported: rename its uses by hand. With --keep-namespaces, functions are left alone.
 * Imported classes outside the map stay reachable: `use Vendor\Lib\Thing` turns
 * `Thing` into `\Vendor\Lib\Thing`, and an aliased global class gets its real name.
 */

$args = array_slice( $argv, 1 );
$keep = in_array( '--keep-namespaces', $args, true );
$args = array_values( array_diff( $args, [ '--keep-namespaces' ] ) );
$fmap = [];
$fpos = array_search( '--functions', $args, true );
if ( $fpos !== false ) {
	foreach ( file( $args[ $fpos + 1 ], FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES ) as $line ) {
		$cols                            = preg_split( '/\s+/', trim( $line ) );
		$fmap[ strtolower( ltrim( $cols[0], '\\' ) ) ] = $cols[1];
	}
	array_splice( $args, $fpos, 2 );
}
if ( count( $args ) < 2 ) {
	fwrite( STDERR, "Usage: php flatten.php [--keep-namespaces] [--functions <function-map>] <map-file> <file>...\n" );
	exit( 1 );
}
$map = [];
foreach ( file( $args[0], FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES ) as $line ) {
	$cols                       = preg_split( '/\s+/', trim( $line ) );
	$map[ strtolower( $cols[0] ) ] = $cols[1];
}

/** Parses the text of a `use` statement into [ lowercase alias => [ alias, full name ] ]. */
function parse_use( string $text ): array {
	$out = [];
	if ( preg_match( '/^(.*?)\\\\?\{(.*)\}$/s', $text, $g ) ) {
		$items = array_map( fn( $p ) => $g[1] . '\\' . trim( $p ), array_filter( array_map( 'trim', explode( ',', $g[2] ) ) ) );
	} else {
		$items = array_map( 'trim', explode( ',', $text ) );
	}
	foreach ( $items as $item ) {
		$bits  = preg_split( '/\s+as\s+/i', $item );
		$full  = ltrim( $bits[0], '\\' );
		$segs  = explode( '\\', $full );
		$alias = $bits[1] ?? end( $segs );
		$out[ strtolower( $alias ) ] = [ $alias, $full ];
	}
	return $out;
}

/** Text of the statement starting after token $i, up to its ';'. Returns [ text, index of ';' ]. */
function statement( array $toks, int $i ): array {
	$text = '';
	for ( $j = $i + 1; $j < count( $toks ) && $toks[ $j ] !== ';'; $j++ ) {
		$text .= is_array( $toks[ $j ] ) ? $toks[ $j ][1] : $toks[ $j ];
	}
	return [ trim( $text ), $j ];
}

/** Whether the T_NAMESPACE at $i starts a statement: `const NAMESPACE = ...` lexes the same way. */
function is_namespace_statement( array $toks, int $i ): bool {
	for ( $j = $i + 1; $j < count( $toks ); $j++ ) {
		if ( is_array( $toks[ $j ] ) && in_array( $toks[ $j ][0], [ T_WHITESPACE, T_COMMENT, T_DOC_COMMENT ], true ) ) {
			continue;
		}
		return is_array( $toks[ $j ] ) ? in_array( $toks[ $j ][0], [ T_STRING, T_NAME_QUALIFIED ], true ) : $toks[ $j ] === '{';
	}
	return false;
}

/** Whether the T_USE at $i is an import, not a closure `use` or a trait `use`. */
function is_import( array $toks, int $i, int $depth ): bool {
	if ( $depth !== 0 ) {
		return false;
	}
	for ( $j = $i - 1; $j >= 0; $j-- ) {
		if ( is_array( $toks[ $j ] ) && in_array( $toks[ $j ][0], [ T_WHITESPACE, T_COMMENT, T_DOC_COMMENT ], true ) ) {
			continue;
		}
		return $toks[ $j ] !== ')';
	}
	return true;
}

foreach ( array_slice( $args, 1 ) as $f ) {
	$toks    = token_get_all( file_get_contents( $f ) );
	$n       = count( $toks );
	$ns      = '';
	$imports = [];
	$fimports = [];
	$depth   = 0;

	// First pass: namespace and imports.
	for ( $i = 0; $i < $n; $i++ ) {
		$t    = $toks[ $i ];
		$id   = is_array( $t ) ? $t[0] : null;
		$text = is_array( $t ) ? $t[1] : $t;
		if ( $text === '{' || $id === T_CURLY_OPEN || $id === T_DOLLAR_OPEN_CURLY_BRACES ) {
			$depth++;
		} elseif ( $text === '}' ) {
			$depth--;
		}
		if ( $id === T_NAMESPACE && is_namespace_statement( $toks, $i ) ) {
			[ $stmt ] = statement( $toks, $i );
			if ( strpos( $stmt, '{' ) !== false ) {
				fwrite( STDERR, "$f: bracketed namespace, flatten by hand\n" );
				continue 2;
			}
			$ns = $stmt;
		}
		if ( $id === T_USE && is_import( $toks, $i, $depth ) ) {
			[ $stmt ] = statement( $toks, $i );
			if ( preg_match( '/^function\s+(.*)$/is', $stmt, $fm ) && $fmap ) {
				$known = true;
				foreach ( parse_use( $fm[1] ) as $key => [ $alias, $full ] ) {
					$fimports[ strtolower( $alias ) ] = strtolower( ltrim( $full, '\\' ) );
					$known = $known && isset( $fmap[ strtolower( ltrim( $full, '\\' ) ) ] );
				}
				if ( $known ) {
					continue;
				}
			}
			if ( preg_match( '/^(function|const)\s/i', $stmt ) ) {
				fwrite( STDERR, "$f:{$t[2]}: `use $stmt` removed: rename every use of it by hand, or the calls point at nothing\n" );
				continue;
			}
			$imports += parse_use( $stmt );
		}
	}

	$rewrite = function ( string $full, bool $imported ) use ( $map ): ?string {
		$key = strtolower( ltrim( $full, '\\' ) );
		if ( isset( $map[ $key ] ) ) {
			return $map[ $key ];
		}
		if ( $imported ) {
			return strpos( $key, '\\' ) === false ? ltrim( $full, '\\' ) : '\\' . ltrim( $full, '\\' );
		}
		return null;
	};

	// Second pass: rebuild the file.
	$out    = '';
	$depth  = 0;
	$prev   = null;
	$cdepth = null;
	$fname  = function ( string $name ) use ( $fmap, &$fimports, $ns ): ?string {
		$key = strtolower( $name );
		$key = $fimports[ $key ] ?? strtolower( ltrim( $ns . '\\' . $name, '\\' ) );
		return $fmap[ $key ] ?? null;
	};
	for ( $i = 0; $i < $n; $i++ ) {
		$t    = $toks[ $i ];
		$id   = is_array( $t ) ? $t[0] : null;
		$text = is_array( $t ) ? $t[1] : $t;
		if ( $text === '{' || $id === T_CURLY_OPEN || $id === T_DOLLAR_OPEN_CURLY_BRACES ) {
			$depth++;
		} elseif ( $text === '}' ) {
			$depth--;
			if ( $cdepth !== null && $depth === $cdepth ) {
				$cdepth = null;
			}
		}
		$before = is_array( $prev ) ? $prev[0] : $prev;
		if ( $cdepth === null && in_array( $id, [ T_CLASS, T_INTERFACE, T_TRAIT, T_ENUM ], true ) && $before !== T_DOUBLE_COLON ) {
			$cdepth = $depth;
		}
		$is_ns = $id === T_NAMESPACE && is_namespace_statement( $toks, $i );
		if ( $keep && $is_ns ) {
			[ , $end ] = statement( $toks, $i );
			for ( ; $i <= $end; $i++ ) {
				$out .= is_array( $toks[ $i ] ) ? $toks[ $i ][1] : $toks[ $i ];
			}
			$i--;
			continue;
		}
		if ( $keep && $id === T_USE && is_import( $toks, $i, $depth ) ) {
			[ $stmt, $end ] = statement( $toks, $i );
			if ( preg_match( '/^(function|const)\s/i', $stmt ) ) {
				$out .= "use $stmt;";
			} else {
				$lines = [];
				foreach ( parse_use( $stmt ) as [ $alias, $full ] ) {
					$segs    = explode( '\\', $full );
					$target  = $map[ strtolower( $full ) ] ?? $full;
					$lines[] = 'use ' . $target . ( $alias !== end( $segs ) ? " as $alias" : '' ) . ';';
				}
				$out .= implode( "\n", $lines );
			}
			$i = $end;
			continue;
		}
		if ( $is_ns || ( $id === T_USE && is_import( $toks, $i, $depth ) ) ) {
			[ , $i ] = statement( $toks, $i );
			if ( is_array( $toks[ $i + 1 ] ?? null ) && $toks[ $i + 1 ][0] === T_WHITESPACE ) {
				$toks[ $i + 1 ][1] = preg_replace( '/^\r?\n/', '', $toks[ $i + 1 ][1] );
			}
			$out = preg_replace( '/\n\n$/', "\n", $out );
			continue;
		}
		$new = null;
		if ( ! $keep && $fmap && in_array( $id, [ T_NAME_QUALIFIED, T_NAME_FULLY_QUALIFIED, T_NAME_RELATIVE ], true ) && ( $toks[ $i + 1 ] ?? null ) === '(' && $before !== T_NEW ) {
			$bare = preg_replace( '/^namespace\\\\/i', '', $text );
			$new  = $fmap[ strtolower( ltrim( $text, '\\' ) ) ] ?? $fmap[ strtolower( ltrim( $ns . '\\' . $bare, '\\' ) ) ] ?? null;
			if ( $new !== null ) {
				$out .= $new;
				$prev = $t;
				continue;
			}
		}
		if ( $id === T_DOC_COMMENT ) {
			// Types in tags follow the same rules as code.
			$new = preg_replace_callback(
				'/(@(?:param|return|var|throws|see|uses|extends|implements|template-extends|template-implements|property(?:-read|-write)?)\s+)((?:[^\s<]+(?:<[^>\n]*>+)?)+)/',
				function ( $m ) use ( $imports, $ns, $map, $keep ) {
					$type = preg_replace_callback(
						'/\\\\?[A-Za-z_][\\\\\w]*/',
						function ( $n ) use ( $imports, $ns, $map, $keep ) {
							$name = ltrim( $n[0], '\\' );
							$segs = explode( '\\', $name );
							$first = strtolower( $segs[0] );
							if ( $n[0][0] === '\\' ) {
								$full = $name;
							} elseif ( isset( $imports[ $first ] ) ) {
								$full = $imports[ $first ][1] . ( count( $segs ) > 1 ? '\\' . implode( '\\', array_slice( $segs, 1 ) ) : '' );
							} else {
								$full = $ns . '\\' . $name;
							}
							$target = $map[ strtolower( $full ) ] ?? null;
							if ( $target === null ) {
								return $n[0];
							}
							$parts = explode( '\\', $target );
							return $keep ? end( $parts ) : $target;
						},
						$m[2]
					);
					return $m[1] . $type;
				},
				$text
			);
		} elseif ( $id === T_NAME_FULLY_QUALIFIED ) {
			$new = $rewrite( $text, false ) ?? ( ! $keep && substr_count( $text, '\\' ) === 1 ? ltrim( $text, '\\' ) : null );
		} elseif ( $id === T_NAME_RELATIVE ) {
			$new = $rewrite( $ns . '\\' . preg_replace( '/^namespace\\\\/i', '', $text ), false );
		} elseif ( $id === T_NAME_QUALIFIED ) {
			$segs  = explode( '\\', $text );
			$first = strtolower( $segs[0] );
			$new   = isset( $imports[ $first ] )
				? $rewrite( $imports[ $first ][1] . '\\' . implode( '\\', array_slice( $segs, 1 ) ), true )
				: ( $rewrite( $ns . '\\' . $text, false ) ?? $rewrite( $text, false ) );
		} elseif ( $id === T_STRING ) {
			$pid  = is_array( $prev ) ? $prev[0] : $prev;
			$next = null;
			for ( $j = $i + 1; $j < $n; $j++ ) {
				if ( ! is_array( $toks[ $j ] ) || ! in_array( $toks[ $j ][0], [ T_WHITESPACE, T_COMMENT, T_DOC_COMMENT ], true ) ) {
					$next = $toks[ $j ];
					break;
				}
			}
			$member = in_array( $pid, [ T_OBJECT_OPERATOR, T_NULLSAFE_OBJECT_OPERATOR, T_DOUBLE_COLON, T_FUNCTION, T_CONST ], true );
			$call   = $next === '(' && $pid !== T_NEW;
			if ( ! $keep && $fmap ) {
				$is_def = $pid === T_FUNCTION && $cdepth === null;
				if ( $is_def || ( $call && ! $member ) ) {
					$new = $fname( $text );
				}
			}
			if ( ! $member && ! $call ) {
				$key = strtolower( $text );
				if ( isset( $imports[ $key ] ) && $imports[ $key ][0] === $text ) {
					$new = $rewrite( $imports[ $key ][1], true );
				} elseif ( $ns !== '' && isset( $map[ strtolower( $ns . '\\' . $text ) ] ) ) {
					// Exact declared spelling only: the map is lowercase, and a constant
					// CRYPTO must not match a class Crypto.
					$declared = array_filter( array_keys( $map ), fn( $k ) => $k === strtolower( $ns . '\\' . $text ) );
					$new      = ( ctype_upper( $text ) && strlen( $text ) > 1 ) ? null : $map[ reset( $declared ) ];
				}
			}
		}
		if ( $keep && $new !== null ) {
			if ( $id === T_STRING ) {
				// Unqualified reference: the import or the namespace still resolves it.
				$key   = strtolower( $text );
				$segs  = explode( '\\', isset( $imports[ $key ] ) ? $imports[ $key ][1] : $text );
				$alias = end( $segs ) !== $text;
				$nsegs = explode( '\\', $new );
				$new   = $alias ? null : end( $nsegs );
			} elseif ( isset( $map[ strtolower( ltrim( $new, '\\' ) ) ] ) || strpos( $new, '\\' ) !== false ) {
				$new = $id === T_NAME_QUALIFIED || $id === T_NAME_RELATIVE || $id === T_NAME_FULLY_QUALIFIED ? '\\' . ltrim( $new, '\\' ) : $new;
			}
			if ( $id === T_STRING && isset( $imports[ strtolower( $text ) ] ) && ! isset( $map[ strtolower( $imports[ strtolower( $text ) ][1] ) ] ) ) {
				$new = null;
			}
		}
		$out .= $new ?? $text;
		if ( $id !== T_WHITESPACE && $id !== T_COMMENT && $id !== T_DOC_COMMENT ) {
			$prev = $t;
		}
	}
	$same = $out === file_get_contents( $f );
	file_put_contents( $f, $out );
	echo ( $same ? 'unchanged ' : 'flattened ' ) . "$f\n";
}
