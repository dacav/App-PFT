use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

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
        'Getopt::Long'      => 0,
        'IO::File'          => 0,
        'PFT'               => 0,
        'Template::Alloy'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PFT-*' },
);
