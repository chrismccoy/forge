#!/usr/bin/env perl
#
# extract-docblocks.pl FILE
#
# Reads FILE, finds every /** ... */ doc block + the declaration line
# that follows it, and sends a JSON array of records
#
# The first doc block in a file is treated as file level when it carries
# @file / @package / @module, or when the line after it is a non-symbol
# line like declare(...) / namespace / use / "use strict" / import.
# In that case "symbol" is the literal string "<file header>".
#
# Doc blocks tagged @internal / @deprecated / @ignore are skipped, but
# the file-level candidacy is preserved for the next eligible block.

use strict;
use warnings;
use JSON::PP    qw(encode_json);
use MIME::Base64 qw(encode_base64);

my $file = shift or die "usage: $0 FILE\n";

my $src = do {
    open(my $fh, '<', $file) or die "open $file: $!";
    binmode $fh, ':raw';            # lock byte mode (see file header note)
    local $/;                       # slurp; scoped to this block only
    <$fh>;
};

my @out;
my $first_candidate = 1;

# Match: /** block */, then any blank lines, then a real (non-/**) line.
# The (?=\s) after /** rejects glob patterns like "./views/**/*.ejs" where /**
# is followed by /. Real docblocks always have whitespace or newline after /**.
while ($src =~ /(\/\*\*(?=\s)[\s\S]*?\*\/)((?:[ \t]*\n)*)((?!\/\*\*)[^\n]+)/g) {
    my $block = $1;
    my $sym   = $3;
    my $start = $-[1];

    next if $block =~ /\@(?:internal|deprecated|ignore)\b/;

    if ($first_candidate) {
        $first_candidate = 0;
        my $is_file_level =
               $block =~ /\@(?:file|package|module)\b/
            || $sym   =~ /^\s*(?:declare|namespace|use|<\?php|"use strict"|import|export|require)\b/;
        $sym = '<file header>' if $is_file_level;
    }

    push @out, {
        start  => $start,
        len    => length($block),
        block  => encode_base64($block, ''),
        symbol => encode_base64($sym,   ''),
    };
}

print encode_json(\@out), "\n";
