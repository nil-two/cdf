#!/usr/bin/env perl
use strict;
use warnings;
use autouse "Cwd" => qw(abs_path getcwd);
use autouse "Encode" => qw(decode_utf8);
use autouse "File::Basename" => qw(basename dirname);
use autouse "File::Path" => qw(make_path);
use autouse "JSON::PP" => qw(encode_json decode_json);

my $CDF_REGISTRY;
if ($^O eq "MSWin32") {
    $CDF_REGISTRY = $ENV{CDF_REGISTRY} // "$ENV{homepath}/.config/cdf/registry.json";
} else {
    $CDF_REGISTRY = $ENV{CDF_REGISTRY} // "$ENV{HOME}/.config/cdf/registry.json";
}

my $supported_shells = [qw(sh bash)];
my $registry_version = "3.0";
my $registry_initial_content = {
    version => $registry_version,
    labels => {},
};

my $cmd_name  = basename($0);
my $cmd_usage = <<EOF;
usage:
  $cmd_name [--]                         # select label and chdir to the labeled path
  $cmd_name [--] <label>                 # chdir to the labeled path
  $cmd_name {-a|--add} <label> [<path>]  # label the path (default: working directory)
  $cmd_name {-l|--list}                  # list labels
  $cmd_name {-L|--list-with-paths}       # list labels with paths
  $cmd_name {-p|--print} <label>         # print the labeled path
  $cmd_name {-r|--remote} <label(s)>     # remove labels
  $cmd_name {-w|--wrapper} [<shell>]     # output the wrapper script (default: sh)
  $cmd_name --help                       # print usage

supported-shells:
  @{[join(", ", @$supported_shells)]}

environment-variables:
  CDF_REGISTRY  # the registry path (default: ~/.config/cdf/registry.json)
  CDF_FILTER    # the intractive filtering command for selecting label
EOF

sub read_file {
    my ($path) = @_;
    open my $fh, "<", $path or die $!;
    my $content = do { local $/; <$fh>; };
    close $fh or die $!;
    return $content;
}

sub write_file {
    my ($path, $content) = @_;
    open my $fh, ">", $path or die $!;
    print $fh $content;
    close $fh or die $!;
}

sub main {
    foreach (@ARGV) {
        $_ = decode_utf8($_);
    }
    if ((@ARGV == 0) || (@ARGV == 1 && $ARGV[0] eq "--")) {
        print STDERR $cmd_usage;
        exit 1;
    }
    if (($ARGV[0] !~ /^-/) || (@ARGV > 1 && $ARGV[0] eq "--")) {
        print STDERR <<"        EOF" =~ s/^ {8}//gmr;
        $cmd_name: shell integration not enabled
        Please add following line to your shell's rcfile.

        command -v $cmd_name > /dev/null && eval "\$($cmd_name -w)"

        EOF
        exit 1;
    }

    my $mode = shift @ARGV;

    if ($mode eq "-a") {

        if (@ARGV < 1) {
            print STDERR "$cmd_name: $mode: no input name\n";
            exit 1;
        }
        if (-e $CDF_REGISTRY && ! -f $CDF_REGISTRY) {
            print STDERR "$cmd_name: $mode: \$CDF_REGISTRY should be a file\n";
            exit 1;
        }

        my $label = $ARGV[0];
        my $path  = $ARGV[1] // getcwd;

        if (! -e $CDF_REGISTRY) {
            make_path(dirname($CDF_REGISTRY));
            write_file($CDF_REGISTRY, json_encode($registry_initial_content) . "\n");
        }

        my $registry = decode_json(read_file($CDF_REGISTRY));

        $registry->{labels}{$label} = abs_path($path);

        write_file($CDF_REGISTRY, encode_json($registry) . "\n");

    } elsif ($mode eq "-l") {

        if (! -e $CDF_REGISTRY) {
            print STDERR "$cmd_name: $mode: \$CDF_REGISTRY doesn't exists\n";
            exit 1;
        }

        my $registry = decode_json(read_file($CDF_REGISTRY));

        for my $label (sort { $a cmp $b } keys %{$registry->{labels}}) {
            print "$label\n";
        }

    } elsif ($mode eq "-L") {

        if (! -e $CDF_REGISTRY) {
            print STDERR "$cmd_name: $mode: \$CDF_REGISTRY doesn't exists\n";
            exit 1;
        }

        my $registry = decode_json(read_file($CDF_REGISTRY));

        for my $label (sort { $a cmp $b } keys %{$registry->{labels}}) {
            printf "%s\t%s\n", $label, $registry->{labels}{$label};
        }

    } elsif ($mode eq "-p") {

        if (@ARGV < 1) {
            print STDERR "$cmd_name: $mode: no input name\n";
            exit 1;
        }
        if (! -e $CDF_REGISTRY) {
            print STDERR "$cmd_name: $mode: \$CDF_REGISTRY doesn't exists\n";
            exit 1;
        }

        my $label = $ARGV[0];

        my $registry = decode_json(read_file($CDF_REGISTRY));

        if (exists $registry->{labels}{$label}) {
            print "$registry->{labels}{$label}\n";
        } else {
            print STDERR "$cmd_name: $mode: $label: label not found\n";
            exit 1;
        }

    } elsif ($mode eq "-r") {

        if (@ARGV < 1) {
            print STDERR "$cmd_name: $mode: no input name\n";
            exit 1;
        }
        if (! -e $CDF_REGISTRY) {
            print STDERR "$cmd_name: $mode: \$CDF_REGISTRY doesn't exists\n";
            exit 1;
        }

        my $labels = [@ARGV];

        my $registry = decode_json(read_file($CDF_REGISTRY));

        for my $label (@$labels) {
            delete $registry->{labels}{$label};
        }

        write_file($CDF_REGISTRY, encode_json($registry) . "\n");

    } elsif ($mode eq "-w") {

        my $type = $ARGV[0] // "sh";

        if ($type eq "sh") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            cdf() {
                if [ \$# -eq 0 ]; then
                    command -- cdf
                    return
                elif [ \$# -eq 1 ] && [ "\$1" = "--" ]; then
                    command -- cdf
                    return
                elif [ \$# -ge 1 ] && [ "\$1" != "\${1#-}" ] && [ "\$1" != "--" ]; then
                    command -- cdf "\$@"
                    return
                fi

                if [ "\$1" = "--" ]; then
                    shift
                fi

                set -- "\$(command -- cdf -p "\$1")"
                if [ -n "\$1" ]; then
                    cd "\$1" || return
                fi
            }
            EOF
        } elsif ($type eq "bash") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            cdf() {
                if [[ \$# -eq 0 || ( \$# -eq 1 && \$1 = -- ) || ( \$# -ge 1 && \$1 = -* && \$1 != -- ) ]]; then
                    command -- cdf "\$@"
                    return
                fi

                if [[ \$1 = -- ]]; then
                    shift
                fi

                local nextpath
                nextpath=\$(command -- cdf -p "\$1")
                if [[ -n \$nextpath ]]; then
                    cd "\$nextpath" || return
                fi
            }

            _cdf() {
                local cur=\${COMP_WORDS[COMP_CWORD]}

                local defaultIFS=\$' \\t\\n'
                local IFS=\$defaultIFS

                case \$COMP_CWORD in
                    1)
                        case \$cur in
                            -*)
                                COMPREPLY=( \$(compgen -W '-- -a -g -l -r -w -h' -- "\$cur") )
                                ;;
                            *)
                                IFS=\$'\\n'; COMPREPLY=( \$(compgen -W '\$(cdf -l)' -- "\$cur") ); IFS=\$defaultIFS
                                ;;
                        esac
                        ;;
                    *)
                        case \${COMP_WORDS[1]} in
                            --)
                                IFS=\$'\\n'; COMPREPLY=( \$(compgen -W '\$(cdf -l)' -- "\$cur") ); IFS=\$defaultIFS
                                ;;
                            -a)
                                case \$COMP_CWORD in
                                    2)
                                        IFS=\$'\\n'; COMPREPLY=( \$(compgen -W '\$(cdf -l)' -- "\$cur") ); IFS=\$defaultIFS
                                        ;;
                                    *)
                                        IFS=\$'\\n'; COMPREPLY=( \$(compgen -A directory -- "\$cur") ); IFS=\$defaultIFS
                                        type compopt &> /dev/null && compopt -o filenames 2> /dev/null || compgen -f /non-existing-dir/ >/dev/null
                                        ;;
                                esac
                                ;;
                            -g)
                                IFS=\$'\\n'; COMPREPLY=( \$(compgen -W '\$(cdf -l)' -- "\$cur") ); IFS=\$defaultIFS
                                ;;
                            -r)
                                IFS=\$'\\n'; COMPREPLY=( \$(compgen -W '\$(cdf -l)' -- "\$cur") ); IFS=\$defaultIFS
                                ;;
                            -w)
                                COMPREPLY=( \$(compgen -W '@$supported_shells' -- "\$cur") )
                                ;;
                        esac
                        ;;
                esac
            }
            complete -F _cdf cdf
            EOF
        } else {
            print STDERR "$cmd_name: $mode: $type doesn't supported\n";
            exit 1;
        }

    } elsif ($mode eq "-h") {

        print $cmd_usage;

    } else {

        print STDERR "$cmd_name: unrecognized option '$mode'\n";
        print STDERR "Try '$cmd_name -h' for more information.\n";
        exit 1;

    }
}

main;
