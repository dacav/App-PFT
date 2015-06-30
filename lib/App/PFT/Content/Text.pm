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
package App::PFT::Content::Text;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

use IO::File;
use Carp;

use Encode;

use App::PFT::Data::Header;

extends 'App::PFT::Content::Base';

has path => (is => 'ro', isa => 'Str');
has fname => (is => 'ro', isa => 'Str');

sub edit() {
    my $path = shift->path;
    system($ENV{EDITOR}, $path);

    if (-z $path) {
        print STDERR 'Removing file', $path, "\n";
        unlink $path;
    }
}

sub title() { shift->header->title }

sub exists { -e shift->path }

sub file {
    my $self = shift;
    IO::File->new($self->path, @_) # Has autoclose upon undef.
        or die 'Cannot open "' . $self->path . ": $!";
}

has lines => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $fd = $self->file;
        my $hdr = App::PFT::Data::Header->new(
            template => $self->template_name,
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
        my $hdr = eval {
            App::PFT::Data::Header->new(
                template => $self->template_name,
                -load => $self->file,
            );
        };
        croak 'Bad file format in ', $self->path, ': ', $@ if $@;
        $hdr
    }
);

no Moose;
__PACKAGE__->meta->make_immutable;

1;
