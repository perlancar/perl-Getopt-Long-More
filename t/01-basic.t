#!perl

use strict;
use warnings;

use Test::More 0.98;

BEGIN { # so that we can : use TestHelperGLM;
    use File::Basename; 
    use lib (dirname(__FILE__) || "./t" ) . "/lib"; 
}
use Getopt::Long::More;
use TestHelperGLM qw(test_getoptions);

# XXX test exports

{
    my $opts = {};
    test_getoptions(
        name => 'empty opts spec',
        opts_spec => [],
        argv => [qw/a b/],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw/a b/],
    );
}
{
    # TABULON: supress the display of warning 'Unknown option: help' => prettier test output.
    local *STDERR = \*STDOUT;
    my $opts = {};
    test_getoptions(
        name => 'unknown opt -> fail',
        opts_spec => [],
        argv => [qw/--help a b/],
        is_success => 0,
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw/a b/],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'config: pass_through',
        config => [qw/pass_through/],
        opts_spec => [],
        argv => [qw/--help a b/],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw/--help a b/],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'basic',
        opts_spec => ['foo=s' => \$opts->{foo}],
        argv => [qw/--foo bar/],
        opts => $opts,
        expected_opts => {foo => "bar"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'basic: with hash-storage',
        opts_spec => [$opts, 'foo=s' => \$opts->{foo}],
        argv => [qw/--foo bar/],
        opts => $opts,
        expected_opts => {foo => "bar"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'basic: mixed implict/explicit linkage',
        opts_spec =>  [
          'foo=s', \$opts->{foo},
          'bar=s',
          'baz=s', \$opts->{baz},
          'gaz=s', \$opts->{gaz},
        ],
        argv => [qw/--foo boo --baz boz --gaz gez/],
        opts => $opts,
        expected_opts => {foo => "boo", baz => "boz", gaz => "gez"},
        expected_argv => [qw//],
    );
}
{
    our $opt_foo;
    my $opts = {};
    test_getoptions(
        name => 'testsuite: can tolerate "default destinations"',  # OK.
        opts_spec => [
          'foo=s',
          'baz=s', \$opts->{baz},
        ],
        argv => [qw/--foo boo --baz boz/],
        opts => $opts,
        expected_opts => {baz => "boz"},
        expected_argv => [qw//],
    );
}
{
    our $opt_foo;      # ==> Expected default destination for option 'foo' (when using GoL's "legacy" call style, as below)
    test_getoptions(
        name => 'legacy: can tolerate "default destinations" [1]',  # OK.
        opts_spec => [
          'foo=s',
          'baz=s',
        ],
        argv => [qw/--foo boo --baz boz/],
        opts => {},
        expected_opts => {},
        expected_argv => [qw//],
    );
    {
      # DONE: Now passes, suggesting #9 is resolved.
      is($opt_foo // "[undef]" => 'boo', "legacy: default destinations work as expected" );
    }
}

# XXX test summary
# XXX test pod

done_testing;


