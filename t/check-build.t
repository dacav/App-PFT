#!/usr/bin/perl -w

use warnings;
use strict;

use feature qw/say/;
use Test::More; # tests => 1;

use Scalar::Util qw/refaddr/;

use File::Temp;
use File::Spec::Functions qw/catdir catfile/;

use App::PFT::Struct::Tree;
use App::PFT::Data::Header;

my $dir = File::Temp->newdir();

$App::PFT::Struct::Tree::Verbose = 0;
my $tree = App::PFT::Struct::Tree->new(basepath => "$dir");

sub same {
    my($x, $y) = map { refaddr $_ } @_;
    $x == $y;
}

# ------ Populate -------------------------------------------------------

my(@entries, @pages);
for my $i (1 .. 4) {
    push @entries, my $e = $tree->entry(
        header => App::PFT::Data::Header->new(
            title => "Hello $i",
            author => 'perl',
            tags => ["foo_$i"],
            encoding => 'utf-8',
        ),
        date => App::PFT::Data::Date->new(
            year => 1,
            month => 2,
            day => $i,
        ),
    );
    my ($te, $undef) = $e->tags;
    my $t = $tree->tag(name => "foo_$i");
    ok !defined $undef && same($te, $t),
        "Consistent tag $i: $te and $t";

    push @pages, $tree->page(
        title => "Page $i",
        author => 'perl',
    )
}

is_deeply [sort @pages], [sort $tree->list_pages], 'List pages';
is_deeply [sort @entries], [sort $tree->list_entries], 'List entries';

$tree = App::PFT::Struct::Tree->new(basepath => $tree->basepath);
is_deeply [sort @pages], [sort $tree->list_pages], 'List pages, resume';
is_deeply [sort @entries], [sort $tree->list_entries], 'List entries, resume';

done_testing()
