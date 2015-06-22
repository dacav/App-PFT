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

use Carp;

sub main {
    pod2usage
        -exitval => 1,
        -verbose => 2,
        -input => pod_where({-inc => 1}, __PACKAGE__)
    ;
}

1;
