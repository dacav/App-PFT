package App::PFT::Content::Blob;

use strict;
use warnings;

use File::Basename qw/basename/;
use Carp;

use namespace::autoclean;
use Moose;

extends 'App::PFT::Content::Base';

has fname => (
    is => 'ro',
    isa => 'Str',
);

has path => (
    is => 'ro',
    isa => 'Str',
);

sub hname { shift->fname }

sub from_root() {
    my $self = shift;
    my @out = (
        'pics',
        $self->fname,
    );
    if (my $up = $self->SUPER::from_root) {
        push @out, $up
    }
    @out
}

around BUILDARGS => sub {
    my($orig, $class, %params) = @_;

    my $fn = $params{path};
    if ($params{'-verify'}) {
        croak "File $fn does not exist" unless -e $fn;
    }
    $params{fname} = basename $fn;
    
    $class->$orig(%params);
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
