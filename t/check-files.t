#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use feature qw/say/;

use PFT::Content::Page;

use Test::More;
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
    my($h, $text) = $page->read();
    is($h, undef, 'Read goes undef 1');
    is($text, undef, 'Read goes undef 2');
};

do {
    my $fh = $page->open('w');
    print $fh 'Hello';
};

is($page->header, undef, 'Arbitrary text has no header');
isnt($@, undef, 'Error instead');
diag('Error was: ', $@);

eval {
    my($h, $text) = $page->read();
};
isnt($@, undef, 'Error also if reading';

done_testing()
