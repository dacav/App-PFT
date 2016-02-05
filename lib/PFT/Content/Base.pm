package PFT::Content::Base;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Content::Base - Base class for content

=head1 SYNOPSIS

    use parent 'PFT::Content::Base'

    sub new {
        my $cls = shift;
        ...
        $cls->SUPER::new({
            tree => $tree       # Mandatory
        })
        ...
    }

=head1 DESCRIPTION

This class is meant for extension for all C<PFT::Content::*> classes.

=cut

use Carp;

use Data::Dumper;

sub new {
    my $cls = shift;
    my $params = shift;
    exists $params->{tree} or confess 'Missing param: tree';
    bless {
        tree => $params->{tree},
    }, $cls
}

1;


