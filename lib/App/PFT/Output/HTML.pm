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

use constant {
    prefix_len => length('App::PFT::Content::'),
};

has title => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has home => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has base_url => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has encoding => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has default_template => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has tree => (
    is => 'ro',
    isa => 'App::PFT::Struct::Tree',
    required => 1,
);

sub build_path { shift->tree->dir_build }
sub pages { shift->tree->list_pages }
sub entries { shift->tree->list_entries }

has schedule => (
    is => 'ro',
    isa => 'CodeRef',
);

has next => (
    is => 'ro',
    isa => 'CodeRef'
);

has links => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $tree = $self->tree;;
        my $mkhref = sub { $self->mkhref($_) };

        # Assumption here is that $tree->link was already called. Tags and
        # Months are already loaded as side effect.

        my @pages = map &$mkhref, sort $tree->list_pages;
        my @entries = map &$mkhref, sort $tree->list_entries;
        my @months = map &$mkhref, sort values %{$tree->months};
        my @tags = map &$mkhref, sort values %{$tree->tags};

        {
            pages => \@pages,
            backlog => \@entries,
            months => \@months,
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

    my(@todo, %seen);
    my $sched = $params{schedule} = sub {
        my $content = shift;
        unless (exists $seen{$content->uid}) {
            undef $seen{$content->uid};
            push @todo, $content;
        }
    };
    $params{next} = sub {
        my $content = pop @todo;
        if ($content) {
            my $uid = $content->uid;
            die if $seen{$uid};
            $seen{$uid}++;
        }
        $content;
    };

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
                    $sched->($got_content);
                    # If this is a generated page, it's an HTML.
                    $out .= '.html';
                }
                return $out;
            }

            # Else this is an URL
            $got_content;
        }
    };

    $class->$orig(%params);
};

sub mkhref {
    my $self = shift;
    my $content = shift;

    my $out = {
        href => join('/', $self->base_url, $content->from_root) . '.html',
        slug => encode($self->encoding, $content->title),
    };
    if (my $date = $content->date) {
        $out->{date} = $date->to_hash;
    }

    $self->schedule->($content);
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
        site => $self,
        content => {
            title => encode($self->encoding, $content->title),
            date => $content->date ? $content->date->to_hash : undef,
            kind => substr(ref $content, prefix_len),
        },
        links => \%links,
    };

    if ($content->isa('App::PFT::Content::Text')) {
        my @tags;
        foreach ($content->tags) {
            push @tags, $self->mkhref($_);
        }
        my $cvars = $vars->{content};
        $cvars->{tags} = \@tags if @tags;
        @{$cvars}{'text', 'html'} = (
            encode($self->encoding, $content->text),
            encode(
                $self->encoding,
                $self->resolve($content, markdown $content->text),
            ),
        );
    }

    @links{keys %{$self->links}} = values %{$self->links};

    if ($content->isa('App::PFT::Content::Linked')) {
        $links{prev} = $self->mkhref($content->prev) if $content->has_prev;
        $links{next} = $self->mkhref($content->next) if $content->has_next;
        $links{root} = $self->mkhref($content->root) if $content->has_root;

        if ($content->has_links) {
            $links{related} = [
                map { $self->mkhref($_) } sort $content->list_links
            ];
        }
    }

    my $fn = catfile($self->tree->dir_build, $content->from_root) . '.html';
    make_path dirname($fn), { verbose => 1 };
    $be->process(
        ($content->template || $self->default_template) . '.html',
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

    $self->tree->link;

    $sched->($_) foreach (
        $self->tree->list_entries,
        $self->tree->list_pages,
    );

    while (my $e = $next->()) {
        eval {
            $self->process($e);
        };
        if ($@) {
            croak "While compiling $e: \n\t", $@;
        } else {
            say STDERR "Compiled $e";
        }
    }
}

sub DEMOLISH {
    my $self = shift;
    my $h = $self->tree->page(title => $self->home);
    if ($h->exists) {
        my $fn = catfile($self->tree->dir_build, 'index.html');
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
