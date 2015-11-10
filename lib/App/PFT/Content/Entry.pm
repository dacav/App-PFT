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
package App::PFT::Content::Entry v0.05.1;

use strict;
use warnings;

use Carp;

use namespace::autoclean;
use Moose;

extends qw/
    App::PFT::Content::Text
    App::PFT::Content::Linked
/;

has date => (
    is => 'ro',
    isa => 'App::PFT::Data::Date',
    required => 1,
);

sub month {
    my $self = shift;
    $self->tree->month(date => $self->date);
}

sub tostr {
    my $self = shift;
    'Entry(' . $self->fname . ', ' . $self->date->repr . ')';
}

sub from_root {
    my $self = shift;
    my $date = $self->date;
    (
        'blog',
        sprintf('%04d-%02d', $date->year, $date->month),
        $self->fname,
    )
}

sub lookup {
    my $self = shift;
    my($kind, @hints) = @_;

    if ($kind eq 'blog') {
        if ($hints[0] eq 'back') {
            my $prev = $self->prev;
            my $jumps = $hints[1];
            while ($jumps && $prev) {
                $prev = $prev->prev;
                $jumps --;
            }
            unless (defined $prev) {
                croak 'Cannot reach ', $hints[0],
                    ': nothing after ', $hints[1] - $jumps, ' steps';
            }
            return $prev;
        }
    }

    $self->SUPER::lookup(@_);
}

with qw/
    App::PFT::Content::Base
/;

no Moose;
__PACKAGE__->meta->make_immutable;
