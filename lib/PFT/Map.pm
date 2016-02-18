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
        pages => [],
    }, $cls;

    $self->_scan_pages;
    $self->_scan_blog;
    $self->_scan_tags;
    $self;
}

sub _mknod {
    my $idref = \(shift->{next});
    local $_ = shift if @_;
    my($p, $h) = $_->isa('PFT::Header')
        ? (undef, $_)
        : ($_, $_->header);
    my %out = ( id => $$idref ++, h => $h );
    $out{p} = $p if defined $p;
    $out{d} = $h->date if defined $h->date;
    \%out;
}

sub _scan_pages {
    my $self = shift;
    push @{$self->{pages}}, map $self->_mknod, $self->{tree}->pages_ls;
}

sub _scan_blog {
    my $self = shift;
    my $tree = $self->{tree};
    my @blog = map $self->_mknod, $tree->blog_ls;
    my @months;

    my($prev, $prev_month);
    foreach (sort { $a->{d} <=> $b->{d} } @blog) {
        if (defined $prev) {
            weaken($_->{'<'} = $prev);
            weaken($prev->{'>'} = $_);
        }

        my $m_node = do {
            my $m_date = $_->{d}->derive(d => undef);

            if (@months == 0 or $months[-1]->{d} <=> $m_date) {
                my $m_hdr = PFT::Header->new(date => $m_date);
                my $m_page = $tree->entry($m_hdr);
                my $n = $self->_mknod($m_page->exists ? $m_page : $m_hdr);
                if (@months) {
                    weaken($n->{'<'} = $months[-1]);
                    weaken($months[-1]->{'>'} = $n);
                }
                push @months, $n;
            }
            $months[-1]
        };

        weaken($_->{'^'} = $m_node);
        $#{$m_node->{'v'}} ++;
        weaken($m_node->{'v'}->[-1] = $_);

        $prev = $_;
    }

    push @{$self->{pages}}, @blog, @months;
}

sub _scan_tags {
    my $self = shift;
    my $tree = $self->{tree};
    my %tags;

    for my $node (@{$self->{pages}}) {
        foreach (@{$node->{h}->tags}) {
            my $t_node = exists $tags{$_} ? $tags{$_} : do {
                my $t_hdr = PFT::Header->new(title => $_);
                my $t_page = $tree->tag($t_hdr);
                $tags{$_} = $self->_mknod(
                    $t_page->exists ? $t_page : $t_hdr
                );
            };
            $#{$t_node->{'.'}} ++;
            weaken($t_node->{'.'}->[-1] = $node);
            $#{$node->{t}} ++;
            weaken($node->{t}->[-1] = $t_node);
        }
    }

    push @{$self->{pages}}, sort { $a->{id} <=> $b->{id} } values %tags;
}

=head2 Methods

=over

=item dump

=cut

sub dump {
    my $node_dump = sub {
        my $node = shift;
        grep defined, (
            id  => $node->{id},
            tt  => $node->{h}->title || '<month>',
            exists $node->{'<'} ? ('<' => $node->{'<'}->{id}) : undef,
            exists $node->{'>'} ? ('>' => $node->{'>'}->{id}) : undef,
            exists $node->{'^'} ? ('^' => $node->{'^'}->{id}) : undef,
            exists $node->{d}   ? ('d' => "$node->{d}")       : undef,
            exists $node->{'v'}
                ? ('v' => [map{ $_->{id} } @{$node->{'v'}}])
                : undef,
            exists $node->{t}
                ? (t => [map{ $_->{id} } @{$node->{t}}])
                : undef,
            exists $node->{'.'}
                ? ('.' => [map{ $_->{id} } @{$node->{'.'}}])
                : undef,
        )
    };

    my $self = shift;
    map {{ $node_dump->($_) }} @{$self->{pages}};
}

=back

=cut

1;
