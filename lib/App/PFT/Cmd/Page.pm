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
package App::PFT::Cmd::Page;

=head1 NAME

pft page

=head1 SYNOPSYS

pft page ...

=cut

use strict;
use warnings;

use Exporter qw/import/;
use feature qw/say/;

use Pod::Usage;
use Pod::Find qw/pod_where/;

use App::PFT::Struct::Tree;
use App::PFT::Data::Date;

use Getopt::Long qw/GetOptionsFromArray/;

Getopt::Long::Configure qw/bundling/;

use App::PFT::Struct::Conf qw/$ROOT $AUTHOR/;

sub main {
    my %opts = (
        author => $AUTHOR,
    );
    my %datespec;
    GetOptions(
        'author|a=s'    => \$opts{author},
        'help|h!'       => sub {
            pod2usage
                -exitval => 1,
                -verbose => 2,
                -input => pod_where({-inc => 1}, __PACKAGE__)
            ;
        },
    );

    unless (@ARGV) {
        say STDERR "Usage: $0 page [options] <title>";
        exit 1;
    }

    my $tree = App::PFT::Struct::Tree->new(basepath => $ROOT);
    my $page = $tree->page(
        title => join(' ', @ARGV),
        %opts
    );

    $page->edit;
}

1;
