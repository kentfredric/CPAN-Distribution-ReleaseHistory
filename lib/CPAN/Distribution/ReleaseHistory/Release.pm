use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Distribution::ReleaseHistory::Release;

our $VERSION = '0.001001';

# ABSTRACT: A container for release data

# AUTHORITY

use Moo qw( has );

=head1 SYNOPSIS

This is mostly a work-a-like for
L<< C<CPAN::Latest::ReleaseHistory::Release>|CPAN::Latest::ReleaseHistory::Release >>, except without the dependency on
L<< C<MetaCPAN::Client>|MetaCPAN::Client >>

  my $release = $releaseiterator->next_release;

  print $release->distname();                   # Dist-Zilla
  print $release->path();                       # R/RJ/RJBS/Dist-Zilla-1.000.tar.gz
  print scalar gmtime $release->timestamp();    # Timestamp is Unixtime.
  print $release->size();                       # 30470 ( bytes )
  my $distinfo = $release->distinfo();          # CPAN::DistInfo object

=cut

use CPAN::DistnameInfo;

=attr C<distname>

The name of the distribution.

  e.g: Dist-Zilla

=cut

has 'distname' => ( is => 'ro' );

=attr C<path>

The path to the distribution relative to a C<CPAN> mirror.

  e.g: R/RJ/RJBS/Dist-Zilla-1.000.tar.gz

=cut

has 'path' => ( is => 'ro' );

=attr C<timestamp>

The time of the release in C<unixtime>

=cut

has 'timestamp' => ( is => 'ro' );

=attr C<size>

The size of the release in C<bytes>

=cut

has 'size' => ( is => 'ro' );

=attr C<distinfo>

A L<< C<CPAN::DistnameInfo>|CPAN::DistnameInfo >> object for this release.

=cut

has 'distinfo' => ( is => 'lazy' );

sub _build_distinfo {
  my $self = shift;

  return CPAN::DistnameInfo->new( $self->path );
}
no Moo;

1;

