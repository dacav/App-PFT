package App::PFT::Content::Base;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

sub from_root() { undef }
sub has_prev() { 0 }
sub has_next() { 0 }
sub has_month() { 0 }
sub has_links() { 0 }
sub text() {''}
sub date () { undef };

has tree => (
    isa => 'App::PFT::Struct::Tree',
    is => 'ro',
    weak_ref => 1,
);

sub lookup {
    my $self = shift;
    $self->tree->lookup(
        relative_to => $self,
        kind => shift,
        hint => shift,
    )
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
