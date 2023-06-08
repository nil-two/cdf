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

my $supported_shells = [qw(sh bash zsh fish)];
my $registry_version = "3.0";
my $registry_initial_content = {
    version => $registry_version,
    labels => {},
};

my $cmd_name  = basename($0);
my $cmd_usage = <<EOF;
usage:
  $cmd_name [--]                 # select label and chdir to the labeled path
  $cmd_name [--] <label>         # chdir to the labeled path
  $cmd_name -a <label> [<path>]  # label the path (default: working directory)
  $cmd_name -l                   # list labels
  $cmd_name -L                   # list labels with pathes
  $cmd_name -p <label>           # print the labeled path
  $cmd_name -r <label(s)>        # remove labels
  $cmd_name -w [<shell>]         # output the wrapper script (default: sh)
  $cmd_name -h                   # print usage

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
        Please add following line to your shell's rc file.

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
        } elsif ($type eq "zsh") {
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
                local cur=\${words[\$CURRENT]}
                local commands labels
                case \$CURRENT in
                    2)
                        case \$cur in
                            -*)
                                commands=(
                                "--[chdir to the path so labeled]"
                                "-a[save the path with the label]"
                                "-g[get the path so labeled]"
                                "-l[list labels]"
                                "-r[remove labels]"
                                "-w[output the wrapper script]"
                                "-h[print usage]"
                                )
                                _values "command" \$commands
                                ;;
                            *)
                                labels=( \${(f)"\$(cdf -l)"} )
                                _describe "label" labels
                                ;;
                        esac
                        ;;
                    *)
                        local mode=\${words[2]}
                        case \$mode in
                            --)
                                labels=( \${(f)"\$(cdf -l)"} )
                                _describe "label" labels
                                ;;
                            -a)
                                case \$CURRENT in
                                    3)
                                      labels=( \${(f)"\$(cdf -l)"} )
                                      _describe "label" labels
                                      ;;
                                    *)
                                      _path_files -/
                                      ;;
                                esac
                                ;;
                            -g)
                                labels=( \${(f)"\$(cdf -l)"} )
                                _describe "label" labels
                                ;;
                            -l)
                                ;;
                            -r)
                                labels=( \${(f)"\$(cdf -l)"} )
                                _describe "label" labels
                                ;;
                            -w)
                                _values "type" @$supported_shells
                                ;;
                            -h)
                                ;;
                        esac
                        ;;
                esac
            }
            compdef _cdf cdf
            EOF
        } elsif ($type eq "fish") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            function cdf
                if test (count \$argv) -eq 0
                    command cdf
                    return
                end
                if test (count \$argv) -eq 1; and test \$argv[1] = "--"
                    command cdf
                    return
                end
                if test (count \$argv) -ge 1; and string match -q -r "^-" -- \$argv[1]; and test \$argv[1] != "--"
                    command cdf \$argv
                    return
                end

                if test \$argv[1] = "--"
                    set argv \$argv[2..-1]
                end

                set -l nextpath (command cdf -p \$argv[1])
                if test -n "\$nextpath"
                    cd \$nextpath
                end
            end

            function __fish_cdf_complete
                set -l cur (commandline -tc)
                set -l words (commandline -pco)
                set -l cword (count \$words)
                switch \$cword
                    case 1
                        switch \$cur
                            case "-*"
                                echo -es -- "--" "\\t" "Chdir to the path so labeled"
                                echo -es -- "-a" "\\t" "Save the path with the label"
                                echo -es -- "-g" "\\t" "Get the path so labeled"
                                echo -es -- "-l" "\\t" "List labels"
                                echo -es -- "-r" "\\t" "Remove Labels"
                                echo -es -- "-w" "\\t" "Output the wrapper script"
                                echo -es -- "-h" "\\t" "Print usage"
                            case "*"
                                cdf -l | awk '{print \$0 "\\t" "Label"}'
                        end
                    case "*"
                        set -l cmd \$words[2]
                        switch \$cmd
                            case "--"
                                cdf -l | awk '{print \$0 "\\t" "Label"}'
                            case "-a"
                                switch \$cword
                                    case 2
                                        cdf -l | awk '{print \$0 "\\t" "Label"}'
                                    case 3
                                        __fish_complete_directories \$cur
                                end
                            case "-g"
                                cdf -l | awk '{print \$0 "\\t" "Label"}'
                            case "-r"
                                cdf -l | awk '{print \$0 "\\t" "Label"}'
                            case "-w"
                                printf "%s\\n" @$supported_shells | awk '{print \$0 "\\t" "Shell"}'
                        end
                end
            end
            complete -c cdf -f -a "(__fish_cdf_complete)"
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
