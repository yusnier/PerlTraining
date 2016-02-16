#!/usr/bin/perl

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

my ($n, $ok);

do {
    print "Enter a number between 2 and 1000000: ";
    chomp($n = <STDIN>);

    # Input validation.
    $ok = looks_like_number($n) && ($n >= 2) && ($n <= 1000000);
    if (not $ok) {
        print STDERR "Error: Invalid number between 2 and 1000000\n";
    }
}
while (not $ok);


# Applying the Sieve of Eratosthenes algorithm.

my @sieve = (0, 0, (1) x ($n - 1));
my $k = int(sqrt($n));

for (my $i=2; $i <= $k; ++$i) {
    if ($sieve[$i]) {
        for (my $j=2; ($i * $j)<=$n; ++$j) {
            $sieve[$i * $j] = 0;
        }
    }
}

# Printing the result.

for (my $i=2; $i<=$n; ++$i) {
    if ($sieve[$i] != 0) {
        print "$i ";
    }
}
print "\n";
