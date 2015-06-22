package App::PFT::Data::Header;

use strict;
use warnings;

use namespace::autoclean;
use Moose;

use YAML::XS;

has title => (
    isa => 'Str',
    is => 'ro',
);

has hide => (
    isa => 'Maybe[Str]',
    is => 'ro',
    predicate => 'is_hidden',
);

has author => (
    isa => 'Maybe[Str]',
    is => 'ro',
);

has encoding => (
    isa => 'Maybe[Str]',
    is => 'ro',
    default => sub { 'utf-8' },
);

sub dump() {
    my($self) = @_;
    YAML::XS::Dump {
        Title => $self->title(),
        Hide => $self->hide(),
        Author => $self->author(),
        Encoding => $self->encoding(),
    }
}

sub flat_title() {
    my $out = $_[0]->title;
    $out =~ s/\W/-/g;
    $out =~ s/--+/-/g;
    $out =~ s/-*$//;
    $out =~ y/[A-Z]/[a-z]/;
    $out;
}

around BUILDARGS => sub {
    my ($orig, $class, %params) = @_;

    die 'Missing title' unless $params{title};

    if (my $from = $params{'-load'}) {
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
                die "Only supporting GLOB and strings. Got $type" if $type;
                $text = $from;
            }
            YAML::XS::Load($text)
        };

        $params{title} = $hdr->{Title};
        if (my $hide = $hdr->{Hide}) {
            $params{hide} = $hide;
        }
        $params{author} = $hdr->{Author};
        $params{encoding} = $hdr->{Encoding};
    }

    $class->$orig(%params);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
