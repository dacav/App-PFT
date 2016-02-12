#!/usr/bin/perl -w

use v5.10;

use strict;
use warnings;
use utf8;

use PFT::Struct::Tree;

use Test::More tests => 1;
use File::Temp;
use File::Spec;

my $dir = File::Temp->newdir();

my $tree = PFT::Tree->new("$dir");



done_testing()
