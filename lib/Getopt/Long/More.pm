## no critic: Modules::ProhibitAutomaticExportation

package Getopt::Long::More;

# DATE
# VERSION

use strict;

use Exporter qw(import);

our @EXPORT    = qw(GetOptions optspec OptSpec);
our @EXPORT_OK = qw(HelpMessage VersionMessage Configure
                    GetOptionsFromArray GetOptionsFromString
                    OptionsPod);

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
    goto &Getopt::Long::Configure;
}

# copied verbatim from Getopt::Long, with a bit of modification (add my)
sub GetOptionsFromString(@) {
    my ($string) = shift;
    require Text::ParseWords;
    my $args = [ Text::ParseWords::shellwords($string) ];
    local $Getopt::Long::caller ||= (caller)[0];
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

    my $ary = shift;

    local $Getopt::Long::caller ||= (caller)[0];  # grab and set this asap.

    my @go_opts_spec;

    if ( ref($_[0]) ) {
      require Scalar::Util;
      if ( Scalar::Util::reftype ($_[0]) eq 'HASH') {
        push @go_opts_spec, shift;  # 'hash-storage' is now directly supported
      }
    }

    my @opts_spec = @_;

    # provide explicit --help|?, for completion. also, we need to override the
    # option destination to use our HelpMessage.
    if ($Getopt::Long::auto_help) {
        unshift @opts_spec, 'help|?' => optspec(
            destination => sub { HelpMessage() },
            summary => 'Print help message and exit',
        );
    }
    local $Getopt::Long::auto_help = 0;

    # provide explicit --version, for completion
    if ($Getopt::Long::auto_version) {
        unshift @opts_spec, 'version' => optspec(
            destination => sub { VersionMessage() },
            summary => 'Print program version and exit',
        );
    }
    local $Getopt::Long::auto_version = 0;

    # to allow our HelpMessage to generate usage/help based on options spec
    $_cur_opts_spec = [@opts_spec];

    # strip the optspec objects
    my $prev;
    my $has_arg_handler;
    my $arg_handler_accessed;
  MAPPING:  # Resulting in the complete EVAPORATION of OptSpec objects, replaced by their destination, if one exists.
      for my $e (@opts_spec) {
        unless ( ref($e) eq 'Getopt::Long::More::OptSpec' ) {
          push @go_opts_spec, $e;
          next;
        }

        next unless exists $e->{destination};

        if ( $prev  eq '<>' ) {
          $has_arg_handler++;
          push @go_opts_spec, sub {
            $arg_handler_accessed++;
            $e->{destination}->(@_);
          };
        } else {
          push @go_opts_spec, $e->{destination};
        }
    } continue {
      $prev = $e;
    }

    # if in completion mode, do completion instead of parsing options
  COMPLETION: {
        my $shell;
        if ($ENV{COMP_SHELL}) {
            ($shell = $ENV{COMP_SHELL}) =~ s!.+/!!;
        } elsif ($ENV{COMMAND_LINE}) {
            $shell = 'tcsh';
        } else {
            $shell = 'bash';
        }

        if ($ENV{COMP_LINE} || $ENV{COMMAND_LINE}) {
            my ($words, $cword);
            if ($ENV{COMP_LINE}) {
                require Complete::Bash;
                ($words,$cword) = @{ Complete::Bash::parse_cmdline(undef, undef, {truncate_current_word=>1}) };
                ($words,$cword) = @{ Complete::Bash::join_wordbreak_words($words, $cword) };
            } elsif ($ENV{COMMAND_LINE}) {
                require Complete::Tcsh;
                $shell //= 'tcsh';
                ($words, $cword) = @{ Complete::Tcsh::parse_cmdline() };
            }

            my %opt_completions;
            my $arg_completion;
            for (my $i=0; $i < @opts_spec; $i++) {
                if ($i % 2 == 0) {
                    my $o = $opts_spec[$i];
                    my $os = $opts_spec[$i+1];
                    if (ref($os) eq 'Getopt::Long::More::OptSpec') {
                        my $completion = $os->{completion};
                        next unless $completion;
                        if (ref $completion eq 'ARRAY') {
                            $completion = sub {
                                require Complete::Util;
                                my %args = @_;
                                Complete::Util::complete_array_elem(
                                    word => $args{word},
                                    array => $os->{completion},
                                );
                            };
                        }
                        if ($o eq '<>') {
                            $arg_completion = $completion;
                        } else {
                            $opt_completions{$o} = $completion;
                        }
                    }
                }
            }

            my $comp = sub {
                my %args = @_;
                if ($args{type} eq 'optval' && $opt_completions{ $args{ospec} }) {
                    return $opt_completions{ $args{ospec} }->(%args);
                } elsif ($args{type} eq 'arg' && $arg_completion) {
                    return $arg_completion->(%args);
                }
                undef;
            };

            require Complete::Getopt::Long;
            shift @$words; $cword--; # strip program name
            my $compres = Complete::Getopt::Long::complete_cli_arg(
                words => $words, cword => $cword, getopt_spec => {@go_opts_spec},
                completion => $comp,
                bundling => $Gteopt::Long::bundling,
            );

            if ($shell eq 'bash') {
                require Complete::Bash;
                print Complete::Bash::format_completion(
                    $compres, {word=>$words->[$cword]});
            } elsif ($shell eq 'fish') {
                require Complete::Fish;
                print Complete::Bash::format_completion(
                    $compres, {word=>$words->[$cword]});
            } elsif ($shell eq 'tcsh') {
                require Complete::Tcsh;
                print Complete::Tcsh::format_completion($compres);
            } elsif ($shell eq 'zsh') {
                require Complete::Zsh;
                print Complete::Zsh::format_completion($compres);
            } else {
                die "Unknown shell '$shell'";
            }

            exit 0;
        }
    }

    my $res = Getopt::Long::GetOptionsFromArray($ary, @go_opts_spec);

    my $i = -1;
    for (@opts_spec) {
        $i++;
        if ($i > 0 && ref($_) eq 'Getopt::Long::More::OptSpec') {
            my $osname = $opts_spec[$i-1];

            # check required
            if ($_->{required}) {
                if ($osname eq '<>') {
                    if ($has_arg_handler) {
                        unless ($arg_handler_accessed) {
                            die "Missing required command-line argument\n";
                        }
                    } else {
                        unless (@{ $ary }) {
                            die "Missing required command-line argument\n";
                        }
                    }
                } elsif ( exists $_->{destination} ) {
                    if (ref($_->{destination}) eq 'SCALAR'
                            && !defined(${$_->{destination}})) {
                        die "Missing required option $osname\n";
                        # XXX doesn't work yet?
                    } elsif (ref($_->{destination}) eq 'ARRAY' &&
                                 !@{$_->{destination}}) {
                        die "Missing required option $osname\n";
                        # XXX doesn't work yet?
                    } elsif (ref($_->{destination}) eq 'HASH'
                                 && !keys(%{$_->{destination}})) {
                        die "Missing required option $osname\n";
                    }
                } else {
                    die "Can't enforce 'required' status without also knowing the 'destination' for option '$osname'. "
                        . "You need to provide a 'destination' to optspec() in order to benefit from that feature\n";
                }
            }
            # supply default value
            if (defined $_->{default}) {
                if ($osname eq '<>') {
                    # currently ignored
                } elsif ( exists $_->{destination} ) {
                    if (ref($_->{destination}) eq 'SCALAR'
                            && !defined(${$_->{destination}})) {
                        ${$_->{destination}} = $_->{default};
                        # XXX doesn't work yet?
                    } elsif (ref($_->{destination}) eq 'ARRAY' &&
                                 !@{$_->{destination}}) {
                        $_->{destination} = [@{ $_->{default} }]; # shallow copy
                        # XXX doesn't work yet?
                    } elsif (ref($_->{destination}) eq 'HASH' &&
                                 !keys(%{$_->{destination}})) {
                        $_->{destination} = { %{ $_->{default} } }; # shallow copy
                    }
                } else {
                    die "Can't assign 'default' without also knowing the 'destination' for option '$osname'. "
                        . "You need to provide a 'destination' to optspec() in order to benefit from that feature\n";
                }
            }
        }
    }

    $res;
}

sub HelpMessage {
    my $opts_spec = @_ ? [@_] : $_cur_opts_spec;
    my $i = -1;
    my @entries;
    my $max_opt_spec_len = 0;
    for (my $i=0; $i < @$opts_spec; $i++) {
        if ($i % 2 == 0) {
            # normalize dashes at the front
            my $osname = $opts_spec->[$i];
            next if $osname eq '<>';
            $osname =~ s/^-+//;
            (my $oname = $osname) =~ s/[=|].*//;
            $osname = length($oname) > 1 ? "--$osname" : "-$osname";

            push @entries, [$osname, "", "", 0, undef]; # [opt, summary, desc, required?, default]
            my $len = length($osname);
            $max_opt_spec_len = $len if $max_opt_spec_len < $len;
            my $os = $opts_spec->[$i+1];
            if (ref($os) eq 'Getopt::Long::More::OptSpec') {
                $entries[-1][1] ||= $os->{summary};
                $entries[-1][3] = 1 if $os->{required};
                $entries[-1][4] = $os->{default};
            }
        }
    }

    my $prog = $0;
    $prog =~ s!.+[/\\]!!;

    print join(
        "",
        "Usage: $prog [options]\n",
        "Options (* marks required option):\n",
        map {
            sprintf("  %-${max_opt_spec_len}s%s  %s%s\n",
                    $_->[0],
                    $_->[3] ? "*" : " ",
                    $_->[1],
                    defined($_->[4]) ? " (default: $_->[4])" : "",
                )
        } @entries,
    );
    exit 0;
}

sub OptionsPod {
    my $opts_spec = @_ ? [@_] : $_cur_opts_spec;
    my $i = -1;
    my @entries;
    for (my $i=0; $i < @$opts_spec; $i++) {
        if ($i % 2 == 0) {
            # normalize dashes at the front
            my $osname = $opts_spec->[$i];
            next if $osname eq '<>';
            $osname =~ s/^-+//;
            (my $oname = $osname) =~ s/[=|].*//;
            $osname = length($oname) > 1 ? "--$osname" : "-$osname";

            push @entries, [$osname, "", "", 0, undef]; # [opt, summary, desc, required?, default]
            my $os = $opts_spec->[$i+1];
            if (ref($os) eq 'Getopt::Long::More::OptSpec') {
                $entries[-1][1] ||= $os->{summary};
                $entries[-1][2] ||= $os->{description};
                $entries[-1][3] = 1 if $os->{required};
                $entries[-1][4] = $os->{default};
            }
        }
    }

    my @res;

    push @res, "=head1 OPTIONS\n\n";
    for (@entries) {
        my @notes;
        if ($_->[3]) { push @notes, "required" }
        if (defined $_->[4]) { push @notes, "default: $_->[4]" }
        push @res, "=head2 $_->[0]", (@notes ? " (".join(", ", @notes).")" : ""), "\n\n";
        push @res, "$_->[1]\n\n" if length $_->[1];
        push @res, "$_->[2]\n\n" if length $_->[2];
    }

    join("", @res);

}

package # hide from PAUSE indexer
    Getopt::Long::More::Util;

our @CARP_NOT = qw( Getopt::Long::More Getopt::Long::More::Util  Getopt::Long::More::OptSpec);

# The subroutines here (::Util) are intended to be pretty generic
# and so could also be used elsewhere later on.

sub map_args {
  my %o = %{; shift || {} };  # shallow copy
  my %p = (@_);
  my ($deprecated, $aliases,
      $deprecated_aliases) =  map {; $_ || {} } @p{qw/deprecated aliases deprecated_aliases/};

  my %deprecations =  ( %$deprecated, %$deprecated_aliases );
  my %synonyms     =  ( %$aliases,    %$deprecated_aliases );

  # Deprecated => warn
  while ( my ($k, $canon) = each %deprecations )  {
    next unless exists $o{$k};
    require Carp;
    Carp::carp( "'$k' is deprecated!",
                ( defined($canon) ? " You should use '$canon' instead." : () ),
                "\n"
              );
  }

  # Synonym => map to canonical key.
  while ( my ($k, $canon) = each %synonyms ) {
    next unless exists $o{$k};

    my $v = delete $o{$k};
    next unless defined $canon; #  if $canon key is undefined => disregard

    if  ( exists $o{$canon} ) {
      require Carp;
      Carp::croak( "'$k' may only be used as a synonym for '$canon'; not alongside it.", "\n" );
    }

    $o{$canon} = $v;
  }
  wantarray ? (%o) : \%o;
}


package # hide from PAUSE indexer
    Getopt::Long::More::OptSpec;

# Poor man's import....
*map_args = \&Getopt::Long::More::Util::map_args;

sub new {
    my $class = shift;
    my $obj   = map_args( { @_ }, deprecated_aliases => { handler => 'destination' } );

    for (keys %$obj) {
        next if /\A(x|x\..+|_.*)\z/;
        unless (/\A(required|default|summary|description|destination|completion)\z/) {
            die "Unknown optspec property '$_'";
        }
    }
    bless $obj, $class;
}

1;
# ABSTRACT: Like Getopt::Long, but with more stuffs

=for Pod::Coverage ^(OptSpec)$

=head1 SYNOPSIS

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
         # will be passed to Getopt::Long
         destination => \$opts{baz},

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

         # other properties: x or x.* or _* are allowed
         'x.debug' => 'blah',
         _app_code => {foo=>1},
     ),
 );


=head1 DESCRIPTION

This module is a wrapper and drop-in replacement for L<Getopt::Long>. It
provides the same interface as Getopt::Long and, unlike other wrappers like
L<Getopt::Long::Complete> or L<Getopt::Long::Modern> it does not change default
configuration and all Getopt::Long configuration are supported. In fact,
Getopt::Long::More behaves much like Getopt::Long until you start to use optspec
object as one or more option destinations.


=head1 OPTSPEC OBJECT

In addition to using scalarref, arrayref, hashref, or coderef as the option
destination as Getopt::Long allows, Getopt::Long::More also allows using
optspec object as the destination. This enables you to specify more stuffs.

Optspec object is created using the C<optspec> function which accepts a list of property
name-property value pairs:

 '--fruit=s' => optspec(
     destination => \$opts{fruit},
     default => 'apple',
     summary => 'Supply name of fruit to order',
     completion => [qw/apple apricot banana/],
     ...
 )

All properties are optional. The C<destination> property, if present, will be passed to
Getopt::Long when parsing options.

Note that, in previous versions of this module, C<destination> was referred to as C<handler>,
which is now B<deprecated>. At this time C<handler> is still being accepted as an
I<alias> for C<destination>, but do NOT count on that forever.
The name C<handler> will be discontinued at one point. You have been B<warned>.

In addition to C<destination>, these other properties
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

=head2 x, x.*, _* => any

You are allowed to have properties named C<x> or anything that begins with C<x.>
or C<_>. These are ignored by Getopt::Long::More. You can use store comments or
whatever additional information here.


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

Will print a usage/help message and exit. Sample result:

 myapp [options]

 Options:
   --fruit=s     Supply name of fruit to order (default: apple)
   --debug       Enable debug mode
   --help|?      Print help message and exit
   --version     Print usage message and exit

=head2 VersionMessage

See Getopt::Long documentation.

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

=head2 optspec(%props) => obj

Create optspec object. See L</"OPTSPEC OBJECT">.


=head1 COMPLETION

Getopt::Long::Mode supports shell tab completion. To activate tab completion,
put your script (e.g. C<myapp.pl>) in C<PATH> and in bash shell type:

 % complete -C myapp.pl myapp.pl

You can then complete option names (or option values or command-line arguments
too, if you provide C<completion> properties). You can also use L<shcompgen> to
activate shell completion; shcompgen supports several shells and various
modules.

Tab completion functionality is provided by L<Complete::Getopt::Long>. Note that
this module assumes C<no_ignore_case> and does not support things like
C<getopt_compat> (starting option with C<+> instead of C<-->).


=head1 FAQ

=head2 How do I provide completion for command-line arguments:

Use the option spec C<< <> >>:

 GetOptions(
     ...
     '<>' => optspec(
         destination => \&process,
         completion => sub {
             ...
         },
     ),
 );


=head1 SEE ALSO

L<Getopt::Long>

Other Getopt::Long wrappers that provide extra features:
L<Getopt::Long::Complete>, L<Getopt::Long::Descriptive>.

If you want I<less> features instead of more: L<Getopt::Long::Less>,
L<Getopt::Long::EvenLess>.
