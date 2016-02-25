package PFT::Tree v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Tree - Filesystem tree mapping a PFT site

=head1 SYNOPSIS

    PFT::Tree->new($basedir);

=head1 DESCRIPTION

=cut

use File::Spec;
use File::Path qw/make_path/;

use PFT::Content;

use Carp;

sub new {
    my $cls = shift;

    my $self = bless { base => shift }, $cls;
    $self->_init();
    $self->{content} = PFT::Content->new($self->dir_content);

    $self
}

sub _init {
    my $self = shift;
    make_path map({ $self->$_ } qw/
        dir_content
        dir_templates
        dir_inject
    /), {
        #verbose => 1,
        mode => 0711,
    }
}

=head2 Properties

=over 1

=item dir_content

=cut

sub dir_content { File::Spec->catdir(shift->{base}, 'content') }
sub dir_templates { File::Spec->catdir(shift->{base}, 'templates') }
sub dir_inject { File::Spec->catdir(shift->{base}, 'inject') }

=item content

=cut

sub content { shift->{content} }

=back

=cut

1;
