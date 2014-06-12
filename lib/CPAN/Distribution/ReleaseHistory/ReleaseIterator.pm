use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Distribution::ReleaseHistory::ReleaseIterator;

our $VERSION = '0.001000';

# ABSTRACT: A container to iterate a collection of releases for a single distribution

# AUTHORITY

use Moo qw( has );
use CPAN::DistnameInfo;
use CPAN::Releases::Latest::Release;

=attr C<result_set>

A C<MetaCPAN::Client::ResultSet>  instance that dispatches C<MetaCPAN::Client::Result> objects.

=cut

has 'result_set' => ( is => 'ro', required => 1 );

=method C<next_release>

Returns a L<< C<CPAN::Releases::Latest::Release>|CPAN::Releases::Latest::Release >>

  my $item = $release_iterator->next_release();

=cut

sub next_release {
  my ($self) = @_;
  my $scroll_result = $self->result_set->next;
  return if not $scroll_result;
  require MetaCPAN::Client::Release;
  my $result = MetaCPAN::Client::Release->new_from_request( $scroll_result->{'_source'} || $scroll_result->{'fields'} );
  return if not $result;
  my $path = $result->download_url;
  $path =~ s{\A.*/authors/id/}{}msx;
  my $distinfo = CPAN::DistnameInfo->new($path);
  my $distname =
    defined($distinfo) && defined( $distinfo->dist )
    ? $distinfo->dist
    : $result->name;
  return CPAN::Releases::Latest::Release->new(
    distname  => $distname,
    path      => $path,
    timestamp => $result->stat->{mtime},
    size      => $result->stat->{size},
  );
}

no Moo;

1;

