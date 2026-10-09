<?php
/**
 * Dumps PHP tokens as JSON for the doc-pass checker.
 *
 * Usage: php php-tokens.php <file> [<file> ...]
 *
 * Prints one JSON object that maps each file path to a list of
 * [kind, name, text, line] tuples. Kind is "comment", "doc", "ws" or "code".
 * Single-character tokens ("{", ";" ...) are code tokens whose name is the
 * character itself. A file that cannot be read maps to null.
 */

$out = array();

foreach ( array_slice( $argv, 1 ) as $file ) {
	$src = @file_get_contents( $file );
	if ( false === $src ) {
		$out[ $file ] = null;
		continue;
	}

	$tokens = array();
	$line   = 1;
	foreach ( token_get_all( $src ) as $t ) {
		if ( is_array( $t ) ) {
			$name = token_name( $t[0] );
			$text = $t[1];
			$line = $t[2];
			if ( T_DOC_COMMENT === $t[0] ) {
				$kind = 'doc';
			} elseif ( T_COMMENT === $t[0] ) {
				$kind = 'comment';
			} elseif ( T_WHITESPACE === $t[0] ) {
				$kind = 'ws';
			} else {
				$kind = 'code';
			}
		} else {
			$name = $t;
			$text = $t;
			$kind = 'code';
		}
		$tokens[] = array( $kind, $name, $text, $line );
		// Single-char tokens carry no line, so track it from the text.
		$line += substr_count( $text, "\n" );
	}

	$out[ $file ] = $tokens;
}

echo json_encode( $out, JSON_UNESCAPED_SLASHES | JSON_INVALID_UTF8_SUBSTITUTE );
