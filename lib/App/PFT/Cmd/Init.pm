package App::PFT::Cmd::Init;

=head1 NAME

pft init

=head1 SYNOPSYS

pft init 

=cut

use strict;
use warnings;

use IO::File;

use App::PFT::Struct::Tree;
use App::PFT::Struct::Conf qw/cfg_dump/;

use Exporter qw/import/;
use feature qw/say/;

use Pod::Usage;
use Pod::Find qw/pod_where/;

use Carp;

sub help {
    pod2usage
        -exitval => 1,
        -verbose => 2,
        -input => pod_where({-inc => 1}, __PACKAGE__)
    ;
}

sub main {
    App::PFT::Struct::Tree->new(basepath => '.');
}

1;
