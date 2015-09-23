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
package App::PFT::Content::Blob v0.04.1;

use strict;
use warnings;

use File::Basename qw/basename/;
use Carp;

use namespace::autoclean;
use Moose;

extends qw/
    App::PFT::Content::File
/;

has group => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
);

sub tostr {
    'Blob(' . shift->fname . ')'
}

sub title {
    shift->fname
}

sub date {
    undef
}

sub from_root {
    my $self = shift;
    (
        @{$self->group},
        $self->fname,
    )
}

with qw/
    App::PFT::Content::Base
/;

no Moose;
__PACKAGE__->meta->make_immutable;

1;
