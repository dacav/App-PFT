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
package App::PFT::Content::Linked v0.03.1;

use strict;
use warnings;

use Carp;

use Moose;
use namespace::autoclean;

use Scalar::Util qw/weaken/;

has root => (
    is => 'rw',
    weak_ref => 1,
    predicate => 'has_root',
);

has prev => (
    is => 'rw',
    weak_ref => 1,
    predicate => 'has_prev',
);

has next => (
    is => 'rw',
    weak_ref => 1,
    predicate => 'has_next',
);

has links => (
    is => 'ro',
    isa => 'HashRef',
    default => sub {{}},
);

sub has_links {
    scalar keys %{shift->links};
}

sub add_link {
    my $links = shift->links;
    my $content = shift;
    $links->{$content->uid} = $content;
    weaken $links->{$content->uid};
}

sub list_links {
    wantarray ? values %{shift->links} : [ values %{shift->links} ];
}

no Moose;
1;
