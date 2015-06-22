use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::PFT',
    AUTHOR           => q{Giovanni Simoni <dacav@openmailbox.org>},
    VERSION_FROM     => 'lib/App/PFT.pm',
    ABSTRACT_FROM    => 'lib/App/PFT.pm',
    LICENSE          => 'GNU GPL v3',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Text::MultiMarkdown'   => 0,
        'Template::Alloy'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'App-PFT-*' },
);
