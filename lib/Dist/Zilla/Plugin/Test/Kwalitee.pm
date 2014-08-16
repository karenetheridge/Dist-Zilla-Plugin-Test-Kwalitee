use strict;
use warnings;
package Dist::Zilla::Plugin::Test::Kwalitee;
# ABSTRACT: Release tests for kwalitee
# KEYWORDS: plugin testing tests distribution kwalitee CPANTS quality lint errors critic

use Moose;
use Sub::Exporter::ForMethods 'method_installer'; # method_installer returns a sub.
use Data::Section 0.004 # fixed header_re
    { installer => method_installer }, '-setup';
use namespace::autoclean;

with
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::PrereqSource';

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

sub register_prereqs
{
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'develop',
        },
        'Test::Kwalitee' => '1.12',
    );
}

sub gather_files {
  my ( $self, ) = @_;

  my $import_options = '';

  if ( @{ $self->skiptest } > 0 ) {
    my $skip = join ' ', map { "-$_" } @{ $self->skiptest };
    $import_options = qq{ tests => [ qw( $skip ) ]};
  }

  require Dist::Zilla::File::InMemory;

  for my $filename ( qw( xt/release/kwalitee.t ) ) {
    my $content = $self->fill_in_string(
      ${$self->section_data($filename)},
      {
        dist => \($self->zilla),
        plugin => \$self,
        import_options => \$import_options,
      },
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
  register_prereqs
  gather_files

=end Pod::Coverage

=head1 SEE ALSO

=for :list

* L<Module::CPANTS::Analyse>
* L<App::CPANTS::Lint>
* L<Test::Kwalitee>
* L<Dist::Zilla::App::Command::kwalitee>
* L<Test::Kwalitee::Extra>
* L<Dist::Zilla::Plugin::Test::Kwalitee::Extra>

=cut

__DATA__
___[ xt/release/kwalitee.t ]___
# this test was generated with {{ ref($plugin) . ' ' . ($plugin->VERSION || '<self>') }}
use strict;
use warnings;
use Test::Kwalitee{{ $import_options }};
