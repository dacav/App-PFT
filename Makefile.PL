use v5.16;
use strict;
use warnings;
use utf8;

use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share module => 'App::PFT', 'share';

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
        'ExtUtils::MakeMaker'   => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'            => 0,
    },
    PREREQ_PM => {
        'Carp'                  => 0,
        'Cwd'                   => 0,
        'Encode'                => 0,
        'Encode::Locale'        => 0,
        'Exporter'              => 0,
        'File::Basename'        => 0,
        'File::Copy'            => 0,
        'File::Copy::Recursive' => 0,
        'File::Path'            => 0,
        'File::ShareDir'        => 0,
        'File::Spec'            => 0,
        'File::Spec::Functions' => 0,
        'FindBin'               => 0,
        'Getopt::Long'          => 0,
        'LWP::Simple'           => 0,
        'Pod::Find'             => 0,
        'Pod::Usage'            => 0,
        'Template::Alloy'       => 0,
        'URI'                   => 0,

        'PFT'                   => v0.5.2,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'PFT-*' },
);

package MY;
use File::ShareDir::Install qw/postamble/;
