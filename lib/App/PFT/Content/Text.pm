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
package App::PFT::Content::Text v0.03.2;

use strict;
use warnings;

use Moose;
use namespace::autoclean;

extends qw/
    App::PFT::Content::File
/;

use File::Path qw/make_path/;
use IO::File;
use Carp;

use Encode;
use App::PFT::Data::Header;

sub edit() {
    my $self = shift;
    my $path = $self->path;
    croak 'Undefined env variable $EDITOR' unless defined $ENV{EDITOR};
    system($ENV{EDITOR}, $path);

    if (-z $path) {
        say STDERR 'Removing empty file', $path;
        unlink $path;
        return
    }

    my $f = $self->open('r');
    eval {
        App::PFT::Data::Header->new(-load => $f);
    };
    if ($@) {
        say STDERR "WARNING: Bad file format in $path: $@";
        return
    }
    if (eof $f) {
        say STDERR 'Removing file', $path, ': no content';
        return
    }
}

sub title() {
    shift->header->title
}

has lines => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $fd = $self->open('r');
        my $hdr = App::PFT::Data::Header->new(-load => $fd);
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
                -load => $self->open('r'),
            );
        };
        confess 'Bad file format in ', $self->path, ': ', $@ if $@;
        $hdr
    }
);

sub template {
    shift->header->template;
}

sub open {
    my $self = shift;
    my $mode = shift;
    my $f = $self->SUPER::open($mode);
    if (index($mode, 'w') >= 0 or
            index($mode, 'a') >= 0 && -z $self->path) {
        confess "Cannot write-open unless header defined"
            unless $self->header_is_loaded;

        $self->header->dump($f);
        print $f '---';
    }
    $f;
}

sub tags {
    my $self = shift;
    my $tree = $self->tree;
    map { $tree->tag(name => $_) } @{$self->header->tags};
}

sub lookup {
    my $self = shift;
    $self->tree->lookup(
        relative_to => $self,
        kind => shift,
        hint => \@_,
    )
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
