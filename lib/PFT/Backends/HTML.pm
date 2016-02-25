package PFT::Backends::HTML v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Backends::HTML - Dump website in HTML format

=head1 SYNOPSIS

    my $tree = PFT::Content->new($basedir);
    my $opts = { ... }
    my $hbe = PFT::Backends::HTML->new($tree, $opts);

=head1 DESCRIPTION

=cut

use Template::Alloy;
use File::Spec;

use Carp;

use parent 'PFT::Backends::Base';

my $check_opts = sub {
    my $opts = shift;

    foreach(qw/
        title
        home
        base_url
        encoding
        default_template
    /) {
        confess "Missing option $_" unless exists $opts->{$_}
    }
};

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(shift);
    $self->{opts} = $check_opts->(shift());
    $self->{tmpl} = Template::Alloy->new(
        INCLUDE_PATH => [$self->dir_templates]
    );

    $self
}

sub dir_templates {
    File::Spec->catdir(shift->tree->dir_templates, 'html')
}

=head2 Methods

=over

=item dump

=cut

=back

=cut

1;
