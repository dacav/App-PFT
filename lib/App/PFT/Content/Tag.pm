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
package App::PFT::Content::Tag v0.05.1;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use App::PFT::Util;

extends 'App::PFT::Content::Linked';

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub date {
    undef
}

sub title {
    shift->name
}

sub from_root {
    (
        'tag',
        App::PFT::Util::slugify(shift->name),
    )
}

sub tostr {
    sprintf 'Tag(' . shift->name . ')'
}

sub create {
    my $self = shift;
    $self->tree->tag(
        name => $self->name,
        -create => 1,
        @_,
    )
}

with qw/
    App::PFT::Content::Base
    App::PFT::Content::Virtual
/;

no Moose;
__PACKAGE__->meta->make_immutable;

1;
