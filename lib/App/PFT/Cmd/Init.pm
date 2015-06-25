package App::PFT::Cmd::Init;

=head1 NAME

pft init

=head1 SYNOPSYS

pft init 

=cut

use strict;
use warnings;

use IO::File;
use File::Spec::Functions qw/catfile/;

use App::PFT::Struct::Tree;
use App::PFT::Struct::Conf qw/cfg_dump/;
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

sub main {
    GetOptions(
        'help|h!'       => sub {
            pod2usage
                -exitval => 1,
                -verbose => 2,
                -input => pod_where({-inc => 1}, __PACKAGE__)
            ;
        },
    );

    my $tree = App::PFT::Struct::Tree->new(basepath => '.');

    my $default = 'default.html';
    unless (-e $default) {
        say STDERR "Creating template $default";
        my $default_templ = IO::File->new(
            catfile($tree->dir_templates, $default),
            'w'
        );
        say $default_templ <App::PFT::Cmd::Init::DATA>;
        close App::PFT::Cmd::Init::DATA;
    }

    my $page = catfile($tree->dir_templates, 'page.html');
    App::PFT::Util::ln $default, $page, 1 unless -e $page;
    my $entry = catfile($tree->dir_templates, 'entry.html');
    App::PFT::Util::ln $default, $entry, 1 unless -e $entry;
    my $gen = catfile($tree->dir_templates, 'gen.html');
    App::PFT::Util::ln $default, $gen, 1 unless -e $gen;

    my $readme = catfile($tree->dir_templates, 'README');
    unless (-e $readme) {
        my $rf = IO::File->new($readme, 'w');
        print $rf $HELP;
    }
}

1;

__DATA__


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
  <title>[% site.title %] :: [% content.title %]</title>
  <meta http-equiv="content-type" content="text/html; charset=[% site.encoding %]">
</head>

<body>

<div id="nav">
  <ul>
    [% IF links.prev %]
    <li>Prev: <a href="[% links.prev.href %]">[% links.prev.slug %]</a></li>
    [% END %]
    [% IF links.next %]
    <li>Next: <a href="[% links.next.href %]">[% links.next.slug %]</a></li>
    [% END %]
    [% IF links.root %]
    <li>Month: <a href="[% links.root.href %]">[% links.root.slug %]</a></li>
    [% END %]
  </ul>
</div>

<div id="content">
  [% content.html %]
  [% IF links.related %]
  <ul>
    [% FOREACH l = links.related %]
      <li>Day [% l.date.d %]: <a href="[% l.href %]">[% l.slug %]</a></li>
    [% END %]
  </ul>
  [% END %]
</div>

</body>
</html>
