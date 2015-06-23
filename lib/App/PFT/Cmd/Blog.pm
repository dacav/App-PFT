package App::PFT::Cmd::Blog;

=head1 NAME

pft blog

=head1 SYNOPSYS

pft blog ...

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
        'year|y=i'      => \$datespec{year},
        'month|m=s'     => \$datespec{month},
        'day|d=i'       => \$datespec{day},
        'hide=s'        => \$opts{hide},
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
        say STDERR "Usage: $0 blog [options] <title>";
        exit 1;
    }

    my $tree = App::PFT::Struct::Tree->new(basepath => $ROOT);
    my $entry = $tree->entry(
        title => join(' ', @ARGV),
        date => App::PFT::Data::Date->new(
            %datespec,
            -fill => 'now',
        ),
        %opts
    );

    $entry->edit;
}

1;
