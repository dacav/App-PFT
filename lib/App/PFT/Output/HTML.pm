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
package App::PFT::Output::HTML;

use strict;
use warnings;

use Template::Alloy;
use Text::MultiMarkdown qw/markdown/;
use IO::File;
use Encode;

use Carp;

use File::Spec::Functions qw/catdir catfile/;
use File::Path qw/remove_tree make_path/;
use File::Basename qw/dirname/;

use App::PFT::Util;

use namespace::autoclean;
use Moose;

use feature qw/say/;

has site_title => (is => 'ro', isa => 'Str');
has site_home => (is => 'ro', isa => 'Str');
has base_url => (is => 'ro', isa => 'Str');
has outputenc => (is => 'ro', isa => 'Str', default => sub{'utf-8'});
has tree => (is => 'ro', isa => 'App::PFT::Struct::Tree');

sub build_path { shift->tree->dir_build }
sub pages { shift->tree->list_pages }
sub entries { shift->tree->list_entries }

has schedule => (is => 'ro', isa => 'CodeRef');
has next => (is => 'ro', isa => 'CodeRef');

has months => (
    is => 'ro',
    isa => 'ArrayRef[App::PFT::Content::MonthPage]',
    lazy => 1,
    default => sub { scalar shift->tree->link_months },
);

has tags => (
    is => 'ro',
    isa => 'HashRef[App::PFT::Content::TagPage]',
    lazy => 1,
    default => sub { scalar shift->tree->link_tags },
);

has links => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my(@pages, @entries, @months, @tags);

        for my $p ($self->pages) {
            push @pages, $self->mkhref($p);
        }

        # Reverse chronological order
        for my $e (sort { $b->cmp cmp $a->cmp } $self->entries) {
            push @entries, $self->mkhref($e);
        }

        for my $m (@{$self->months}) {
            push @months, $self->mkhref($m);
        }

        for my $t (values %{$self->tags}) {
            push @tags, $self->mkhref($t);
        }

        {
            pages => \@pages,
            backlog => \@entries,
            months => [reverse @months],
            tags => \@tags,
        }
    },
);

has lookup => (
    is => 'ro',
    isa => 'CodeRef',
);

has backend => (
    is => 'ro',
    isa => 'Template::Alloy',
    lazy => 1,
    default => sub {
        Template::Alloy->new(
            INCLUDE_PATH => [
                shift->tree->dir_templates,
            ]
            #AUTO_FILTER => 'auto',
            #FILTERS => {
            #    markdown => sub { $hrefs->(markdown shift) },
            #    #auto => $hrefs,
            #}
        );
    }
);

around BUILDARGS => sub {
    my ($orig, $class, %params) = @_;

    my $base_url = $params{base_url};
    my $tree = $params{tree};
    my $build_path = $tree->dir_build;
    die unless $base_url;

    remove_tree $build_path;
    make_path $build_path;

    $params{lookup} = do {
        App::PFT::Util::ln
            $tree->dir_pics,
            catdir($build_path, 'pics')
        ;
        App::PFT::Util::ln
            $tree->dir_attach,
            catdir($build_path, 'attachments')
        ;
        sub {
            my $cur_content = shift;
            my $got_content = $cur_content->lookup(@_);

            if (ref $got_content) {
                # Got an internal link, resolve it w.r.t $base_url.

                my $out = join('/', $base_url, $got_content->from_root);

                my $type = shift;
                if ($type eq 'page' || $type eq 'blog' || $type eq 'tag') {
                    # If this is a generated page, it's an HTML.
                    $out .= '.html';
                }
                return $out;
            }

            # Else this is an URL
            $got_content;
        }
    };

    my(@todo, %done);

    $params{schedule} = sub {
        my $content = shift;
        push @todo, $content unless (exists $done{$content->uid});
    };

    $params{next} = sub {
        return undef unless @todo;

        my $content = pop @todo;
        my $uid = $content->uid;
        die if exists $done{$uid};
        $done{$uid} = $content;

        $content;
    };

    $class->$orig(%params);
};

sub mkhref {
    my $self = shift;
    my $content = shift;

    my $out = {
        href => join('/', $self->base_url, $content->from_root) . '.html',
        slug => encode($self->outputenc, $content->title),
    };
    if (my $date = $content->date) {
        $out->{date} = $date->to_hash;
    }

    $out;
}

sub resolve {
    my $lookup = shift->lookup;
    my $curr_content = shift;
    my $str = shift;

    $str =~ s/<(a\s.*?href="):(page|blog|tag|attach|web):(.*?)"/
        '<' . $1 . $lookup->($curr_content, $2, split m|\/|, $3) . '"'
    /mge;

    $str =~ s/(<img\s.*?src="):pic:(.*?)(".*?>)/
        my $h = $lookup->($curr_content, 'pic', $2);
        "<a href=\"$h\">$1$h$3<\/a>"
    /mge;

    $str;
}

sub process {
    my($self, $content) = @_;
    my $be = $self->backend;

    my %links;
    my $vars = {
        site => {
            title => encode($self->outputenc, $self->site_title),
            encoding => $self->outputenc,
        },
        content => {
            title => encode($self->outputenc, $content->title),
            text => encode($self->outputenc, $content->text),
            html => encode(
                $self->outputenc,
                $self->resolve($content, markdown $content->text),
            ),
            date => $content->date ? $content->date->to_hash : undef,
        },
        links => \%links,
    };

    my @tags;
    for my $t (@{$content->header->tags}) {
        push @tags, $self->mkhref($self->tags->{lc $t});
    }
    $vars->{content}{tags} = \@tags if @tags;

    @links{keys %{$self->links}} = values %{$self->links};
    $links{prev} = $self->mkhref($content->prev) if $content->has_prev;
    $links{next} = $self->mkhref($content->next) if $content->has_next;
    $links{root} = $self->mkhref($content->month) if $content->has_month;

    if ($content->has_links) {
        my @hrefs =
            map { $self->mkhref($_) }
            sort { $a->cmp cmp $b->cmp }
            @{$content->links}
        ;
        $links{related} = \@hrefs;
    }

    my $fn = catfile($self->build_path, $content->from_root) . '.html';
    make_path dirname($fn), { verbose => 1 };
    $be->process(
        $content->template . '.html',
        $vars,
        (IO::File->new($fn, 'w') or die "Unable to open $fn: $!")
    ) or croak
        'Cannot process page ', $fn,
        "\n\ttemplate engine says: ", $be->error,
        "\n\t(Missing template?)",
    ;
}

sub build {
    my $self = shift;
    my $next = $self->next;
    my $sched = $self->schedule;

    &$sched($_) foreach (
        $self->entries,
        $self->pages,
        @{$self->months},
        $self->tree->link_tags,
    );

    while (my $e = &$next()) {
        eval {
            $self->process($e);
        };
        if ($@) {
            croak 'While compiling ', $e->hname, ": \n\t", $@;
        } else {
            say STDERR 'Compiled ', $e->hname;
        }
    }
}

sub DEMOLISH {
    my $self = shift;
    my $h = $self->tree->page(title => $self->site_home, -noinit => 1);
    if ($h->exists) {
        my $fn = catfile($self->build_path, 'index.html');
        my $f = IO::File->new($fn, 'w') or die "Unable to open $fn: $!";
        my $href = $self->mkhref($h);
        print $f
            "<!--\n",
            "    This file is generated automatically. Do not edit, it will be\n",
            "    overwritten. It points browsers to $href->{slug}\n",
            "-->\n",
            "<meta HTTP-EQUIV=\"REFRESH\" content=\"0; url=$href->{href}\">"
        ;
    } else {
        say STDERR 'SiteHome page ', $h->path, ' does not exist';
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
