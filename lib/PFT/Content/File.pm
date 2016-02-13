package PFT::Content::File v0.0.1;

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
        tree => $tree,
        path => $path,
        name => $name,  # optional, defaults to basename($path)
    });

=cut

use File::Path qw/make_path/;
use File::Basename qw/basename dirname/;
use File::Spec;

use IO::File;

use Carp;

use parent 'PFT::Content::Base';

use overload
    '""' => sub {
        my $self = shift;
        my($name, $path) = @{$self}{'name', 'path'};
        ref($self) . "({name => \"$name\", path => \"$path\"})"
    },
;

sub new {
    my $cls = shift;
    my $params = shift;

    exists $params->{path} or confess 'Missing param: path';
    my $path = $params->{path};
    exists $params->{name} or $params->{name} = basename $path;
    my $self = $cls->SUPER::new($params);

    $self->{path} = File::Spec->rel2abs($path);
    $self
}

=head1 DESCRIPTION

This class describes a file on disk.

=head2 Properties

Besides the properties following in this section, more are inherited from
PFT::Content::Base.

=over

=cut

=item path

Absolute path of the file on the filesystem.

=cut 

sub path { shift->{path} }

=item filename

Base name of the file

=cut

sub filename { basename shift->{path} }

=item mtime

Last modification time according to the filesystem.

=cut

sub mtime {
    (stat shift->path)[9];
}

=item open

Open a file descriptor for the file:

    $f->open        # Read file descriptor
    $f->open($mode) # Open with r|w|a mode

If C<protect_unlink> was previously called, returns the protected file
descriptor, which could be positioned anywhere, depending on previous
actions on it. The mode parameter is ignored.

=cut

sub open {
    my $self = shift;

    if (exists $self->{unlinked}) {
        $self->{unlinked}
    } else {
        # Regular behavior
        my $path = $self->path;
        my $mode = shift;
        make_path dirname $path if $mode =~ /w|a/;
        IO::File->new($path, $mode) or confess "Cannot open $path: $!"
    }
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

=item protect_unlink

Protect the file by unlinking it, keep it alive with a read file
descriptor.

=cut

sub protect_unlink {
    my $self = shift;

    my $out = $self->{unlinked} = $self->open('r+');
    unlink $self->{path} or confess "Cannot unlink $!";

    return $out;
}

=back

=cut

1;
