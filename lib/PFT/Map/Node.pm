package PFT::Map::Node v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Map::Node - Node of a PFT site map

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Carp;

sub new {
    my $cls = shift;
    my $id = shift;
    my $from = shift;

    my($hdr, $page);
    if ($from->isa('PFT::Header')) {
        $hdr = $from;
    } else {
        confess 'Allowed only PFT::Header or PFT::Content::Page'
            unless $from->isa('PFT::Content::Page');
        ($page, $hdr) = ($from, $from->header);
    }

    bless { id => $id, hdr => $hdr, page => $page }, $cls;
}

=head2 Properties

=cut

sub header { shift->{hdr} }
sub page { shift->{page} }
sub id { shift->{id} }
sub date { shift->{hdr}->date }
sub next { shift->{next} }

use WeakRef;

sub prev {
    my $self = shift;
    return $self->{prev} unless @_;

    my $p = shift;
    weaken($self->{prev} = $p);
    weaken($p->{next} = $self);
}

sub month {
    my $self = shift;
    unless (@_) {
        exists $self->{month} ? $self->{month} : undef;
    } else {
        confess 'Must be dated and date-complete'
            unless eval{ $self->{hdr}->date->complete };

        my $m = shift;
        weaken($self->{month} = $m);

        push @{$m->{days}}, $self;
        weaken($m->{days}[-1]);
    }
}

sub add_tag {
    my $self = shift;

    my $t = shift;
    push @{$self->{tags}}, $t;
    weaken($self->{tags}[-1]);

    push @{$t->{tagged}}, $self;
    weaken($t->{tagged}[-1]);
}

sub _list {
    my($self, $name) = @_;
    exists $self->{$name}
        ? wantarray ? @{$self->{$name}} : $self->{$name}
        : wantarray ? () : undef
}

sub tags { shift->_list('tags') }
sub tagged { shift->_list('tagged') }
sub days { shift->_list('days') }

use overload
    '<=>' => sub {
        my($self, $oth, $swap) = @_;
        my $out = $self->{id} <=> $oth->{id};
        $swap ? -$out : $out;
    },
    '""' => sub {
        'PFT::Map::Node[id='.shift->{id}.']'
    },
;

1;
