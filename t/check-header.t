#!/usr/bin/perl -w

use warnings;
use strict;

use v5.10;

use feature qw/say/;
use Test::More tests => 1;

use Encode qw/encode decode/;
use File::Temp qw/tempfile tempdir/;

use PFT::Text::Header;

my $h = PFT::Text::Header->new(
    title => 'Rådmansgatan',
    encoding => 'iso8859-15',
);

my $dir = tempdir(CLEANUP => 1);
my($fh, $filename) = tempfile(DIR => $dir);

$h->dump($fh);
print $fh 'Hello';
seek $fh, 0, 0;
my $hl = PFT::Text::Header->load($fh);
close $fh;

is_deeply($h, $h, 'dump and reload');

done_testing()
