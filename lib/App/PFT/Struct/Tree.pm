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
use File::Basename;

use IO::File;

use Carp;

use App::PFT::Content::Entry;
use App::PFT::Content::Page;
use App::PFT::Content::Blob;
use App::PFT::Content::MonthPage;
use App::PFT::Content::TagPage;

use App::PFT::Data::Date;
use App::PFT::Data::Header;
use App::PFT::Lookups::Web qw/weblookup/;

use App::PFT::Util;

use feature qw/state/;

use constant {
    entry_pat1 => '[0-9]' x 4 . '-' . '[0-9]' x 2,
    entry_pat2 => '[0-9]' x 2 . '-' . '*',
};

has basepath => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

our $Verbose = 1;

sub BUILD {
    my $bp = $_[0]->basepath;
    make_path
        $bp,
        catdir($bp, 'content', 'pages'),
        catdir($bp, 'content', 'tags'),
        catdir($bp, 'content', 'blog'),
        catdir($bp, 'content', 'pics'),
        catdir($bp, 'content', 'attachments'),
        catdir($bp, 'inject'),
        catdir($bp, 'templates'),
        { verbose => $Verbose }
}

my $textinit = sub {
    my($basedir, $path, $hdr) = @_;
    make_path($basedir);
    write_file($path, $hdr->dump, '---');
};

my $get_header = sub {
    my $opts = shift;
    if (my $hdr = $opts->{header}) {
        die unless $hdr->isa('App::PFT::Data::Header');
        $hdr;
    } else {
        App::PFT::Data::Header->new(%$opts);
    }
};

has pages => (
    isa => 'HashRef[App::PFT::Content::Page]',
    is => 'ro',
    default => sub{{}}
);

has entries => (
    isa => 'HashRef[App::PFT::Content::Entry]',
    is => 'ro',
    default => sub{{}}
);

has months => (
    isa => 'HashRef[App::PFT::Content::Month]',
    is => 'ro',
    default => sub{{}}
);

has tags => (
    isa => 'HashRef[App::PFT::Content::Tag]',
    is => 'ro',
    default => sub{{}}
);

sub page {
    my $self = shift;
    my %opts = @_;

    my $hdr = $get_header->(\%opts);
    my $slug = $hdr->slug;

    if (my $have = $self->pages->{$slug}) {
        return $have;
    }

    my $basedir = catdir($self->basepath, 'content', 'pages');
    my $path = catfile $basedir, $slug;

    unless (-e $path) {
        die 'Page ', $hdr->title, ' does not exist' if $opts{'-verify'};
        $textinit->($basedir, $path, $hdr) unless $opts{'-noinit'};
    }

    my $out = App::PFT::Content::Page->new(
        tree => $self,
        path => $path,
        fname => $slug,
    );
    $self->pages->{$slug} = $out;
}

sub entry {
    my $self = shift;
    my %opts = @_;

    my $hdr = $get_header->(\%opts);
    my $date = $opts{date};
    die unless $date->isa('App::PFT::Data::Date') && $date->is_complete;
    my $month_year = sprintf '%04d-%02d', $date->year, $date->month;
    my $fname = sprintf '%02d-%s', $date->day, $hdr->slug;

    my $key = "$month_year-$fname";
    if (my $have = $self->entries->{$key}) {
        return $have;
    }

    my $basedir = catdir($self->basepath, 'content', 'blog', $month_year);
    my $path = catfile $basedir, $fname;

    unless (-e $path) {
        die 'Entry ', $date, ' ', $hdr->title, ' does not exist'
            if $opts{'-verify'};
        $textinit->($basedir, $path, $hdr) unless $opts{'-noinit'};
    }

    my $out = App::PFT::Content::Entry->new(
        tree => $self,
        path => $path,
        fname => $fname,
        date => $date,
    );

    $self->entries->{$key} = $out;
}

sub month {
    my $self = shift;
    my %opts = @_;

    my $date = do {
        if (my $d = $opts{date}) {
            die unless $d->isa('App::PFT::Data::Date');
            $d;
        } else {
            App::PFT::Data::Date->new(
                year => $opts{year},
                month => $opts{month},
            )
        }
    };

    my $key = sprintf '%04d-%02d', $date->year, $date->month;
    my $have = $self->months->{$key};

    if ($have && $have->isa('App::PFT::Content::MonthPage')) {
        return $have;
    }

    my $out = do {
        my $path = catdir $self->basepath, 'content', 'blog', $key, 'month';

        if (-e $path || $opts{'-create'}) {
            unless (-e $path) {
                my $hdr = $opts{header} || App::PFT::Data::Header->new(
                    title => $key,
                );
                $textinit->(
                    File::Basename::dirname($path),
                    $path,
                    $hdr,
                );
            }

            App::PFT::Content::MonthPage->new(
                tree => $self,
                path => $path,
                date => $date,
            );
        } else {
            $have || App::PFT::Content::Month->new(
                tree => $self,
                title => $key,
                date => $date,
            );
        }
    };

    $self->months->{$key} = $out;
}

sub tag {
    my $self = shift;
    my %opts = @_;

    my $name = join ' ', map { ucfirst } split /\s+/, ($opts{name} || die);
    my $slug = App::PFT::Util::slugify($opts{name});
    my $have = $self->tags->{$slug};

    if ($have && $have->isa('App::PFT::Content::TagPage')) {
        return $have;
    }

    my $out = do {
        my $path = catdir($self->basepath, 'content', 'tags', $slug);

        if (-e $path || $opts{'-create'}) {
            unless (-e $path) {
                my $hdr = $opts{header} || App::PFT::Data::Header->new(
                    title => $name,
                );
                $textinit->(
                    File::Basename::dirname($path),
                    $path,
                    $hdr,
                );
            }
            App::PFT::Content::TagPage->new(
                tree => $self,
                path => $path,
                name => $name,
            );
        } else {
            $have || App::PFT::Content::Tag->new(
                tree => $self,
                name => $name,
            );
        }
    };

    $self->tags->{$slug} = $out;
}

sub list_pages {
    my $self = shift;
    my $pages = $self->pages;

    my $base = catdir($self->basepath, 'content', 'pages');
    my $N = length($base) + 1;
    for my $path (glob catfile($base, '*')) {
        my $slug = substr($path, $N);
        next if $pages->{$slug};

        $pages->{$slug} = App::PFT::Content::Page->new(
            tree => $self,
            path => $path,
            fname => $slug,
        );
    }

    wantarray ? values %$pages : [ values %$pages ];
}

sub list_entries {
    my $self = shift;
    my $entries = $self->entries;

    my $base = catdir($self->basepath, 'content', 'blog');
    my $N = length($base) + 1;
    for my $path (glob catfile($base, entry_pat1, entry_pat2)) {
        my($y, $m, $d, $t) = (
            substr($path, $N, 4),
            substr($path, $N + 5, 2),
            substr($path, $N + 8, 2),
            substr($path, $N + 11),
        );
        my $k = join '-', $y, $m, $d, $t;
        next if $entries->{$k};

        $entries->{$k} = App::PFT::Content::Entry->new(
            tree => $self,
            path => $path,
            date => App::PFT::Data::Date->new(
                year => $y,
                month => $m,
                day => $d,
            ),
        );
    }

    wantarray ? values %$entries : [ values %$entries ];
}

sub latest_entry {
    my $self = shift;
    my $back = shift || 0;

    my $base = catdir $self->basepath, 'content', 'blog';
    my $N = length($base) + 1;
    for my $p_l1 (sort {$b cmp $a} glob catfile($base, entry_pat1)) {
        my($y, $m) = (
            substr($p_l1, $N, 4),
            substr($p_l1, $N + 5),
        );

        for my $p_l2 (sort {$b cmp $a} glob catfile($p_l1, entry_pat2)) {
            my($d, $t) = (
                substr($p_l2, $N + 8, 2),
                substr($p_l2, $N + 11),
            );

            next if $back--;

            my $entries = $self->entries;
            my $k = join '-', $y, $m, $d, $t;

            return $entries->{$k}
                or $entries->{$k} = App::PFT::Content::Entry->new(
                tree => $self,
                path => $p_l2,
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

sub link {
    my $self = shift;

    my($prev_entry, $cur_month);
    for my $c (sort ($self->list_pages, $self->list_entries)) {
        $_->add_link($c) foreach $c->tags;

        if ($c->isa('App::PFT::Content::Entry')) {
            my $month = $c->month;

            $c->root($month);
            $month->add_link($c);
            if (defined $cur_month && $cur_month cmp $month) {
                $cur_month->prev($month);
                $month->next($cur_month);
            }
            $cur_month = $month;

            if (defined $prev_entry) {
                $c->prev($prev_entry);
                $prev_entry->next($c);
            }
            $prev_entry = $c;
        }
    }

}

sub lookup {
    my($self, %params) = @_;

    if ($params{kind} eq 'page') {
        return $self->page(title => join(' ', @{$params{hint}}));
    }

    if ($params{kind} eq 'tag') {
        return $self->tag(name => join(' ', @{$params{hint}}));
    }

    if ($params{kind} eq 'attach') {
        return App::PFT::Content::Blob->new(
            tree => $self,
            group => 'attachments',
            path => catfile($self->dir_attach, @{$params{hint}}),
            -verify => 1,
        );
    }

    if ($params{kind} eq 'pic') {
        return App::PFT::Content::Blob->new(
            tree => $self,
            path => catfile($self->dir_pics, @{$params{hint}}),
            group => 'pics',
            -verify => 1,
        );
    }

    if ($params{kind} eq 'web') {
        return weblookup($params{hint});
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
sub dir_attach() { catdir $_[0]->basepath, 'content', 'attachments' }

#has pictures => ( is => 'ro', isa => 'ArrayRef[App::PFT::Content::Picture]' );
#has blobs => ( is => 'ro', isa => 'ArrayRef[App::PFT::Content::Picture]' );

no Moose;
__PACKAGE__->meta->make_immutable;

1;
