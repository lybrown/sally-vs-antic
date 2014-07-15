#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(ceil);

my %scanlines = qw(
    2  8
    3  10
    4  8
    5  16
    6  8
    7  16
    8  8
    9  4
    10 4
    11 2
    12 1
    13 2
    14 1
    15 1
);

my %bpl = qw(
    2  40
    3  40
    4  40
    5  40
    6  20
    7  20
    8  10
    9  10
    10 20
    11 20
    12 20
    13 40
    14 40
    15 40
);

my %maxlines = map { $_ => int(240 / $scanlines{$_}) } keys %scanlines;

sub calc {
    my ($totalscanlines, $norm) = @_;
    printf "%5s", "Mode";
    printf " %5s", sprintf("%X", $_) for (2 .. 15);
    print "\n";
    printf "%5s", "Lines";
    printf " %5s", "----" for (2 .. 15);
    print "\n";
    for my $lines (0 .. 30, map 40+$_*10, 0 .. 20) {
        printf "%5d", $lines;
        for my $mode (2 .. 15) {
            my $available = $totalscanlines*114;
            my $realavailable = $totalscanlines*(114-9);
            my $refreshlines = $mode <= 5 ? $totalscanlines - $lines : $totalscanlines;
            my $refreshcycles = $refreshlines*9;
            my $totalbytes = $bpl{$mode} * $lines;
            my $lms_count = ceil($totalbytes / 4096);
            my $lms_cycles = $lms_count * 3;
            my $symbol_cycles = $mode <= 7 ? $bpl{$mode}*$lines : 0;
            my $bitmap_multiple = $mode <= 7 ? 8 + ($mode == 3 ? 2 : 0) : 1;
            my $bitmap_cycles = $bpl{$mode}*$bitmap_multiple*$lines;
            my $total = $refreshcycles + $lms_count + $symbol_cycles + $bitmap_cycles;
            if ($lines <= $maxlines{$mode}) {
                if ($norm) {
                    my $total = $lms_count + $symbol_cycles + $bitmap_cycles;
                    printf " %5.1f", ($realavailable-$total)/$realavailable*100;
                } else {
                    printf " %5.1f", ($available-$total)/$available*100;
                }
            } else {
                printf " %5s", "-";
            }
        }
        print "\n";
    }
}

sub main {
    print "PAL\n";
    print "---\n";
    calc(312);
    print "\n";
    print "PAL normalized\n";
    print "--------------\n";
    calc(312, 1);
    print "\n";
    print "NTSC\n";
    print "----\n";
    calc(262);
    print "\n";
    print "NTSC normalized\n";
    print "---------------\n";
    calc(262, 1);
}

main();
