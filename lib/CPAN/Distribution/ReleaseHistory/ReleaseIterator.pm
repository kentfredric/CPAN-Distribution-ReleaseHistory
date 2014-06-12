use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Distribution::ReleaseHistory::ReleaseIterator;

our $VERSION = '0.001000';

# ABSTRACT: A container to iterate a collection of releases for a single distribution

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use CPAN::DistnameInfo;
use CPAN::Distribution::ReleaseHistory::Release;







has 'result_set' => ( is => 'ro', required => 1 );









sub next_release {
  my ($self) = @_;
  my $scroll_result = $self->result_set->next;
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
  return CPAN::Distribution::Releases::Release->new(
    distname  => $distname,
    path      => $path,
    timestamp => $data_hash->{stat}->{mtime},
    size      => $data_hash->{stat}->{size},
  );
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Distribution::ReleaseHistory::ReleaseIterator - A container to iterate a collection of releases for a single distribution

=head1 VERSION

version 0.001000

=head1 METHODS

=head2 C<next_release>

Returns a L<< C<CPAN::Releases::Latest::Release>|CPAN::Releases::Latest::Release >>

  my $item = $release_iterator->next_release();

=head1 ATTRIBUTES

=head2 C<result_set>

A C<MetaCPAN::Client::ResultSet>  instance that dispatches C<MetaCPAN::Client::Result> objects.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
