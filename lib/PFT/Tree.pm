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
use File::Basename qw/dirname basename/;
use Carp;

use PFT::Content::Page;
use PFT::Date;

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
        #verbose => 1,
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
    my $out = shift;

    $out =~ s/[\W_]/-/g;
    $out =~ s/--+/-/g;
    lc $out
};

sub entry {
    my $self = shift;
    my $hdr = shift;
    confess 'Not a header' if ref $hdr ne 'PFT::Text::Header';

    my $fname = $slugify->($hdr->title);

    my $basedir;
    if (defined(my $d = $hdr->date)) {

        defined $d->y && defined $d->m
            or confess 'Year and month are required';

        my $ym = sprintf('%04d-%02d', $d->y, $d->m);
        if (defined $d->d) {
            $basedir = File::Spec->catdir($self->dir_blog, $ym);
            $fname = sprintf('%02d-%s', $d->d, $fname);
        } else {
            $basedir = $self->dir_blog;
            $fname = $ym . '.month';
        }

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

sub _ls {
    my $self = shift;

    my @out;
    for my $path (map glob, @_) {
        my $h = eval { PFT::Text::Header->load($path) };
        $h or croak "Loading $path: " . $@ =~ s/ at .*$//rs;

        push @out, PFT::Content::Page->new({
            tree => $self,
            path => $path,
            name => $h->title,
        });
    }
    @out
}

=item blog_ls

List all blog entries

=cut

sub blog_ls {
    my $self = shift;
    $self->_ls(File::Spec->catfile($self->dir_blog, '*', '*'))
}

=item pages_ls

List all pages

=cut

sub pages_ls {
    my $self = shift;
    $self->_ls(File::Spec->catfile($self->dir_pages, '*'))
}

=item path_to_date

Given a path (of a page) determine the corresponding date. Returns a
PFT::Date object or undef if the page does not have date.

=cut

sub path_to_date {
    my $self = shift;
    my $path = shift;

    my $rel = File::Spec->abs2rel($path, $self->dir_blog);
    return undef unless index($rel, File::Spec->updir) < 0;

    my($ym, $dt) = File::Spec->splitdir($rel);

    PFT::Date->new(
        substr($ym, 0, 4),
        substr($ym, 5, 2),
        defined($dt) ? substr($dt, 0, 2) : do {
            $ym =~ /^\d{4}-\d{2}.month$/ or confess "Unexpected $ym";
            undef
        }
    )
}

=item path_to_slug

Given a path (of a page) determine the corresponding slug string.

=cut

sub path_to_slug {
    my $self = shift;
    my $path = shift;

    my $fname = basename $path;

    my $rel = File::Spec->abs2rel($path, $self->dir_blog);
    $fname =~ s/^\d{2}-// if index($rel, File::Spec->updir) < 0;

    $fname
}

=item was_renamed

Notify a renaming of a inner file. First parameter is the original name,
second parameter is the new name.

=cut

sub was_renamed {
    my $self = shift;
    my $d = dirname shift;

    # $ignored = shift

    opendir(my $dh, $d) or return;
    rmdir $d unless File::Spec->no_upwards(readdir $dh);
    close $dh;
}

=back

=cut

1;
