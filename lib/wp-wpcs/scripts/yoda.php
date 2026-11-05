<?php
/**
 * Swaps the operands of comparisons that WordPress.PHP.YodaConditions reports.
 * Given a phpcs JSON report of Yoda-condition violations (e.g. `$x === 'foo'`
 * where WordPress coding standards want `'foo' === $x`), this script rewrites
 * the flagged lines in place, swapping left/right operands around the
 * comparison operator. Anything too complex to safely auto-swap (multi-line
 * expressions, either operand containing a function call, or an operand whose
 * edge can't be trusted: interpolated strings, bitwise operators, compound
 * assignments, print and similar) is printed to stdout as "HAND: ..." for a
 * human to fix manually instead.
 *
 * 1. Load the phpcs JSON report and collect, per file, the set of line and
 *    column positions flagged for Yoda-condition violations.
 * 2. For each flagged file, tokenize its full source with token_get_all().
 * 3. Walk the token array backwards looking for a comparison operator
 *    (==, ===, !=, !==) sitting at a flagged line and column.
 * 4. For each match, scan forward from the operator to find where the right
 *    operand ends (respecting bracket depth and stop tokens), and scan
 *    backward from the operator to find where the left operand starts.
 * 5. Reconstruct the left and right operand text. If either is multi-line,
 *    contains a function call or has an untrustworthy edge, just report it
 *    for manual handling.
 * 6. Otherwise, swap the two operand token slots directly in the token array,
 *    blanking out any tokens that were "absorbed" into the operand.
 * 7. After processing all matches in a file, re-join the (possibly mutated)
 *    token array back into source text and write it back to disk (unless
 *    --dry-run was passed, in which case nothing is written).
 * 8. Report any flagged position that wasn't reached, then print a summary
 *    count of how many comparisons were swapped. Exit 1 if any file failed.
 *
 * USAGE:
 *   vendor/bin/phpcs -q --report=json --sniffs=WordPress.PHP.YodaConditions > yoda.json
 *   php yoda.php yoda.json [--dry-run] [--tab-width=N]
 *
 * --dry-run performs the full scan/swap simulation and prints the same
 * "swapped"/"HAND:"/"CHECK:" output, but does not write any files. Useful
 * for previewing what the script would do before letting it touch disk.
 *
 * --tab-width=N must match the tab width phpcs used, because phpcs expands
 * tabs when it counts columns. The default is 4, the WordPress ruleset's
 * value. A wrong width swaps nothing: each flagged position is reported as
 * HAND.
 *
 * REQUIREMENTS:
 * - PHP 8.1 or later.
 * - A phpcs JSON report (from the WordPress.PHP.YodaConditions sniff) as
 *   input — the script relies on that specific JSON shape ($report['files']
 *   -> ['messages'] -> ['line'] and ['column']).
 * - Write access to the source files named in the report (unless
 *   --dry-run is used), since they are modified in place.
 */

declare( strict_types=1 );

/**
 * Loads and decodes a phpcs JSON report from disk.
 *
 * @param string $path Path to the JSON report file.
 * @return array<string,mixed> Decoded report.
 */
function load_report( string $path ): array {
	if ( ! is_readable( $path ) ) {
		fwrite( STDERR, "Cannot read report file: $path\n" );
		exit( 1 );
	}
	$raw    = file_get_contents( $path );
	$report = json_decode( $raw, true );
	if ( ! is_array( $report ) || ! isset( $report['files'] ) || ! is_array( $report['files'] ) ) {
		// Guards against being pointed at the wrong file (e.g. a plain text
		// log instead of `--report=json` output), which would otherwise
		// cause confusing "undefined index" errors further down.
		fwrite( STDERR, "Not a phpcs JSON report. Run phpcs with -q --report=json.\n" );
		exit( 1 );
	}
	return $report;
}

/**
 * Collapses a phpcs report down to filename => line => column => true.
 * We only need positions, not full message detail, because the token scan
 * re-derives everything else directly from the source. A line alone isn't
 * enough: it can hold comparisons phpcs didn't flag, including correct ones.
 *
 * @param array<string,mixed> $report Decoded phpcs report.
 * @return array<string,array<int,array<int,bool>>>
 */
function collect_flagged_positions( array $report ): array {
	$by = [];
	foreach ( $report['files'] as $file => $data ) {
		foreach ( $data['messages'] ?? [] as $m ) {
			$by[ $file ][ (int) $m['line'] ][ (int) ( $m['column'] ?? 0 ) ] = true;
		}
	}
	return $by;
}

/**
 * Returns the printable text of a single PHP token, regardless of whether
 * token_get_all() represented it as an [id, text, line] array or a bare
 * single-character string.
 *
 * @param array{0:int,1:string,2:int}|string $tok
 */
function token_text( $tok ): string {
	return is_array( $tok ) ? $tok[1] : $tok;
}

/** @param array{0:int,1:string,2:int}|string $tok */
function token_id( $tok ) {
	return is_array( $tok ) ? $tok[0] : $tok;
}

/**
 * Works out the column phpcs reports for text that follows $prefix on a line:
 * one per character, with tabs expanded to the next tab stop.
 *
 * @param string $prefix    The line's text before the token.
 * @param int    $tab_width Tab width phpcs used. 0 counts a tab as one column.
 */
function visual_column( string $prefix, int $tab_width ): int {
	// Invalid UTF-8 makes preg_split() return false; count bytes then.
	$chars = preg_split( '//u', $prefix, -1, PREG_SPLIT_NO_EMPTY );
	if ( false === $chars ) {
		$chars = '' === $prefix ? [] : str_split( $prefix );
	}
	$col = 1;
	foreach ( $chars as $char ) {
		$col += "\t" === $char && $tab_width > 0 ? $tab_width - ( ( $col - 1 ) % $tab_width ) : 1;
	}
	return $col;
}

/**
 * Maps the index of each comparison operator to its phpcs column. Must run
 * before any swap, while token lengths still match the source.
 *
 * @param array<int,mixed> $t         Full token array.
 * @param string           $src       The source $t came from.
 * @param int[]            $ops       Comparison operator token IDs.
 * @param int              $tab_width Tab width phpcs used.
 * @return array<int,int>
 */
function comparison_columns( array $t, string $src, array $ops, int $tab_width ): array {
	$columns = [];
	$offset  = 0;
	foreach ( $t as $k => $tok ) {
		if ( in_array( token_id( $tok ), $ops, true ) ) {
			$newline       = strrpos( substr( $src, 0, $offset ), "\n" );
			$start         = false === $newline ? 0 : $newline + 1;
			$columns[ $k ] = visual_column( substr( $src, $start, $offset - $start ), $tab_width );
		}
		$offset += strlen( token_text( $tok ) );
	}
	return $columns;
}

/**
 * Advances (or retreats) an index past any whitespace tokens, stopping
 * safely at the array bounds instead of reading past them.
 *
 * @param array<int,mixed> $t   Full token array.
 * @param int               $i  Starting index.
 * @param int               $dir +1 to skip forward, -1 to skip backward.
 * @return int The first non-whitespace index in that direction, or -1 / n
 *             (out of bounds) if the array ends first.
 */
function skip_whitespace( array $t, int $i, int $dir ): int {
	$n = count( $t );
	while ( $i >= 0 && $i < $n && is_array( $t[ $i ] ) && $t[ $i ][0] === T_WHITESPACE ) {
		$i += $dir;
	}
	return $i;
}

/**
 * Scans from $from in direction $dir looking for the boundary of an
 * operand: either a stop token/char at bracket depth 0, or an unmatched
 * bracket that belongs to an *enclosing* expression. Used for both the
 * left operand (scanning backward) and the right operand (scanning
 * forward) — the only difference is which bracket characters count as
 * "opening" vs "closing" relative to the scan direction.
 *
 * @param array<int,mixed> $t           Full token array.
 * @param int               $from       Index to start scanning from (inclusive).
 * @param int               $dir        +1 for right operand, -1 for left operand.
 * @param int[]             $stop_ids   Token IDs that terminate an operand.
 * @param string[]          $stop_chars Single-character tokens that terminate an operand.
 * @return int Index of the boundary token (not part of the operand), or
 *             count($t) / -1 if the scan ran off the end of the array.
 */
function find_operand_boundary( array $t, int $from, int $dir, array $stop_ids, array $stop_chars ): int {
	$open  = 1 === $dir ? [ '(', '[' ] : [ ')', ']' ];
	$close = 1 === $dir ? [ ')', ']' ] : [ '(', '[' ];
	$depth = 0;
	$n     = count( $t );

	for ( $p = $from; $p >= 0 && $p < $n; $p += $dir ) {
		$x  = token_text( $t[ $p ] );
		$id = token_id( $t[ $p ] );

		if ( in_array( $x, $open, true ) ) {
			// Entering a nested group — anything inside it is part of this
			// operand even if it contains characters that would otherwise
			// look like stop characters (e.g. ',' in a function call's
			// argument list).
			$depth++;
		} elseif ( in_array( $x, $close, true ) ) {
			if ( 0 === $depth ) {
				// A bracket we didn't open ourselves means we've hit the
				// edge of an *enclosing* group — that's the true end of
				// the operand.
				return $p;
			}
			$depth--;
		} elseif ( 0 === $depth
			&& ( in_array( $id, $stop_ids, true ) || in_array( $x, $stop_chars, true ) )
		) {
			// Only treat these as boundaries at depth 0 (top level of this
			// operand) — inside nested parens they might just be normal
			// punctuation (e.g. a comma in a function call).
			return $p;
		}
	}

	return 1 === $dir ? $n : -1;
}

/**
 * Given the index of a comparison operator, works out the inclusive token
 * index ranges of its left and right operands (trimmed of surrounding
 * whitespace).
 *
 * @param array<int,mixed> $t Full token array.
 * @param int $i Index of the comparison operator token.
 * @param int[] $stop_ids
 * @param string[] $stop_chars
 * @return array{0:int,1:int,2:int,3:int}|null [l_start, l_end, r_start, r_end]
 *         or null if either operand runs off the edge of the file (treated
 *         as "too weird, skip").
 */
function find_operands( array $t, int $i, array $stop_ids, array $stop_chars ): ?array {
	$n = count( $t );

	// --- Right operand ---
	$r_start = skip_whitespace( $t, $i + 1, 1 );
	if ( $r_start >= $n ) {
		return null;
	}
	$r_boundary = find_operand_boundary( $t, $r_start, 1, $stop_ids, $stop_chars );
	$r_end      = $r_boundary - 1;
	$r_end      = skip_whitespace( $t, $r_end, -1 ); // Trim trailing whitespace.
	if ( $r_end < $r_start ) {
		return null;
	}

	// --- Left operand ---
	$l_end = skip_whitespace( $t, $i - 1, -1 );
	if ( $l_end < 0 ) {
		return null;
	}
	$l_boundary = find_operand_boundary( $t, $l_end, -1, $stop_ids, $stop_chars );
	$l_start    = $l_boundary + 1;
	$l_start    = skip_whitespace( $t, $l_start, 1 ); // Trim leading whitespace.
	if ( $l_start > $l_end ) {
		return null;
	}

	return [ $l_start, $l_end, $r_start, $r_end ];
}

/**
 * Flattens a range of token indices back into plain source text.
 *
 * @param array<int,mixed> $t
 */
function tokens_to_text( array $t, int $a, int $b ): string {
	$out = '';
	for ( $k = $a; $k <= $b; $k++ ) {
		$out .= token_text( $t[ $k ] );
	}
	return $out;
}

/**
 * Says whether a token range holds something at bracket depth 0 that makes
 * its edges untrustworthy. An interpolated string has '{' and '}' tokens that
 * end the scan inside the string. The other tokens bind looser than the
 * comparison, so the scan took in text that isn't part of the operand.
 *
 * @param array<int,mixed> $t
 * @param int[]    $hand_ids   Token IDs that send the comparison to a human.
 * @param string[] $hand_chars Token text that does the same.
 */
function operand_is_unsafe( array $t, int $a, int $b, array $hand_ids, array $hand_chars ): bool {
	$depth = 0;
	for ( $k = $a; $k <= $b; $k++ ) {
		$x = token_text( $t[ $k ] );
		if ( in_array( $x, [ '(', '[' ], true ) ) {
			$depth++;
		} elseif ( in_array( $x, [ ')', ']' ], true ) ) {
			$depth--;
		} elseif ( 0 === $depth
			&& ( in_array( token_id( $t[ $k ] ), $hand_ids, true ) || in_array( $x, $hand_chars, true ) )
		) {
			return true;
		}
	}
	return false;
}

/**
 * Processes a single file: tokenizes it, finds flagged Yoda-condition
 * comparisons, swaps the safe ones, and reports the rest for manual review.
 *
 * @param string $file      Path to the source file.
 * @param array<int,array<int,bool>> $flagged Flagged line => column => true.
 * @param bool   $dry_run   If true, never writes to disk.
 * @param int    $tab_width Tab width phpcs used.
 * @return int Number of comparisons swapped in this file.
 * @throws RuntimeException If the file can't be read or written.
 */
function process_file( string $file, array $flagged, bool $dry_run, int $tab_width ): int {
	$src = @file_get_contents( $file );
	if ( false === $src ) {
		throw new RuntimeException( "can't read the file" );
	}

	// token_get_all() returns either [id, text, line] arrays for named
	// tokens, or a bare single-character string for "simple" tokens like
	// ';' or '(' — the is_array() checks throughout this script exist to
	// distinguish those two shapes. TOKEN_PARSE throws a ParseError on
	// malformed source, so a file with a syntax error is never rewritten.
	$t = token_get_all( $src, TOKEN_PARSE );

	// The comparison operator token types we're willing to swap operands
	// around. Deliberately excludes things like <, >, <=, >= — Yoda
	// conditions are only a style concern for equality-style comparisons,
	// not ordering comparisons.
	static $ops = [ T_IS_EQUAL, T_IS_IDENTICAL, T_IS_NOT_EQUAL, T_IS_NOT_IDENTICAL ];

	// Token types that mark the boundary of a statement/expression — if the
	// scanner hits one of these at bracket depth 0, it means it has walked
	// past the edge of the current operand and must stop. This list exists
	// because an operand has no single delimiter character; it ends
	// wherever PHP syntax says the expression ends.
	static $stop = [ T_BOOLEAN_AND, T_BOOLEAN_OR, T_LOGICAL_AND, T_LOGICAL_OR, T_LOGICAL_XOR, T_RETURN, T_ECHO, T_COALESCE, T_DOUBLE_ARROW, T_CASE, T_OPEN_TAG, T_OPEN_TAG_WITH_ECHO ];

	// Same idea as $stop, but for single-character tokens that PHP's
	// tokenizer returns as raw strings rather than named constants (so
	// they can't live in $stop, which is checked against token IDs).
	// Note: '!' is deliberately NOT included here — a bare '!' only ever
	// appears as the unary NOT operator (since !=/!== are already single
	// tokens), so treating it as an operand boundary would truncate a
	// negated left operand like `! $foo === $bar` and produce a swap that
	// isn't equivalent to the original.
	static $stop_chars = [ ';', ',', '?', ':', '=', '{', '}' ];

	// Tokens that send a comparison to a human when an operand holds them at
	// depth 0. See operand_is_unsafe().
	static $hand_ids = [
		T_PLUS_EQUAL, T_MINUS_EQUAL, T_MUL_EQUAL, T_DIV_EQUAL, T_CONCAT_EQUAL, T_MOD_EQUAL, T_AND_EQUAL, T_OR_EQUAL,
		T_XOR_EQUAL, T_SL_EQUAL, T_SR_EQUAL, T_POW_EQUAL, T_COALESCE_EQUAL, T_PRINT, T_YIELD, T_YIELD_FROM, T_THROW,
		T_INCLUDE, T_INCLUDE_ONCE, T_REQUIRE, T_REQUIRE_ONCE, T_START_HEREDOC, T_END_HEREDOC,
	];
	static $hand_chars = [ '&', '|', '^', '"', '`' ];

	$columns = comparison_columns( $t, $src, $ops, $tab_width );
	$swapped = 0;

	// Later positions first, so earlier indexes stay valid. Walking
	// backwards means that once we've handled token index $i, nothing we do
	// to it or tokens after it can disturb the meaning of any index less
	// than $i — so we never need to recompute positions mid-loop.
	for ( $i = count( $t ) - 1; $i >= 0; $i-- ) {
		// Skip anything that isn't one of our comparison operators sitting
		// at a position the phpcs report actually flagged.
		if ( ! is_array( $t[ $i ] ) || ! isset( $columns[ $i ], $flagged[ $t[ $i ][2] ][ $columns[ $i ] ] ) ) {
			continue;
		}
		unset( $flagged[ $t[ $i ][2] ][ $columns[ $i ] ] );

		$bounds = find_operands( $t, $i, $stop, $stop_chars );
		if ( null === $bounds ) {
			// Operand ran off the edge of the file/array — too unusual to
			// trust; leave it for a human.
			echo "HAND: $file:{$t[ $i ][2]}: (could not determine operand bounds)\n";
			continue;
		}
		[ $l_start, $l_end, $r_start, $r_end ] = $bounds;

		$left  = tokens_to_text( $t, $l_start, $l_end );
		$right = tokens_to_text( $t, $r_start, $r_end );

		// Bail out to manual review if either operand spans multiple lines
		// (swapping could mangle formatting/comments) or if either side
		// looks like it contains a function call (swapping call
		// expressions is riskier to get right mechanically than swapping
		// simple variables/literals). Checked symmetrically on both sides.
		// The same goes for an operand whose edge can't be trusted.
		if (
			str_contains( $left, "\n" ) || str_contains( $right, "\n" )
			|| str_contains( $left, '(' ) || str_contains( $right, '(' )
			|| operand_is_unsafe( $t, $l_start, $l_end, $hand_ids, $hand_chars )
			|| operand_is_unsafe( $t, $r_start, $r_end, $hand_ids, $hand_chars )
		) {
			echo "HAND: $file:{$t[ $i ][2]}: $left {$t[ $i ][1]} $right\n";
			continue;
		}

		// Perform the swap directly on the token array:
		// - Put the right operand's text where the left operand started.
		// - Blank out the rest of the left operand's original token slots
		//   (rather than deleting them, which would shift every later
		//   index).
		$t[ $l_start ] = $right;
		for ( $k = $l_start + 1; $k <= $l_end; $k++ ) {
			$t[ $k ] = '';
		}
		// Same idea in reverse: put the left operand's text where the
		// right operand started, and blank out its remaining original
		// slots.
		$t[ $r_start ] = $left;
		for ( $k = $r_start + 1; $k <= $r_end; $k++ ) {
			$t[ $k ] = '';
		}
		$swapped++;

		if ( preg_match( '/\+\+|--|[%*\/+]/', $left ) ) {
			echo "CHECK: $file:{$t[ $i ][2]}: swapped a non-plain operand: $left\n";
		}
	}

	// A position left over wasn't a comparison the loop reached: a stale
	// report, the wrong --tab-width, or one nested in an operand just moved.
	foreach ( $flagged as $line => $cols ) {
		foreach ( array_keys( $cols ) as $col ) {
			echo "HAND: $file:$line: no comparison handled at column $col (stale report, wrong --tab-width, or nested)\n";
		}
	}

	if ( $swapped > 0 && ! $dry_run ) {
		// Reconstruct the full file text from the (possibly mutated) token
		// array and write it back out. Because blanked tokens are empty
		// strings rather than removed array entries, this implode()
		// naturally skips them while preserving everything else exactly
		// as it was.
		$out = implode( '', array_map( 'token_text', $t ) );
		if ( false === @file_put_contents( $file, $out ) ) {
			throw new RuntimeException( "can't write the file" );
		}
	}

	return $swapped;
}

/**
 * Entry point.
 *
 * @param string[] $argv
 */
function main( array $argv ): int {
	$usage     = "Usage: php yoda.php <phpcs-json-report> [--dry-run] [--tab-width=N]\n";
	$path      = null;
	$dry_run   = false;
	$tab_width = 4;

	foreach ( array_slice( $argv, 1 ) as $arg ) {
		if ( '--dry-run' === $arg ) {
			$dry_run = true;
		} elseif ( 1 === preg_match( '/^--tab-width=(\d+)$/', $arg, $match ) ) {
			$tab_width = (int) $match[1];
		} elseif ( null === $path && ! str_starts_with( $arg, '--' ) ) {
			$path = $arg;
		} else {
			// Reject anything unknown: a mistyped --dry-run must not write.
			fwrite( STDERR, $usage );
			return 1;
		}
	}

	if ( null === $path ) {
		fwrite( STDERR, $usage );
		return 1;
	}

	$report = load_report( $path );
	$by     = collect_flagged_positions( $report );

	$swapped = 0;
	$failed  = 0;
	foreach ( $by as $file => $flagged ) {
		try {
			$swapped += process_file( $file, $flagged, $dry_run, $tab_width );
		} catch ( \Throwable $e ) {
			// Isolate failures per file (e.g. a tokenizer ParseError on a
			// file with a syntax error) so one bad file doesn't abort the
			// whole batch.
			fwrite( STDERR, "Error processing $file: {$e->getMessage()}\n" );
			$failed++;
		}
	}

	echo ( $dry_run ? 'would swap ' : 'swapped ' ) . "$swapped\n";
	return $failed > 0 ? 1 : 0;
}

exit( main( $argv ) );
