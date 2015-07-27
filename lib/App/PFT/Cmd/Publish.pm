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
package App::PFT::Cmd::Publish;

=head1 NAME

pft publish

=head1 SYNOPSYS

pft publish ...

=cut

use strict;
use warnings;

use Exporter qw/import/;
use feature qw/say/;

use Pod::Usage;
use Pod::Find qw/pod_where/;

use File::Spec::Functions qw/catfile/;

use App::PFT::Struct::Conf qw/$ROOT %REMOTE/;
use App::PFT::Struct::Tree;

use Carp;

use Getopt::Long;
Getopt::Long::Configure 'bundling';

sub rsync_ssh {
    my $tree = shift;

    my $src = catfile($tree->dir_build, '');
    my $dst = "$REMOTE{User}\@$REMOTE{Host}:$REMOTE{Path}";

    # Checks here maybe...

    say STDERR 'Sending with RSync, from ', $src, ' to ', $dst;

    system('rsync',
        '--recursive',
        '--verbose',
        '--copy-links',
        '--times',
        '--delete',
        '--human-readable',
        '--progress',
        $src, $dst,
    );
}

sub main {
    GetOptions(
        'help|h' => sub {
            pod2usage
                -exitval => 1,
                -verbose => 2,
                -input => pod_where({-inc => 1}, __PACKAGE__)
            ;
        }
    ) or exit 1;

    my $method = {
        'rsync+ssh' => \&rsync_ssh,
    }->{$REMOTE{Method}};
    die 'Unknown method ', $REMOTE{Method} unless $method;

    my $tree = App::PFT::Struct::Tree->new( basepath => $ROOT);
    $method->($tree);
}

1;
