package Perinci::Sub::To::FishComplete;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;

use Perinci::Object;

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
        ggls_res => {
            summary => 'Full result from gen_getopt_long_spec_from_meta()',
            schema  => 'array*', # XXX envres
            description => <<'_',

If you already call `Perinci::Sub::GetArgs::Argv`'s
`gen_getopt_long_spec_from_meta()`, you can pass the _full_ enveloped result
here, to avoid calculating twice. What will be useful for the function is the
extra result in result metadata (`func.*` keys in `$res->[3]` hash).

_
        },
        per_arg_json => {
            schema => 'bool',
            summary => 'Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv',
        },
        per_arg_yaml => {
            schema => 'bool',
            summary => 'Pass per_arg_json=1 to Perinci::Sub::GetArgs::Argv',
        },
        lang => {
            schema => 'str*',
        },
    },
    result => {
        schema => 'hash*',
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
    my $ggls_res = $args{ggls_res} // do {
        require Perinci::Sub::GetArgs::Argv;
        Perinci::Sub::GetArgs::Argv::gen_getopt_long_spec_from_meta(
            meta=>$meta, meta_is_normalized=>1, common_opts=>$common_opts,
            per_arg_json => $args{per_arg_json},
            per_arg_yaml => $args{per_arg_yaml},
        );
    };
    $ggls_res->[0] == 200 or return $ggls_res;

    my $args_prop = $meta->{args} // {};
    my @cmds;

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

This module is used by L<Perinci::CmdLine>.

L<Complete::Fish::Gen::FromGetoptLong>.
