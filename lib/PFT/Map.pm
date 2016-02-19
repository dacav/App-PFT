package PFT::Map v0.0.1;

use v5.10;

use strict;
use warnings;
use utf8;

=pod

=encoding utf8

=head1 NAME

PFT::Map - Map of a PFT site

=head1 SYNOPSIS

    my $tree = PFT::Tree->new($basedir);
    PFT::Map->new($tree);

=head1 DESCRIPTION

Map of a PFT site

=cut

use WeakRef;

sub new {
    my $cls = shift;
    my $tree = shift;

    my $self = bless {
        tree => $tree,
        next => 0,
        nodes => [],
    }, $cls;

    $self->_scan_pages;
    $self->_scan_blog;
    $self->_scan_tags;
    $self;
}

use PFT::Map::Node;

sub _mknod {
    PFT::Map::Node->new(shift->{next} ++, @_ ? shift : $_);
}

sub _scan_pages {
    my $self = shift;
    push @{$self->{nodes}}, map $self->_mknod, $self->{tree}->pages_ls;
}

sub _scan_blog {
    my $self = shift;
    my $tree = $self->{tree};
    my @blog = map $self->_mknod, $tree->blog_ls;
    my @months;

    my($prev, $prev_month);
    foreach (sort { $a->date <=> $b->date } @blog) {
        $_->prev($prev) if defined $prev;

        my $m_node = do {
            my $m_date = $_->date->derive(d => undef);

            if (@months == 0 or $months[-1]->date <=> $m_date) {
                my $m_hdr = PFT::Header->new(date => $m_date);
                my $m_page = $tree->entry($m_hdr);
                my $n = $self->_mknod($m_page->exists ? $m_page : $m_hdr);
                $n->prev($months[-1]) if @months;
                push @months, $n;
            }
            $months[-1]
        };

        $_->month($m_node);
        $prev = $_;
    }

    push @{$self->{nodes}}, @blog, @months;
}

sub _scan_tags {
    my $self = shift;
    my $tree = $self->{tree};
    my %tags;

    for my $node (@{$self->{nodes}}) {
        foreach (@{$node->header->tags}) {
            my $t_node = exists $tags{$_} ? $tags{$_} : do {
                my $t_hdr = PFT::Header->new(title => $_);
                my $t_page = $tree->tag($t_hdr);
                $tags{$_} = $self->_mknod(
                    $t_page->exists ? $t_page : $t_hdr
                );
            };
            $node->add_tag($t_node);
        }
    }

    push @{$self->{nodes}}, sort { $a <=> $b } values %tags;
}

=head2 Methods

=over

=item dump

=cut

use feature 'say';

sub dump {
    my $node_dump = sub {
        my $node = shift;
        my %out = (
            id => $node->id,
            tt => $node->header->title || '<month>',
        );

        if (defined(my $prev = $node->prev)) { $out{'<'} = $prev->id }
        if (defined(my $next = $node->next)) { $out{'>'} = $next->id }
        if (defined(my $month = $node->month)) { $out{'^'} = $month->id }
        if (defined(my $date = $node->header->date)) { $out{d} = "$date" }
        if (my @l = $node->days) { $out{v} = [map{ $_->id } @l] }
        if (my @l = $node->tags) { $out{t} = [map{ $_->id } @l] }
        if (my @l = $node->tagged) { $out{'.'} = [map{ $_->id } @l] }

        \%out
    };

    my $self = shift;
    map $node_dump->($_), @{$self->{nodes}};
}

=back

=cut

1;
