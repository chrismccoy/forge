<?php
/**
 * Renames camelCase methods, properties and variables to snake_case, by tokens.
 *
 * Usage:
 *   php snake-case.php scan [--wp <wp-includes-dir>] <path>... > names.json
 *   php snake-case.php apply <methods|variables> [--dry-run] <names.json> <path>...
 *
 * Scan lists what the paths define and what needs a decision:
 *   methods, properties, variables  old => new maps; edit a value to change a name
 *   collisions                      two old names, or an old and an existing name, that map to one
 *   external_overlap                call sites of plugin method names that PHP or WordPress classes
 *                                   also define: add "file:line:name" to skip_sites for calls on
 *                                   objects the plugin doesn't own. Pass --wp, or core is not checked.
 *   string_hits                     strings equal to a method name; the apply step still renames those in callback arrays
 *   external_properties             camelCase properties the plugin reads but never declares; never renamed
 *   skip_methods, skip_properties, skip_variables  fill in to leave a name alone in every file.
 *                                   skip_properties also takes "Class::$name": that class keeps
 *                                   the declaration and its own $this->, self:: and static:: uses.
 *                                   Other "->name" uses still rename, and are printed as CHECK.
 *                                   skip_methods takes "Class::name" the same way. Use --dry-run
 *                                   to read the CHECK lines before anything is written.
 *   skip_sites                      leave one place alone: "file:line:name" for a method or property,
 *                                   "file:line:$name" for a variable or a property declaration
 *
 * Apply never touches names outside the maps. The "methods" step renames
 * definitions, calls, array callbacks and comments. The "variables" step renames
 * variables, property declarations and property access together, because a
 * promoted constructor parameter is both. A name in skip_properties keeps its
 * declaration too, and a skipped promoted parameter keeps its name across that
 * file. Needs PHP 8.1 or later.
 */

const KEEP_VARS = [ '$_GET', '$_POST', '$_SERVER', '$_COOKIE', '$_FILES', '$_REQUEST', '$_SESSION', '$_ENV', '$GLOBALS', '$this' ];

function snake( string $name ): string {
	$parts = preg_split( '/(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])/', $name );
	return strtolower( implode( '_', $parts ) );
}

function is_camel( string $name ): bool {
	return (bool) preg_match( '/^_?[a-z][a-z0-9]*[A-Z]/', $name );
}

function php_files( array $paths ): array {
	$out = [];
	foreach ( $paths as $p ) {
		if ( is_file( $p ) ) {
			$out[] = $p;
			continue;
		}
		foreach ( new RecursiveIteratorIterator( new RecursiveDirectoryIterator( $p, FilesystemIterator::SKIP_DOTS ) ) as $f ) {
			if ( $f->getExtension() === 'php' ) {
				$out[] = $f->getPathname();
			}
		}
	}
	sort( $out );
	return $out;
}

/** Significant-token neighbours of index $i. */
function prev_sig( array $t, int $i ) {
	for ( $j = $i - 1; $j >= 0; $j-- ) {
		if ( ! is_array( $t[ $j ] ) || ! in_array( $t[ $j ][0], [ T_WHITESPACE, T_COMMENT, T_DOC_COMMENT ], true ) ) {
			return $t[ $j ];
		}
	}
	return null;
}
function next_sig( array $t, int $i ) {
	for ( $j = $i + 1; $j < count( $t ); $j++ ) {
		if ( ! is_array( $t[ $j ] ) || ! in_array( $t[ $j ][0], [ T_WHITESPACE, T_COMMENT, T_DOC_COMMENT ], true ) ) {
			return $t[ $j ];
		}
	}
	return null;
}
function tid( $t ) {
	return is_array( $t ) ? $t[0] : $t;
}

function builtin_methods(): array {
	$out = [];
	foreach ( array_merge( get_declared_classes(), get_declared_interfaces() ) as $c ) {
		$r = new ReflectionClass( $c );
		if ( ! $r->isInternal() ) {
			continue;
		}
		foreach ( $r->getMethods() as $m ) {
			$out[ $m->getName() ][ $c ] = true;
		}
	}
	return $out;
}

/** camelCase method names defined under a WordPress wp-includes directory. */
function wp_methods( string $dir ): array {
	$out = [];
	foreach ( php_files( [ $dir ] ) as $f ) {
		if ( preg_match_all( '/function\s+&?([a-z]+[A-Z]\w*)\s*\(/', file_get_contents( $f ), $m ) ) {
			foreach ( $m[1] as $name ) {
				$out[ $name ][ str_replace( $dir, '', $f ) ] = true;
			}
		}
	}
	return $out;
}

function scan( array $paths, ?string $wp = null ): array {
	$files    = php_files( $paths );
	$methods  = [];
	$props    = [];
	$vars     = [];
	$existing = [];
	$calls    = [];
	$strings  = [];
	foreach ( $files as $f ) {
		$t = token_get_all( file_get_contents( $f ) );
		foreach ( $t as $i => $tok ) {
			if ( ! is_array( $tok ) ) {
				continue;
			}
			$p  = prev_sig( $t, $i );
			$n  = next_sig( $t, $i );
			if ( $tok[0] === T_STRING && tid( $p ) === T_FUNCTION ) {
				if ( is_camel( $tok[1] ) ) {
					$methods[ $tok[1] ] = snake( $tok[1] );
				} else {
					$existing[ $tok[1] ] = true;
				}
			}
			if ( $tok[0] === T_STRING && $n === '(' && in_array( tid( $p ), [ T_OBJECT_OPERATOR, T_NULLSAFE_OBJECT_OPERATOR, T_DOUBLE_COLON ], true ) ) {
				$before = prev_sig( $t, array_search( $p, array_slice( $t, 0, $i ), true ) ?: 0 );
				$calls[ $tok[1] ][] = [ "$f:{$tok[2]}:{$tok[1]}", is_array( $t[ $i - 2 ] ?? null ) ? $t[ $i - 2 ][1] : '' ];
			}
			if ( $tok[0] === T_VARIABLE && ! in_array( $tok[1], KEEP_VARS, true ) && is_camel( substr( $tok[1], 1 ) ) ) {
				$vars[ $tok[1] ] = '$' . snake( substr( $tok[1], 1 ) );
			}
			if ( $tok[0] === T_CONSTANT_ENCAPSED_STRING ) {
				$strings[ substr( $tok[1], 1, -1 ) ][] = "$f:{$tok[2]}";
			}
			if ( $tok[0] === T_STRING && in_array( tid( $p ), [ T_OBJECT_OPERATOR, T_NULLSAFE_OBJECT_OPERATOR ], true ) && $n !== '(' && is_camel( $tok[1] ) ) {
				$props[ $tok[1] ] = true;
			}
		}
	}
	// Same-file clashes: $fooBar and $foo_bar would merge into one variable.
	$clashes = [];
	foreach ( $files as $f ) {
		$seen = [];
		foreach ( token_get_all( file_get_contents( $f ) ) as $tok ) {
			if ( is_array( $tok ) && $tok[0] === T_VARIABLE ) {
				$seen[ $tok[1] ] = true;
			}
		}
		foreach ( $vars as $old => $new ) {
			if ( isset( $seen[ $old ], $seen[ $new ] ) ) {
				$clashes[] = "$f: $old and $new";
			}
		}
	}
	// A property counts as the plugin's own only if a variable of that name is declared.
	$declared = [];
	foreach ( $files as $f ) {
		$t     = token_get_all( file_get_contents( $f ) );
		$depth = 0;
		$class = null;
		foreach ( $t as $i => $tok ) {
			$text = is_array( $tok ) ? $tok[1] : $tok;
			if ( is_array( $tok ) && in_array( $tok[0], [ T_CLASS, T_TRAIT ], true ) && tid( prev_sig( $t, $i ) ) !== T_DOUBLE_COLON ) {
				$class = $depth;
			}
			if ( $text === '{' || tid( $tok ) === T_CURLY_OPEN || tid( $tok ) === T_DOLLAR_OPEN_CURLY_BRACES ) {
				$depth++;
			} elseif ( $text === '}' ) {
				$depth--;
			}
			if ( tid( $tok ) === T_VARIABLE ) {
				$p = prev_sig( $t, $i );
				// Skip a type, then look for a visibility or readonly keyword.
				$j = $i - 1;
				while ( $j > 0 && ( ( is_array( $t[ $j ] ) && in_array( $t[ $j ][0], [ T_WHITESPACE, T_STRING, T_NAME_QUALIFIED, T_NAME_FULLY_QUALIFIED, T_ARRAY, T_CALLABLE, T_STATIC ], true ) ) || in_array( $t[ $j ], [ '?', '|' ], true ) ) ) {
					$j--;
				}
				if ( is_array( $t[ $j ] ) && in_array( $t[ $j ][0], [ T_PUBLIC, T_PROTECTED, T_PRIVATE, T_VAR, T_READONLY ], true ) ) {
					$declared[ substr( $tok[1], 1 ) ] = true;
				}
			}
		}
	}
	$own   = [];
	$other = [];
	foreach ( array_keys( $props ) as $name ) {
		if ( isset( $declared[ $name ] ) ) {
			$own[ $name ] = snake( $name );
		} else {
			$other[] = $name;
		}
	}
	foreach ( array_keys( $declared ) as $name ) {
		if ( is_camel( $name ) ) {
			$own[ $name ] = snake( $name );
		}
	}

	$collisions = [];
	$seen       = [];
	foreach ( $methods as $old => $new ) {
		if ( isset( $existing[ $new ] ) ) {
			$collisions[] = "$old => $new, already defined";
		}
		if ( isset( $seen[ $new ] ) ) {
			$collisions[] = "$old and {$seen[ $new ]} both => $new";
		}
		$seen[ $new ] = $old;
	}

	$builtin  = builtin_methods();
	if ( $wp ) {
		foreach ( wp_methods( $wp ) as $name => $where ) {
			$builtin[ $name ] = ( $builtin[ $name ] ?? [] ) + $where;
		}
	}
	$overlap  = [];
	foreach ( $methods as $old => $new ) {
		if ( isset( $builtin[ $old ] ) ) {
			$sites = array_values( array_filter( $calls[ $old ] ?? [], fn( $c ) => ! in_array( $c[1], [ '$this', 'self', 'static', 'parent' ], true ) ) );
			$overlap[ $old ] = [
				'php_classes' => array_slice( array_keys( $builtin[ $old ] ), 0, 4 ),
				'sites'       => array_map( fn( $c ) => $c[0] . ' on ' . $c[1], $sites ),
			];
		}
	}
	$hits = [];
	foreach ( $methods as $old => $new ) {
		if ( isset( $strings[ $old ] ) ) {
			$hits[ $old ] = $strings[ $old ];
		}
	}
	ksort( $methods );
	ksort( $own );
	ksort( $vars );
	return [
		'methods'             => $methods,
		'properties'          => $own,
		'variables'           => $vars,
		'collisions'          => array_merge( $collisions, $clashes ),
		'external_overlap'    => $overlap,
		'string_hits'         => $hits,
		'external_properties' => $other,
		'skip_methods'        => [],
		'skip_properties'     => [],
		'skip_variables'      => [],
		'skip_sites'          => [],
	];
}

/** True when the variable at $i declares a property or a promoted constructor parameter. */
function is_declaration( array $t, int $i ): bool {
	$j = $i - 1;
	while ( $j > 0 && ( ( is_array( $t[ $j ] ) && in_array( $t[ $j ][0], [ T_WHITESPACE, T_STRING, T_NAME_QUALIFIED, T_NAME_FULLY_QUALIFIED, T_ARRAY, T_CALLABLE, T_STATIC ], true ) ) || in_array( $t[ $j ], [ '?', '|' ], true ) ) ) {
		$j--;
	}
	return is_array( $t[ $j ] ) && in_array( $t[ $j ][0], [ T_PUBLIC, T_PROTECTED, T_PRIVATE, T_VAR, T_READONLY ], true );
}

/** Maps each token index inside a class, trait or enum body to that class's name. */
function class_owners( array $t ): array {
	$owners = [];
	$depth  = 0;
	$name   = null;
	$start  = null;
	foreach ( $t as $i => $tok ) {
		$text = is_array( $tok ) ? $tok[1] : $tok;
		if ( $name === null && in_array( tid( $tok ), [ T_CLASS, T_TRAIT, T_ENUM ], true ) && tid( prev_sig( $t, $i ) ) !== T_DOUBLE_COLON ) {
			$next = next_sig( $t, $i );
			if ( tid( $next ) === T_STRING ) {
				$name  = $next[1];
				$start = $depth;
			}
		}
		if ( $text === '{' || tid( $tok ) === T_CURLY_OPEN || tid( $tok ) === T_DOLLAR_OPEN_CURLY_BRACES ) {
			$depth++;
		} elseif ( $text === '}' ) {
			$depth--;
			if ( $name !== null && $depth === $start ) {
				$name = null;
			}
		}
		if ( $name !== null ) {
			$owners[ $i ] = $name;
		}
	}
	return $owners;
}

/** True when the property name at $i is read as $this->name. */
function is_on_this( array $t, int $i ): bool {
	$k = $i - 1;
	while ( $k > 0 && tid( $t[ $k ] ) === T_WHITESPACE ) {
		$k--;
	}
	$k--;
	while ( $k > 0 && tid( $t[ $k ] ) === T_WHITESPACE ) {
		$k--;
	}
	return is_array( $t[ $k ] ) && $t[ $k ][1] === '$this';
}

function apply_step( string $step, array $n, array $paths, bool $dry = false ): void {
	$kept_methods = array_flip( $n['skip_methods'] );
	$methods = array_diff_key( $n['methods'], array_flip( $n['skip_methods'] ) );
	$props   = array_diff_key( $n['properties'], array_flip( $n['skip_properties'] ) );
	$vars    = array_diff_key( $n['variables'], array_flip( $n['skip_variables'] ) );
	$skip    = array_flip( $n['skip_sites'] );
	foreach ( php_files( $paths ) as $f ) {
		$t   = token_get_all( file_get_contents( $f ) );
		$out = '';
		// A skipped promoted parameter is also a variable in its constructor.
		$kept   = array_flip( $n['skip_properties'] );
		$local  = $vars;
		$paren  = 0;
		$owner  = class_owners( $t );
		$scoped = function ( int $i, string $bare ) use ( $kept, &$owner ): bool {
			return isset( $owner[ $i ] ) && isset( $kept[ $owner[ $i ] . '::$' . $bare ] );
		};
		foreach ( $t as $i => $tok ) {
			$paren += ( $tok === '(' ? 1 : 0 ) - ( $tok === ')' ? 1 : 0 );
			if ( $paren > 0 && tid( $tok ) === T_VARIABLE && is_declaration( $t, $i ) ) {
				$bare = substr( $tok[1], 1 );
				if ( isset( $kept[ $bare ] ) || $scoped( $i, $bare ) ) {
					unset( $local[ $tok[1] ] );
				}
			}
		}
		foreach ( $t as $i => $tok ) {
			if ( ! is_array( $tok ) ) {
				$out .= $tok;
				continue;
			}
			[ $id, $text, $line ] = $tok;
			$p = prev_sig( $t, $i );
			$x = next_sig( $t, $i );
			$pid = tid( $p );
			if ( $step === 'methods' ) {
				if ( $id === T_STRING && isset( $methods[ $text ] ) && ! isset( $skip[ "$f:$line:$text" ] ) ) {
					$call = $x === '(' && in_array( $pid, [ T_OBJECT_OPERATOR, T_NULLSAFE_OBJECT_OPERATOR, T_DOUBLE_COLON ], true );
					$in_class = isset( $owner[ $i ] ) && isset( $kept_methods[ $owner[ $i ] . '::' . $text ] );
					$own_call = $pid === T_FUNCTION || is_on_this( $t, $i ) || ( $pid === T_DOUBLE_COLON && in_array( strtolower( (string) ( prev_sig( $t, $i - 1 )[1] ?? '' ) ), [ 'self', 'static' ], true ) );
					if ( ( $pid === T_FUNCTION || $call ) && ! ( $in_class && $own_call ) ) {
						if ( $call && ! $own_call && preg_grep( '/::' . preg_quote( $text, '/' ) . '$/', $n['skip_methods'] ) ) {
							echo "CHECK: $f:$line: ->$text() renamed; keep it if the object is the skipped class\n";
						}
						$text = $methods[ $text ];
					}
				} elseif ( $id === T_CONSTANT_ENCAPSED_STRING && isset( $methods[ substr( $text, 1, -1 ) ] ) && ! isset( $skip[ "$f:$line:" . substr( $text, 1, -1 ) ] ) ) {
					// [ $this, 'x' ], [ self::class, 'x' ], [ Foo::class, 'x' ].
					$before = $pid === ',' ? prev_sig( $t, array_search( $p, array_slice( $t, 0, $i, true ), true ) ) : null;
					$is_cb  = $pid === ',' && $x === ']' || $pid === ',' && $x === ')';
					if ( $is_cb ) {
						$text = $text[0] . $methods[ substr( $text, 1, -1 ) ] . $text[0];
					}
				} elseif ( $id === T_COMMENT || $id === T_DOC_COMMENT ) {
					$text = preg_replace_callback(
						'/(?<![\w$])([a-z_][A-Za-z0-9_]*)(?=\()/',
						fn( $m ) => $methods[ $m[1] ] ?? $m[1],
						$text
					);
				}
			} else {
				if ( $id === T_VARIABLE && ! isset( $skip[ "$f:$line:$text" ] ) ) {
					$bare = substr( $text, 1 );
					if ( $pid === T_DOUBLE_COLON ) {
						$text = isset( $props[ $bare ] ) && ! $scoped( $i, $bare ) ? '$' . $props[ $bare ] : $text;
					} elseif ( ! ( is_declaration( $t, $i ) && ( isset( $kept[ $bare ] ) || $scoped( $i, $bare ) ) ) ) {
						$text = $local[ $text ] ?? $text;
					}
				} elseif ( $id === T_STRING && isset( $props[ $text ] ) && $x !== '(' && in_array( $pid, [ T_OBJECT_OPERATOR, T_NULLSAFE_OBJECT_OPERATOR ], true ) && ! isset( $skip[ "$f:$line:$text" ] ) ) {
					$on_this = is_on_this( $t, $i );
					if ( ! ( $on_this && $scoped( $i, $text ) ) ) {
						if ( ! $on_this && in_array( '$' . $text, array_map( fn( $k ) => strstr( (string) $k, '$' ), $n['skip_properties'] ), true ) ) {
							echo "CHECK: $f:$line: ->$text renamed; keep it if the object is the skipped class\n";
						}
						$text = $props[ $text ];
					}
				} elseif ( $id === T_STRING && isset( $vars[ '$' . $text ] ) && $x === ':' && in_array( $pid, [ '(', ',' ], true ) ) {
					$text = substr( $vars[ '$' . $text ], 1 ); // Named argument.
				} elseif ( $id === T_COMMENT || $id === T_DOC_COMMENT ) {
					$text = preg_replace_callback( '/\$[a-zA-Z_][A-Za-z0-9_]*/', fn( $m ) => $local[ $m[0] ] ?? $m[0], $text );
				}
			}
			$out .= $text;
		}
		if ( ! $dry ) {
			file_put_contents( $f, $out );
		}
	}
}

$cmd = $argv[1] ?? '';
if ( $cmd === 'scan' && $argc > 2 ) {
	$rest = array_slice( $argv, 2 );
	$wp   = null;
	if ( $rest[0] === '--wp' ) {
		$wp   = $rest[1];
		if ( ! is_dir( $wp ) ) {
			fwrite( STDERR, "--wp needs the wp-includes folder: $wp\n" );
			exit( 1 );
		}
		$rest = array_slice( $rest, 2 );
	}
	echo json_encode( scan( $rest, $wp ), JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES ), "\n";
} elseif ( $cmd === 'apply' && $argc > 4 ) {
	$rest = array_slice( $argv, 3 );
	$dry  = $rest[0] === '--dry-run';
	$rest = $dry ? array_slice( $rest, 1 ) : $rest;
	apply_step( $argv[2], json_decode( file_get_contents( $rest[0] ), true ), array_slice( $rest, 1 ), $dry );
	echo ( $dry ? 'dry run ' : 'applied ' ) . "{$argv[2]}\n";
} else {
	fwrite( STDERR, "Usage: php snake-case.php scan [--wp <wp-includes-dir>] <path>... | apply <methods|variables> <names.json> <path>...\n" );
	exit( 1 );
}
