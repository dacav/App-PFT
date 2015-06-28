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
use File::Spec::Functions qw/catdir catfile no_upwards/;
use File::Path qw/make_path/;

use App::PFT::Struct::Conf qw/
    $ROOT
    $SITE_TITLE
    $SITE_URL
    $SITE_HOME
    $OUTPUT_ENC
/;
use App::PFT::Struct::Tree;
use App::PFT::Output::HTML;
use App::PFT::Util qw/ln/;

Getopt::Long::Configure ("bundling");

sub inject {
    my $tree = shift;
    my $inject = $tree->dir_inject;
    App::PFT::Util::ln
            catfile($inject, $_),
            catfile($tree->dir_build, $_),
            1
        foreach
            no_upwards
            map { substr($_, 1 + length $inject) }
        (
            glob(catfile $inject, '*'),
            glob(catfile $inject, '.*'),
        )
}

sub main {
    my $preview;
    GetOptions(
        'preview|p!' => \$preview,
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
        site_home => $tree->page(title => $SITE_HOME, -noinit => 1),
        base_url => $preview ? $tree->dir_build : $SITE_URL,
        outputenc => $OUTPUT_ENC || 'utf-8',
        pics_path => $tree->dir_pics,
        build_path => $tree->dir_build,
    );

    my $months = $tree->link_months;

    for my $e ($tree->list_entries, $tree->list_pages, @$months) {
        $html->process($e)
    }

    inject $tree;
}

1;
