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

use App::PFT;

use Exporter qw/import/;
our @EXPORT_OK = qw/
    $ROOT
    $AUTHOR
    $TEMPLATE
    $SITE_TITLE
    $SITE_URL
    $HOME_PAGE
    %REMOTE
    $INPUT_ENC
    $OUTPUT_ENC
    cfg_is_loaded
    cfg_load
    cfg_dump
    cfg_default
/;
# Adding more configuration variables? Mind adding configs also as option.
# See App::PFT::Cmd::Init command.

our $ROOT;

our $AUTHOR;
our $TEMPLATE;
our $SITE_TITLE;
our $SITE_URL;
our $HOME_PAGE;
our %REMOTE;
our $INPUT_ENC;
our $OUTPUT_ENC;

sub cfg_default {
    $AUTHOR = $ENV{USER} || 'John Doe';
    $TEMPLATE = 'default';
    $SITE_TITLE = "My $App::PFT::Name website";
    $SITE_URL = 'http://example.org/';
    $HOME_PAGE = 'Welcome';
    %REMOTE = (
        Method => 'rsync+ssh',
        Host => 'example.org',
        User => 'user',
        Path => '/home/user/public-html/whatever',
    );
    $INPUT_ENC = $OUTPUT_ENC = 'utf-8';
}

sub cfg_dump {
    $ROOT = shift;
    DumpFile catfile($ROOT, $App::PFT::ConfName), {
        Author => $AUTHOR,
        Template => $TEMPLATE,
        SiteTitle => $SITE_TITLE,
        SiteURL => $SITE_URL,
        HomePage => $HOME_PAGE,
        Remote => \%REMOTE,
        InputEnc => $INPUT_ENC,
        OutputEnc => $OUTPUT_ENC,
    };
}

sub check_assign {
    my $cfg = shift;

    my @out;
    for my $name (@_) {
        my $val = $cfg;
        my $optional = $name =~ /\?$/;
        foreach (split /\./, $optional ? substr($name, 0, -1) : $name) {
            $val = $val->{$_};
            last unless $val
        }
        croak "Configuration $name is missing" unless defined($val) || $optional;
        push @out, $val;
    }

    @out;
}

sub cfg_is_loaded { defined $ROOT }

sub cfg_load {
    $ROOT = shift;
    my $cfg = LoadFile (catfile $ROOT, $App::PFT::ConfName);

    (
        $AUTHOR,
        $TEMPLATE,
        $SITE_TITLE,
        $SITE_URL,
        $HOME_PAGE,
        $REMOTE{Method},
        $REMOTE{Host},
        $REMOTE{User},
        $REMOTE{Path},
        $REMOTE{Port},
        $INPUT_ENC,
        $OUTPUT_ENC,
    ) = check_assign $cfg,
        'Author',
        'Template',
        'SiteTitle',
        'SiteURL',
        'HomePage',
        'Remote.Method',
        'Remote.Host?',
        'Remote.User?',
        'Remote.Path?',
        'Remote.Port?',
        'InputEnc',
        'OutputEnc',
    ;

    $SITE_URL =~ s/\/*$//;
}

1;
