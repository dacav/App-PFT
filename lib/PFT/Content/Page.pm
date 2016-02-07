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

sub header {
    my $self = shift;
    return undef unless $self->exists;
    my $fh = $self->open('r');
    my $h = eval { PFT::Text::Header->load($fh) };
    $@ =~ s/ at .*$// if $@;
    $h;
}

=back

=cut

1;
