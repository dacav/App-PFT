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
package App::PFT::Content::Base;

use strict;
use warnings;

use Carp;

use namespace::autoclean;
use Moose;

sub from_root() { undef }
sub has_prev() { 0 }
sub has_next() { 0 }
sub has_month() { 0 }
sub has_links() { 0 }
sub text() {''}
sub date() { undef };
sub hname() { confess "Undefined human name for ", shift }

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
