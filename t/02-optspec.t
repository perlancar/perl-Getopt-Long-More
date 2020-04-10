#!perl

use strict;
use warnings;

use Test::Exception;
use Test::Warn;
use Test::More 0.98;

BEGIN { # so that we can : use TestHelperGLM;
    use File::Basename; 
    use lib (dirname(__FILE__) || "./t" ) . "/lib"; 
}

use Getopt::Long::More qw(optspec);
use TestHelperGLM qw(test_getoptions);

# XXX test exports

subtest "optspec: no property is required" => sub {
    lives_ok { optspec() };
};

subtest "optspec: unknown property -> dies" => sub {
    dies_ok { optspec(foo=>1) };
};

subtest "optspec: 'handler' is deprecated -> lives, but warns" => sub {
    warnings_exist {
      lives_ok { optspec( handler => sub { } ) }
    }
    [qr/\Whandler\W.*deprecated/],
    "optspec: 'handler' is deprecated -> warns";
};

subtest "optspec: Illegal to provide both 'destination' and its deprecated alias 'handler' -> dies" => sub {
    local *STDERR = \*STDOUT; # supress the depecation warning before 'die' => Just prettier test output.
    dies_ok { optspec(destination => sub {}, handler => sub {} ) };
};

subtest "optspec: extra properties allowed" => sub {
    lives_ok { optspec(destination=>sub{}, _foo=>1, 'x.bar'=>2, _=>{baz=>3}, x=>{qux=>4}) };
};

subtest "optspec: invalid extra properties -> dies" => sub {
    dies_ok { optspec(destination=>sub{}, 'x.'=>1) };
};

{
    my $opts = {};
    test_getoptions(
        name => 'optspec: default (unset)',
        opts_spec => ['foo=s' => optspec(destination => \$opts->{foo}, default => "bar")],
        argv => [qw//],
        opts => $opts,
        expected_opts => {foo => "bar"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: default (set)',
        opts_spec => ['foo=s' => optspec(destination => \$opts->{foo}, default => "bar")],
        argv => [qw/--foo qux/],
        opts => $opts,
        expected_opts => {foo => "qux"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: default (set, but no destination) -> dies',
        opts_spec => ['foo=s' => optspec(default => "bar")],
        argv => [qw/--foo qux/],
        opts => $opts,
        dies => 1,
    );
}
TODO: {
    local $TODO = "currently dies, but we shouldn't require destination when in hash-storage mode";
    my $opts = {};
    test_getoptions(
        name => 'optspec: default (set, but no destination) -> dies',
        opts_spec => [$opts, 'foo=s' => optspec(default => "bar")],
        argv => [qw/--foo qux/],
        opts => $opts,
        expected_opts => {foo => "qux"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: default (on <> -> ignored)',
        opts_spec => ['<>' => optspec(destination => sub{}, default => ["a","b"])],
        argv => [qw//],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (unset)',
        opts_spec => ['foo=s' => optspec(destination => \$opts->{foo}, required => 1)],
        argv => [qw//],
        dies => 1,
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (set)',
        opts_spec => ['foo=s' => optspec(destination => \$opts->{foo}, required => 1)],
        argv => [qw/--foo=bar/],
        opts => $opts,
        expected_opts => {foo => "bar"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (set, but no destination) -> dies',
        opts_spec => ['foo=s' => optspec(required => 1)],
        argv => [qw/--foo qux/],
        opts => $opts,
        dies => 1,
    );
}
TODO: {
    local $TODO = "currently dies, but we shouldn't require destination when in hash-storage mode";
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (set, but no destination) -> dies',
        opts_spec => [$opts, 'foo=s' => optspec(required => 1)],
        argv => [qw/--foo qux/],
        opts => $opts,
        expected_opts => {foo => "qux"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (on <>, unset)',
        opts_spec => ['<>' => optspec(destination => sub{}, required => 1)],
        argv => [qw//],
        dies => 1,
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (on <>, set)',
        opts_spec => ['<>' => optspec(destination => sub{}, required => 1)],
        argv => [qw/a b/],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (on <>, set, but no destination, no arguments) -> dies',
        opts_spec => ['<>' => optspec(required => 1)],
        argv => [qw//],
        opts => $opts,
        dies => 1,
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: required (on <>, set, but no destination, has arguments) -> ok',
        opts_spec => ['<>' => optspec(required => 1)],
        argv => [qw/a b/],
        opts => $opts,
        expected_opts => {},
        expected_argv => [qw/a b/],
    );
}

{
    my $opts = {};
    test_getoptions(
        name => 'optspec: mixed implict/explicit linkage',
        opts_spec =>  [
          'foo=s', optspec(destination => \$opts->{foo} ),
          'bar=s',
          'baz=s', optspec(destination => \$opts->{baz} ),
          'gaz=s', \$opts->{gaz},
        ],
        argv => [qw/--foo boo --baz boz --gaz gez/],
        opts => $opts,
        expected_opts => {foo => "boo", baz => "boz", gaz => "gez"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: with "hash-storage"',
        opts_spec => [
          $opts,
          'foo=s', optspec(destination => \$opts->{foo} ),
          'bar=s',
        ],
        argv => [qw/--foo boo --bar bur/],
        opts => $opts,
        expected_opts => {foo => "boo", bar => "bur"},
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: mixed implict/explicit linkage (with "hash-storage")',
        opts_spec => [
          $opts,
          'foo=s', optspec(destination => \$opts->{foo} ),
          'bar=s',
          'baz=s', optspec(destination => \$opts->{baz} ),
          'gaz=s', \$opts->{gaz},
        ],
        argv => [qw/--foo boo --bar bur --baz boz --gaz gez/],
        opts => $opts,
        expected_opts => {foo => "boo", bar => "bur", baz => "boz", gaz => "gez" },
        expected_argv => [qw//],
    );
}
{
    my $opts = {};
    test_getoptions(
        name => 'optspec: evaporates when it has no destination (in hash-storage mode)',
        opts_spec => [
          $opts,
          'foo=s', optspec(),
          'bar=s',
          'baz=s', optspec(destination => \$opts->{baz} ),
          'gaz=s', \$opts->{gaz},
        ],
        argv => [qw/--foo boo --bar bur --baz boz --gaz gez/],
        opts => $opts,
        expected_opts => {foo => "boo", bar => "bur", baz => "boz", gaz => "gez" },
        expected_argv => [qw//],
    );
}
{   our ($opt_foo, $opt_bar);
    my $opts = {};
    test_getoptions(
        name => "optspec: evaporates when it has no destination in 'classic mode' with 'legacy default desinations'" ,
        opts_spec => [
          'foo=s', optspec(),
          'bar=s',
          'baz=s', optspec(destination => \$opts->{baz} ),
          'gaz=s', \$opts->{gaz},
        ],
        argv => [qw/--foo boo --bar bur --baz boz --gaz gez/],
        opts => $opts,
        expected_opts => { baz => "boz", gaz => "gez" },
        expected_argv => [qw//],
    );
    {
      # DONE: These now pass, suggesting #9 is resolved.
      is($opt_foo // "[undef]" => 'boo', "optspec: [evaporation][without a destination][in classic mode][legacy default destination][1]");
      is($opt_bar // "[undef]" => 'bur', "optspec: [evaporation][without a destination][in classic mode][legacy default destination][2]");
    }
}

# XXX test summary
# XXX test pod

done_testing;


