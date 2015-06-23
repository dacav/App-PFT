package App::PFT::Util;

use strict;
use warnings;

use Exporter qw/import/;
our @EXPORT_OK = qw/groupby ln findroot/;

use Carp;

use File::Copy::Recursive qw/dircopy/;
use File::Path qw/remove_tree/;
use File::Spec::Functions qw/updir catfile catdir rootdir/;
use Cwd qw/abs_path cwd/;

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

sub findroot {
    my %opts = @_;

    my $name = $opts{name};
    croak "Missing name" unless $name;
    my $cur = $opts{start} || cwd;
    my $cat = do {
        my $type = $opts{type};
        $type eq 'file' ? \&catfile :
        $type eq 'dir'  ? \&catdir :
        croak "Unsupported type $type";
    };

    while ($cur ne rootdir) {
        my $attempt = $cat->($cur, $name);
        return $cur if -e $attempt;
        $cur = abs_path catdir $cur, updir;
    }

    undef
}

1;
