package App::PFT::Launcher v0.05.2;

use strict;
use warnings;

use App::PFT::Struct::Conf qw/%SYSTEM/;

use Exporter 'import';
our @EXPORT_OK = qw(browser editor);

sub browser {
    my $cmd = shift;

    if (!defined $cmd && exists $ENV{BROWSER}) {
        $cmd = $ENV{BROWSER};
    }
    if (!defined $cmd && exists $SYSTEM{Browser}) {
        $cmd = $SYSTEM{Browser};
    }
    unless (defined $cmd) {
        undef;
    }
    elsif (index($cmd, '%s') >= 0) {
        sub { system(sprintf $cmd, @_) }
    }
    else {
        sub { system($cmd, @_) }
    }
}

sub editor {
    my $cmd = shift;

    if (!defined $cmd && exists $SYSTEM{Editor}) {
        $cmd = $SYSTEM{Editor};
    }
    if (!defined $cmd && exists $ENV{EDITOR}) {
        $cmd = $ENV{EDITOR};
    }

    unless (defined $cmd) {
        undef;
    }
    elsif (index($cmd, '%s') >= 0) {
        sub { system(sprintf $cmd, @_) }
    }
    else {
        sub { system($cmd, @_) }
    }
}

1;

