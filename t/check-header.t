#!/usr/bin/perl -w

use warnings;
use strict;

use feature qw/say/;
use Test::More tests => 2;

use Encode qw/encode decode/;

use PFT::Text::Header;

my $h = PFT::Text::Header->new(
    title => encode('utf-8', 'Rådmansgatan'),
);
cmp_ok($h->title, 'eq', 'Rådmansgatan');

$h = PFT::Text::Header->new(
    title => encode('iso8859-15', 'Rådmansgatan'),
    encoding => 'iso8859-15',
);
cmp_ok(decode('iso8859-15', $h->title), 'eq', 'Rådmansgatan');


done_testing()
