#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use PFT::Content::Page;

use Test::More tests => 4;
use File::Temp;
use File::Spec;

my $dir = File::Temp->newdir();

my $page = PFT::Content::Page->new({
    tree => undef,
    path => File::Spec->catfile($dir, 'foo'),
    name => 'foo',
});

is($page->header, undef, 'Empty file has no header');
is($@, '', 'But also no error');

do {
    my $fh = $page->open('w');
    print $fh 'Hello';
};

is($page->header, undef, 'Arbitrary text has no header');
isnt($@, undef, 'Error instead');
diag('Error was: ', $@);

done_testing()
