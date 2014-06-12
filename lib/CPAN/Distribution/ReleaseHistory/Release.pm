use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package CPAN::Distribution::ReleaseHistory::Release;

our $VERSION = '0.001000';

# ABSTRACT: A container for release data

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );

#pod =head1 SYNOPSIS
#pod
#pod This is mostly a workalike for L<< C<CPAN::Latest::ReleaseHistory::Release>|CPAN::Latest::ReleaseHistory::Release >>, except without the dependency on L<< C<MetaCPAN::Client>|MetaCPAN::Client >>
#pod
#pod   my $release = $releaseiterator->next_release;
#pod
#pod   print $release->distname();                   # Dist-Zilla
#pod   print $release->path();                       # R/RJ/RJBS/Dist-Zilla-1.000.tar.gz
#pod   print scalar gmtime $release->timestamp();    # Timestamp is Unixtime.
#pod   print $release->size();                       # 30470 ( bytes )
#pod   my $distinfo = $release->distinfo();          # CPAN::DistInfo object
#pod
#pod =cut

use CPAN::DistnameInfo;

#pod =attr C<distname>
#pod
#pod The name of the distribution.
#pod
#pod   e.g: Dist-Zilla
#pod
#pod =cut

has 'distname' => ( is => 'ro' );

#pod =attr C<path>
#pod
#pod The path to the distribution relative to a C<CPAN> mirror.
#pod
#pod   e.g: R/RJ/RJBS/Dist-Zilla-1.000.tar.gz
#pod
#pod =cut

has 'path' => ( is => 'ro' );

#pod =attr C<timestamp>
#pod
#pod The time of the release in C<unixtime>
#pod
#pod =cut

has 'timestamp' => ( is => 'ro' );

#pod =attr C<size>
#pod
#pod The size of the release in C<bytes>
#pod
#pod =cut

has 'size' => ( is => 'ro' );

#pod =attr C<distinfo>
#pod
#pod A L<< C<CPAN::DistnameInfo>|CPAN::DistnameInfo >> object for this release.
#pod
#pod =cut

has 'distinfo' => ( is => 'lazy' );

sub _build_distinfo {
  my $self = shift;

  return CPAN::DistnameInfo->new( $self->path );
}
no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Distribution::ReleaseHistory::Release - A container for release data

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

This is mostly a workalike for L<< C<CPAN::Latest::ReleaseHistory::Release>|CPAN::Latest::ReleaseHistory::Release >>, except without the dependency on L<< C<MetaCPAN::Client>|MetaCPAN::Client >>

  my $release = $releaseiterator->next_release;

  print $release->distname();                   # Dist-Zilla
  print $release->path();                       # R/RJ/RJBS/Dist-Zilla-1.000.tar.gz
  print scalar gmtime $release->timestamp();    # Timestamp is Unixtime.
  print $release->size();                       # 30470 ( bytes )
  my $distinfo = $release->distinfo();          # CPAN::DistInfo object

=head1 ATTRIBUTES

=head2 C<distname>

The name of the distribution.

  e.g: Dist-Zilla

=head2 C<path>

The path to the distribution relative to a C<CPAN> mirror.

  e.g: R/RJ/RJBS/Dist-Zilla-1.000.tar.gz

=head2 C<timestamp>

The time of the release in C<unixtime>

=head2 C<size>

The size of the release in C<bytes>

=head2 C<distinfo>

A L<< C<CPAN::DistnameInfo>|CPAN::DistnameInfo >> object for this release.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
