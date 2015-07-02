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
package App::PFT::Content::TagPage;

use strict;
use warnings;

use Scalar::Util qw/weaken/;

use namespace::autoclean;
use Moose;

extends 'App::PFT::Content::Base';

sub hname {
    'Tag: ' . shift->tagname;
}

has tagname => ( is=>'ro', isa => 'Str' );

has links => (
    is => 'rw',
    isa => 'ArrayRef[App::PFT::Content::Entry]',
    lazy => 1,
    default => sub{[]},
    predicate => 'has_links',
);

sub add_content {
    my $self = shift;
    my $links = $self->links;
    for my $e (@_) {
        push @$links, $e;
        weaken $links->[$#$links];
    }
}

sub from_root() {
    my $self = shift;
    my @out = (
        'tags',
        $self->tagname
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
            title => $self->hname
        );
    }
);

sub title() { shift->hname }

no Moose;
__PACKAGE__->meta->make_immutable;

1;

