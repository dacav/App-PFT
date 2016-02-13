package PFT::Text::Header v0.0.1;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Text::Header - Header for PFT content textfiles

=head1 SYNOPSIS

    use PFT::Text::Header;

    my $hdr = PFT::Text::Header->new(
        title => $title,        # mandatory
        author => $author,
        template => $template,
        encoding => $encoding,  # defaults 'utf-8'
        tags => $tags,          # defaults []
        opts => $opts,          # defaults {}
    );

    my $hdr = PFT::Text::Header->load(STDIN);

    my $hdr = PFT::Text::Header->load('/path/to/file');

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

sub new {
    my $cls = shift;
    my %opts = @_;

    exists $opts{title} or die 'title is mandatory';

    my $enc = $opts{encoding} || $DEFAULT_ENC;

    defined $opts{date} and ref $opts{date} eq 'PFT::Date'
        || confess 'date parameter must be PFT::Date';

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

    my $hdr = do {
        # Header starts with a valid YAML document (including the leading
        # /^---$/ string) and ends with another /^---$/ string.

        my $text;
        my $type = ref $from;
        if ($type eq 'GLOB' || $type eq 'IO::File') {
            $text = <$from>;
            local $_;
            while (<$from>) {
                last if ($_ =~ /^---$/);
                $text .= $_;
            }
        } else {
            croak "Only supporting GLOB and IO::File. Got $type" if $type;
        }
        eval { YAML::Tiny::Load($text) };
    };
    croak $@ =~ s/ at .*$//rs if $@;

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

    bless {
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
    }, $cls;
}

=head2 Properties

    $hdr->title
    $hdr->author
    $hdr->template
    $hdr->encoding
    $hdr->tags
    $hdr->date
    $hdr->opts

=cut

sub title { shift->{title} }
sub author { shift->{author} }
sub template { shift->{template} }
sub encoding { shift->{encoding} }
sub tags { shift->{tags} }
sub date { shift->{date} }
sub opts { shift->{opts} }

=head2 Methods

=over

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

=pod

=back

=cut

1;
