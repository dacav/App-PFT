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
package App::PFT::Content::File v0.05.2;

use strict;
use warnings;

use Carp;

use Moose;
use namespace::autoclean;

use File::Basename qw/basename dirname/;
use File::Path qw/make_path/;

has path => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

has fname => (
    isa => 'Str',
    is => 'ro',
    lazy => 1,
    default => sub { basename shift->path },
);

sub mtime {
    (stat shift->path)[9];
}

sub open {
    my $path = shift->path;
    my $mode = shift;
    make_path dirname $path if $mode =~ /w|a/;
    IO::File->new($path, $mode) or croak "Cannot open $path: $!"
}

sub touch {
    shift->open('a')
};

sub exists {
    -e shift->path
}

around BUILDARGS => sub {
    my($orig, $self, %opts) = @_;
    if (delete $opts{'-verify'} && ! -e $opts{path}) {
        croak "File $opts{path} does not exist";
    }
    my $create = delete $opts{'-create'};
    my $out = $self->$orig(%opts);
    $out->open('w') if $create && !$out->exists;

    $out;
};

no Moose;
1;
