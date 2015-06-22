#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::PFT' ) || print "Bail out!\n";
}

diag( "Testing App::PFT $App::PFT::VERSION, Perl $], $^X" );
