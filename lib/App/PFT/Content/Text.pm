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

has path => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has fname => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

sub edit() {
    my $self = shift;
    my $path = $self->path;
    croak 'Undefined env variable $EDITOR' unless defined $ENV{EDITOR};
    system($ENV{EDITOR}, $path);

    if (-z $path) {
        print STDERR 'Removing file', $path, "\n";
        unlink $path;
    } else {
        eval {
            App::PFT::Data::Header->new(-load => $self->file);
        };
        say STDERR "WARNING: Bad file format in $path: $@" if $@;
    }
}

sub title() {
    shift->header->title
}

sub exists { -e shift->path }

sub file {
    my $self = shift;
    IO::File->new($self->path, @_) # Has autoclose upon undef.
        or confess 'Cannot open "' . $self->path . ": $!";
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

sub text {
    join "\n", @{shift->lines}
}

has header => (
    is => 'rw',
    isa => 'App::PFT::Data::Header',
    lazy => 1,
    predicate => 'header_is_loaded',
    default => sub {
        my $self = shift;
        my $hdr = eval {
            App::PFT::Data::Header->new(
                -load => $self->file,
            );
        };
        croak 'Bad file format in ', $self->path, ': ', $@ if $@;
        $hdr
    }
);

sub lookup {
    my $self = shift;
    $self->tree->lookup(
        relative_to => $self,
        kind => shift,
        hint => \@_,
    )
}

sub date() { undef }
sub has_links() { 0 }
sub has_month() { 0 }
sub has_prev() { 0 }
sub has_next() { 0 }

no Moose;
__PACKAGE__->meta->make_immutable;

1;
