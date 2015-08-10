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
package App::PFT::Cmd::Init;

=head1 NAME

pft init - Initialize a PFT Site

=head1 SYNOPSYS

pft init [<options>]

=head1 DESCRIPTION

Initialize a PFT Site.

The command generates the C<pft.yaml> configuration file, creates the
filesystem structure for a PFT site, a site Home Page and the site
templates.

A test configuration is provided by default, and can be later modified by
editing the be modified by editing the C<pft.yaml> configuration file.

The C<pft init> command accepts options which will override the default
configuration. The options are listed in this document (see
B<CONFIGURATION OPTIONS>)

The C<pft init> command can also be used to override an existing
configuration by running it on a site which was already initialized.
The existing configuration will be respected, except for the overriden
keys.

=head1 OPTIONS

=over

=item --no-home

Skip Home Page generation.

=item --help | -h

Show this help page.

=back

=head1 CONFIGURATION OPTIONS

=over

=item --author

Specify a C<Author> configuration.

The C<Author> value will be used as default C<Author> for all new content
files.

=item --site-title

Specify a C<SiteTitle> configuration.

The C<SiteTitle> value will be accessible by the template engine, so the
title can be shown on all pages.

=item --site-url

Specify a C<SiteURL> configuration.

C<SiteURL> is the base URL for the site. This will be used as prefix for
all internal URLs. You probably want to specify something like
C<http://example.org/path/to/site/>. Since B<pft> will not try to guess
your protocol scheme, you should put it right.

=item --home-page

Specify a C<HomePage> configuration.

C<HomePage> declares a Home Page for the site. The page will be generated
automatically unless it exists already or the C<--no-home> is used.

=item --input-enc

Specify a C<InputEnc> configuration.

C<InputEnc> declares the default encoding for content files. The encoding
of single content files can be redefined by editing their header.

=item --output-enc

Specify a C<OutputEnc> configuration.

C<OutputEnc> declares the encoding for output HTML files.

=item --remote-method

Specify a C<Remote.Method> configuration.

C<Remote.Method> indicates how to upload the compiled content onto a
remote machine. Current valid values are:

=over

=item * C<rsync+ssh> (default): Use I<RSync> over I<SSH> for sending files.

=back

=item --remote-host

Specify a C<Remote.Host> configuration.

C<Remote.Host> is optional, and declares the host name (or ip address) of
the remote machine hosting the website. The selected remote method
(C<--remote-method> option) may require this configuration.

=item --remote-port

Specify a C<Remote.Port> configuration.

C<Remote.Port> is optional, and declares a port on the remote machine
where a file upload service is running. The value may be used as parameter
for different transport protocols, depending on the C<--remote-method> in
use. Sensible defaults are assumed unless diffrently specified.

For instance, if using C<--remote-method=rsync+ssh>, the C<Remote.Port>
configuration will be used to determine the I<SSH> port, and will default
to 22.

=item --remote-user

Specify a C<Remote.User> configuration.

C<Remote.User> is optional, and declares a user on the remote machine
where a file upload service is running. The value may be used as parameter
for different transport protocols, depending on the C<--remote-method> in
use.

For instance, if using C<--remote-method=rsync+ssh>, the C<Remote.User>
configuration will be used as user for SSH login.

=back

=cut

use strict;
use warnings;

use IO::File;
use File::Spec::Functions qw/catfile/;

use App::PFT::Struct::Tree;
use App::PFT::Struct::Conf qw/cfg_is_loaded cfg_default cfg_dump $ROOT $HOME_PAGE/;
use App::PFT::Util;

use Exporter qw/import/;
use feature qw/say/;

use Pod::Usage;
use Pod::Find qw/pod_where/;

use Getopt::Long qw/GetOptionsFromArray/;
Getopt::Long::Configure qw/bundling/;

my $HELP = <<"EOF";
This is the templates directory. Here you must have three files:

- page.html     -> Mandatory, template for pages
- entry.html    -> Mandatory, template for blog entries
- gen.html      -> Mandatory, template for generated pages (e.g. month)

Upon initialization, the three files are all symlinked to a fourth file
named `default.html`, which is created by $0 with sensible defaults.

If you wish to modify all the pages together you may change
`default.html`.

In order to modify a single template replace the symlinks with regular
template files.

The default can be restored by running `$0 init`: `default.html` is
regenerated if it is missing. Each of the other missing files is symlinked
to `default.html`.

EOF

my $HOME_TEXT = <<"EOF";

Welcome to this $0 site.

This page was auto-generated by the $0 Configurator.
EOF

sub main {
    if (grep /^--help|-h$/, @ARGV) {
        pod2usage
            -exitval => 0,
            -verbose => 2,
            -input => pod_where({-inc => 1}, __PACKAGE__)
    }

    cfg_default unless cfg_is_loaded;

    my %opts = (
        home => 1,
    );

    GetOptions(
        'author=s' => \$App::PFT::Struct::Conf::AUTHOR,
        'site-title=s' => \$App::PFT::Struct::Conf::SITE_TITLE,
        'site-url=s' => \$App::PFT::Struct::Conf::SITE_URL,
        'home-page=s' => \$App::PFT::Struct::Conf::HOME_PAGE,
        'input-enc=s' => \$App::PFT::Struct::Conf::INPUT_ENC,
        'output-enc=s' => \$App::PFT::Struct::Conf::OUTPUT_ENC,
        'remote-method=s' => \$App::PFT::Struct::Conf::REMOTE{Method},
        'remote-host=s' => \$App::PFT::Struct::Conf::REMOTE{Host},
        'remote-user=s' => \$App::PFT::Struct::Conf::REMOTE{User},
        'remote-path=s' => \$App::PFT::Struct::Conf::REMOTE{Path},
        'remote-port=i' => \$App::PFT::Struct::Conf::REMOTE{Port},

        'home!' => \$opts{home},
    );

    if (cfg_is_loaded) {
        say STDERR 'Configuration file caressed in ', $ROOT;
        cfg_dump $ROOT;
    } else {
        say STDERR 'Creating configuration';
        cfg_dump '.';
    }

    my $tree = App::PFT::Struct::Tree->new(basepath => '.');
    my $default = catfile($tree->dir_templates, 'default.html');
    unless (-e $default) {
        say STDERR 'Creating template ', $default;
        my $fd = IO::File->new($default, 'w');
        say $fd <App::PFT::Cmd::Init::DATA>;
        close App::PFT::Cmd::Init::DATA;
    }

    foreach (qw/page.html entry.html gen.html/) {
        my $fn = catfile($tree->dir_templates, $_);
        unless (-e $fn) {
            App::PFT::Util::ln 'default.html', $fn, 1
        }
    }

    my $readme = catfile($tree->dir_templates, 'README');
    unless (-e $readme) {
        my $rf = IO::File->new($readme, 'w');
        print $rf $HELP;
    }

    my $home = $tree->page(title => $HOME_PAGE);
    unless ($home->exists) {
        if ($opts{home}) {
            say STDERR "Creating default site home: $HOME_PAGE";
            my $hf = $home->open('w');
            print $hf $HOME_TEXT;
        } else {
            say STDERR 'Skipping creation of page "', $HOME_PAGE,
                       '" as requested';
        }
    }
}

1;

__DATA__

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <meta http-equiv="content-type" content="text/html; charset=[% site.encoding %]">
  <title>[% site.title %] :: [% content.title %]</title>

    <style type="text/css">

        html {
            margin : 0;
            padding : 0;
            font-family : sans-serif;
        }

        body {
            margin : 0 auto 0;
            padding : 5em 5em 0;
            min-width : 40em;
            max-width : 50em;
            font-size : 10pt;
            line-height : 1.3em;
        }

        h1,h2,h3,h4,h5,h6 {
            line-height : 1em;
        }

        div#title {
            text-align : center;
        }

        a a:link a:visited {
            color : cornflowerblue;
            text-decoration : none;
        }

        a:hover {
            color : #87aced;
        }

        .side {
            float : right;
        }

        div#sitemap {
            margin-top : 3em;
            width : 30%;
        }

        div#sitemap h1 {
            font-size : 1em;
        }

        div#sitemap h2 {
            font-size : 1em;
            font-style : italic;
        }

        h1#sitetitle {
            margin-bottom : 1em;
            border-bottom : 1px solid cornflowerblue;
            text-align : right;
            clear : both;
        }

        div#pagetitle {
            margin : 2em 0 2em;
        }

        div#pagetitle h2 {
            font-size : 1em;
        }

        div#pagetitle h3 {
            font-size : 1em;
            display : inline;
            font-style : italic;
        }

        div#navigation ul {
            list-style-type : none;
        }

        div#navigation li h3 {
            display : inline;
        }

        div#content {
            font-family : serif;
            width : 65%;
        }

        div#content #title h1 {
            font-size : 2em;
        }

        div#content #text pre {
            overflow : auto;
            background : #ccc;
            padding : .5em;
        }

        div#content p img {
            max-width : 100%;
        }

        div#content h1,h2,h3,h4,h5,h6 { font-family : sans; }
        div#content h1 { font-size : 1.7em; }
        div#content h2 { font-size : 1.5em; }
        div#content h3 { font-size : 1.4em; }
        div#content h4 { font-size : 1.3em; }
        div#content h5 { font-size : 1.2em; }
        div#content h6 { font-size : 1.1em; }

        div#footer {
            color : silver;
            clear : right;
            margin-right : 0;
            margin-left : auto;
            font-size : .8em;
            text-align : left;
        }

    </style>
</head>

<body id="top">

<h1 id="sitetitle">[% site.title %]</h1>

<div id="sitemap" class="side">
  <h1>Site Map:</h1>

  [% IF links.pages %]
  <h2>Pages:</h2>
  <ul>
    [% FOREACH p = links.pages %]
      <li><a href="[% p.href %]">[% p.slug %]</a></li>
    [% END %]
  </ul>
  [% END %]

  [% IF links.backlog %]
  <h2>Last 5 entries:</h2>
  <ul>
    [% FOREACH e = links.backlog; IF loop.count > 5 BREAK END %]
      <li>
        <a href="[% e.href %]">
          [% e.slug %]
        </a>
      </li>
    [% END %]
  </ul>
  [% END %]

  [% IF links.months %]
  <h2>Last 5 months:</h2>
  <ul>
    [% FOREACH m = links.months; IF loop.count > 5 BREAK END %]
      <li>
        <a href="[% m.href %]">[% m.slug %]</a>
      </li>
    [% END %]
  </ul>
  [% END %]

  [% IF links.tags %]
  <h2>All the tags</h2>
  <ul>
    [% FOREACH t = links.tags %]
      <li>
        <a href="[% t.href %]">[% t.slug %]</a>
      </li>
    [% END %]
  </ul>
  [% END %]

</div>

<div id="pagetitle">
  <h1>[% content.title %]</h1>
  [% IF content.date %]
  <h2>
      <a href="[% links.root.href %]">[% content.date.y %] / [% content.date.m %]</a> / [% content.date.d %]
  </h2>
  [% END %]
</div>

<div id="navigation">
  <ul>
    [% IF links.prev %]
    <li>
      <h3>Prev:</h3>
      <a href="[% links.prev.href %]">[% links.prev.slug %]</a>
    </li>
    [% END %]

    [% IF links.next %]
    <li>
      <h3>Next:</h3>
      <a href="[% links.next.href %]">[% links.next.slug %]</a>
    </li>
    [% END %]

    [% IF content.tags %]
    <li>
      <h3>Tags:</h3>
      <ul>
        [% FOREACH t = content.tags %]
          <li><a href="[% t.href %]">[% t.slug %]</a></li>
        [% END %]
      </uL>
    </li>
    [% END %]
  </ul>
</div>

<div id="content">
  <div id="text">
    [% content.html %]

    [% IF links.related %]
    <ul>
      [% FOREACH l = links.related %]
        <li>
        [% IF l.date %]
          [% l.date.y %] / [% l.date.m %] / [% l.date.d %]:
        [% ELSE %]
          Page:
        [% END %]
        <a href="[% l.href %]">[% l.slug %]</a></li>
      [% END %]
    </ul>
    [% END %]
  </div>
</div>

<div id="footer">
    <a href="#top">Back</a>
</div>

</body>
</html>
