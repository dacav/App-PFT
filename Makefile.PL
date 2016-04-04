use v5.16;
use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
    NAME             => 'PFT',
    AUTHOR           => q{Giovanni Simoni (dacav at openmailbox)},
    VERSION_FROM     => 'lib/App/PFT.pm',
    ABSTRACT         => 'Hacker friendly static blog generator',
    LICENSE          => 'GNU GPL v3',
    PL_FILES         => {},
    EXE_FILES        => [grep { -x } glob 'bin/*'],
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'        => 0,
    },
    PREREQ_PM => {
        'Carp'              => 0,
        'Encode'            => 0,
        'Pod::Find'         => 0,
        'File::Basename'    => 0,
        'File::Copy'        => 0,
        'File::Path'        => 0,
        'File::Spec'        => 0,
        'File::ShareDir'    => 0,
        'File::Share'       => 0,
        'Getopt::Long'      => 0,
        'IO::File'          => 0,
        'PFT'               => 0,
        'LWP::Simple'       => 0,
        'Template::Alloy'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PFT-*' },
);

package MY;
use File::ShareDir::Install qw/postamble/;
