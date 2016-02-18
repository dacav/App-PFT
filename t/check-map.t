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

# main::expected is declared down in the file.
is_deeply(\@dumped, \@main::expected, 'Deeply equal');

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
    if (defined(my $down = $node->{'.'})) {
        is(scalar(@{$down}), scalar(grep {
                # The list of tags of the page indexed by $_ contains our
                # id exactly once.
                1 == grep { $_ == $i } @{$dumped[$_]->{t}}
            } @{$down}),
            'Taggee refers to tag ' . $i
        );
    }
}

done_testing();

BEGIN {
    # Obtained by dumping, verified manually
    @main::expected = (
      {
        'id' => 0,
        'tt' => 'A page',
      },
      {
        'id' => 1,
        'tt' => 'Another page',
        't' => [9, 10]
      },
      {
        'id' => 2,
        'd' => '2014-01-01',
        'tt' => 'Blog post nr.1',
        '>' => 3,
        '^' => 7,
      },
      {
        'id' => 3,
        'd' => '2014-01-02',
        'tt' => 'Blog post nr.11',
        '<' => 2,
        '>' => 4,
        '^' => 7,
        't' => [9],
      },
      {
        'id' => 4,
        'd' => '2014-01-03',
        'tt' => 'Blog post nr.3',
        '^' => 7,
        't' => [10],
        '>' => 5,
        '<' => 3,
      },
      {
        'id' => 5,
        'd' => '2014-02-04',
        'tt' => 'Blog post nr.2',
        '^' => 8,
        '>' => 6,
        '<' => 4,
      },
      {
        'id' => 6,
        'd' => '2014-02-05',
        'tt' => 'Blog post nr.12',
        '<' => 5,
        't' => [9],
        '^' => 8,
      },
      {
        'id' => 7,
        'd' => '2014-01-*',
        'tt' => '<month>',
        'v' => [2, 3, 4],
        '>' => 8,
      },
      {
        'id' => 8,
        'd' => '2014-02-*',
        'tt' => 'Month nr.2',
        '<' => 7,
        'v' => [5, 6],
      },
      {
        'id' => 9,
        'tt' => 'foo',
        '.' => [1, 3, 6],
      },
      {
        'id' => 10,
        'tt' => 'Bar',
        '.' => [1, 4],
      }
    )
}
