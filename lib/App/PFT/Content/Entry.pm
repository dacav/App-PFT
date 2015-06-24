package App::PFT::Content::Entry;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

extends 'App::PFT::Content::Text';

has date => (is => 'ro', isa => 'App::PFT::Data::Date');
has month => (
    is => 'rw',
    isa => 'Maybe[App::PFT::Content::MonthPage]',
    weak_ref => 1,
);

has prev => (
    is => 'rw',
    isa => 'Maybe[App::PFT::Content::Entry]',
    weak_ref => 1,
    predicate => 'has_prev',
);

has month => (
    is => 'rw',
    isa => 'Maybe[App::PFT::Content::MonthPage]',
    weak_ref => 1,
    predicate => 'has_month',
);

has next => (
    is => 'rw',
    isa => 'Maybe[App::PFT::Content::Entry]',
    weak_ref => 1,
    predicate => 'has_next',
);

sub cmp {
    my($self) = @_;
    $self->date->repr('') . $self->fname;
}

sub from_root() {
    my $self = shift;
    my $date = $self->date;
    my @out = (
        'blog',
        sprintf('%04d-%02d', $date->year, $date->month),
        sprintf('%02d-%s', $date->day, $self->fname),
    );
    if (my $up = $self->SUPER::from_root) {
        push @out, $up
    }
    @out
}

sub lookup {
    my ($self, $kind, $hint) = @_;

    if ($kind eq 'blog') {
        if ($hint eq 'yesterday') {
            return $self->prev;
        }
    }

    $self->SUPER::lookup(@_);
}

sub template_name() { 'entry' }

no Moose;
__PACKAGE__->meta->make_immutable;
