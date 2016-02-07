package PFT::Content::Page;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Content::Page - Content edited by user.

=head1 SYNOPSIS

    use PFT::Content::Page;

    my $p = PFT::Content::Page->new({
        tree => $tree,
        path => $path,
        name => $name, 
    })

=head1 DESCRIPTION


=head2 Methods

=over

=item header

Returns a PFT::Text::Header object representing the header of the file.
If the file is empty returns undef. If the file is not empty, but the
header is broken returns undef and sets $@.

=cut

use parent 'PFT::Content::File';
use PFT::Text::Header;

use Carp;

sub header {
    my $self = shift;
    return undef unless $self->exists;
    my $fh = $self->open('r');
    my $h = eval { PFT::Text::Header->load($fh) };
    $@ =~ s/ at .*$// if $@;
    $h;
}

=item read

Read the page. In scalar context returns an open file descriptor
configured with the correct `binmode` according to the header.

In list context returns the header and the same descriptor. Returns undef
if the file does not exist.

Croaks if the header is broken.

=cut

sub read {
    my $self = shift;

    return undef unless $self->exists;
    my $fh = $self->open('r');
    my $h = eval { PFT::Text::Header->load($fh) };
    croak $@ =~ s/ at .*$//rs if $@;
    binmode $fh, ':encoding(' . $h->encoding . ')';

    wantarray ? ($h, $fh) : $fh;
}

=pod

=back

=cut

1;
