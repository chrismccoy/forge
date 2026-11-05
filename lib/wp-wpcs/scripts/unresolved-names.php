<?php
/**
 * Lists class names that resolve to nothing in namespaced code.
 *
 * In a namespace, an unqualified name with no `use` means <namespace>\Name. If no
 * such class exists, `catch` and `instanceof` silently never match. Once the
 * namespace is removed, the same name reaches the global class and starts matching.
 *
 * Usage: php unresolved-names.php <dir-or-file>...   Needs PHP 8.1 or later.
 * Pass every path that declares plugin classes. Exit code 1 when anything is listed.
 */

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
	return $out;
}

$files    = php_files( array_slice( $argv, 1 ) );
$declared = [];
foreach ( $files as $f ) {
	$src = file_get_contents( $f );
	$ns  = preg_match( '/^namespace\s+([^;{\s]+)/m', $src, $m ) ? $m[1] . '\\' : '';
	preg_match_all( '/^\s*(?:(?:final|abstract|readonly)\s+)*(?:class|interface|trait|enum)\s+(\w+)/m', $src, $m );
	foreach ( $m[1] as $c ) {
		$declared[ strtolower( $ns . $c ) ] = true;
	}
}

$builtin = [ 'self', 'static', 'parent', 'string', 'int', 'bool', 'float', 'array', 'void', 'mixed', 'callable', 'iterable', 'object', 'null', 'false', 'true', 'never' ];
$found   = 0;
foreach ( $files as $f ) {
	$src = file_get_contents( $f );
	if ( ! preg_match( '/^namespace\s+([^;{\s]+)/m', $src, $m ) ) {
		continue;
	}
	$ns   = $m[1];
	$uses = [];
	preg_match_all( '/^use\s+(?!function\b|const\b)([^;]+);/m', $src, $m );
	foreach ( $m[1] as $u ) {
		if ( preg_match( '/^(.*)\{(.*)\}$/s', trim( $u ), $g ) ) {
			$parts = explode( ',', $g[2] );
		} else {
			$parts = explode( ',', $u );
		}
		foreach ( $parts as $part ) {
			$bits = preg_split( '/\s+as\s+/i', trim( $part ) );
			$segs = explode( '\\', $bits[0] );
			$uses[ strtolower( $bits[1] ?? end( $segs ) ) ] = true;
		}
	}
	$toks = array_values( array_filter( token_get_all( $src ), fn( $x ) => ! is_array( $x ) || ! in_array( $x[0], [ T_WHITESPACE, T_COMMENT, T_DOC_COMMENT ], true ) ) );
	$id   = fn( $t ) => is_array( $t ) ? $t[0] : $t;
	$n    = count( $toks );
	for ( $i = 1; $i < $n; $i++ ) {
		$t = $toks[ $i ];
		if ( ! is_array( $t ) || $t[0] !== T_STRING ) {
			continue;
		}
		$prev  = $id( $toks[ $i - 1 ] );
		$prev2 = $id( $toks[ $i - 2 ] ?? '' );
		$next  = $id( $toks[ $i + 1 ] ?? '' );
		if ( in_array( $prev, [ T_OBJECT_OPERATOR, T_NULLSAFE_OBJECT_OPERATOR, T_DOUBLE_COLON, T_FUNCTION, T_CONST ], true ) ) {
			continue;
		}
		$is_class = in_array( $prev, [ T_NEW, T_INSTANCEOF, T_EXTENDS, T_IMPLEMENTS ], true )
			|| ( $prev === '(' && $prev2 === T_CATCH )
			|| $next === T_DOUBLE_COLON
			|| $next === T_VARIABLE
			|| ( ( $next === '|' || $prev === '|' ) && ! preg_match( '/^[A-Z0-9_]+$/', $t[1] ) ) // Not FLAG_A | FLAG_B.
			|| ( $prev === ':' && $prev2 === ')' )
			|| ( $prev === '?' && $prev2 === ':' );
		if ( ! $is_class || $next === '(' && $prev !== T_NEW ) { // A function call, not a class.
			continue;
		}
		$name = $t[1];
		if ( in_array( strtolower( $name ), $builtin, true ) || isset( $uses[ strtolower( $name ) ] ) || isset( $declared[ strtolower( "$ns\\$name" ) ] ) ) {
			continue;
		}
		echo "$f:{$t[2]}: '$name' resolves to $ns\\$name, which does not exist\n";
		$found = 1;
	}
}
if ( ! $found ) {
	echo "none found\n";
}
exit( $found );
