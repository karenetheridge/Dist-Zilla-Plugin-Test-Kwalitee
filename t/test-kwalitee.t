use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::DZil;
use Path::Tiny;
use Cwd;

# FILENAME: test-kwalitee.t
# CREATED: 29/08/11 15:36:11 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test the Test::Kwalitee plugin works

my $tzil = Builder->from_config( { dist_root => path(qw( t test-kwalitee )), } );

my $tempdir       = $tzil->tempdir;
my $sourcedir     = $tempdir->subdir('source');
my $builddir      = $tempdir->subdir('build');
my $expected_file = $builddir->subdir('xt')->subdir('release')->file('kwalitee.t');

$tzil->build;

ok( -e $expected_file, 'test created' );

my $cwd = getcwd;
chdir $builddir;

SKIP: {
    skip 'remainder of tests are only run locally', 3
        unless $ENV{AUTHOR_TESTING} or $ENV{RELEASE_TESTING};

    require Capture::Tiny;
    my ( $result, $output, $error, $errflags );
    {
      local $@;
      local $!;
      local $?;
      ( $output, $error ) = Capture::Tiny::capture(sub {
        $result = system( "RELEASE_TESTING=1 $^X $expected_file" );
      });
      $errflags = { '@' => $@, '!' => $!, '?' => $? };
    }
    my $success = 1;
    isnt( $result, 0, 'Test ran, and failed, as intended' ) or do { $success = 0 };
    like( $output, qr/ok.*no_symlinks/m, 'Test dist lacked symlinks' )   or do { $success = 0 };
    like( $output, qr/not ok.*has_readme/m, 'Test dist has no readme' )   or do { $success = 0 };

    if ( not $success ) {
      diag explain {
        'stdout' => $output,
        'stderr' => $error,
        'result' => $result,
        'flags'  => $errflags,
      };
    }
}

chdir $cwd;

done_testing;
