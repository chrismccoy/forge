<?php
/**
 * Compares the assertion count of every test in two JUnit files.
 *
 * Usage: php junit-compare.php old.xml new.xml [map.txt]
 * map.txt lines: "OldClass::old_test<TAB>NewClass::new_test", for renamed tests. Separate
 * the names with a tab: data-set test names contain spaces. A line with no "::" maps a
 * whole class: "OldClass<TAB>NewClass". A method line beats a class line, so list data
 * sets whose names hold a class name on their own lines.
 * Exit code 1 when a test disappeared, lost assertions, or failed in the new file.
 */

function load( $f ) {
	$x = simplexml_load_file( $f );
	$r = [];
	foreach ( $x->xpath( '//testcase' ) as $tc ) {
		$r[ (string) $tc['class'] . '::' . (string) $tc['name'] ] = (int) $tc['assertions'];
	}
	return $r;
}
function failed( $f ) {
	$r = [];
	foreach ( simplexml_load_file( $f )->xpath( '//testcase[failure or error]' ) as $tc ) {
		$r[] = (string) $tc['class'] . '::' . (string) $tc['name'];
	}
	return $r;
}
$a   = load( $argv[1] );
$b   = load( $argv[2] );
$map = [];
if ( isset( $argv[3] ) && is_file( $argv[3] ) ) {
	foreach ( file( $argv[3], FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES ) as $l ) {
		[ $o, $n ] = array_pad( explode( "\t", trim( $l ), 2 ), 2, '' );
		if ( $n === '' ) {
			fwrite( STDERR, "Map line has no tab: $l\n" );
			exit( 2 );
		}
		$map[ $o ] = $n;
	}
}
$bad = 0;
foreach ( $a as $name => $count ) {
	$new = $map[ $name ] ?? $name;
	if ( ! isset( $map[ $name ] ) && strpos( $name, '::' ) !== false ) {
		[ $class, $rest ] = explode( '::', $name, 2 );
		if ( isset( $map[ $class ] ) ) {
			$new = $map[ $class ] . '::' . $rest;
		}
	}
	if ( ! isset( $b[ $new ] ) ) {
		echo "MISSING: $name\n";
		$bad = 1;
	} elseif ( $b[ $new ] < $count ) {
		echo "DROP: $name $count -> {$b[$new]}\n";
		$bad = 1;
	}
}
foreach ( failed( $argv[2] ) as $name ) {
	echo "FAILED: $name\n";
	$bad = 1;
}
printf( "old: %d tests / %d assertions; new: %d tests / %d assertions\n", count( $a ), array_sum( $a ), count( $b ), array_sum( $b ) );
exit( $bad );
