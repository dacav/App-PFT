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
package App::PFT::Content::Month;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

use App::PFT::Data::Date;

has date => (
    is => 'ro',
    isa => 'App::PFT::Data::Date',
    required => 1,
);

has title => (
    is => 'ro',
    isa => 'Str',
    lazy => 1,
    default => sub {
        my $self = shift;
        sprintf('%04d-%02d', $self->year, $self->month)
    },
);

sub from_root() {
    my $self = shift;
    (
        'blog',
        sprintf('%04d-%02d', $self->year, $self->month),
    );
}

sub tostr {
    my $self = shift;
    sprintf 'Month(%04d/%02d)', $self->date->year, $self->date->month
}

sub template {
    'gen'
}

sub create {
    my $self = shift;
    $self->tree->month(
        date => $self->date,
        -create => 1,
        @_,
    )
}

around BUILDARGS => sub {
    my ($orig, $class, %params) = @_;

    if (my $date = $params{date}) {
        $params{date} = $date->derive(day => undef) if $date->is_complete
    } else {
        $params{date} = App::PFT::Data::Date->new(
            year => delete $params{year},
            month => delete $params{month},
        );
    }

    return $class->$orig(%params);
};

with qw/
    App::PFT::Content::Base
    App::PFT::Content::Linked
    App::PFT::Content::Virtual
/;

no Moose;
__PACKAGE__->meta->make_immutable;

1;
