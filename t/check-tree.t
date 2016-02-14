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
    is_deeply($tree->path_to_date($p->path), $date, 'Path-to-date')
};
do {
    my $p = $tree->entry(PFT::Text::Header->new(
        title => 'foo-bar-baz',
    ));
    is($tree->path_to_date($p->path), undef, 'Path-to-date, no date')
};

# Testing make_consistent function
do {
    my $hdr = PFT::Text::Header->new(
        title => 'one',
        date => PFT::Date->new(10, 11, 12),
    );

    my $e = $tree->entry($hdr);
    $e->set_header(PFT::Text::Header->new(
        title => 'two',
        date => PFT::Date->new(10, 12, 14),
    ));

    ok($e->path =~ /0010-11.*12-one/, 'Original path');
    my $orig_path = $e->path;
    $e->make_consistent;
    ok($e->path !~ /0010-11.*12-one/, 'Not original path');
    ok(!-e $orig_path && -e $e->path, 'Actually moved');
    ok($e->path =~ /0010-12.*14-two/, 'New path');
};

done_testing()
