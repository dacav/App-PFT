#!/usr/bin/perl -w

use warnings;
use strict;

use v5.10;

use feature qw/say/;
use Test::More;

use Encode qw/encode decode/;
use File::Temp qw/tempfile tempdir/;

use PFT::Text::Header;
use PFT::Date;

for my $date (undef, PFT::Date->from_string('2014-12-16')) {
    my $h = PFT::Text::Header->new(
        title => 'Rådmansgatan',
        encoding => 'iso8859-15',
        date => $date,
    );

    my $dir = tempdir(CLEANUP => 1);
    my($fh, $filename) = tempfile(DIR => $dir);

    $h->dump($fh);
    print $fh 'Hello';
    seek $fh, 0, 0;
    my $hl = PFT::Text::Header->load($fh);
    close $fh;

    is_deeply($h, $h,
        'dump and reload ' . ($date ? $date : 'no date')
    );
}

done_testing()
