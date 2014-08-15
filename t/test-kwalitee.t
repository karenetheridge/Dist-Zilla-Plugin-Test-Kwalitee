use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';

# FILENAME: test-kwalitee.t
# CREATED: 29/08/11 15:36:11 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test the Test::Kwalitee plugin works

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'Test::Kwalitee' => ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source bin foobar)) => <<'FOOBAR',
#!/usr/bin/perl
print "foo\n";
FOOBAR
        },
    },
);

my $build_dir     = path($tzil->tempdir)->child('build');
my $expected_file = $build_dir->child(qw(xt release kwalitee.t));

$tzil->chrome->logger->set_debug(1);
$tzil->build;

ok( -e $expected_file, 'test created' );

my $content = $expected_file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
