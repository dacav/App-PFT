#!/usr/bin/perl -w

use warnings;
use strict;

use feature qw/say/;
use Test::More tests => 13;

use File::Temp;
use File::Spec::Functions qw/catdir catfile/;

use App::PFT::Struct::Tree;
use App::PFT::Data::Date;

my $dir = File::Temp->newdir();

$App::PFT::Struct::Tree::Verbose = 0;
my $tree = App::PFT::Struct::Tree->new(
    basepath => "$dir"
);

for my $dn ('content', 'inject', 'templates') {
    ok -d catfile($dir, $dn), "Creation of dir $dn";
}

for my $i (1 .. 4) {
    my $e = $tree->entry(
        title => "Hello $i",
        author => 'perl',
        date => App::PFT::Data::Date->new(
            year => 1,
            month => 2,
            day => $i,
        ),
    );
    ok -e $e->path, "Creation of entry $e";
    ok $e->fname eq sprintf('%02d-hello-%d', $i, $i),
        'Title page (' . $e->fname . ')';
};

do {
    my $e = $tree->page(
        title => 'Hello 2',
        author => 'perl',
    );
    ok -e $e->path, "Creation of entry $e";
    ok $e->fname eq 'hello-2';
};

done_testing()
