#!/usr/bin/perl
use strict;
use warnings;
use autouse "Cwd" => qw(abs_path getcwd);
use autouse "File::Basename" => qw(dirname);
use autouse "File::Path" => qw(make_path);
use autouse "JSON::PP" => qw(encode_json decode_json);

my $CDFFILE = $ENV{CDFFILE} // "$ENV{HOME}/.local/share/cdf/cdf.json";

my $cmd_name = $0 =~ s/.*\///r;
my $usage = <<EOF;
usage:
  $cmd_name [--] <label>         # chdir to the path so labeled
  $cmd_name -a <label> [<path>]  # save the path with the label
  $cmd_name -g <label>           # get the path so labeled
  $cmd_name -l                   # list labels
  $cmd_name -r <label>           # remove the label
  $cmd_name -w [sh|bash|zsh]     # output the wrapper script (default: sh)
  $cmd_name -h                   # print usage

environment-variables:
  CDFFILE   # the registry path (default: ~/.local/share/cdf/cdf.json)
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

sub sh_escape {
    my ($s) = @_;
    $s =~ s/'/'"'"'/g;
    $s =~ s/^|$/'/g;
    return $s;
}

if ((@ARGV == 0) || (@ARGV == 1 && $ARGV[0] eq "--")) {
    print STDERR $usage;
    exit 2;
}
if (($ARGV[0] !~ /^-/) || (@ARGV > 1 && $ARGV[0] eq "--")) {
    print STDERR <<"    EOF" =~ s/^ {4}//gmr;
    $cmd_name: shell integration not enabled
    Please add following line to your shell's rc file.
    
    command -v $cmd_name > /dev/null && eval "\$($cmd_name -w)"

    EOF
    exit 2;
}

my $mode = shift @ARGV;

if ($mode eq "-a") {

    if (@ARGV < 1) {
        print STDERR "$cmd_name: $mode: no input name\n";
        exit 2;
    }
    if (-e $CDFFILE && ! -f $CDFFILE) {
        print STDERR "$cmd_name: $mode: \$CDFFILE should be a file\n";
        exit 2;
    }

    my $label = $ARGV[0];
    my $path  = $ARGV[1] // getcwd;

    if (! -e $CDFFILE) {
        make_path(dirname($CDFFILE));
        write_file($CDFFILE, "{}\n");
    }

    my $pathes = decode_json(read_file($CDFFILE));

    $pathes->{$label} = abs_path($path);

    write_file($CDFFILE, encode_json($pathes) . "\n");

} elsif ($mode eq "-g") {

    if (@ARGV < 1) {
        print STDERR "$cmd_name: $mode: no input name\n";
        exit 2;
    }
    if (! -e $CDFFILE) {
        print STDERR "$cmd_name: $mode: \$CDFFILE doesn't exists\n";
        exit 2;
    }

    my $label = $ARGV[0];

    my $pathes = decode_json(read_file($CDFFILE));

    if (exists $pathes->{$label}) {
        print "$pathes->{$label}\n";
    } else {
        print STDERR "$cmd_name: $mode: $label: label not found\n";
        exit 1;
    }

} elsif ($mode eq "-l") {

    if (! -e $CDFFILE) {
        print STDERR "$cmd_name: $mode: \$CDFFILE doesn't exists\n";
        exit 2;
    }

    my $pathes = decode_json(read_file($CDFFILE));

    for my $label (sort { $a cmp $b } keys %$pathes) {
        print "$label\n";
    }

} elsif ($mode eq "-r") {

    if (@ARGV < 1) {
        print STDERR "$cmd_name: $mode: no input name\n";
        exit 2;
    }
    if (! -e $CDFFILE) {
        print STDERR "$cmd_name: $mode: \$CDFFILE doesn't exists\n";
        exit 2;
    }

    my $label = $ARGV[0];

    my $pathes = decode_json(read_file($CDFFILE));

    delete $pathes->{$label};

    write_file($CDFFILE, encode_json($pathes) . "\n");

} elsif ($mode eq "-w") {

    my $type = $ARGV[0] // "sh";

    my $cmd_path = abs_path($0);

    if ($type eq "sh") {
        print <<"        EOF" =~ s/^ {8}//gmr;
        cdf() {
            if [ \$# -eq 0 ]; then
                @{[sh_escape $cmd_path]}
                return
            elif [ \$# -ge 1 ] && [ "\$1" != "\${1#-}" ] && [ "\$1" != "--" ]; then
                @{[sh_escape $cmd_path]} "\$@"
                return
            fi

            if [ "\$1" = "--" ]; then
                shift
            fi

            set -- "\$(@{[sh_escape $cmd_path]} -g "\$1")"
            if [ -n "\$1" ]; then
                cd "\$1" || return
            fi
        }
        EOF
    } elsif ($type eq "bash") {
        print <<"        EOF" =~ s/^ {8}//gmr;
        cdf() {
            if [[ \$# -eq 0 || ( \$# -ge 1 && \$1 = -* && \$1 != -- ) ]]; then
                @{[sh_escape $cmd_path]} "\$@"
                return
            fi

            if [[ \$1 = -- ]]; then
                shift
            fi

            local path
            path=\$(@{[sh_escape $cmd_path]} -g "\$1")
            if [[ -n \$path ]]; then
                cd "\$path" || return
            fi
        }
        _cdf() {
            local cur=\${COMP_WORDS[COMP_CWORD]}
            case \$COMP_CWORD in
                1)
                    case \$cur in
                        -*) COMPREPLY=( \$(compgen -W "-- -a -g -l -r -w -h" -- "\$cur") ) ;;
                        *)  COMPREPLY=( \$(compgen -W "\$(cdf -l)" -- "\$cur") ) ;;
                    esac
                    ;;
                *)
                    local cmd=\${COMP_WORDS[1]}
                    case \$cmd in
                        --)
                            COMPREPLY=( \$(compgen -W "\$(cdf -l)" -- "\$cur") )
                            ;;
                        -a)
                            case \$COMP_CWORD in
                                2) COMPREPLY=( \$(compgen -W "\$(cdf -l)" -- "\$cur") ) ;;
                                *) _filedir -d ;;
                            esac
                            ;;
                        -g)
                            COMPREPLY=( \$(compgen -W "\$(cdf -l)" -- "\$cur") )
                            ;;
                        -l)
                            COMPREPLY=()
                            ;;
                        -r)
                            COMPREPLY=( \$(compgen -W "\$(cdf -l)" -- "\$cur") )
                            ;;
                        -w)
                            COMPREPLY=( \$(compgen -W "sh bash zsh" -- "\$cur") )
                            ;;
                    esac
                    ;;
            esac
        }
        complete -F _cdf cdf
        EOF
    } elsif ($type eq "zsh") {
        print <<"        EOF" =~ s/^ {8}//gmr;
        cdf() {
            if [[ \$# -eq 0 || ( \$# -ge 1 && \$1 = -* && \$1 != -- ) ]]; then
                @{[sh_escape $cmd_path]} "\$@"
                return
            fi

            if [[ \$1 = -- ]]; then
                shift
            fi

            local path
            path=\$(@{[sh_escape $cmd_path]} -g "\$1")
            if [[ -n \$path ]]; then
                cd "\$path"
            fi
        }
        _cdf() {
            local cur=\${words[\$CURRENT]}
            case \$CURRENT in
                2)
                    case \$cur in
                        -*)
                            local modes
                            modes=(
                            "--[chdir to the path so labeled]"
                            "-a[save the path with the label]"
                            "-g[get the path so labeled]"
                            "-l[list labels]"
                            "-r[remove the label]"
                            "-w[output the wrapper script (default: sh)]"
                            "-h[print usage]"
                            )
                            _values "mode" \$modes
                            ;;
                        *)
                            _values "label" \$(cdf -l)
                            ;;
                    esac
                    ;;
                *)
                    local mode=\${words[2]}
                    case \$mode in
                        --)
                            _values "label" \$(cdf -l)
                            ;;
                        -a)
                            case \$CURRENT in
                                3) _values "label" \$(cdf -l) ;;
                                *) _path_files -/ ;;
                            esac
                            ;;
                        -g)
                            _values "label" \$(cdf -l)
                            ;;
                        -l)
                            ;;
                        -r)
                            _values "label" \$(cdf -l)
                            ;;
                        -w)
                            _values "type" sh bash zsh
                            ;;
                        -h)
                            ;;
                    esac
                    ;;
            esac
        }
        compdef _cdf cdf
        EOF
    } else {
        print STDERR "$cmd_name: $mode: $type doesn't supported\n";
        exit 2;
    }

} elsif ($mode eq "-h") {

    print $usage;

} else {

    print STDERR $usage;
    exit 2;

}
