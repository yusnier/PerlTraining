#!/usr/bin/perl

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

# Arguments validation.

my $size = $#ARGV + 1;
if ($size == 0 || $size > 3) {
    die "Error: Invalid number of arguments\n";
}

for my $num(@ARGV) {
    if (not looks_like_number($num)) {
        die "Error: Invalid arguments format\n";
    }
}

if ($ARGV[0] == 0) {
    die "Error: These arguments don't complete a quadratic equation\n";
}

#  Solving equation using discriminant.

my ($a, $b, $c) = @ARGV;
if (not defined $b) { $b = 0; }
if (not defined $c) { $c = 0; }

my $D = $b*$b - 4*$a*$c;

if ($D > 0) { # There are tow real solutions.
    my $x1 = (-$b + sqrt($D)) / (2 * $a);
    my $x2 = (-$b - sqrt($D)) / (2 * $a);
    print "$x1 $x2\n";
}
elsif ($D == 0) { # There are one real solution.
    my $x = -$b / (2 * $a);
    print "$x\n";
}
else {
    die "Error: There are no real solutions for this quadratic equation\n";
}
