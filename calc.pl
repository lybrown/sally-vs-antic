#!/usr/bin/perl
use strict;
use warnings;
use POSIX qw(ceil);
use List::Util qw(min);

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
            my $modeline_cycles = $lines - $lms_count;
            my $symbol_cycles = $mode <= 7 ? $bpl{$mode}*$lines : 0;
            my $bitmap_multiple = $mode <= 7 ? $scanlines{$mode} : 1;
            my $bitmap_cycles = $bpl{$mode}*$bitmap_multiple*$lines;
            my $jump_cycles = $lines < $maxlines{$mode} ? 3 : 0;
            my $blank_scanlines = ($maxlines{$mode} - $lines)*$scanlines{$mode};
            my $blank_cycles = min($blank_scanlines>>3, 3);
            my $total = $refreshcycles +
                $blank_cycles +
                $lms_count + $modeline_cycles +
                $symbol_cycles + $bitmap_cycles +
                $jump_cycles;
            if ($lines <= $maxlines{$mode}) {
                if ($norm) {
                    printf " %5.1f", ($available-$total)/$realavailable*100;
                    #printf " %5.1f", $blank_scanlines;
                } else {
                    printf " %5.1f", ($available-$total)/$available*100;
                    #printf " %5.1f", $blank_cycles;
                }
            } else {
                printf " %5s", "-";
            }
        }
        print "\n";
    }
}

sub main {
    print <<"EOF";
Atari CPU Time vs. Graphics Mode
================================

These tables show the percentage of cycles available to the CPU for various
ANTIC modes of varying heights. The normalized tables show the percentage
relative to the number of available cycles minus the DRAM refresh cycles which
cannot be disabled except on text-mode bad-lines. See calc.pl for the math used
to generate the tables. The calculations include the following cases where the
CPU is halted:

* DRAM refresh cycles (9 per scanline except for text-mode bad-lines)
* Blank cycles (1 per group of 8 blank lines in top border, usually 3)
* LMS cycles (3 per 4K of bitmap data)
* Modeline cycles (1 per mode line that's not an LMS)
* Symbol cycles (1 per text-mode column)
* Bitmap cycles (1 per byte for graphics, 8 per text-mode column, 10 for mode 3)
* Jump cycles (3 unless display list spans all 240 visible scanlines)

<pre>
EOF
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
    print "</pre>\n";
    print <<"EOF";

Links
-----

* AtariAge Topic
  * http://atariage.com/forums/topic/227644-possible-screen-antic4-with-30charlines/
EOF
}

main();
