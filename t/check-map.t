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
for (1 .. 2) {
    $tree->new_entry(PFT::Header->new(title => 'Blog post nr.'.$_,
        date => PFT::Date->new(2014, $_, $_ * $_),
    ));
    $tree->new_entry(PFT::Header->new(title => 'Blog post nr.'.($_ + 10),
        date => PFT::Date->new(2014, $_, $_ * $_ + 1),
    ));
}
for (2 .. 3) {
    $tree->new_entry(PFT::Header->new(title => 'Month nr.'.$_,
        date => PFT::Date->new(2014, $_),
    ));
}

my @dumped = PFT::Map->new($tree)->dump;

my @expected = (
    {
        'id' => 0,
        't' => 'A page',
    }, {
        'id' => 1,
        't' => 'Another page',
    }, {
        'id' => 2,
        't' => 'Blog post nr.1',
        'd' => '2014-01-01',
        '>' => 3,
        '^' => 6,
    }, {
        'id' => 3,
        't' => 'Blog post nr.11',
        'd' => '2014-01-02',
        '<' => 2,
        '>' => 4,
        '^' => 6,
    }, {
        'id' => 4,
        't' => 'Blog post nr.2',
        'd' => '2014-02-04',
        '<' => 3,
        '>' => 5,
        '^' => 7,
    }, {
        'id' => 5,
        't' => 'Blog post nr.12',
        'd' => '2014-02-05',
        '<' => 4,
        '^' => 7,
    }, {
        'id' => 6,
        't' => '<month>',
        'd' => '2014-01-*',
        '>' => 7,
        'v' => [2, 3],
    }, {
        'id' => 7,
        't' => 'Month nr.2',
        'd' => '2014-02-*',
        '<' => 6,
        'v' => [4, 5],
    }
);

is_deeply(\@dumped, \@expected, 'Deeply equal');

while (my($i, $node) = each @dumped) {
    exists $node->{'>'} and ok(($expected[$node->{'>'}]->{'<'} == $i),
        'Next refers Prev for ' . $i
    );
    exists $node->{'<'} and ok(($expected[$node->{'<'}]->{'>'} == $i),
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

