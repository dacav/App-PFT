package PFT::Backends::Base;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Backends::Base - Base class for backends.

=head1 SYNOPSIS

    use parent 'PFT::Backends::Base';

    sub new {
        my $cls = shift;
        ...
        $cls->SUPER::new($tree)
        ...
    }

=head1 DESCRIPTION

=cut

use Carp;

sub new {
    my $cls = shift;
    my $tree = shift;
    confess 'Tree must be PFT::Tree'
        unless $tree && $tree->isa('PFT::Tree');
    bless { tree => $tree }, $cls
}

sub tree { shift->{tree} }

1;


