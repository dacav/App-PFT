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
package App::PFT::Cmd::Help;

=head1 NAME

pft - Static blog and website manager

=head1 SYNOPSYS

pft <command> [options]

=head1 AVAILABLE COMMANDS

Here follows a list of available commands:

=over

=item * B<init>: Initialize a B<pft> site in the current directory;

=item * B<blog>: Create a new blog entry;

=item * B<page>: Create a new page;

=item * B<make>: Build the website;

=item * B<pub>: Publish on the Web;

=item * B<clean>: Clear built tree;

=item * B<tag>: Edit tag page;

=item * B<help>: Show usage manual.

=back

For options of a specific command I<cmd> use C<pft I<cmd> --help>

=head1 FILESYSTEM LAYOUT

A new site can be initialized by running the C<pft init> command inside a
directory. In this document such directory will be conveniently called
I<ROOT>.

The initialization command produces the following filesystem structure:

    ROOT
    ├── content
    │   ├── attachments
    │   ├── blog
    │   ├── pages
    │   └── pics
    ├── inject
    ├── pft.yaml
    └── templates

=head2 Configuration in pft.yaml

=head2 Title Mangling

The C<pft blog> and C<pft page> commands can be used to generate new blog
entries and pages respectively. Besides options, both require a title to
be specified in order to enable editing. The title is obtained by joining
the non-option parameters into a space separated string.

For example, the command

    pft page [...options...] The "User's" Original Title

Will result into the following title:

    $title = "The User's Original Title";

The original title is retained in the header of the generated content
file, while the file where the content will be stored is named by
mangling the title:

    $title =~ s/\W/-/g;    # all the non-word characters replaced by '-'
    $title =~ s/--+/-/g;   # multiple '-' are packed together
    $title =~ s/-*$//;     # trailing '-' are dropped
    $basename = lc $title; # everything is lower-cased

=head2 Editing files

TODO: mention how to remove a file automatically


=head1 CONTENT FILE FORMAT

The skeleton of a content file is usually created by B<pft> when a blog
entry or a page is edited. Content files are always positioned under the
C<I<ROOT>/content> directory.

Content files are made of plain text. A first section is a I<YAML> header
representing the configuration for the content. The header is followed by
a line with three dashes (C<--->) which marks the beginning of the actual
content document.  The document will be parsed as I<MultiMarkdown> when
compiled.

=head2 Special references handling

Markdown supports a syntax for defining links and pictures which gets
translated into HTML C<E<lt>aE<gt>> and C<E<lt>imgE<gt>> tags
respectively. Also, since Markdown is a super-set of HTML, direct HTML can
be supplied in the text.  Both forms will result in HTML links after the
Markdown to HTML transformation, so here we refer in general to the final
HTML.

B<pft> parses these URLs in order to provide additional linkage semantics.
The recognized format is:

    :kind:param/param/...

There is a number of supported C<kind> keywords, enumerated in this
document. Additional parameters can be specified and separated by a C</>
symbol.

=head3 Pictures:

Picture reference accept special links in the form

    <img src=":pic:filename"/>

This form will be resolved by B<pft>, and a link will be generated to the
file named named I<filename> inside the C<I<ROOT>/content/pics> directory.
The name provided is used directly as lookup, so the complete basename
should be provided.  Compilation results in errors unless the required
file exists

Example:

    <img alt="..." src=":pic:test.png"/>

=head3 URLs:

Regular URLs in C<E<lt>a/E<gt>> tags accept the following special
prefixes:

=over

=item :page:I<pagename>

Binds the link to the coordinates of the page named I<pagename>. The
provided name can be:

=over

=item *

The actual file name of the content in C<ROOT/content/pages>;

=item *

Any title which results in the correct file name after mangling (see the
B<Title Mangling> section). Mind about spaces, which must be replaced by
C</> symbols.

For example, the following forms are equivalently pointing to the same
page, previously created with the C<pft page 'Foo, Bar '+' Baz'> command:

    <a href=":page:foo-bar-baz">

    <a href=":page:foo/bar/baz">

    <a href=":page:Foo,/Bar/+/baz">

=back

=item :blog:back/I<N>

Only valid within a blog entry. The generated link refers to I<N> blog
entries before the current one. The I<N> parameter is optional, and
defaults to zero.

Examples:

    <a href=":blog:back/5">     (5 entries ago)

    <a href=":blog:back/0">     (previous entry)

    <a href=":blog:back">       (equivalently, previous entry)

=item :web:I<service>/I<param>/I<param>/...

Generate an URL which points to a web service (e.g. search engines, or
specialized website) and passes data on the query.

The B<Web Search> section of this document contains a number of supported
values for I<service>, while the following list of I<param>s depends on
the specific service.

=back

=head2 Web Search

Special URLs in the form C<:web:I<service>/I<param>/...> can be used to
link to online services, like search engines, portals and others. This
section is a reference of supported services.

=over

=item Duck Duck Go

C<:web:ddg/I<bang>/I<param>/I<param>/...>

Search query on the I<Duck Duck Go> search engine. The first parameter is
used for I<Duck Duck Go>'s Bang syntax, and can be empty in order not to
use any Bang.

Example: search C<linux howto> on Duck Duck Go:

    :web:ddg//linux/howto

Example: search C<linux howto> with the C<!yt> bang (redirects search
on I<YouTube>):

    :web:ddg/yt/linux/howto

Example: search C<linux howto> with the C<!so> bang (redirects search
on I<StackOverflow>):

    :web:ddg/so/linux/howto

=item Manpages

C<:web:man/I<name>

C<:web:man/I<name>/I<section>

Point to an online manpage. Manual section can be optionally supplied.

Examples:

    :web:man/bash

    :web:man/signal/7

=over

=back

=back

=cut

use Pod::Usage;
use Pod::Find qw/pod_where/;

sub main {
    pod2usage
        -exitval => 0,
        -verbose => 2,
        -input => pod_where({-inc => 1}, __PACKAGE__)
    ;
}

1;
