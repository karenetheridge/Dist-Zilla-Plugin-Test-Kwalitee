use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use File::pushd 'pushd';
use Test::Deep;

# FILENAME: test-kwalitee.t
# CREATED: 29/08/11 15:36:11 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test the Test::Kwalitee plugin works

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Test::Kwalitee' => { skiptest => [ 'no_symlinks' ] } ],
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

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => {
            develop => {
                requires => {
                    'Test::Kwalitee' => '1.21',
                },
            },
        },
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::Kwalitee',
                    config => {
                        'Dist::Zilla::Plugin::Test::Kwalitee' => {
                            skiptest => [ 'no_symlinks' ],
                        },
                    },
                    name => 'Test::Kwalitee',
                    version => ignore,
                },
            ),
        }),
    }),
    'prereqs are properly injected for the develop phase; dumped configs are good',
) or diag 'got distmeta: ', explain $tzil->distmeta;

ok( -e $expected_file, 'test created' );

my $content = $expected_file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

like($content, qr/^use Test::Kwalitee 1.21 'kwalitee_ok';$/m, 'correct version is used');

like($content, qr/^kwalitee_ok\( qw\( -no_symlinks \) \);$/m, 'correct arguments are passed');

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
