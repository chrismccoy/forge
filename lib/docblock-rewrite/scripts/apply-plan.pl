#!/usr/bin/env perl
#
# apply-plan.pl FILE PLAN DRY_RUN BACKUP
#
# Applies a replacement plan to FILE. PLAN is a tab separated file where
# each line is:   start <TAB> len <TAB> base64(new_text)
#
# - FILE     path to the source file being edited
# - PLAN     path to the plan file built by the runner
# - DRY_RUN  "1" prints a unified diff and exits without writing
# - BACKUP   "1" preserves the previous file as .bak (rotated to .bak.N
#            if .bak already exists, so repeat runs do not destroy history)

use strict;
use warnings;
use File::Temp   qw(tempfile);
use MIME::Base64 qw(decode_base64);

my ($file, $plan, $dry, $backup) = @ARGV;
die "usage: $0 FILE PLAN DRY_RUN BACKUP\n"
    unless $file && $plan && defined $dry && defined $backup;

# read source

my $src = do {
    open(my $fh, '<', $file) or die "open $file: $!";
    binmode $fh, ':raw';
    local $/;
    <$fh>;
};
my $original = $src;            # snapshot for dry-run diff

# parse and validate plan

my @repl;
open(my $pf, '<', $plan) or die "open plan $plan: $!";
binmode $pf, ':raw';
while (my $line = <$pf>) {
    chomp $line;
    next if $line eq '';
    my ($start, $len, $b64) = split /\t/, $line, 3;

    die "malformed plan line $.: '$line'\n"
        unless defined $start && defined $len && defined $b64;
    die "non-numeric offset at plan line $.: start='$start' len='$len'\n"
        unless $start =~ /^\d+$/ && $len =~ /^\d+$/;
    die "replacement at $start+$len exceeds file length " . length($src) . "\n"
        if $start + $len > length($src);

    push @repl, [ $start, $len, decode_base64($b64) ];
}
close $pf;

# detect overlapping ranges

{
    my @asc = sort { $a->[0] <=> $b->[0] } @repl;
    for my $i (1 .. $#asc) {
        my $prev = $asc[$i - 1];
        my $curr = $asc[$i];
        if ($prev->[0] + $prev->[1] > $curr->[0]) {
            die sprintf(
                "overlapping replacements: [%d+%d) and [%d+%d)\n",
                $prev->[0], $prev->[1], $curr->[0], $curr->[1],
            );
        }
    }
}

# apply replacements right to left

my @desc = sort { $b->[0] <=> $a->[0] } @repl;
for my $r (@desc) {
    substr($src, $r->[0], $r->[1]) = $r->[2];
}

# dry-run

if ($dry eq "1") {
    print "=== diff: $file ===\n";

    my ($fh_a, $tmp_a) = tempfile('dbr-before-XXXXXX', TMPDIR => 1, UNLINK => 1);
    my ($fh_b, $tmp_b) = tempfile('dbr-after-XXXXXX',  TMPDIR => 1, UNLINK => 1);
    binmode $fh_a, ':raw';
    binmode $fh_b, ':raw';
    print $fh_a $original;
    print $fh_b $src;
    close $fh_a;
    close $fh_b;

    my $rc = system("diff", "-u", $tmp_a, $tmp_b);
    if ($rc == -1) {
        warn "diff not found on PATH: $!\n";
    } elsif (($rc >> 8) == 2) {
        warn "diff failed (exit 2)\n";
    }
    exit 0;
}

# backup

if ($backup eq "1") {
    my $bak = "$file.bak";
    if (-e $bak) {
        my $n = 1;
        $n++ while -e "$file.bak.$n";
        $bak = "$file.bak.$n";
    }
    rename($file, $bak) or die "backup ($bak): $!";
}

# write via .tmp and rename

my $tmp_out = "$file.tmp";
open(my $nw, '>', $tmp_out) or die "write $tmp_out: $!";
binmode $nw, ':raw';
print $nw $src       or do { unlink $tmp_out; die "write error: $!\n" };
close $nw            or do { unlink $tmp_out; die "close error: $!\n" };
rename($tmp_out, $file) or do { unlink $tmp_out; die "rename: $!\n" };

print "    wrote $file\n";
