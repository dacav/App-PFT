#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use Test::More; # tests => 1;
use File::Temp;

use PFT::Tree;
use PFT::Backends::HTML;

my $root = File::Temp->newdir();
my $tree = PFT::Tree->new("$root");

# Populating
do { 
    my $c = $tree->content;
    $c->new_entry(PFT::Header->new(title => 'A page'));
    $c->new_entry(PFT::Header->new(
        title => 'Another page',
        tags => ['foo', 'bar'],
    ));
    $c->new_entry(PFT::Header->new(
        title => 'Blog post nr.3',
        date => PFT::Date->new(2014, 1, 3),
        tags => ['bar'],
    ));
    for (1 .. 2) {
        $c->new_entry(PFT::Header->new(
            title => 'Blog post nr.'.$_,
            date => PFT::Date->new(2014, $_, $_ * $_),
        ));
        $c->new_entry(PFT::Header->new(title => 'Blog post nr.'.($_ + 10),
            date => PFT::Date->new(2014, $_, $_ * $_ + 1),
            tags => ['foo'],
        ));
    }
    $c->new_entry(PFT::Header->new(title => 'Month nr.2',
        date => PFT::Date->new(2014, 2),
    ));
    $c->new_entry(PFT::Header->new(title => 'Month nr.3',
        date => PFT::Date->new(2014, 3),
        tags => ['bar'],
    ));
    $c->new_tag(PFT::Header->new(title => 'Bar'));
};

PFT::Backends::HTML->new($tree, {
    map { $_ => '' } qw/title home base_url encoding default_template/
});

done_testing();
