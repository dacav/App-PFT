package App::PFT::Cmd::Clean;

=head1 NAME

pft clean

=head1 SYNOPSYS

pft clean ...

=cut

use strict;
use warnings;

use Exporter qw/import/;
use feature qw/say/;

use Pod::Usage;
use Pod::Find qw/pod_where/;

use App::PFT::Struct::Conf qw/$ROOT/;
use App::PFT::Struct::Tree;
use App::PFT::Util qw/ln/;

use File::Path;
use Getopt::Long;

Getopt::Long::Configure ("bundling");

sub main {
    my $verbose = 0;
    GetOptions(
        'verbose|v' => \$verbose,
        'help|h' => sub {
            pod2usage
                -exitval => 1,
                -verbose => 2,
                -input => pod_where({-inc => 1}, __PACKAGE__)
            ;
        }
    ) or exit 1;

    my $tree = App::PFT::Struct::Tree->new(
        basepath => $ROOT
    );

    File::Path::rmtree
        $tree->dir_build,
        { verbose => $verbose }
    ;
}

1;
