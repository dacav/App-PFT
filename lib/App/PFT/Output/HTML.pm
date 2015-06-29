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

has months => (
    is => 'ro',
    isa => 'ArrayRef[App::PFT::Content::MonthPage]',
    lazy => 1,
    default => sub {
        my @months = shift->tree->link_months;
        \@months;
    }
);

use Data::Dumper;

has links => (
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my(@pages, @entries, @months);

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

        {
            pages => \@pages,
            backlog => \@entries,
            months => [reverse @months],
        }
    },
);

has lookups => (
    is => 'ro',
    isa => 'HashRef[CodeRef]',
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

    $params{lookups} = {
        pic => do {
            my $from_pics = $tree->dir_pics;
            my $to_pics = catdir($build_path, 'pics');
            # FIXME: probably this works bad.
            App::PFT::Util::ln $from_pics, $to_pics;
            sub { catfile($to_pics, $_[1]) };
        },
        page => sub {
            my $cur_content = shift;
            my $got_content = $cur_content->lookup('page', @_);
            join('/', $base_url, $got_content->from_root) . '.html';
        },
        blog => sub {
            my $cur_content = shift;
            my $got_content = $cur_content->lookup('blog', @_);
            join('/', $base_url, $got_content->from_root) . '.html';
        },
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
    my $lookups = shift->lookups;
    my $curr_content = shift;
    my $str = shift;

    $str =~ s/<(a\s.*?href="):(page|blog|tag):(.*?)"/
        '<' . $1 . $lookups->{$2}->($curr_content, $3) . '"'
    /mge;

    $str =~ s/(<img\s.*?src="):pic:(.*?)(".*?>)/
        my $h = $lookups->{pic}->($curr_content, $2);
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

    @links{keys %{$self->links}} = values %{$self->links};
    $links{prev} = $self->mkhref($content->prev) if $content->has_prev;
    $links{next} = $self->mkhref($content->next) if $content->has_next;
    $links{root} = $self->mkhref($content->month) if $content->has_month;

    if ($content->has_links) {
        my @hrefs = map { $self->mkhref($_) } @{$content->links};
        $links{related} = \@hrefs;
    }

    my $fn = catfile($self->build_path, $content->from_root) . '.html';
    make_path dirname($fn), { verbose => 1 };
    $be->process(
        $content->header->template . '.html',
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

    # Order matters: link_months builds the structure.
    for my $e (@{$self->months}, $self->entries, $self->pages) {
        $self->process($e);
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
