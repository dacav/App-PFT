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
    $self;
}

sub _mknod {
    my $idref = \(shift->{next});
    local $_ = shift if @_;
    my($p, $h) = ref($_) eq 'PFT::Header'
        ? (undef, $_)
        : ($_, $_->header);
    { id => ++ $$idref, p => $p, h => $h, d => $h->date }
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
        weaken($_->{'<'} = $prev);
        defined($prev) and weaken($prev->{'>'} = $_);

        my $m_node = do {
            my $m_date = $_->{d}->derive(d => undef);

            if (@months == 0 or $months[-1]->{d} <=> $m_date) {
                my $m_hdr = PFT::Header->new(date => $m_date);
                my $m_page = $tree->entry($m_hdr);
                my $n = $self->_mknod($m_page->exists ? $m_page : $m_hdr);
                push @months, $n;
            }
            $months[-1]
        };

        weaken($_->{'^'} = $m_node);
        $#{$m_node->{'v'}} ++;
        weaken($m_node->{'v'}->[-1] = $_);
        if (defined($m_node->{'<'} = $months[$#months])) {
            weaken($months[$#months]->{'>'} = $m_node)
        }

        $prev = $_;
    }

    push @{$self->{pages}}, @blog, @months;
}

=head2 Methods

=over

=item dump

=cut

sub dump {
    my $node_dump = sub {
        my $node = shift;
        {
            id  => $node->{id},
            '<' => exists $node->{'<'} ? $node->{'<'}->{id} : undef,
            '>' => exists $node->{'>'} ? $node->{'>'}->{id} : undef,
            '^' => exists $node->{'^'} ? $node->{'^'}->{id} : undef,
            t   => $node->{h}->title,
            d   => "$node->{d}",
            'v' => exists $node->{'v'}
                   ? join ', ', map{ $_->{id} } @{$node->{'v'}}
                   : undef
        }
    };

    my $self = shift;
    map { $node_dump->($_) } @{$self->{pages}};
}

=back

=cut

1;
