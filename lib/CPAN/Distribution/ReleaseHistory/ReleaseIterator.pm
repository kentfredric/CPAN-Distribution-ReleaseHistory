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

has 'result_set' => ( is => 'ro', required => 1 );

sub next_release {
  my ($self) = @_;
  my $result = $self->result_set->next;
  return if not $result;

  my $path     = $result->download_url;
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

