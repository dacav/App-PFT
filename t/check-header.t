#!/usr/bin/perl -w

use warnings;
use strict;

use v5.10;

use feature qw/say/;
use Test::More;

use Encode qw/encode decode/;
use File::Temp qw/tempfile tempdir/;

use PFT::Header;
use PFT::Date;

my $dir = tempdir(CLEANUP => 1);

for my $date (undef, PFT::Date->from_string('2014-12-16')) {
    my $h = PFT::Header->new(
        title => 'Rådmansgatan',
        encoding => 'iso8859-15',
        date => $date,
    );

    my $fh = tempfile(DIR => $dir);

    $h->dump($fh);
    say $fh $_ for qw/Hello world/;
    seek $fh, 0, 0;
    my $hl = PFT::Header->load($fh);
    chomp(my @text = <$fh>);
    is_deeply(\@text, ['Hello', 'world'], 'text is ok');
    close $fh;

    is_deeply($hl, $h, 'dump and reload, ' . ($date ? $date : 'no date'));
}

is(eval { PFT::Header->new( title => 'X', date => 0)}, undef, 'broken because...');
isnt(undef, $@, 'date must be PFT::Date');
diag($@);

is(eval { PFT::Header->new(date => PFT::Date->new(1,2,3))}, undef,
    'broken because...'
);
isnt(undef, $@, 'full date but no title');
diag($@);

isnt(PFT::Header->new(date => PFT::Date->new(1, 2)), undef,
    'not broken because day is missing'
);

is(eval { PFT::Header->new(date => PFT::Date->new(1)) }, undef,
    'broken because...'
);
isnt(undef, $@, 'date missing year or month');
diag($@);

do {
    my $h = PFT::Header->new(
        title => 'Rådmansgatan',
        encoding => 'iso8859-15',
    );

    my($fh, $filename) = tempfile(DIR => $dir);
    $h->dump($fh);
    close $fh;
    my $hl = PFT::Header->load($filename);
    is_deeply($hl, $h, 'reload from path');
};

do {
    my $ts = ['One tag', 'Two ~ tags'];
    my $h = PFT::Header->new(title => 'x', tags => $ts);
    is_deeply($h->tags, $ts, 'Full tags');
    is_deeply([$h->slug_tags], ['one-tag', 'two-tags'], 'Slug tags');
};

done_testing()
