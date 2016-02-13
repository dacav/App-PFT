package PFT::Date v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Date - Representation of date

=head1 SYNOPSIS

    PFT::Date->new(2016, 12, 10)

    PFT::Date->from_spec(
        d => 12,
        m => 'june', # human friendly
        # missing ones (e.g. year) filled with today's year.
    )

    PFT::Date->from_string('1955-11-05');

=head1 DESCRIPTION

PFT::Date is defined as a blessed array reference. The first element is
the year, the second is the month, the third is the day.

=cut

use Carp;

use overload 
    '""' => sub { shift->repr('-') }
;

sub new {
    my $cls = shift;
    my $self = bless [map { defined and int or undef } @_[0 .. 2]], $cls;

    $self->[1] > 0 && $self->[1] < 13 or confess "Month $self->[1]";
    $self->[2] > 0 && $self->[2] < 32 or confess "Day $self->[2]";

    $self
}

my %MONTHS = (
    ja  => 1,
    f   => 2,
    mar => 3,
    ap  => 4,
    may => 5,
    jun => 6,
    jul => 7,
    au  => 8,
    s   => 9,
    o   => 10,
    n   => 11,
    d   => 12,
);

sub from_spec {
    my $cls = shift;
    my %params = @_;

    my($y, $m, $d) = (localtime)[5, 4, 3];

    exists $params{d} or $params{d} = $d;
    if (local $_ = $params{m}) {
        if (/^\d{1,2}$/) {
            $params{m} = int($_)
        } elsif (m/^(j(?:a|u[nl])|[fsond]|ma[ry]|a[pu]).*/) {
            $params{m} = $MONTHS{$1}
        } else {
            croak "Invalid month: $_";
        }
    } else {
        $params{m} = $m + 1;
    }
    exists $params{y} or $params{y} = $y + 1900;

    bless [ @params{qw/y m d/} ], $cls
}

sub from_string {
    my $cls = shift;
    my $text = shift;

    my ($y, $m, $d) = $text =~ m/^(\d{4})-(\d{2})-(\d{2})$/
        or croak "Date \"$text\" not in YYYY-MM-DD format";

    bless [int($y), int($m), int($d)], $cls;
}

=head2 Properties

=over

=item y

Year getter

=item m

Month getter

=item d

Day getter

=cut

sub y { shift->[0] }
sub m { shift->[1] }
sub d { shift->[2] }

=item to_hash

Returns a dictionary in the form

    { y => ..., m => ..., d => ... }

=cut

sub to_hash {
    my %out;
    @out{qw/y m d/} = @{shift()};
    \%out;
}

=item repr

Returns a string representing the date. Optional parameter is a separator
string, by default C<'-'>

    PFT::Date->new(1,2,3)->repr      eq '0001-02-03'
    PFT::Date->new(1,2,3)->repr('/') eq '0001/02/03'

=cut

sub repr {
    my $self = shift;
    join shift || '-',
        defined $self->[0] ? sprintf('%04d', $self->[0]) : '*',
        defined $self->[1] ? sprintf('%02d', $self->[1]) : '*',
        defined $self->[2] ? sprintf('%02d', $self->[2]) : '*';
}

=item derive

Returns a copy of the PFT::Date object with the provided components
replaced.

    PFT::Date->new(1, 2, 3)->derive(m => undef)

is like

    PFT::Date->new(1, undef, 3)

=cut

sub derive {
    my $self = shift;
    my %change = @_;
    PFT::Date->new(
        exists $change{y} ? $change{y} : $self->y,
        exists $change{m} ? $change{m} : $self->m,
        exists $change{d} ? $change{d} : $self->d,
    )
}

=pod

=back

=cut

1;
