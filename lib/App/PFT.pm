package App::PFT v1.0.1;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/$Name $ConfName/;

our $Name = 'pft';
our $ConfName = 'pft.yaml';
our $NoInitMsg = "Not a $Name site. Try running: $Name init";

use FindBin;
use File::Spec;

sub help_of {
    File::Spec->catfile($FindBin::RealBin, join '-', $Name, @_);
}

1;
