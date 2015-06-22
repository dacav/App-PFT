package App::PFT::Content::Text;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

use IO::File;

use Encode;

use App::PFT::Data::Header;

extends 'App::PFT::Content::Base';

has path => (is => 'ro', isa => 'Str');
has fname => (is => 'ro', isa => 'Str');

sub edit() { system($ENV{EDITOR}, shift->path) }

sub title() { shift->header->title }

sub file {
    my $self = shift;

    my $create = -e $self->path && $self->header_is_loaded;
    my $out = IO::File->new($self->path, @_) # Has autoclose upon undef.
        or die 'Cannot open "' . $self->path . ": $!";

    print $out, $self->header->dump if $create;
    $out;
}

has lines => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $fd = $self->file;
        my $hdr = App::PFT::Data::Header->new(
            -load => $fd
        );
        $self->header($hdr) unless $self->header_is_loaded;
        my @out = map { chomp; decode($hdr->encoding, $_) } <$fd>;
        \@out;
    },
);

sub text { join "\n", @{shift->lines} }

has header => (
    is => 'rw',
    isa => 'App::PFT::Data::Header',
    lazy => 1,
    predicate => 'header_is_loaded',
    default => sub {
        my $self = shift;
        App::PFT::Data::Header->new(
            -load => $self->file,
        );
    }
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
