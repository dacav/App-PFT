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

sub help {
    pod2usage
        -exitval => 1,
        -verbose => 2,
        -input => pod_where({-inc => 1}, __PACKAGE__)
    ;
}

sub main {
    my $tree = App::PFT::Struct::Tree->new(basepath => '.');

    my $default = catfile($tree->dir_templates, 'default.html');
    my $default_templ = IO::File->new($default, 'w');
    say $default_templ <App::PFT::Cmd::Init::DATA>;
    close App::PFT::Cmd::Init::DATA;

    App::PFT::Util::ln $default, catfile($tree->dir_templates, 'page.html');
    App::PFT::Util::ln $default, catfile($tree->dir_templates, 'entry.html');
    App::PFT::Util::ln $default, catfile($tree->dir_templates, 'month.html');
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
