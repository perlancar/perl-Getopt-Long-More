#!perl

use strict;
use warnings;
use Test::More 0.98;

use Capture::Tiny qw(capture_stdout);
use Getopt::Long::More;

test_complete(
    # Complete::Getopt::Long still requires a destination for each option
    opts_spec => ['--foo'=>[], '--bar'=>[]],
    comp_line0 => 'cmd --^',

    output => <<'_',
--bar
--foo
_
);

test_complete(
    # Complete::Getopt::Long still requires a destination for each option
    opts_spec => ['--foo'=>[], '--bar'=>[]],
    comp_line0 => 'cmd --f^',

    output => <<'_',
--foo
_
);

DONE_TESTING:
done_testing;

sub test_complete {
    my %args = @_;

    subtest +($args{name} // $args{comp_line0}) => sub {

        # $args{comp_line0} contains comp_line with '^' indicating where
        # comp_point should be, the caret will be stripped. this is more
        # convenient than counting comp_point manually.
        my $comp_line  = $args{comp_line0};
        defined ($comp_line) or die "BUG: comp_line0 not defined";
        my $comp_point = index($comp_line, '^');
        $comp_point >= 0 or
            die "BUG: comp_line0 should contain ^ to indicate where ".
                "comp_point is";
        $comp_line =~ s/\^//;

        {
            local $ENV{COMP_LINE} = $comp_line;
            local $ENV{COMP_POINT} = $comp_point;
            local $Getopt::Long::More::_exit_after_completion = 0;
            my $output = capture_stdout {
                Getopt::Long::More::GetOptionsFromArray(\@ARGV, @{ $args{opts_spec} });
            };
            is($output, $args{output});
        }
    };
}
