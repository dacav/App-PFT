#!/usr/bin/perl -w

use warnings;
use strict;

use feature qw/say/;
use Test::More tests => 30;

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
            month => 1 + ($i & 1),
            day => $i,
        ),
    );
    $e->open('w');
    my ($te, $undef) = $e->tags;
    my $t = $tree->tag(name => "foo_$i");
    ok !defined $undef && same($te, $t),
        "Consistent tag $i: $te and $t";

    ok same($e->month, $tree->month(date => $e->date)), "Consistent date";

    push @pages, my $p = $tree->page(
        title => "Page $i",
        author => 'perl',
        encoding => 'utf-8',
    );
    $p->open('w');
}

is_deeply [sort @pages], [sort $tree->list_pages], 'List pages';
is_deeply [sort @entries], [sort $tree->list_entries], 'List entries';

do {
    my $tree = App::PFT::Struct::Tree->new(basepath => $tree->basepath);
    is_deeply [sort @pages], [sort $tree->list_pages], 'List pages, resume';
    is_deeply [sort @entries], [sort $tree->list_entries], 'List entries, resume';
};

$tree->link;
@entries = sort @entries;

foreach (0 .. $#entries) {
    my($p, $c, $n) = @entries[$_ - 1 .. $_ + 1];

    if ($_ == 0) {
        ok !$c->has_prev,           "entry $_ has no prev";
    } else {
        ok $c->has_prev,            "entry $_ has prev";
        ok !($c->prev cmp $p),      "  ... and it corresponds";
    }

    my %in_month = map{$_->uid => 1} $c->month->list_links;
    ok exists $in_month{$c->uid},   "  ... and month is fine";

    if ($_ == $#entries) {
        ok !$c->has_next,           "  ... and has no next";
    } else {
        ok $c->has_next,            "  ... and has next";
        ok !($c->next cmp $n),      "  ... and it corresponds";
    }
}

done_testing()
