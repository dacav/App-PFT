package App::PFT::Data::Date;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

has year => (is => 'ro', isa => 'Int');
has month => (is => 'ro', isa => 'Int');
has day => (is => 'ro', isa => 'Int');

sub repr {
    my($self, $sep) = @_;
    $sep = '-' unless defined $sep;
    return join $sep, $self->year, $self->month, $self->day;
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

my %FILLS = (
    now => sub {
        (localtime)[5,4,3]
    },

    # yesterday => sub {...}
);

around BUILDARGS => sub {
    my ($orig,$class,%params) = @_;

    if (my $fill = $params{'-fill'}) {
        my ($y, $m, $d) = do {
            my $cb = $FILLS{$fill};
            die ('Unknown fill method ' . $fill) unless $cb;
            $cb->(@{$params{'-fill-args'} || []});
        };
        $params{year} = $y + 1900 unless $params{year};
        $params{month} = $m + 1 unless $params{month};
        $params{day} = $d unless $params{day};
    }

    if ((my $m = $params{month}) !~ m/^\d{1,2}$/) {
        $m =~ s/^(j(?:a|u[nl])|[fsond]|ma[ry]|a[pu]).*/$MONTHS{$1}/e
            or die "Invalid month: $m";
        $params{month} = $m;
    } else {
        die "Invalid month: $m" unless ($m >= 1 && $m <= 12);
    }

    my $d = $params{day};
    die "Invalid day: $d" if ($d !~ m/^\d{1,2}$/ || $d < 1 || $d > 30);

    return $class->$orig(%params);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
