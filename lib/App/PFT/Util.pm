package App::PFT::Util;

use strict;
use warnings;

BEGIN {
    require Exporter;

    our $VERSION     = 1.00;
    our @ISA         = qw/Exporter/;
    our @EXPORT;
    our @EXPORT_OK   = qw/groupby ln/;
}

use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree/;

sub ln ($$) {
    # Not clear which modern system doesn't support symlinks. I think even
    # Windows does that. ...anyway....
    eval { symlink $_[0], $_[1]; 1 } or do {
        print STDERR "Cannot symlink $_[0] to $_[1]: $@. Hard-copying it\n";
        remove_tree $_[1], {verbose => 1};
        dircopy @_;
    }
}

sub groupby(&@) {
    my $getkey = shift;
    my %groups;

    for my $item (@_) {
        my $k = do {
            local $_ = $item;
            &$getkey();
        };
        push @{$groups{$k}}, $item;
    }

    wantarray ? %groups : \%groups;
}

1;

