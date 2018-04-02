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
package App::PFT::Filters v1.2.2;

use strict;
use warnings;
use v5.16;

use Exporter qw(import);
our @EXPORT_OK = qw(%filters);

sub yaml_indent {
    my($text, $indent, $opts) = @_;

    return undef unless defined $text;

    my $spaces = ' ' x $indent;
    $text =~ s/^\s*/$spaces/mge;

    # Optionally the first line can be chopped away. This is useful if the
    # filter is applied to some indented line. Disabled by default.
    if (exists($opts->{chop_first}) && $opts->{chop_first}) {
        $text =~ s/^\s+//;
    }

    return $text;
}

our %filters = (
    yaml_indent => \&yaml_indent,
);

1;
