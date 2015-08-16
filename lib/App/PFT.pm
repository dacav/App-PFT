package App::PFT v0.03.0;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/$Name $ConfName findroot/;

use App::PFT::Util;
use Carp;

# Application Constants

our $Name = 'pft';
our $ConfName = 'pft.yaml';
our $NoInitMsg = "Not a $Name site. Try running: $Name init";

sub findroot {
    my %opts = @_;
    my $out = App::PFT::Util::findroot(
        type => 'file',
        name => $ConfName
    );
    croak $NoInitMsg if (!defined($out) and $opts{'-die'});
    $out;
}

1;
