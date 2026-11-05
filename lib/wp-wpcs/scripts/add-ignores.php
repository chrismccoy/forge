<?php
/**
 * Places reasoned phpcs:ignore comments from a phpcs JSON report and a rules file.
 *
 * Usage: vendor/bin/phpcs -q --report=json > report.json
 *        php add-ignores.php report.json rules.json [--dry-run]
 *
 * rules.json is a list of { "sniff": "...", "reason": "...", "file": "optional regex",
 * "line": optional number }. "sniff" matches the report's source exactly or as a prefix.
 * A message with no rule is listed as NO RULE and left alone: never give a rule to
 * a report that should be fixed. A line with an ignore gets the new sniff added to it,
 * and a line that ends in inline HTML gets the comment before its last `?>`. Sniffs
 * that report on a multi-line statement may need the comment moved by hand: run phpcs
 * again afterwards. Needs PHP 8.1 or later.
 */

if ( $argc < 3 ) {
	fwrite( STDERR, "Usage: php add-ignores.php report.json rules.json [--dry-run]\n" );
	exit( 1 );
}
$report = json_decode( file_get_contents( $argv[1] ), true );
$rules  = json_decode( file_get_contents( $argv[2] ), true );
$dry    = in_array( '--dry-run', $argv, true );
if ( ! is_array( $report ) || ! is_array( $rules ) ) {
	fwrite( STDERR, "Could not read the report or the rules. Run phpcs with -q --report=json.\n" );
	exit( 1 );
}

$placed  = 0;
$no_rule = 0;
foreach ( $report['files'] as $file => $data ) {
	$lines = file( $file, FILE_IGNORE_NEW_LINES );
	$todo  = [];
	foreach ( $data['messages'] as $m ) {
		$rule = null;
		foreach ( $rules as $r ) {
			$match = str_starts_with( $m['source'], $r['sniff'] );
			if ( $match && ( empty( $r['file'] ) || preg_match( '#' . $r['file'] . '#', $file ) ) && ( empty( $r['line'] ) || (int) $r['line'] === $m['line'] ) ) {
				$rule = $r;
				break;
			}
		}
		if ( $rule === null ) {
			echo "NO RULE: $file:{$m['line']}: {$m['source']}\n";
			$no_rule++;
			continue;
		}
		$todo[ $m['line'] ][ $m['source'] ] = $rule['reason'];
	}
	foreach ( $todo as $line => $sniffs ) {
		$text   = $lines[ $line - 1 ];
		$names  = implode( ', ', array_keys( $sniffs ) );
		$reason = implode( '; ', array_unique( array_values( $sniffs ) ) );
		if ( preg_match( '/^(.*phpcs:ignore )([^-]*?)( -- (.*?))?(\s*\?>.*)?$/', $text, $e ) ) {
			$old = rtrim( $e[4] ?? '', ' .' );
			$all = $old !== '' && $old !== rtrim( $reason, ' .' ) ? "$old; $reason" : $reason;
			$new = $e[1] . trim( $e[2] ) . ', ' . $names . ' -- ' . $all . ( $e[5] ?? '' );
		} elseif ( ( $pos = strrpos( $text, '?>' ) ) !== false ) {
			$new = rtrim( substr( $text, 0, $pos ) ) . " /* phpcs:ignore $names -- $reason */ " . substr( $text, $pos );
		} else {
			$new = rtrim( $text ) . " // phpcs:ignore $names -- $reason";
		}
		$lines[ $line - 1 ] = $new;
		$placed            += count( $sniffs );
	}
	if ( $todo && ! $dry ) {
		file_put_contents( $file, implode( "\n", $lines ) . "\n" );
	}
}
echo "placed $placed, no rule $no_rule" . ( $dry ? ' (dry run, nothing written)' : '' ) . "\n";
