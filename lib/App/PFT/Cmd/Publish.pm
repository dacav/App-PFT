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

use App::PFT::Struct::Conf qw/$ROOT $SITE_LOGIN $SITE_PATH/;
use App::PFT::Struct::Tree;

use Carp;

use Getopt::Long;
Getopt::Long::Configure ("bundling");

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

    my $tree = App::PFT::Struct::Tree->new(
        basepath => $ROOT
    );
    my $src = catfile($tree->dir_build, '');
    my $dst = "$SITE_LOGIN:$SITE_PATH";

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

1;
