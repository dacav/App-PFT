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

    PFT::Text::Header->load(STDIN);
    PFT::Text::Header->load('/path/to/file');

    PFT::Text::Header->new(
        title => $title,        # mandatory, encoded form
        author => $author,      # optional, encoded form
        template => $template,
        encoding => $encoding,  # defaults 'utf-8'
        tags => $tags,          # list of encoded bytes, defaults []
        opts => $opts,          # defaults {}
    );

=head1 DESCRIPTION

A header starts with a valid YAML document (including the leading '---'
line and ends with another '---' line.

The I<title> parameter is mandatory;

The I<title> and I<author> parameters are expected to be byte strings
encoded according to the I<encoding> parameter. The I<tag> parameter is
expected to be a list of encoded strings.

=cut

use Encode 'decode';

sub new {
    my $cls = shift;
    my %opts = @_;

    exists $opts{title} or die 'title is mandatory';

    my $enc = $opts{encoding} || 'utf-8';
    my $dec = sub { decode $enc, shift };

    bless {
        title => $dec->($opts{title}),
        author => $dec->($opts{author}),
        template => $opts{template},
        encoding => $enc,
        tags => map { $dec->($_) } ($opts{tags} || []),
        opts => $opts{opts} || {},
    }, $cls;
}

sub title { shift->{title} }
sub author { shift->{author} }
sub template { shift->{template} }
sub encoding { shift->{encoding} }
sub opts { shift->{opts} }

1;

