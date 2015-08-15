package App::PFT v0.03.0;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/$Name $ConfName/;

# Application Constants

our $Name = 'pft';
our $ConfName = 'pft.yaml';
our $NoInitMsg = "Not a $Name site. Try running: $Name init";

1;
