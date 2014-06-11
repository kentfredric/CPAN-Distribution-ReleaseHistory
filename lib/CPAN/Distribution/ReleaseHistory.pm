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

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
