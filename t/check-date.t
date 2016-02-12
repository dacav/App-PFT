#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use PFT::Date;

use Test::More;

is(
    PFT::Date->new(1, 2, 3)->repr,
    '0001-02-03',
    'represented'
);

is_deeply(
    PFT::Date->new(1, 2, 3)->to_hash,
    { y=>1, m=>2, d=>3 },
    'hash'
);

is(
    PFT::Date->new(1, 2)->derive(m => 3)->repr,
    '0001-03-*',
    'derive'
);

is(
    PFT::Date->new(1, 2)->derive(y => undef, m => 3)->repr,
    '*-03-*',
    'derive'
);

is(
    PFT::Date->from_spec(y => 2000, m => 'january', d => 12)->repr,
    '2000-01-12',
    'human-friendly',
);

is_deeply(
    PFT::Date->from_string('1999-08-02')->to_hash,
    { y=>1999, m=>8, d=>2 },
    'repr from string',
);

eval { PFT::Date->from_string('09-08-02')->to_hash };
isnt($@, undef, 'parse error');

done_testing()
