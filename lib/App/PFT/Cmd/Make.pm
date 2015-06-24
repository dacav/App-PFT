package App::PFT::Cmd::Make;

=head1 NAME

pft compile

=head1 SYNOPSYS

pft compile ...

=cut

use strict;
use warnings;

use Exporter qw/import/;
use feature qw/say/;

use Pod::Usage;
use Pod::Find qw/pod_where/;

use Getopt::Long;
use File::Spec::Functions qw/catdir catfile/;
use File::Path qw/make_path/;

use App::PFT::Struct::Conf qw/$ROOT $SITE_TITLE $SITE_URL $OUTPUT_ENC/;
use App::PFT::Struct::Tree;
use App::PFT::Output::HTML;

Getopt::Long::Configure ("bundling");

sub main {
    my %opts;
    GetOptions(
        'preview|p!' => \$opts{preview},
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

    my $html = App::PFT::Output::HTML->new(
        template_dirs => [
            $tree->dir_templates,
        ],
        site_title => $SITE_TITLE,
        # site_footer => $ENV{SITE_FOOTER},
        base_url => $opts{preview} ? $tree->dir_build : $SITE_URL,
        outputenc => $OUTPUT_ENC || 'utf-8',
        pics_path => $tree->dir_pics,
        build_path => $tree->dir_build,
    );

    my $months = $tree->link_months;

    my %vars;
    for my $e ($tree->list_entries, $tree->list_pages, @$months) {
        $html->process($e)
    }
}

1;
