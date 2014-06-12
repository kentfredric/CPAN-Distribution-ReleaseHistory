use strict;
use warnings;

use Test::More;

plan skip_all => 'NO_NETWORK_TESTING set. Skipping network dependent tests'
  if $ENV{NO_NETWORK_TESTING};

diag "set NO_NETWORK_TESTING to disable this test";

# ABSTRACT: Show live Moo history

0 and eval <<'DEBUGGING';
  use HTTP::Tiny;
  package HTTP::Tiny;

  use Class::Method::Modifiers qw( around );
  use Data::Dump qw(pp);
  require JSON;

  sub _decode_response {
    my ( $response ) = @_;
    if ( exists $response->{content} ) {
      my $clone = { %{$response} };

      my $data = $clone->{content};
      local $@;
      my $ok = eval {
        $clone->{content} = JSON->new->decode( "$data" );
        1;
      };
      $response->{json_err} = substr $@, 0, 130 if not $ok;
      #warn $@ if not $ok;
      return $clone if $ok;
    }
    return $response;
  }
  sub _decode_request {
    my ( $request ) = @_;
    my ( $method, $url, $params ) = @_;
    return $request unless $params;
    return $request unless $params->{'content'};
    my $content;
    return $request unless eval { $content = JSON->new->decode( $params->{'content'}); 1 };
    my $clone = {%{$params}};
    $clone->{content} = $content;
    return [ $method, $url, $clone ];
  }
  around 'request' => sub {
    my ( $orig, $self, @args )  = @_;
      pp( _decode_request(@args) );
      my $rval = $orig->( $self, @args );
      pp( _decode_response($rval));
      return $rval;
  };
DEBUGGING

use CPAN::Distribution::ReleaseHistory;

my $rh = CPAN::Distribution::ReleaseHistory->new(
  distribution => "Moo",
  sort         => 'asc',
);

my $ri = $rh->release_iterator;

my $i = 0;
while ( my $r = $ri->next_release ) {
  last if $i > 11;
  $i++;
  subtest "$i-th release: " . $r->distinfo->version => sub {
    cmp_ok( $r->timestamp, '<=', 1321316878, "Prior to Tue Nov 15 00:27:58 2011" );
    is( $r->distinfo->cpanid, 'MSTROUT', "Was released by MST" );
    cmp_ok( $r->distinfo->version, '>=', 0.009000, "V >= 0.009000" );
    cmp_ok( $r->distinfo->version, '<=', 0.009012, "V <= 0.009012" );
  };
}

done_testing;

