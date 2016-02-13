#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use PFT::Tree;
use PFT::Text::Header;
use PFT::Date;

use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

my $dir = tempdir(CLEANUP => 1);

my $tree = PFT::Tree->new("$dir");

do {
    my $date = PFT::Date->new(0, 12, 25);
    my $p = $tree->entry(PFT::Text::Header->new(
        title => 'foo-bar-baz',
        date => $date,
    ));
    is_deeply($tree->path_to_date($p->path), $date, 'Path-to-date if')
};
do {
    my $p = $tree->entry(PFT::Text::Header->new(
        title => 'foo-bar-baz',
    ));
    is($tree->path_to_date($p->path), undef, 'Path-to-date unless')
};

done_testing()
