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
package App::PFT::Content::Blob;

use strict;
use warnings;

use File::Basename qw/basename/;
use Carp;

use namespace::autoclean;
use Moose;

extends 'App::PFT::Content::Base';

has fname => (
    is => 'ro',
    isa => 'Str',
);

has path => (
    is => 'ro',
    isa => 'Str',
);

has group => (
    is => 'ro',
    isa => 'Str',
);

sub hname { shift->fname }

sub from_root() {
    my $self = shift;
    my @out = (
        $self->group,
        $self->fname,
    );
    if (my $up = $self->SUPER::from_root) {
        push @out, $up
    }
    @out
}

around BUILDARGS => sub {
    my($orig, $class, %params) = @_;

    my $fn = $params{path};
    if ($params{'-verify'}) {
        croak "File $fn does not exist" unless -e $fn;
    }
    $params{fname} = basename $fn;
    
    $class->$orig(%params);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
