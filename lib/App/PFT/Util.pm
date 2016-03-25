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
package App::PFT::Util v0.03.2;

use strict;
use warnings;

use Exporter qw/import/;
our @EXPORT_OK = qw/
    ln
/;

use Carp;

use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree/;
use File::Spec::Functions qw/updir catfile catdir rootdir/;
use Cwd qw/abs_path cwd/;

sub ln {
    if ($_[2]) {
        print STDERR "Linking $_[1] -> $_[0]\n";
    }
    # Not clear which modern system doesn't support symlinks. I think even
    # Windows does that. ...anyway....
    eval { symlink $_[0], $_[1]; 1 } or do {
        print STDERR "Cannot symlink $_[0] to $_[1]: $@. Hard-copying it\n";
        remove_tree $_[1], {verbose => 1};
        dircopy @_;
    }
}

1;
