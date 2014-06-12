use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Distribution::ReleaseHistory;

our $VERSION = '0.001000';

# ABSTRACT: Show the release history of a single distribution

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo 1.000008 qw( has );



































has 'ua' => (
  is        => 'ro',
  predicate => 'has_ua',
);







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













has 'scroll_size' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { 1000 },
);














has 'distribution' => (
  is       => 'ro',
  required => 1,
);









































has 'sort' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { 'desc' },
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

  my $scroller = $self->es->scroll_helper(%scrollargs);
  require MetaCPAN::Client::ResultSet;
  require MetaCPAN::Client::Release;
  return MetaCPAN::Client::ResultSet->new(
    scroller => $scroller,
    type     => 'release',
  );
}












sub release_iterator {
  my ($self) = @_;
  require CPAN::Distribution::ReleaseHistory::ReleaseIterator;
  return CPAN::Distribution::ReleaseHistory::ReleaseIterator->new(
    result_set => $self->_mk_query_distribution( $self->distribution ) );
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

This is similar in concept to C<CPAN::ReleaseHistory>, except its tailored to use a single distribution name, and uses C<MetaCPAN> to resolve its information.

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

=head1 ATTRIBUTES

=head2 C<ua>

A C<HTTP::Tiny> compatible user agent.

=head2 C<es>

A Search::Elasticsearch instance.

=head2 C<scroll_size>

Volume of results to fetch per request.

  default: 1000

Larger values give slower responses but faster total execution time.

Smaller values give faster responses but slower total execution time. ( Due to paying ping time both ways per request in addition to other per-request overheads that are constant sized )

=head2 C<distribution>

A string exactly matching a name of a CPAN distribution.

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

  scroll_size > N_results : undef slower than 'desc'
  scroll_size ~ 10        : undef faster than 'desc'
  scroll_size ~ 20        : undef marginally faster than 'desc'

--

  test_sorted(){
    perl -Ilib -MCPAN::Distribution::ReleaseHistory \
      -E' $rs = CPAN::Distribution::ReleaseHistory->new( scroll_size => 10, distribution => q[Dist-Zilla], sort => q[desc] )->release_iterator; say $_->size while $_ = $rs->next_release ' >> /dev/null
  }
  test_unsorted(){
    perl -Ilib -MCPAN::Distribution::ReleaseHistory \
      -E' $rs = CPAN::Distribution::ReleaseHistory->new( scroll_size => 10, distribution => q[Dist-Zilla], sort => undef )->release_iterator; say $_->size while $_ = $rs->next_release ' >> /dev/null
  }
  for i in $(seq 0 10); do
    echo "sorted";
    time test_sorted;
    echo "unsorted"
    time test_unsorted;
  done

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
