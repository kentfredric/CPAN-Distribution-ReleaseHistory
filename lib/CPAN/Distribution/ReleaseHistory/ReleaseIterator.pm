use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Distribution::ReleaseHistory::ReleaseIterator;

# ABSTRACT: A container to iterate a collection of releases for a single distribution

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo;
use CPAN::DistnameInfo;
use CPAN::Releases::Latest::Release;

has 'result_set' => ( is => 'ro',  required => 1 );



sub next_release {
  my ($self) = @_;
  my $result = $self->result_set->next;
  return if not $result;

scannext: {
    my $maturity = $result->maturity;
    my $path     = $result->download_url;
    $path =~ s!^.*/authors/id/!!;
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

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
