package App::PFT::Content::MonthPage;

use strict;
use warnings;

use Scalar::Util qw/weaken/;

use namespace::autoclean;
use Moose;

extends 'App::PFT::Content::Base';

has year => ( is=>'ro', isa => 'Int' );
has month => ( is=>'ro', isa => 'Int' );

has links => (
    is => 'rw',
    isa => 'ArrayRef[App::PFT::Content::Entry]',
    lazy => 1,
    default => sub{[]},
    predicate => 'has_links',
);

sub add_entries {
    my $self = shift;
    my $links = $self->links;
    for my $e (@_) {
        push @$links, $e;
        weaken $links->[$#$links];
    }
}

has prev => (
    is => 'rw',
    isa => 'Maybe[App::PFT::Content::MonthPage]',
    weak_ref => 1,
    predicate => 'has_prev',
);

has next => (
    is => 'rw',
    isa => 'Maybe[App::PFT::Content::MonthPage]',
    weak_ref => 1,
    predicate => 'has_next',
);

sub from_root() {
    my $self = shift;
    my @out = (
        'blog',
        sprintf('%04d-%02d', $self->year, $self->month),
    );
    if (my $up = $self->SUPER::from_root) {
        push @out, $up
    }
    @out
}

has header => (
    is => 'ro',
    isa => 'App::PFT::Data::Header',
    lazy => 1,
    default => sub {
        my $self = shift;
        App::PFT::Data::Header->new(
            title => sprintf('%04d / %02d', $self->year, $self->month),
            template => 'gen'
        );
    }
);

sub title() { shift->header->title }

no Moose;
__PACKAGE__->meta->make_immutable;

1;

