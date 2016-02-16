#!/usr/bin/perl

use strict;
use warnings;


package Numeric;
use feature 'current_sub';

my %BASE = (
    zero      => 0,
    one       => 1,
    two       => 2,
    three     => 3,
    four      => 4,
    five      => 5,
    six       => 6,
    seven     => 7,
    eight     => 8,
    nine      => 9,

    ten       => 10,
    eleven    => 11,
    twelve    => 12,
    thirteen  => 13,
    fourteen  => 14,
    fifteen   => 15,
    sixteen   => 16,
    seventeen => 17,
    eighteen  => 18,
    nineteen  => 19,

    twenty    => 20,
    thirty    => 30,
    forty     => 40, fourty => 40, # Sometimes this variant is also used.
    fifty     => 50,
    sixty     => 60,
    seventy   => 70,
    eighty    => 80,
    ninety    => 90
);

my %SCALE = (
    hundred   => 100,
    thousand  => 1000,
    million   => 1000000,
    billion   => 1000000000
);

my $prepare = sub {
    my $exp = shift @_; 

    # 'and' conjunctions, '-'  and ',' characters are removed.
    $exp =~ s/ and / /g;
    $exp =~ tr/\-,/ /;

    # A lowercase token list is returned.
    return split(/\s+/, lc $exp);
};

my $resolve = sub {
    if ($#_ == -1) {
        return 0;
    }
    elsif ($#_ == 0) {
        if (exists $BASE{$_[0]}) {
            return $BASE{$_[0]};
        }
        else {
            die "\n";
        }
    }
    elsif ($#_ == 1) {
        if (exists $BASE{$_[0]} and exists $BASE{$_[1]}) {
            return $BASE{$_[0]} + $BASE{$_[1]};
        }
        elsif (exists $BASE{$_[0]} and exists $SCALE{$_[1]}) {
            return $BASE{$_[0]} * $SCALE{$_[1]};
        }
        else {
            die "\n";
        }
    }
    else {
        my ($max, $k) = (0, -1);
        
        for (my $i=0; $i<=$#_; ++$i) {
            if (exists $SCALE{$_[$i]} and $SCALE{$_[$i]} > $max) {
                $max = $SCALE{$_[$i]};
                $k = $i;
            }
        }

        if ($k != -1) {
            return __SUB__->(@_[0..$k-1]) * $max + __SUB__->(@_[$k+1..$#_]);
        }
        else {
            die "\n";
        }
    }
};

sub from_words {
    my @words = $prepare->($_[0]);

    if (not scalar @words) {
        return;
    }

    my $sign = 1;

    if ($words[0] eq "minus") {
        shift @words;
        $sign = -1;
    }

    my $result;

    if (not defined eval { $result = $resolve->(@words) * $sign; } ) {
        die "Error: Invalid numeric expression: \"$_[0]\"\n";
    }

    return $result;
}


package main;

# Arguments validation.

if (not scalar @ARGV) {
    die "​Error: Enter the file name as argument\n";
}

# Reading the file and ordering numbers.

open my $file, "<",  $ARGV[0] or die "Error: Could not open file \"$ARGV[0]\"\n";
my @lines = grep {/\S/} readline($file); # Ignoring blank lines.
chomp @lines;
close $file;

sub des_compare {
    Numeric::from_words($b) <=> Numeric::from_words($a);
}

my @des_sorted = sort des_compare @lines;

# Printing the result.

for my $line(@des_sorted) {
    print "$line\n";
}
