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
$tree->new_entry(PFT::Header->new(
    title => 'Another page',
    tags => ['foo', 'bar'],
));
$tree->new_entry(PFT::Header->new(
    title => 'Blog post nr.3',
    date => PFT::Date->new(2014, 1, 3),
    tags => ['bar'],
));
for (1 .. 2) {
    $tree->new_entry(PFT::Header->new(
        title => 'Blog post nr.'.$_,
        date => PFT::Date->new(2014, $_, $_ * $_),
    ));
    $tree->new_entry(PFT::Header->new(title => 'Blog post nr.'.($_ + 10),
        date => PFT::Date->new(2014, $_, $_ * $_ + 1),
        tags => ['foo'],
    ));
}
$tree->new_entry(PFT::Header->new(title => 'Month nr.2',
    date => PFT::Date->new(2014, 2),
));
$tree->new_entry(PFT::Header->new(title => 'Month nr.3',
    date => PFT::Date->new(2014, 3),
    tags => ['bar'],
));
$tree->new_tag(PFT::Header->new(title => 'Bar'));

my @dumped = PFT::Map->new($tree)->dump;

use Data::Dumper;
die Dumper \@dumped;

#is_deeply(\@dumped, \@expected, 'Deeply equal');

while (my($i, $node) = each @dumped) {
    exists $node->{'>'} and ok(($dumped[$node->{'>'}]->{'<'} == $i),
        'Next refers Prev for ' . $i
    );
    exists $node->{'<'} and ok(($dumped[$node->{'<'}]->{'>'} == $i),
        'Prev refers Next for ' . $i
    );
    if (defined(my $down = $node->{'v'})) {
        is(scalar(@$down), scalar(map{ $dumped[$_]->{'^'} == $i } @$down),
            'Down refers up for ' . $i
        );
    }
    if (defined(my $up = $node->{'^'})) {
        is(scalar(grep{ $_ == $i } @{$dumped[$up]->{'v'}}), 1,
            'Down refers up for ' . $i
        );
    }
}

done_testing()

