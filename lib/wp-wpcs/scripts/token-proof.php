<?php
/**
 * Token-stream proof: shows that a change altered layout or comments only.
 *
 * Run from the plugin root (a git repository). Needs PHP 8.1 or later.
 * Usage: php token-proof.php <git-ref> [--strip-comments] [--drop-declare] [file...]
 *
 * Compares each PHP file at <git-ref> with the working tree, after normalizing
 * the differences listed in references/phase-2-tier-a.md. With no files, it
 * checks every PHP file that differs from <git-ref>.
 *
 *   --strip-comments  ignore comment text (Phase 5, Phase 7)
 *   --drop-declare    remove declare(strict_types=1) from the old version (Phase 7)
 *
 * Test annotations and phpcs: directives are always compared. Exit code 0 means
 * every file matched. COMMENT-ONLY lines are allowed differences, to review by hand.
 */

$ref   = $argv[1] ?? 'HEAD';
$strip = in_array( '--strip-comments', $argv, true );
$dropd = in_array( '--drop-declare', $argv, true );
$files = array_values( array_filter( array_slice( $argv, 2 ), fn( $a ) => $a[0] !== '-' ) );
if ( ! $files ) {
	$files = array_filter( explode( "\n", trim( shell_exec( 'git diff --name-only ' . escapeshellarg( $ref ) . ' -- "*.php"' ) ) ) );
}

const ANNOT = '/@(runInSeparateProcess|runTestsInSeparateProcesses|preserveGlobalState|backupGlobals|dataProvider|depends|group|covers|requires|ticket|expectedDeprecated|expectedIncorrectUsage)\b[^\n*]*/';
const MODS  = [ 'public', 'protected', 'private', 'static', 'abstract', 'final', 'readonly' ];
const LOWER = [ 'true', 'false', 'null', 'int', 'string', 'bool', 'float', 'array', 'void', 'self', 'parent', 'mixed', 'iterable', 'object', 'callable', 'static', 'never' ];

function decode_string( string $s ): string {
	if ( $s[0] === "'" ) {
		return str_replace( [ "\\'", '\\\\' ], [ "'", '\\' ], substr( $s, 1, -1 ) );
	}
	return stripcslashes( substr( $s, 1, -1 ) );
}

/** @return array{0: string[], 1: string[], 2: string[]} code items, comment texts, annotations/directives */
function normalize( string $src ): array {
	$toks   = token_get_all( $src );
	$out    = [];
	$cmt    = [];
	$ann    = [];
	$stack  = [];
	$pend   = false;
	$exact  = 0; // depth inside <pre>/<textarea>/<script> inline HTML
	$n      = count( $toks );
	for ( $i = 0; $i < $n; $i++ ) {
		$t    = $toks[ $i ];
		$id   = is_array( $t ) ? $t[0] : null;
		$text = is_array( $t ) ? $t[1] : $t;

		if ( $id === T_WHITESPACE ) {
			continue;
		}
		if ( $id === T_COMMENT || $id === T_DOC_COMMENT ) {
			if ( preg_match_all( ANNOT, $text, $m ) ) {
				foreach ( $m[0] as $a ) {
					$ann[] = trim( $a );
				}
			}
			if ( preg_match_all( '/phpcs:[^\n*]*/', $text, $m ) ) {
				foreach ( $m[0] as $a ) {
					$ann[] = trim( $a );
				}
			}
			if ( ! $GLOBALS['strip'] ) {
				$cmt[] = rtrim( preg_replace( '/\s+/', ' ', trim( $text ) ), '.' );
			}
			continue;
		}
		if ( $id === T_INLINE_HTML ) {
			// Collapse whitespace, except inside <pre>, <textarea> and <script>.
			$html = '';
			foreach ( preg_split( '#(</?(?:pre|textarea|script)\b[^>]*>)#i', $text, -1, PREG_SPLIT_DELIM_CAPTURE ) as $k => $part ) {
				if ( $k % 2 ) {
					$exact += $part[1] === '/' ? -1 : 1;
					$html  .= preg_replace( '/\s+/', ' ', $part );
				} else {
					$html .= $exact > 0 ? $part : trim( preg_replace( '/\s+/', ' ', $part ) );
				}
			}
			$out[] = 'HTML:' . $html;
			continue;
		}
		if ( $id === T_OPEN_TAG || $id === T_OPEN_TAG_WITH_ECHO ) {
			$out[] = rtrim( $text );
			continue;
		}
		if ( $id === T_CLOSE_TAG ) {
			if ( end( $out ) === ';' ) {
				array_pop( $out );
			}
			$out[] = '?>';
			continue;
		}
		if ( $id === T_CONSTANT_ENCAPSED_STRING ) {
			$out[] = 'S:' . decode_string( $text );
			continue;
		}
		if ( in_array( $id, [ T_INT_CAST, T_DOUBLE_CAST, T_STRING_CAST, T_ARRAY_CAST, T_OBJECT_CAST, T_BOOL_CAST, T_UNSET_CAST ], true ) ) {
			$out[] = token_name( $id );
			continue;
		}
		if ( $id === T_ARRAY || $id === T_LIST ) {
			// array(...) / list(...) vs [...]; `array` is also a type, so only when '(' follows.
			$pend = true;
			continue;
		}
		if ( $text === '(' ) {
			$stack[] = $pend ? 'arr' : 'paren';
			$out[]   = $pend ? '[' : '(';
			$pend    = false;
			continue;
		}
		if ( $pend ) {
			$out[] = 'array'; // was a type declaration
			$pend  = false;
		}
		if ( $text === '[' ) {
			$stack[] = 'arr';
			$out[]   = '[';
			continue;
		}
		if ( $text === ')' || $text === ']' ) {
			$kind = array_pop( $stack );
			if ( $kind === 'arr' ) {
				if ( end( $out ) === ',' ) {
					array_pop( $out );
				}
				$out[] = ']';
			} else {
				$out[] = ')';
			}
			continue;
		}
		if ( $id === T_NAME_FULLY_QUALIFIED && in_array( 'use', array_slice( $out, -1 ), true ) ) {
			$out[] = ltrim( $text, '\\' );
			continue;
		}
		if ( $id === T_STRING && in_array( strtolower( $text ), LOWER, true ) ) {
			$out[] = strtolower( $text );
			continue;
		}
		if ( $id !== null && $id !== T_STRING && $id !== T_VARIABLE && $id !== T_ENCAPSED_AND_WHITESPACE
			&& ! in_array( $id, [ T_NAME_QUALIFIED, T_NAME_FULLY_QUALIFIED, T_NAME_RELATIVE, T_LNUMBER, T_DNUMBER ], true ) ) {
			$out[] = strtolower( $text );
			continue;
		}
		$out[] = $text;
	}
	if ( end( $out ) === '?>' ) {
		array_pop( $out );
	}
	return [ post( $out ), $cmt, $ann ];
}

/** Stream-level rewrites: elseif, new X(), modifier order, standalone ++/--. */
function post( array $o ): array {
	$r = [];
	$n = count( $o );
	for ( $i = 0; $i < $n; $i++ ) {
		// dirname( __FILE__ ) equals __DIR__ (Modernize.FunctionCalls.Dirname).
		if ( $o[ $i ] === 'dirname' && array_slice( $o, $i + 1, 3 ) === [ '(', '__file__', ')' ] ) {
			$r[] = '__dir__';
			$i  += 3;
			continue;
		}
		if ( $o[ $i ] === 'else' && ( $o[ $i + 1 ] ?? '' ) === 'if' ) {
			$r[] = 'elseif';
			$i++;
			continue;
		}
		if ( in_array( $o[ $i ], MODS, true ) ) {
			$run = [];
			while ( $i < $n && in_array( $o[ $i ], MODS, true ) ) {
				$run[] = $o[ $i++ ];
			}
			$i--;
			sort( $run );
			array_push( $r, ...$run );
			continue;
		}
		$r[] = $o[ $i ];
		if ( $o[ $i ] === 'new' ) {
			$j = $i + 1;
			if ( isset( $o[ $j ] ) && $o[ $j ] !== 'class' && $o[ $j ] !== '(' ) {
				$r[] = $o[ $j ];
				$i   = $j;
				if ( ( $o[ $j + 1 ] ?? '' ) !== '(' ) {
					$r[] = '(';
					$r[] = ')';
				}
			}
		}
	}
	// Standalone post-increment/decrement: `; $x ++ ;` equals `; ++ $x ;`.
	// Only a whole statement (or the third expression of a for) counts: in
	// foo( $x++ ) or $a = $b++ the two forms give different values.
	$m = count( $r );
	for ( $i = 1; $i < $m; $i++ ) {
		if ( ( $r[ $i ] !== '++' && $r[ $i ] !== '--' ) || ! in_array( $r[ $i + 1 ] ?? '', [ ';', ')' ], true ) ) {
			continue;
		}
		$start = $i - 1;
		while ( $start > 0 && preg_match( '/^(\$\w+|->|::|\w+|\[|\]|S:.*)$/s', $r[ $start - 1 ] ) ) {
			$start--;
		}
		if ( ( $r[ $start ][0] !== '$' && ! in_array( $r[ $start ], [ 'self', 'static', 'parent' ], true ) ) || ! ( in_array( $r[ $start - 1 ] ?? '', [ ';', '{', '}' ], true ) || strpos( $r[ $start - 1 ] ?? '', '<?php' ) === 0 ) ) {
			continue;
		}
		$op = $r[ $i ];
		array_splice( $r, $i, 1 );
		array_splice( $r, $start, 0, [ $op ] );
	}
	return $r;
}

$fail = 0;
foreach ( $files as $f ) {
	$old = shell_exec( 'git show ' . escapeshellarg( "$ref:$f" ) . ' 2>/dev/null' );
	if ( $old === null || ! is_file( $f ) ) {
		echo "SKIP (new or deleted): $f\n";
		continue;
	}
	if ( $dropd ) {
		$old = preg_replace( '/^declare\(strict_types=1\);\n/m', '', $old );
	}
	[ $a, $ca, $aa ] = normalize( $old );
	[ $b, $cb, $ab ] = normalize( file_get_contents( $f ) );
	if ( $a !== $b ) {
		$fail = 1;
		$k = 0;
		while ( $k < min( count( $a ), count( $b ) ) && $a[ $k ] === $b[ $k ] ) {
			$k++;
		}
		echo "CODE DIFF: $f at item $k\n  old: " . implode( ' ', array_slice( $a, max( 0, $k - 6 ), 14 ) ) . "\n  new: " . implode( ' ', array_slice( $b, max( 0, $k - 6 ), 14 ) ) . "\n";
		continue;
	}
	if ( $aa !== $ab ) {
		$fail = 1;
		echo "ANNOTATION/DIRECTIVE DIFF: $f\n  old: " . implode( ' | ', $aa ) . "\n  new: " . implode( ' | ', $ab ) . "\n";
		continue;
	}
	if ( $ca !== $cb ) {
		echo "COMMENT-ONLY (allowed, review): $f\n";
		foreach ( array_diff( $cb, $ca ) as $c ) {
			echo '  + ' . substr( $c, 0, 110 ) . "\n";
		}
		continue;
	}
	echo "OK: $f\n";
}
exit( $fail );
