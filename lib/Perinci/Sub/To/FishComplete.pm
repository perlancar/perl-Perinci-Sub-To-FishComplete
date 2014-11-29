package Perinci::Sub::To::FishComplete;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use String::ShellQuote;

our %SPEC;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(gen_fish_complete_from_meta);

$SPEC{gen_fish_complete_from_meta} = {
    v => 1.1,
    summary => 'From Rinci function metadata, generate tab completion '.
        'commands for the fish shell',
    description => <<'_',


_
    args => {
        meta => {
            schema => 'hash*', # XXX rifunc
            req => 1,
            pos => 0,
        },
        meta_is_normalized => {
            schema => 'bool*',
        },
        common_opts => {
            summary => 'Will be passed to gen_getopt_long_spec_from_meta()',
            schema  => 'hash*',
        },
        gco_res => {
            summary => 'Full result from gen_cli_opt_spec_from_meta()',
            schema  => 'array*', # XXX envres
            description => <<'_',

If you already call `Perinci::Sub::To::CLIOptSpec`'s
`gen_cli_opt_spec_from_meta()`, you can pass the _full_ enveloped result here,
to avoid calculating twice.

_
        },
        per_arg_json => {
            summary => 'Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv',
            schema => 'bool',
        },
        per_arg_yaml => {
            summary => 'Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv',
            schema => 'bool',
        },
        lang => {
            schema => 'str*',
        },

        cmdname => {
            summary => 'Command name',
            schema => 'str*',
        },
    },
    result => {
        schema => 'str*',
        summary => 'A script that can be fed to the fish shell',
    },
};
sub gen_fish_complete_from_meta {
    my %args = @_;

    my $lang = $args{lang};
    my $meta = $args{meta} or return [400, 'Please specify meta'];
    my $common_opts = $args{common_opts};
    unless ($args{meta_is_normalized}) {
        require Perinci::Sub::Normalize;
        $meta = Perinci::Sub::Normalize::normalize_function_metadata($meta);
    }
    my $gco_res = $args{gco_res} // do {
        require Perinci::Sub::To::CLIOptSpec;
        Perinci::Sub::To::CLIOptSpec::gen_cli_opt_spec_from_meta(
            meta=>$meta, meta_is_normalized=>1, common_opts=>$common_opts,
            per_arg_json => $args{per_arg_json},
            per_arg_yaml => $args{per_arg_yaml},
        );
    };
    $gco_res->[0] == 200 or return $gco_res;
    my $cliospec = $gco_res->[2];

    my $cmdname = $args{cmdname};
    if (!$cmdname) {
        ($cmdname = $0) =~ s!.+/!!;
    }

    my @cmds;
    my $prefix = "complete -c ".shell_quote($cmdname);
    push @cmds, "$prefix -e"; # currently does not work (fish bug)
    for my $opt0 (sort keys %{ $cliospec->{opts} }) {
        my $ospec = $cliospec->{opts}{$opt0};
        my $req_arg;
        for my $opt (split /, /, $opt0) {
            $opt =~ s/^--?//;
            $opt =~ s/=.+// and $req_arg = 1;

            my $cmd = $prefix;
            $cmd .= length($opt) > 1 ? " -l '$opt'" : " -s '$opt'";
            $cmd .= " -d ".shell_quote($ospec->{summary}) if $ospec->{summary};

            if ($req_arg) {
                $cmd .= " -r -f -a ".shell_quote("(begin; set -lx COMP_OPT '$opt'; ".shell_quote($cmdname)."; end)");
            }
            push @cmds, $cmd;
        }
    }

    [200, "OK", join("", map {"$_\n"} @cmds)];
}

1;
# ABSTRACT: Generate tab completion commands for the fish shell

=head1 SYNOPSIS

 use Perinci::Sub::To::FishComplete qw(gen_fish_complete_from_meta);
 my $res = gen_fish_complete_from_meta(meta => $meta);
 die "Failed: $res->[0] - $res->[1]" unless $res->[0] == 200;
 say $res->[2];


=head1 SEE ALSO

This module is used by L<Perinci::CmdLine> and L<Getopt::Long::Complete>.

L<Complete::Fish::Gen::FromGetoptLong>.
