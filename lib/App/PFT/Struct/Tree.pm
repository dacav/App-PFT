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
package App::PFT::Struct::Tree;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

use File::Spec::Functions qw/catdir catfile abs2rel/;
use File::Path qw/make_path/;
use File::Slurp qw/write_file/;

use Carp;

use App::PFT::Content::Entry;
use App::PFT::Content::Page;
use App::PFT::Content::Blob;
use App::PFT::Content::MonthPage;
use App::PFT::Content::TagPage;

use App::PFT::Data::Date;
use App::PFT::Data::Header;

use App::PFT::Util;

use feature qw/state/;

has basepath => (is => 'ro', isa => 'Str');

sub BUILD {
    my $bp = $_[0]->basepath;
    make_path
        $bp,
        catdir($bp, 'content', 'pages'),
        catdir($bp, 'content', 'blog'),
        catdir($bp, 'content', 'pics'),
        catdir($bp, 'content', 'attachments'),
        catdir($bp, 'inject'),
        catdir($bp, 'templates'),
        { verbose => 1 }
}

my $textinit = sub {
    my($basedir, $path, $hdr) = @_;
    unless (-e $path) {
        make_path($basedir);
        write_file($path, $hdr->dump, '---');
    }
};

my $get_header = sub {
    my $opts = shift;
    if (my $hdr = $opts->{header}) {
        $hdr;
    } else {
        App::PFT::Data::Header->new(%$opts);
    }
};

sub latest_entry {
    my $self = shift;
    my $back = shift || 0;

    my $base = catfile $self->basepath, 'content', 'blog';
    for my $l1 (sort {$b cmp $a} glob "$base/*") {
        my($y,$m) = (abs2rel $l1, $base) =~ m/^(\d{4})-(\d{2})$/
            or die "Junk in $base: $l1";

        for my $l2 (sort {$b cmp $a} glob "$l1/*") {
            my($d,$fn) = (abs2rel $l2, $l1) =~ m/^(\d{2})-(.*)$/
                or die "Junk in $l1: $l2";

            next if $back--;

            return App::PFT::Content::Entry->new(
                tree => $self,
                path => $l2,
                fname => $fn,
                date => App::PFT::Data::Date->new(
                    year => $y,
                    month => $m,
                    day => $d,
                )
            );
        }
    }

    croak "No entries";
}

sub entry {
    my($self, %opts) = @_;

    my $hdr = $get_header->(\%opts);
    my $date = $opts{date};
    my $fname = sprintf '%02d-%s', $date->day, $hdr->flat_title;
    my $basedir = catdir(
        $_[0]->basepath,
        'content',
        'blog',
        sprintf('%04d-%02d', $date->year, $date->month),
    );
    my $path = catfile $basedir, $fname;
    my $out = App::PFT::Content::Entry->new(
        tree => $self,
        path => $path,
        fname => $fname,
        date => $date,
    );

    unless ($opts{'-noinit'}) {
        $textinit->($basedir, $path, $hdr);
        $self->entries->{$path} = $out if $self->entries_loaded;
        # FIXME: Do we need to rewire it in linking?
    }
    $out;
}

has entries => (
    is => 'ro',
    isa => 'HashRef[App::PFT::Content::Entry]',
    lazy => 1,
    predicate => 'entries_loaded',
    default => sub {
        my $self = shift;
        my %out;
        my $base = catfile $self->basepath, 'content', 'blog';

        my $prev;
        for my $l1 (sort { $a cmp $b } glob "$base/*") {
            my($y,$m) = (abs2rel $l1, $base) =~ m/^(\d{4})-(\d{2})$/
                or die "Junk in $base: $l1";

            for my $l2 (sort { $a cmp $b } glob "$l1/*") {
                my($d,$fn) = (abs2rel $l2, $l1) =~ m/^(\d{2})-(.*)$/
                    or die "Junk in $l1: $l2";

                my $e = App::PFT::Content::Entry->new(
                    tree => $self,
                    path => $l2,
                    fname => $fn,
                    date => App::PFT::Data::Date->new(
                        year => $y,
                        month => $m,
                        day => $d,
                    )
                );

                if (defined $prev) {
                    $e->prev($prev);
                    $prev->next($e);
                }
                $out{$l2} = $prev = $e;
            }
        }

        return \%out;
    }
);

sub list_entries { values %{shift->entries} }

sub page {
    my($self, %opts) = @_;

    my $hdr = $get_header->(\%opts);

    my $fname = $hdr->flat_title;
    my $basedir = catdir($_[0]->basepath, 'content', 'pages');
    my $path = catfile $basedir, $fname;

    my $out = App::PFT::Content::Page->new(
        tree => $self,
        path => $path,
        fname => $fname,
    );

    unless ($opts{'-noinit'}) {
        $textinit->($basedir, $path, $hdr);
        $self->pages->{$path} = $out if $self->pages_loaded;
    }
    $out;
}

has pages => (
    is => 'ro',
    isa => 'HashRef[App::PFT::Content::Page]',
    lazy => 1,
    predicate => 'pages_loaded',
    default => sub {
        my $self = shift;
        my %out;
        my $base = catfile $self->basepath, 'content', 'pages';

        for my $path (glob "$base/*") {
            $out{$path} = App::PFT::Content::Page->new(
                tree => $self,
                path => $path,
                fname => abs2rel($path, $base),
            );
        }

        return \%out;
    }
);

sub list_pages { values %{shift->pages} }

sub link_tags {
    my $self = shift;
    my %tags;

    for my $content ($self->list_entries, $self->list_pages) {
        for my $tname (@{$content->header->tags}) {
            my $t = $tags{$tname};
            unless (defined $t) {
                $t = App::PFT::Content::TagPage->new(tagname => $tname);
                $tags{$tname} = $t;
            }
            $t->add_content($content);
        }
    }

    values %tags;
}

sub link_months {
    my $self = shift;
    my @es = sort {$a->cmp cmp $b->cmp} $self->list_entries;
    return [] unless @es;

    my %months = App::PFT::Util::groupby
        { sprintf('%04d%02d', $_->date->year, $_->date->month) }
        @es
    ;

    my($prev_m, @out);
    for my $k (sort keys %months) {
        my $mp = App::PFT::Content::MonthPage->new(
            tree => $self,
            year  => 0 + substr($k, 0, 4),
            month => 0 + substr($k, 4, 2),
        );
        for my $e (@{$months{$k}}) {
            $mp->add_entries($e);
            $e->month($mp);
        }
        if ($prev_m) {
            $mp->prev($prev_m);
            $prev_m->next($mp);
        }
        push @out, $mp;
        $prev_m = $mp;
    }

    wantarray ? @out : \@out;
};

sub lookup {
    my($self, %params) = @_;

    if ($params{kind} eq 'pic') {
        return App::PFT::Content::Blob->new(
            tree => $self,
            path => catfile($self->dir_pics, @{$params{hint}}),
            -verify => 1,
        );
    }

    if ($params{kind} eq 'page') {
        return $self->page(
            title => $params{hint}->[0],
            # TODO: support -verify for Content::Text
        );
    }

    croak
        "Failed to search for kind '$params{kind}' ",
        "relative to '$params{relative_to}' ",
        "@{$params{hint}}" ? "using hint '@{$params{hint}}' " : 'no hint',
        "\n",
    ;
}

sub dir_templates() { catdir $_[0]->basepath, 'templates' }
sub dir_build() { catdir $_[0]->basepath, 'build' }
sub dir_inject() { catdir $_[0]->basepath, 'inject' }

sub dir_pics() { catdir $_[0]->basepath, 'content', 'pics' }

#has pictures => ( is => 'ro', isa => 'ArrayRef[App::PFT::Content::Picture]' );
#has blobs => ( is => 'ro', isa => 'ArrayRef[App::PFT::Content::Picture]' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
