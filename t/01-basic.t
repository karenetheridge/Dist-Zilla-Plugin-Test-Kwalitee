use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
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
                [ MakeMaker => ],
                [ MetaYAML => ],
                [ Manifest => ],
                [ License => ],
                [ Readme => ],
                [ 'Test::Kwalitee' => { skiptest => [ qw(no_symlinks has_license_in_source_file) ] } ],
            ),
            path(qw(source lib Foo.pm)) => <<'FOO',
package Foo;
use strict;
1;,
FOO
            path(qw(source bin foobar)) => <<'FOOBAR',
#!/usr/bin/perl
print "foo\n";
FOOBAR
            path(qw(source Changes)) => "ohhai\n",
            path(qw(source t foo.t)) => "et tu\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        prereqs => superhashof({
            develop => {
                requires => {
                    'Test::Kwalitee' => '1.21',
                },
            },
        }),
        x_Dist_Zilla => superhashof({
            plugins => supersetof(
                {
                    class => 'Dist::Zilla::Plugin::Test::Kwalitee',
                    config => {
                        'Dist::Zilla::Plugin::Test::Kwalitee' => {
                            # note this is not the same order as provided above
                            skiptest => [ qw(has_license_in_source_file no_symlinks) ],
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

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child(qw(xt release kwalitee.t));

SKIP: {
ok( -e $file, 'test created' ) or skip 'test was not created', 3;

my $content = $file->slurp_utf8;
unlike($content, qr/[^\S\n]\n/m, 'no trailing whitespace in generated test');

like($content, qr/^use Test::Kwalitee 1.21 'kwalitee_ok';$/m, 'correct version is used');

like($content, qr/^kwalitee_ok\( qw\( -has_license_in_source_file -no_symlinks \) \);$/m, 'correct arguments are passed, and they are sorted');

subtest 'run the generated test' => sub
{
    my $wd = pushd $build_dir;
    #$tzil->plugin_named('MakeMaker')->build;

    local $ENV{AUTHOR_TESTING} = 1;
    do $file;
    note 'ran tests successfully' if not $@;
    fail($@) if $@;
};
}

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
