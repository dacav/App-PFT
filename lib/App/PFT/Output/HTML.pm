package App::PFT::Output::HTML;

use strict;
use warnings;

use Template::Alloy;
use Text::MultiMarkdown qw/markdown/;
use IO::File;
use Encode;

use File::Spec::Functions qw/catdir catfile/;
use File::Path qw/remove_tree make_path/;
use File::Basename qw/dirname/;

use App::PFT::Util;

use namespace::autoclean;
use Moose;

has site_title => (is => 'ro', isa => 'Str');
has site_footer => (is => 'ro', isa => 'Str');
has base_url => (is => 'ro', isa => 'Str');
has outputenc => (is => 'ro', isa => 'Str', default => sub{'utf-8'});
has build_path => (is => 'ro', isa => 'Str');

has template_dirs => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub{[]},
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
            INCLUDE_PATH => $_[0]->template_dirs,
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

    my($build_path, $base_url) = @params{'build_path','base_url'};
    die unless $build_path;
    die unless $base_url;

    remove_tree $build_path;
    make_path $build_path;

    $params{lookups} = {
        pic => do {
            if (my $from_pics = $params{pics_path}) {
                my $to_pics = catdir($build_path, 'pics');
                App::PFT::Util::ln $from_pics, $to_pics;
                sub { catfile($to_pics, @_) };
            } else {
                undef;
            }
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
    my($self, $content) = @_;
    my $out = {
        href => join('/', $self->base_url, $content->from_root) . '.html',
        slug => $content->title,
    };
    if (my $date = $content->date) {
        $out->{date} = {
            y => $date->year,
            m => $date->month,
            d => $date->day,
        }
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

    my $vars = {
        site => {
            title => $self->site_title,
            encoding => $self->outputenc,
        },
        content => {
            title => encode($self->outputenc, $content->title),
            text => encode($self->outputenc, $content->text),
            html => encode(
                $self->outputenc,
                $self->resolve($content, markdown $content->text),
            ),
        },
    };

    $vars->{links}{prev} = $self->mkhref($content->prev) if $content->has_prev;
    $vars->{links}{next} = $self->mkhref($content->next) if $content->has_next;
    $vars->{links}{root} = $self->mkhref($content->month) if $content->has_month;
    if ($content->has_links) {
        my @hrefs = map { $self->mkhref($_) } @{$content->links};
        $vars->{links}{related} = \@hrefs;
    }

    my $fn = catfile($self->build_path, $content->from_root) . '.html';
    make_path dirname($fn), { verbose => 1 };
    $be->process(
        $content->header->template . '.html',
        $vars,
        (IO::File->new($fn, 'w') or die "Unable to open $fn: $!")
    ) or die $be->error;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
