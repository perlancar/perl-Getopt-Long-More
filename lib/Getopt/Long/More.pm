package Getopt::Long::More;

# DATE
# VERSION

use strict;

use Exporter qw(import);

our @EXPORT    = qw(GetOptions optspec OptSpec);
our @EXPORT_OK = qw(HelpMessage VersionMessage Configure
                    GetOptionsFromArray GetOptionsFromString);

sub optspec {
    Getopt::Long::More::OptSpec->new(@_);
}

# synonym for convenience
sub OptSpec {
    Getopt::Long::More::OptSpec->new(@_);
}

sub VersionMessage {
    require Getopt::Long;
    goto &Getopt::Long::VersionMessage;
}

sub Configure {
    require Getopt::Long;
    goto &Getopt::Long::VersionMessage;
}

# copied verbatim from Getopt::Long
sub GetOptionsFromString(@) {
    my ($string) = shift;
    require Text::ParseWords;
    my $args = [ Text::ParseWords::shellwords($string) ];
    $caller ||= (caller)[0];	# current context
    my $ret = GetOptionsFromArray($args, @_);
    return ( $ret, $args ) if wantarray;
    if ( @$args ) {
	$ret = 0;
	warn("GetOptionsFromString: Excess data \"@$args\" in string \"$string\"\n");
    }
    $ret;
}

# copied verbatim from Getopt::Long
sub GetOptions(@) {
    # Shift in default array.
    unshift(@_, \@ARGV);
    # Try to keep caller() and Carp consistent.
    goto &GetOptionsFromArray;
}

my $_cur_opts_spec = [];

sub GetOptionsFromArray {
    require Getopt::Long;

    my $ary = [@{shift}]; # shallow copy

    if (ref($_[0]) eq 'HASH') {
        # we bail out, user only specifies a list of option specs, e.g. (\%h,
        # 'foo=s', 'bar!')
        return Getopt::Long::GetOptionsFromArray($ary, @_);
    }

    my @opts_spec = @_;

    # provide explicit --help|?, for completion. also, we need to override the
    # option handler to use our HelpMessage.
    if ($Getopt::Long::auto_help) {
        unshift @opts_spec, 'help|?' => sub { HelpMessage() };
    }
    local $Getopt::Long::auto_help = 0;

    # provide explicit --version, for completion
    if ($Getopt::Long::auto_version) {
        unshift @opts_spec, 'version' => sub { VersionMessage() };
    }
    local $Getopt::Long::auto_version = 0;

    # to allow our HelpMessage to generate usage/help based on options spec
    $_cur_opts_spec = [@opts_spec];

    # strip the optspec objects
    my $i = -1;
    my @go_opts_spec;
    for (@opts_spec) {
        $i++;
        if ($i % 2 && ref($_) eq 'Getopt::Long::More::OptSpec') {
            push @go_opts_spec, $_->{handler};
        } else {
            push @go_opts_spec, $_;
        }
    }

    my $res = Getopt::Long::GetOptionsFromArray($ary, @go_opts_spec);

    # TODO: set default value

    # TODO: check required

    $res;
}

sub HelpMessage {
    my $opts_spec = @_ ? [@_] : $_cur_opts_spec;
    # TODO
}

sub OptionsPod {
    my $opts_spec = @_ ? [@_] : $_cur_opts_spec;
    # TODO
}

package # hide from PAUSE indexer
    Getopt::Long::More::OptSpec;

sub new {
    my $class = shift;
    my $obj = bless {@_}, $class;
    unless (exists $obj->{handler}) {
        die "You must specify handler in optspec";
    }
    for (keys %$obj) {
        unless (/\A(handler|required|default|summary|description|completion)\z/) {
            die "Unknown optspec property '$_'";
        }
    }
    $obj;
}

1;
# ABSTRACT: Like Getopt::Long, but with more stuffs

=head1 ABSTRACT

 use Getopt::Long::More; # imports GetOptions as well as optspec; you can also
                         # explicitly import Configure, GetOptionsFromArray,
                         # GetOptionsFromString

 my %opts;
 GetOptions(
     # just like in Getopt::Long
     'foo=s' => \$opts{foo},
     'bar'   => sub { ... },

     # but if you want to specify extra stuffs...
     'baz'   => optspec(
         # at least specify this, for Getopt::Long
         handler => \$opts{baz},

         # specify that this option is required
         required => 1,

         # specify this for default value
         default => 10,

         # specify this if you want nicer usage message
         summary => 'Blah blah blah',

         # specify longer (multiparagraphs) of text for POD, in POD format
         description => <<'_',
Blah blah ...
blah

Blah blah ...
blah blah
_

         # provide completion from a list of strings
         # completion => [qw/apple apricot banana/],

         # provide more advanced completion routine
         completion => sub {
             require Complete::Util;
             my %args = @_;
             Complete::Util::complete_array_elem(
                 word => $args{word},
                 array => [ ... ],
             );
         },
     ),
 );


=head1 DESCRIPTION

This module is a wrapper and drop-in replacement for L<Getopt::Long>. It
provides the same interface as Getopt::Long and, unlike other wrappers like
L<Getopt::Long::Complete> it does not change default configuration and all
Getopt::Long configuration are supported. In fact, Getopt::Long::More behaves
much like Getopt::Long until you start to use optspec object as one or more
option handlers.


=head1 OPTSPEC OBJECT

In addition to using scalarref, arrayref, hashref, or coderef as the option
handler as Getopt::Long allows, Getopt::Long::More also allows using optspec
object as option handler. This allows you to specify more stuffs. Optspec object
is created using the C<optspec> function which accepts a list of property
name-property value pairs:

 '--fruit=s' => optspec(
     handler => \$opts{fruit},
     default => 'apple',
     summary => 'Supply name of fruit to order',
     completion => [qw/apple apricot banana/],
     ...
 )

At least the C<handler> property must be specified, as this will be passed to
Getopt::Long when parsing options. In addition to that, these other properties
are also recognized:

=head2 required => bool

Set this to 1 to specify that the option is required.

=head2 default => any

Provide default for the option.

=head2 summary => str

Provide a short summary message for the option. This is used when generating
usage/help message.

=head2 description => str

Provide a longer (multiparagraph) text, in POD format. Will be used to generate
POD.

=head2 completion => array|code

Provide completion routine. Can also be a simple array of strings.

Completion routine will be passed a hash argument, with at least the following
keys: C<word> (str, the word to be completed). It is expected to return a
completion answer structure (see L<Complete> for mor edetails) which is usually
just an array of strings.


=head1 FUNCTIONS

=head2 Configure

See Getopt::Long documentation.

=head2 GetOptionsFromArray

See Getopt::Long documentation.

=head2 GetOptionsFromString

See Getopt::Long documentation.

=head2 GetOptions

See Getopt::Long documentation.

=head2 HelpMessage(@opts_spec) => str

Will generate a usage/help message. Sample result:

 myapp [options]

 Options:
   --fruit=s     Supply name of fruit to order (default: apple)
   --debug       Enable debug mode
   --help|?      Print help message and exit
   --version     Print usage message and exit

=head2 OptionsPod(@opts_spec) => str

Will generate a POD containing list of options. The text will be taken from the
C<summary> and C<description> properties of optspec objects. Example result:

 =head1 OPTIONS

 =head2 --fruit|f=s

 Supply name of fruit to order.

 Blah blah blah
 blah blah ...

 =head2 --debug

 =head2 --version

 Display program version and exit.

 =head2 --help

 Display help message and exit.


=head1 COMPLETION

Getopt::Long::Mode supports shell tab completion.

Tab completion functionality is provided by L<Complete::Getopt::Long>. Note that
this module assumes C<no_ignore_case> and does not support things like
C<getopt_compat> (starting option with C<+> instead of C<-->).


=head1 SEE ALSO

L<Getopt::Long>

Other Getopt::Long wrappers that provide extra features:
L<Getopt::Long::Complete>, L<Getopt::Long::Descriptive>.

If you want I<less> features instead of more: L<Getopt::Long::Less>,
L<Getopt::Long::EvenLess>.