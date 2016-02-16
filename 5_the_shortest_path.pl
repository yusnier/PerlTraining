#!/usr/bin/perl

use strict;
use warnings;

# Arguments validation.

if (not scalar @ARGV) {
    die "​Error: Enter the file name as argument\n";
}

# Reading the file and preparing the connections graph.

open my $file, "<",  $ARGV[0] or die "Error: Could not open file \"$ARGV[0]\"\n";
my @lines = grep {/\S/} readline($file); # Ignoring blank lines.
chomp @lines;
close $file;

my ($first, $last) = split(/\s+/, shift @lines);
my %graph;

for my $line(@lines) {
    my ($nodeA, $nodeB) = split(/\s+/, $line);
    push @{$graph{$nodeA}}, $nodeB;

    # Comment this line if the connection is valid in one direction.
    # That is, nodeA -> nodeB, not nodeA <-> nodeB.
    push @{$graph{$nodeB}}, $nodeA;
}

# Applying the Breadth-first search (BFS) algorithm.

my %visited = ($first => 0);
my @bfs_queue = ($first);
my $found = 0;

while (not $found and scalar @bfs_queue) {
    my $current_node = shift @bfs_queue;
    my $current_level = $visited{$current_node};
    my @children;
    if (exists $graph{$current_node}) {
        @children = @{$graph{$current_node}};
    }

    for my $child(@children) {
        if (not exists $visited{$child}) {
            $visited{$child} = $current_level + 1;
            push @bfs_queue, $child;

            if ($child eq $last) {
                $found = 1;
                last;
            }
        }
    }
}

# Printing the result.

print $found ? "$visited{$last}\n" : "-1\n";
