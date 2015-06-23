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
use Carp;

Getopt::Long::Configure qw/bundling/;

use App::PFT::Struct::Conf qw/$ROOT/;

sub main {
    my %opts;
    my %datespec;
    GetOptions(
        'year|y=i'  => \$datespec{year},
        'month|m=s' => \$datespec{month},
        'day|d=i'   => \$datespec{day},
        'hide=s'    => \$opts{'-hide'},
        'help|h!'   => sub {
            pod2usage
                -exitval => 1,
                -verbose => 2,
                -input => pod_where({-inc => 1}, __PACKAGE__)
            ;
        },
    );

    my $tree = App::PFT::Struct::Tree->new(basepath => $ROOT);
    my $entry = $tree->entry(
        title => join(' ', @_),
        date => App::PFT::Data::Date->new(
            %datespec,
            -fill => 'now',
        ),
        %opts
    );

    $entry->edit;
}

1;
