#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use Test::More; # tests => 1;

use PFT::Tree;
use PFT::Header;
use PFT::Map;

use File::Temp;

my $root = File::Temp->newdir();
my $tree = PFT::Tree->new("$root");

# Populating

$tree->new_entry(PFT::Header->new(title => 'A page'));
$tree->new_entry(PFT::Header->new(title => 'Another page'));
for (1 .. 5) {
    $tree->new_entry(PFT::Header->new(title => 'Blog post nr.'.$_,
        date => PFT::Date->new(2014, $_, $_ * $_),
    ))
}

use Data::Dumper;

my $map = PFT::Map->new($tree);
print Dumper [$map->dump];

done_testing()

