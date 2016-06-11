package App::PFT v1.0.1;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/$Name $ConfName $VersionString/;

our $Name = 'pft';
our $ConfName = 'pft.yaml';
our $NoInitMsg = "Not a $Name site. Try running: $Name init";
our $VersionString = <<EOF;
PFT v 1.0.1  Copyright (C) 2016  Giovanni Simoni
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions; see the source code for details.
EOF

use FindBin;
use File::Spec;

sub help_of {
    File::Spec->catfile($FindBin::RealBin, join '-', $Name, @_);
}

1;
