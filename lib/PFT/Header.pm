package PFT::Header v0.0.1;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Header - Header for PFT content textfiles

=head1 SYNOPSIS

    use PFT::Header;

    my $hdr = PFT::Header->new(
        title => $title,        # mandatory
        author => $author,
        template => $template,
        encoding => $encoding,  # defaults 'utf-8'
        tags => $tags,          # defaults []
        opts => $opts,          # defaults {}
    );

    my $hdr = PFT::Header->load(STDIN);

    my $hdr = PFT::Header->load('/path/to/file');

=head1 DESCRIPTION

A header starts with a valid YAML document (including the leading '---'
line and ends with another '---' line.

The I<title> parameter is mandatory;

The I<title> and I<author> parameters are expected to be byte strings
encoded according to the I<encoding> parameter. The I<tag> parameter is
expected to be a list of encoded strings.

=cut

use Encode qw/encode decode/;
use Carp;
use YAML::Tiny;

use PFT::Date;

our $DEFAULT_ENC = 'utf-8';

my $params_check = sub {
    my $params = shift;

    if (exists $params->{date} and defined(my $d = $params->{date})) {
        $d->isa('PFT::Date')
            or confess 'date parameter must be PFT::Date';

        if ($d->complete) {
            exists $params->{title}
                or croak 'Title is mandatory headers having complete date';
        } elsif (!defined $d->y or !defined $d->m) {
            croak 'Year and month are mandatory for headers with date';
        }
    } else {
        exists $params->{title}
            or croak 'Title is mandatory for headers not having dates';
    }
};

sub new {
    my $cls = shift;
    my %opts = @_;

    my $enc = $opts{encoding} || $DEFAULT_ENC;
    $params_check->(\%opts);

    bless {
        title => $opts{title},
        author => $opts{author},
        template => $opts{template},
        encoding => $enc,
        date => $opts{date},
        tags => $opts{tags} || [],
        opts => $opts{opts} || {},
    }, $cls;
}

sub load {
    my $cls = shift;
    my $from = shift;

    if (my $type = ref $from) {
        unless ($type eq 'GLOB' || $type eq 'IO::File') {
            confess "Only supporting GLOB and IO::File. Got $type";
        }
    } else {
        my $fh = IO::File->new($from) or confess "Cannot open $from";
        $from = $fh;
    }

    # Header starts with a valid YAML document (including the leading
    # /^---$/ string) and ends with another /^---$/ string.
    my $text = <$from>;
    local $_;
    while (<$from>) {
        last if ($_ =~ /^---$/);
        $text .= $_;
    }

    my $hdr = eval { YAML::Tiny::Load($text) };
    $hdr or confess 'Loading header: ' . $@ =~ s/ at .*$//rs;

    my $enc = $hdr->{Encoding} || $DEFAULT_ENC;

    my $decode = sub {
        my $v = $hdr->{$_[0]};
        croak "Conf '$_[0]' is mandatory" if $_[1] && !defined $v;
        croak "Conf '$_[0]' must be a string" if ref $v;
        decode($enc, $v)
    };

    my $date;
    $hdr->{Date} and $date = eval {
        PFT::Date->from_string($hdr->{Date})
    };
    croak $@ =~ s/ at .*$//rs if $@;

    my $self = {
        title => $decode->(Title => 1),
        author => $decode->(Author => 0),
        template => exists $hdr->{Template}
            ? $decode->(Template => 0)
            : undef,
        tags => do {
            my $tags = $hdr->{Tags};
            ref $tags eq 'ARRAY' ? $tags
                : defined $tags ? [$tags]
                : []
        },
        encoding => $enc,
        date => $date,
        opts => exists $hdr->{Options}
            ? $hdr->{Options}
            : undef,
    };
    $params_check->($self);

    bless $self, $cls;
}

=head2 Properties

    $hdr->title
    $hdr->author
    $hdr->template
    $hdr->encoding
    $hdr->tags
    $hdr->date
    $hdr->opts
    $hdr->slug
    $hdr->slug_tags

=cut

sub title { shift->{title} }
sub author { shift->{author} }
sub template { shift->{template} }
sub encoding { shift->{encoding} }
sub tags { shift->{tags} }
sub date { shift->{date} }
sub opts { shift->{opts} }

my $slugify = sub {
    my $out = shift;
    $out =~ s/[\W_]/-/g;
    $out =~ s/--+/-/g;
    $out =~ s/-$//;
    lc $out
};

sub slug {
    $slugify->(shift->{title})
}

sub slug_tags {
    map{ $slugify->($_) } @{shift->tags || []}
}

=head2 Methods

=over

=item enc

Encode a string with the encoding defined by the header

=cut

sub enc {
    my $enc = shift->{encoding};
    wantarray
        ? map { encode($enc, $_) } @_
        : encode($enc, shift)
}

=item dec

Decode a byte string with the encoding defined by the header

=cut

sub dec {
    my $enc = shift->{encoding};
    wantarray
        ? map { decode($enc, $_) } @_
        : decode($enc, shift)
}

=item set_date

=cut

sub set_date {
    my $self = shift;
    my $date = pop;

    $date->isa('PFT::Date') or confess 'Must be PFT::Date';
    $self->{date} = $date;
}

=item dump

Dump the header on a file. A GLOB or IO::File is expected as argument.

=cut

sub dump {
    my $self = shift;
    my $to = shift;

    my $type = ref $to;
    if ($type ne 'GLOB' && $type ne 'IO::File') {
        confess "Only supporting GLOB and IO::File. Got ",
                $type ? $type : 'Scalar'
    }
    my $tags = $self->tags;
    print $to encode($self->encoding, YAML::Tiny::Dump {
        Title => $self->title,
        Author => $self->author,
        Encoding => $self->encoding,
        Template => $self->template,
        Tags => @$tags ? $tags : undef,
        Date => $self->date ? $self->date->repr('-') : undef,
        Options => $self->opts,
    }), "---\n"
}

=back

=cut

1;
