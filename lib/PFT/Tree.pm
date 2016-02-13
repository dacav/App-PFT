package PFT::Tree v0.0.1;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Tree - Create a new structure mapping a filesystem tree.

=head1 SYNOPSIS

    use PFT::Tree;

    my $tree = PFT::Tree->new($basedir);

=head1 DESCRIPTION

The structure is the following:

    ├── build
    ├── content
    │   ├── attachments
    │   ├── blog
    │   ├── pages
    │   ├── pics
    │   └── tags
    ├── inject
    ├── pft.yaml
    └── templates

=cut

use File::Spec;
use File::Path qw/make_path/;
use Carp;

use PFT::Content::Page;

sub new {
    my $cls = shift;
    my $base = shift;

    my $self = bless { base => $base }, $cls;
    $self->_init();
    $self;
}

sub _init {
    my $self = shift;
    make_path map({ $self->$_ } qw/
        dir_build
        dir_attach
        dir_blog
        dir_pages
        dir_pics
        dir_tags
        dir_inject
        dir_templates
    /), {
        verbose => 1,
        mode => 0711,
    }
}

=pod

=head2 Properties

Quick accessors for directories

    $tree->dir_root
    $tree->dir_build
    $tree->dir_attach
    $tree->dir_blog
    $tree->dir_pages
    $tree->dir_pics
    $tree->dir_tags
    $tree->dir_inject
    $tree->dir_templates

Non-existing directories are created by the constructor.

=cut

sub dir_root { shift->{base} }
sub dir_build { File::Spec->catdir(shift->{base}, 'build') }
sub dir_attach { File::Spec->catdir(shift->{base}, 'content', 'attachments') }
sub dir_blog { File::Spec->catdir(shift->{base}, 'content', 'blog') }
sub dir_pages { File::Spec->catdir(shift->{base}, 'content', 'pages') }
sub dir_pics { File::Spec->catdir(shift->{base}, 'content', 'pics') }
sub dir_tags { File::Spec->catdir(shift->{base}, 'content', 'tags') }
sub dir_inject { File::Spec->catdir(shift->{base}, 'inject') }
sub dir_templates { File::Spec->catdir(shift->{base}, 'templates') }

=head2 Methods

=over

=item entry

Getter for a page. A header is required as argument. If the page does not
exist it gets created according to the header. If the header contains a
date, the page is considered to be a blog entry (and positioned as such).

=cut

my $slugify = sub {
    $_[0]
};

sub entry {
    my $self = shift;
    my $hdr = shift;
    confess 'Not a header' if ref $hdr ne 'PFT::Text::Header';

    my $fname = $slugify->($hdr->title);

    my $basedir;
    if (defined(my $d = $hdr->date)) {
        $basedir = File::Spec->catdir($self->dir_blog, $d->y .'-'. $d->m);
        $fname = $d->d .'-'. $fname
    } else {
        $basedir = $self->dir_pages
    }

    my $p = PFT::Content::Page->new({
        tree => $self,
        path => File::Spec->catfile($basedir, $fname),
        name => $hdr->title,
    });

    $hdr->dump($p->open('w')) unless $p->exists;

    return $p
}

=item pages

List all pages

=cut

sub pages {
    my $self = shift;

    for my $path (glob File::Spec->catfile($self->dir_pages, '*')) {
    }
}

=item blog

List all blog pages

=cut

sub blog {
    my $self = shift;

    for my $path (glob File::Spec->catfile($self->dir_blog, '*', '*')) {
    }
}

=back

=cut

1;
