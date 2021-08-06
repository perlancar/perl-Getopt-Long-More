use strict;
use warnings;

package TestHelperGLM;
 
use Carp;
use Test::More 0.98;

use Exporter;
our @ISA    = qw/Exporter/;
our @EXPORT_OK = qw(
  test_getoptions
);
 
# PUBLIC (outer) routine; responsable for "caller" and "TODO" tricekery
sub test_getoptions {
    my $caller = (caller)[0];

    # For TODO tests, [Test::More] needs (in the current package) : 
    #   * a `TODO:` (label) as well as a `$TODO` (variable)  
    local $TODO = do { no strict qw/refs/; ${ $caller . '::TODO' } };
    return _test_getoptions(caller=>$caller, @_) unless (defined($TODO));
TODO:    { _test_getoptions(caller=>$caller, @_) } 
}

# PRIVATE (inner) routine. 
sub _test_getoptions {
    my %args = @_;
    my @argv = @{ $args{argv} };

    subtest +($args{name} // join(" ", @argv)) => sub {

        my $old_conf;
        $old_conf = Getopt::Long::More::Configure(@{$args{config}})
            if $args{config};

        # This is needed for testing 'legacy' destinations ($opt_XXX) which get created caller's package; 
        # i.e. whatever GoL happens to percieve as its 'caller'.
        local $Getopt::Long::caller ||= $args{caller} unless defined($Getopt::Long::caller);

        my $res;
        eval {
            $res = Getopt::Long::More::GetOptionsFromArray(
                \@argv,
                @{ $args{opts_spec} },
            );
        };
        my $err = $@;

        {
            if ($args{dies}) {
                ok($err, "dies");
                last;
            } else {
                ok(!$err, "doesn't die") or do {
                    diag "err=$err";
                    last;
                };
            }
            if ($args{is_success} // 1) {
                ok($res, "success");
            } else {
                ok(!$res, "fail");
            }
            if ($args{expected_opts}) {
                is_deeply($args{opts}, $args{expected_opts}, "options")
                    or diag explain $args{opts};
            }
            if ($args{expected_argv}) {
                is_deeply(\@argv, $args{expected_argv}, "remaining argv")
                    or diag explain \@argv;
            }
            if ($args{posttest}) {
                $args{posttest}->();
            }
        }

        Getopt::Long::More::Configure($old_conf) if $old_conf;
    };
}

1;

# ABSTRACT: Things that are common to many GLM tests


