use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::Test::Kwalitee;
# ABSTRACT: Release tests for kwalitee
use Moose;
use Data::Section -setup;
with 'Dist::Zilla::Role::FileGatherer','Dist::Zilla::Role::TextTemplate';

sub mvp_multivalue_args { return qw( skiptest ) }

has skiptest => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  traits  => [ 'Array' ],
  default => sub { [] },
  handles => {
    push_skiptest => 'push'
  },
);

sub gather_files {
  my ( $self, ) = @_;

  my $skiptests = q{eval "use Test::Kwalitee";};

  if ( @{ $self->skiptest } > 0 ) {

    my $skip = join ' ', map { "-$_" } @{ $self->skiptest };

    $skiptests = qq[eval {
  require Test::Kwalitee;
  Test::Kwalitee->import( tests => [ qw( $skip ) ]);
};];

  }
  require Dist::Zilla::File::InMemory;

  for my $filename ( qw( xt/release/kwalitee.t ) ) {
    my $content = $self->fill_in_string(
      ${$self->section_data($filename)},
      { skiptests => \$skiptests },
    );
    $self->add_file(
      Dist::Zilla::File::InMemory->new( {
        'name'    => $filename,
        'content' => $content,
      } ),
    );
  }
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=begin :prelude

=for test_synopsis
1;
__END__

=end :prelude

=head1 SYNOPSIS

In C<dist.ini>:

    [Test::Kwalitee]
    skiptest=use_strict ; Don't test for strictness.

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/kwalitee.t - a standard Test::Kwalitee test

=begin Pod::Coverage

  mvp_multivalue_args
  gather_files

=end Pod::Coverage

=cut

__DATA__
___[ xt/release/kwalitee.t ]___
# This test is generated by Dist::Zilla::Plugin::Test::Kwalitee
use strict;
use warnings;
use Test::More;   # needed to provide plan.
{{ $skiptests }}

plan skip_all => "Test::Kwalitee required for testing kwalitee" if $@;
