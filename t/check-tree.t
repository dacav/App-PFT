#!/usr/bin/perl -w

use warnings;
use strict;

use feature qw/say/;
use Test::More tests => 28;

use Scalar::Util qw/refaddr/;

use File::Temp;
use File::Spec::Functions qw/catdir catfile/;

use IO::File;

use App::PFT::Struct::Tree;
use App::PFT::Data::Date;
use App::PFT::Data::Header;

my $dir = File::Temp->newdir();

$App::PFT::Struct::Tree::Verbose = 0;
my $tree = App::PFT::Struct::Tree->new(
    basepath => "$dir"
);

for my $dn ('content', 'inject', 'templates') {
    ok -d catfile($dir, $dn), "Creation of dir $dn";
}


# -------------------- Creation of entries ------------------------------

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
        'Title entry (' . $e->fname . ')';
};

# -------------------- Creation of pages --------------------------------

do {
    my $e = $tree->page(
        title => 'Hello 2',
        author => 'perl',
    );
    ok -e $e->path, "Creation of entry $e";
    ok $e->fname eq 'hello-2',
        'Title page (' . $e->fname . ')';
};

# -------------------- Creation of months -------------------------------

do {
    my $m1 = $tree->month(
        month => 'oct',
        year => 2015,
    );
    ok $m1->isa('App::PFT::Content::Month'), 'Virtual month';

    do {
        my $m2 = $tree->month(
            month => 'oct',
            year => 2015
        );
        my($a1, $a2) = map { refaddr $_ } ($m1, $m2);
        ok $a1 == $a2, "Same month $a1 vs $a2";
    };

    my $m2 = $tree->month(
        month => 'oct',
        year => 2015,
        -create => 1,
        header => App::PFT::Data::Header->new(
            title => 'Herp derp',
            author => 'perl',
            encoding => 'utf-8',
        )
    );

    do {
        ok -e $m2->path, 'File was created';
        my $hdr = eval {
            App::PFT::Data::Header->new(
                -load => IO::File->new($m2->path, 'r')
            )
        };
        ok !$@, 'Header is valid';
        ok $hdr->slug eq 'herp-derp', '...and soud (' . $hdr->slug . ')';
    };

    do { 
        my $m3 = $tree->month(
            month => 'oct',
            year => 2015,
        );
        my $m4 = $m3->create;
        my($a1, $a2, $a3, $a4) = map { refaddr $_ } ($m1, $m2, $m3, $m4);
        ok $a1 != $a2, "Different month after create $a1 vs $a2";
        ok $a2 == $a3, "Same month after create $a2 vs $a3";
        ok $a3 == $a4, "Same month after create $a3 vs $a4";
    };
};

# -------------------- Creation of tags ---------------------------------

do {
    my $t1 = $tree->tag(name => 'foo  bar baz');
    ok $t1->isa('App::PFT::Content::Tag'), 'Virtual tag';
    ok $t1->name eq 'Foo Bar Baz', 'Tag name conversion: ' . $t1->name;

    my $t2 = $t1->create(header => App::PFT::Data::Header->new(
        title => 'Hurr durr',
        author => 'perl',
        encoding => 'utf-8',
    ));

    do {
        ok -e $t2->path, 'File was created';
        my $hdr = eval {
            App::PFT::Data::Header->new(
                -load => IO::File->new($t2->path, 'r')
            )
        };
        ok !$@, 'Header is valid';
        ok $hdr->slug eq 'hurr-durr', '...and soud (' . $hdr->slug . ')';
    };

    do {
        my $t3 = $tree->tag(name => 'Foo bAr BaZ', author => 'me');

        my($a1, $a2, $a3) = map { refaddr $_ } ($t1, $t2, $t3);
        ok $a1 != $a2, "Different tag after create $a1 vs $a2";
        ok $a2 == $a3, "Same tag after create $a2 vs $a3";
    };
};

done_testing()
