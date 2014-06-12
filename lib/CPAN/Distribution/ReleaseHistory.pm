use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Distribution::ReleaseHistory;

our $VERSION = '0.001000';

# ABSTRACT: Show the release history of a single distribution

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo 1.000008 qw( has );

#pod =head1 SYNOPSIS
#pod
#pod This is similar in concept to C<CPAN::ReleaseHistory>, except its tailored to use a single distribution name, and uses
#pod C<MetaCPAN> to resolve its information.
#pod
#pod   use CPAN::Distribution::ReleaseHistory;
#pod
#pod   my $release_history = CPAN::Distribution::ReleaseHistory->new(
#pod     distribution => 'Dist-Zilla',
#pod     # ua          => a HTTP::Tiny instance to use for requests
#pod     # es          => a Search::Elasticsearch instance
#pod     # scroll_size => 1000  : How many results to fetch per HTTP request
#pod     # sort        => 'desc': Direction of sort ( vs 'asc' and undef )
#pod   );
#pod
#pod   # Returns a CPAN::Distribution::ReleaseHistory::ReleaseIterator
#pod   my $iterator = $release_history->release_iterator();
#pod
#pod   # $release is an instance of CPAN::Releases::Latest::Release
#pod   while ( my $release = $iterator->next_release() ) {
#pod     print $release->distname();                   # Dist-Zilla
#pod     print $release->path();                       # R/RJ/RJBS/Dist-Zilla-1.000.tar.gz
#pod     print scalar gmtime $release->timestamp();    # Timestamp is Unixtime.
#pod     print $release->size();                       # 30470 ( bytes )
#pod     my $distinfo = $release->distinfo();          # CPAN::DistInfo object
#pod   }
#pod
#pod =cut

#pod =attr C<distribution>
#pod
#pod A string exactly matching a name of a C<CPAN> distribution.
#pod
#pod example:
#pod
#pod   Dist-Zilla
#pod   MetaCPAN-Client
#pod   Search-Elasticsearch
#pod   WWW-Mechanize-Cached
#pod
#pod =cut

has 'distribution' => (
  is       => 'ro',
  required => 1,
);

#pod =attr C<sort>
#pod
#pod The implicit sort direction of the output.
#pod
#pod   default: 'desc' # The most recent release is returned first.
#pod
#pod Alternative options:
#pod
#pod   'asc' # The oldest release is returned first
#pod   undef # Results are unsorted
#pod
#pod =head4 C<undef>
#pod
#pod Opting for C<undef> for this value will give a slight speed up to the responsiveness of queries.
#pod
#pod Though this benefit will only be observed in conjunction with low values of C<scroll_size>
#pod
#pod     5 desc average 0.08625 /each   11.594 items/sec
#pod    5 undef average 0.03856 /each   25.937 items/sec
#pod
#pod    10 desc average 0.05384 /each   18.573 items/sec
#pod   10 undef average 0.03773 /each   26.507 items/sec
#pod
#pod    20 desc average 0.03856 /each   25.934 items/sec
#pod   20 undef average 0.02758 /each   36.252 items/sec
#pod
#pod    50 desc average 0.02579 /each   38.777 items/sec
#pod   50 undef average 0.02547 /each   39.267 items/sec
#pod
#pod   100 desc average 0.02279 /each   43.873 items/sec
#pod  100 undef average 0.02510 /each   39.846 items/sec
#pod
#pod =cut

has 'sort' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { 'desc' },
);

#pod =attr C<scroll_size>
#pod
#pod Volume of results to fetch per request.
#pod
#pod   default: 1000
#pod
#pod Larger values give slower responses but faster total execution time.
#pod
#pod Smaller values give faster responses but slower total execution time. ( Due to paying ping time both ways per request in
#pod addition to other per-request overheads that are constant sized )
#pod
#pod =cut

has 'scroll_size' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { 1000 },
);

#pod =method C<release_iterator>
#pod
#pod Perform the query and return a new
#pod L<< C<CPAN::Distribution::ReleaseHistory::ReleaseIterator>|CPAN::Distribution::ReleaseHistory::ReleaseIterator >> to walk over
#pod the results.
#pod
#pod
#pod   my $iterator = $object->release_iterator
#pod
#pod =cut

sub release_iterator {
  my ($self) = @_;
  require CPAN::Distribution::ReleaseHistory::ReleaseIterator;
  return CPAN::Distribution::ReleaseHistory::ReleaseIterator->new(
    result_set => $self->_mk_query_distribution( $self->distribution ) );
}

#pod =attr C<ua>
#pod
#pod A C<HTTP::Tiny> compatible user agent.
#pod
#pod =cut

#pod =method C<has_ua>
#pod
#pod Determine if user specified a custom C<UserAgent>
#pod
#pod =cut

has 'ua' => (
  is        => 'ro',
  predicate => 'has_ua',
);

#pod =attr C<es>
#pod
#pod A Search::Elasticsearch instance.
#pod
#pod =cut

has 'es' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub {
    my ($self) = @_;
    my %args = (
      nodes            => 'api.metacpan.org',
      cxn_pool         => 'Static::NoPing',
      send_get_body_as => 'POST',
    );
    if ( $self->has_ua ) {
      $args{handle} = $self->ua;
    }
    require Search::Elasticsearch;
    return Search::Elasticsearch->new(%args);
  },
);

sub _mk_query_distribution {
  my ( $self, $distribution ) = @_;

  my $term = { term => { distribution => $distribution } };
  my $body = { query => $term };
  my %scrollargs = (
    scroll => '5m',
    index  => 'v0',
    type   => 'release',
    size   => $self->scroll_size,
    body   => $body,
    fields => [qw(name version date status maturity stat download_url )],
  );

  if ( $self->sort ) {
    $body->{sort} = { 'stat.mtime' => $self->sort };
  }
  else {
    $scrollargs{'search_type'} = 'scan';
  }

  require Search::Elasticsearch::Scroll;

  return $self->es->scroll_helper(%scrollargs);
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Distribution::ReleaseHistory - Show the release history of a single distribution

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

This is similar in concept to C<CPAN::ReleaseHistory>, except its tailored to use a single distribution name, and uses
C<MetaCPAN> to resolve its information.

  use CPAN::Distribution::ReleaseHistory;

  my $release_history = CPAN::Distribution::ReleaseHistory->new(
    distribution => 'Dist-Zilla',
    # ua          => a HTTP::Tiny instance to use for requests
    # es          => a Search::Elasticsearch instance
    # scroll_size => 1000  : How many results to fetch per HTTP request
    # sort        => 'desc': Direction of sort ( vs 'asc' and undef )
  );

  # Returns a CPAN::Distribution::ReleaseHistory::ReleaseIterator
  my $iterator = $release_history->release_iterator();

  # $release is an instance of CPAN::Releases::Latest::Release
  while ( my $release = $iterator->next_release() ) {
    print $release->distname();                   # Dist-Zilla
    print $release->path();                       # R/RJ/RJBS/Dist-Zilla-1.000.tar.gz
    print scalar gmtime $release->timestamp();    # Timestamp is Unixtime.
    print $release->size();                       # 30470 ( bytes )
    my $distinfo = $release->distinfo();          # CPAN::DistInfo object
  }

=head1 METHODS

=head2 C<release_iterator>

Perform the query and return a new
L<< C<CPAN::Distribution::ReleaseHistory::ReleaseIterator>|CPAN::Distribution::ReleaseHistory::ReleaseIterator >> to walk over
the results.

  my $iterator = $object->release_iterator

=head2 C<has_ua>

Determine if user specified a custom C<UserAgent>

=head1 ATTRIBUTES

=head2 C<distribution>

A string exactly matching a name of a C<CPAN> distribution.

example:

  Dist-Zilla
  MetaCPAN-Client
  Search-Elasticsearch
  WWW-Mechanize-Cached

=head2 C<sort>

The implicit sort direction of the output.

  default: 'desc' # The most recent release is returned first.

Alternative options:

  'asc' # The oldest release is returned first
  undef # Results are unsorted

=head4 C<undef>

Opting for C<undef> for this value will give a slight speed up to the responsiveness of queries.

Though this benefit will only be observed in conjunction with low values of C<scroll_size>

    5 desc average 0.08625 /each   11.594 items/sec
   5 undef average 0.03856 /each   25.937 items/sec

   10 desc average 0.05384 /each   18.573 items/sec
  10 undef average 0.03773 /each   26.507 items/sec

   20 desc average 0.03856 /each   25.934 items/sec
  20 undef average 0.02758 /each   36.252 items/sec

   50 desc average 0.02579 /each   38.777 items/sec
  50 undef average 0.02547 /each   39.267 items/sec

  100 desc average 0.02279 /each   43.873 items/sec
 100 undef average 0.02510 /each   39.846 items/sec

=head2 C<scroll_size>

Volume of results to fetch per request.

  default: 1000

Larger values give slower responses but faster total execution time.

Smaller values give faster responses but slower total execution time. ( Due to paying ping time both ways per request in
addition to other per-request overheads that are constant sized )

=head2 C<ua>

A C<HTTP::Tiny> compatible user agent.

=head2 C<es>

A Search::Elasticsearch instance.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
