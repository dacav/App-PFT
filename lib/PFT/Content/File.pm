package PFT::Content::File;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Content::File - On disk content file.

=head1 SYNOPSIS

    use PFT::Content::File;

    my $f1 = PFT::Content::File->new({
        tree => $tree,  # see PFT::Content::Base
        path => $path,
        name => $name,  # optional, defaults to basename($path)
    });

=cut

use File::Basename 'basename';
use File::Spec;
use Carp;

use parent 'PFT::Content::Base';

sub new {
    my $self = shift->SUPER::new(@_);
    my $params = shift;

    exists $params->{path} or confess 'Missing param: path';
    my $path = $params->{path};
    my $name = $params->{name} || basename $path;

    $self->{p} = File::Spec->rel2abs($path);
    $self->{fn} = $name;

    $self
}

=head1 DESCRIPTION

This class describes a file on disk..

=head2 Properties

=over

=cut

=item path

Absolute path of the file on the filesystem.

=cut 

sub path { shift->{p} }

=item filename

Base naeme or human friendly name of the file.

=cut

sub filename { shift->{fn} }

=item mtime

Last modification time according to the filesystem.

=cut

sub mtime {
    (stat shift->path)[9];
}

=item open

Open a file descriptor for the file:

    $f->open        # Read file descriptor
    $f->open($mode) # Open with r/w/a mode

=cut

sub open {
    my $path = shift->path;
    my $mode = shift;
    make_path dirname $path if $mode =~ /w|a/;
    IO::File->new($path, $mode) or croak "Cannot open $path: $!"
}

=item touch

Change modification time on the filesytem to current timestamp.

=cut

sub touch {
    shift->open('a')
};

=item exists

Verify if the file exists

=cut

sub exists {
    -e shift->path
}

=back

=cut

1;


