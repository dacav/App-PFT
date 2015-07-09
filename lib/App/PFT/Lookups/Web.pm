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
package App::PFT::Lookups::Web;

use strict;
use warnings;

use Carp;

use Exporter qw/import/;
our @EXPORT_OK = qw/weblookup/;

sub search_duckduckgo {
    my $hints = shift;
    # hints[0] -> optional bang
    # hints[1..] -> query parts

    my $bang = shift @$hints;

    my $url = 'https://duckduckgo.com/lite/?q=';
    $url .= '%21' . $bang if $bang;
    unshift @$hints, $url;
    join "%20", @$hints;
}

sub weblookup {
    my $hints = shift;
    my $service = shift @$hints;

    if ($service eq 'ddg') {
        return search_duckduckgo $hints;
    }

    croak "Web-lookup: Unknown service $service ($service @$hints)";
}

1;

