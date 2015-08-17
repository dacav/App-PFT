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
package App::PFT::Content::Base v0.03.1;

use strict;
use warnings;

use Carp;

use Moose::Role;
use namespace::autoclean;

requires qw/
    title
    date
    tostr
    from_root
/;

use overload
    '""' => "tostr",
    cmp => sub {
        my @selfroot = shift()->from_root;
        my @othroot = shift()->from_root;
        my $N = @selfroot > @othroot ? @othroot : @selfroot;
        my $neg = shift() ? 1 : -1;
        for (my $i = 0; $i < $N; $i ++) {
            my $cmp = $selfroot[$i] cmp $othroot[$i];
            return $cmp * $neg if $cmp;
        }
        @selfroot > @othroot ?  $neg :
        @selfroot < @othroot ? -$neg :
                               0     ;
    },
;

# Universally identify the content. Incidentally the filesystem already
# does it, so if we just join from_root over '/' we get an unique
# identifier for the content, site-wise.
has uid => (
    isa => 'Str',
    is => 'ro',
    lazy => 1,
    default => sub {
        join '/', shift->from_root
    },
);

has tree => (
    isa => 'App::PFT::Struct::Tree',
    is => 'ro',
    weak_ref => 1,
    required => 1,
);

no Moose;
1;
