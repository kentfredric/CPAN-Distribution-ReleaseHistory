use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Distribution::ReleaseHistory::ReleaseIterator;

our $VERSION = '0.002002';

# ABSTRACT: A container to iterate a collection of releases for a single distribution

# AUTHORITY

use Moo qw( has );
use CPAN::DistnameInfo;
use CPAN::Distribution::ReleaseHistory::Release;

=attr C<scroller>

A C<Search::Elasticsearch::Scroll>  instance that dispatches results.

=cut

has 'scroller' => ( is => 'ro', required => 1 );

=method C<next_release>

Returns a L<< C<CPAN::Distribution::ReleaseHistory::Release>|CPAN::Distribution::ReleaseHistory::Release >>

  my $item = $release_iterator->next_release();

=cut

sub next_release {
  my ($self) = @_;
  my $scroll_result = $self->scroller->next;
  return if not $scroll_result;

  my $data_hash = $scroll_result->{'_source'} || $scroll_result->{'fields'};
  return if not $data_hash;

  my $path = $data_hash->{download_url};
  $path =~ s{\A.*/authors/id/}{}msx;
  my $distinfo = CPAN::DistnameInfo->new($path);
  my $distname =
    defined($distinfo) && defined( $distinfo->dist )
    ? $distinfo->dist
    : $data_hash->{name};
  return CPAN::Distribution::ReleaseHistory::Release->new(
    distname  => $distname,
    path      => $path,
    timestamp => $data_hash->{stat}->{mtime},
    size      => $data_hash->{stat}->{size},
  );
}

no Moo;

1;
