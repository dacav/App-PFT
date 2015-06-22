package App::PFT::Content::Page;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

extends 'App::PFT::Content::Text';

sub cmp {
    #YYYYMMDD
    '--------' . shift->fname;
}

sub from_root() {
    my $self = shift;
    my @out = (
        'pages',
        $self->fname,
    );
    if (my $up = $self->SUPER::from_root) {
        push @out, $up
    }
    @out
}

no Moose;
__PACKAGE__->meta->make_immutable;
