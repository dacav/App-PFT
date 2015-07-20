# Copyright 2014 - Giovanni Simoni
#
# This file is part of PFT.
#
# PFT is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# PFT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PFT.  If not, see <http://www.gnu.org/licenses/>.
#
package App::PFT::Content::MonthPage;

use strict;
use warnings;

use Scalar::Util qw/weaken/;

use namespace::autoclean;
use Moose;

has year => (
    is=>'ro',
    isa => 'Int',
);

has month => (
    is=>'ro',
    isa => 'Int',
);

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
    (
        'blog',
        sprintf('%04d-%02d', $self->year, $self->month),
    );
}

has header => (
    is => 'ro',
    isa => 'App::PFT::Data::Header',
    lazy => 1,
    default => sub {
        my $self = shift;
        App::PFT::Data::Header->new(
            title => sprintf('%04d / %02d', $self->year, $self->month),
        );
    }
);

sub tostr {
    my $self = shift;
    sprintf 'MonthPage(%04d/%02d)', $self->year, $self->month
}

sub title() { shift->header->title }
sub has_month() { 0 }
sub date() { undef }
sub text { '' }

with 'App::PFT::Content::Base';

no Moose;
__PACKAGE__->meta->make_immutable;

1;

