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
package App::PFT::Data::Header v0.04.0;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

use Encode;

use Carp;
use YAML::Tiny;

use App::PFT::Struct::Conf qw/$AUTHOR $TEMPLATE $INPUT_ENC/;
use App::PFT::Util qw/slugify/;

has title => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

has template => (
    isa => 'Maybe[Str]',
    is => 'ro',
);

has author => (
    isa => 'Str',
    is => 'ro',
    lazy => 1,
    default => sub { $AUTHOR || confess 'Missing $AUTHOR' },
);

has encoding => (
    isa => 'Maybe[Str]',
    is => 'ro',
    lazy => 1,
    default => sub { $INPUT_ENC || confess 'Missing $INPUT_ENC' },
);

has tags => (
    isa => 'ArrayRef[Str]',
    is => 'ro',
    lazy => 1,
    default => sub {[]},
);

has opts => (
    isa => 'Maybe[HashRef]',
    is => 'ro',
    predicate => 'has_opts',
);

sub dump {
    my($self, $to) = @_;

    my $type = ref $to;
    if ($type ne 'GLOB' && $type ne 'IO::File') {
        confess "Only supporting GLOB and IO::File. Got ",
            $type ? $type : 'Scalar'
    }
    my $tags = $self->tags;
    print $to Encode::encode($INPUT_ENC, YAML::Tiny::Dump {
        Title => $self->title,
        Author => $self->author,
        Encoding => $self->encoding,
        Template => $self->template,
        Tags => @$tags ? $tags : undef,
        Options => $self->has_opts ? $self->opts : undef,
    })
}

sub slug {
    slugify shift->title;
}

my $load_file = sub {
    my $params = shift;
    my $from = $params->{'-load'};

    my $hdr = do {
        # Header starts with a valid YAML document (including the leading
        # /^---$/ string) and ends with another /^---$/ string.

        my $text;
        my $type = ref $from;
        if ($type eq 'GLOB' || $type eq 'IO::File') {
            $text = <$from>;
            while (<$from>) {
                last if ($_ =~ /^---$/);
                $text .= $_;
            }
        } else {
            confess "Only supporting GLOB and IO::File. Got $type" if $type;
            $text = $from;
        }
        eval { YAML::Tiny::Load($text) };
    };
    croak $@ if $@;

    my $decode = do {
        my $enc = $params->{encoding} = $hdr->{Encoding} || $INPUT_ENC;
        sub {
            my $v = $hdr->{$_[0]};
            croak "Conf '$_[0]' is mandatory" if $_[1] && !defined $v;
            if (ref $v) {
                croak "Conf '$_[0]' must be a string"
            }
            decode($enc, $v)
        }
    };
    $params->{title} = $decode->(Title => 1);
    $params->{author} = $decode->(Author => 0);
    $params->{template} = $decode->(Template => 0) if $hdr->{Template};
    $params->{opts} = $hdr->{Options};

    my $tags = $hdr->{Tags};
    $params->{tags} = ref $tags eq 'ARRAY' ? $tags
                    : defined $tags ? [$tags]
                    : []
                    ;
};

my $generate = sub {
    my $params = shift;
    $params->{title} = Encode::decode($INPUT_ENC, $params->{title});
};

around BUILDARGS => sub {
    my ($orig, $class, %params) = @_;

    if ($params{'-load'}) {
        $load_file->(\%params)
    } else {
        $generate->(\%params)
    }

    $class->$orig(%params);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
