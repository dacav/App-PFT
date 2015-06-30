# Copyright 2014 - Giovanni Simoni
#
# This file is part of PFT.
#
# PFT is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your
# option) any later version.
#
# PFT is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with PFT.  If not, see <http://www.gnu.org/licenses/>.
#
package App::PFT::Struct::Conf;

use strict;
use warnings;

use YAML::Tiny qw/DumpFile LoadFile/;
use File::Basename qw/basename/;
use File::Spec::Functions qw/catfile/;

use Carp;

use Exporter qw/import/;
our @EXPORT_OK = qw/
    $ROOT
    $CONF_FILENAME
    $AUTHOR
    $SITE_TITLE
    $SITE_URL
    $SITE_HOME
    $SITE_LOGIN
    $SITE_PATH
    $INPUT_ENC
    $OUTPUT_ENC
    cfg_load
    cfg_dump
    cfg_default
/;


our $CONF_FILENAME = basename($0) . '.yaml';
our $ROOT;

our $AUTHOR;
our $SITE_TITLE;
our $SITE_URL;
our $SITE_HOME;
our $SITE_LOGIN;
our $SITE_PATH;
our $INPUT_ENC;
our $OUTPUT_ENC;

sub cfg_default {
    $AUTHOR = $ENV{USER} || 'John Doe';
    $SITE_TITLE = "My $0 website";
    $SITE_URL = 'http://example.org/';
    $SITE_HOME = 'Welcome';
    $SITE_LOGIN = 'user@example.org';
    $SITE_PATH = '/home/user/public-html/whatever';
    $INPUT_ENC = $OUTPUT_ENC = 'utf-8';
}

sub cfg_dump {
    DumpFile catfile(shift, $CONF_FILENAME), {
        Author => $AUTHOR,
        SiteTitle => $SITE_TITLE,
        SiteURL => $SITE_URL,
        SiteHome => $SITE_HOME,
        SiteLogin => $SITE_LOGIN,
        SitePath => $SITE_PATH,
        InputEnc => $INPUT_ENC,
        OutputEnc => $OUTPUT_ENC,
    };
}

sub check_assign {
    my $cfg = shift;

    my @out;
    for my $name (@_) {
        my $val = $cfg->{$name};
        croak "Configuration $name is missing" unless $val;
        push @out, $val;
    }

    @out;
}

sub cfg_load {
    $ROOT = shift;
    my $cfg = LoadFile (catfile $ROOT, $CONF_FILENAME);

    (
        $AUTHOR,
        $SITE_TITLE,
        $SITE_URL,
        $SITE_HOME,
        $SITE_LOGIN,
        $SITE_PATH,
        $INPUT_ENC,
        $OUTPUT_ENC,
    ) = check_assign $cfg,
        'Author',
        'SiteTitle',
        'SiteURL',
        'SiteHome',
        'SiteLogin',
        'SitePath',
        'InputEnc',
        'OutputEnc',
    ;

    $SITE_URL =~ s/\/*$//;
}

1;
