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
package App::PFT::Data::Date;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

use overload
    '""' => sub { 'Date(' . shift->repr . ')' },
;

has year => (
    is => 'ro',
    isa => 'Int',
    predicate => 'has_year',
);

has month => (
    is => 'ro',
    isa => 'Int',
    predicate => 'has_month',
);

has day => (
    is => 'ro',
    isa => 'Int',
    predicate => 'has_day',
);

sub is_complete {
    my $self = shift;
    $self->has_year && $self->has_month && $self->has_day;
}

sub repr {
    my $self = shift;
    join
        do { my $sep = shift; defined $sep ? $sep : '-' },
        ($self->has_year ? sprintf('%04d', $self->year) : '*'),
        ($self->has_month ? sprintf('%02d', $self->month) : '*'),
        ($self->has_day ? sprintf('%02d', $self->day) : '*')
    ;
}

sub to_hash {
    my $self = shift;
    {
        y => $self->year,
        m => $self->month,
        d => $self->day,
    }
}

my %MONTHS = (
    ja  => 1,
    f   => 2,
    mar => 3,
    ap  => 4,
    may => 5,
    jun => 6,
    jul => 7,
    au  => 8,
    s   => 9,
    o   => 10,
    n   => 11,
    d   => 12,
);

my %FILLS = (
    now => sub {
        (localtime)[5,4,3]
    },

    # yesterday => sub {...}
);

around BUILDARGS => sub {
    my ($orig,$class,%params) = @_;

    if (my $fill = $params{'-fill'}) {
        my ($y, $m, $d) = do {
            my $cb = $FILLS{$fill};
            die ('Unknown fill method ' . $fill) unless $cb;
            $cb->(@{$params{'-fill-args'} || []});
        };
        $params{year} = $y + 1900 unless $params{year};
        $params{month} = $m + 1 unless $params{month};
        $params{day} = $d unless $params{day};
    }

    if ((my $m = $params{month}) !~ m/^\d{1,2}$/) {
        $m =~ s/^(j(?:a|u[nl])|[fsond]|ma[ry]|a[pu]).*/$MONTHS{$1}/e
            or die "Invalid month: $m";
        $params{month} = $m;
    } else {
        die "Invalid month: $m" unless ($m >= 1 && $m <= 12);
    }

    if (my $d = $params{day}) {
        die "Invalid day: $d" if ($d !~ m/^\d{1,2}$/ || $d < 1 || $d > 31);
    }

    return $class->$orig(%params);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
