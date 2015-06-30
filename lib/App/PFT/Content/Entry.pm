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
package App::PFT::Content::Entry;

use strict;
use warnings;

use Carp;

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

sub hname {
    my $self = shift;
    'Entry "' . $self->fname . '" (' . $self->date->repr . ')';
}

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
    my $self = shift;
    my($kind, $hint) = @_;

    if ($kind eq 'blog') {
        if (my($jumps) = $hint =~ m|back(?:/(\d+))?|) {
            my $prev = $self->prev;
            my $done = 0;
            while ($jumps && $prev) {
                $prev = $prev->prev;
                $jumps --;
                $done ++;
            }
            unless (defined $prev) {
                croak "Cannot reach $hint: nothing after $done steps";
            }
            return $prev;
        }
    }

    $self->SUPER::lookup(@_);
}

sub template_name() { 'entry' }

no Moose;
__PACKAGE__->meta->make_immutable;
