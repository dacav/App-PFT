package App::PFT v0.05.2;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/$Name $ConfName findroot/;

use App::PFT::Util;

use FindBin;
use File::Spec::Functions qw/catfile/;
use Carp;

# Application Constants

our $Name = 'pft';
our $ConfName = 'pft.yaml';
our $NoInitMsg = "Not a $Name site. Try running: $Name init";

sub help_of {
    catfile $FindBin::RealBin, join '-', $Name, @_
}

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
