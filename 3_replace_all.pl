#!/usr/bin/perl

use strict;
use warnings;

sub trim { $_[0] =~ s/^\s+|\s+$//g; };

# Getting input.

my $text;

do {
    print "replace: Please, enter 1 line of text:\n";
    trim($text = <STDIN>);
}
while (not $text);

print "replace: Please, enter space separated strings to match and replace (one pair per line).\n";
print "replace: Empty line will interrupt input and start execution:\n";

# Preparing the replacement map.

my %rep;

my $line;
trim($line = <STDIN>);

while ($line) {
    my ($a, $b) = split /\s+/, $line;
    $a = quotemeta $a; # Escape regex metachars if present.
    $rep{$a} = $b;

    trim($line = <STDIN>);
}

# Performing multiple substitution.

if (scalar %rep)
{
    my $regex = join "|", keys %rep;
    $regex = qr/$regex/;

    $text =~ s/($regex)/$rep{$1}/g;
}

# Printing the result.

print "replace: $text\n";
