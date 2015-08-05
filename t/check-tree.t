#!/usr/bin/perl -w

use warnings;
use strict;

use feature qw/say/;
use Test::More tests => 3;

use File::Temp;
use File::Spec::Functions qw/catdir catfile/;

use App::PFT::Struct::Tree;

my $dir = File::Temp->newdir();

$App::PFT::Struct::Tree::Verbose = 0;
my $tree = App::PFT::Struct::Tree->new(
    basepath => "$dir"
);

for my $dn ('content', 'inject', 'templates') {
    ok -d catfile($dir, $dn), 'Creation ' . $dn;
}

done_testing()
