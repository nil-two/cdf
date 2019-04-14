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
  $cmd_name -w [<shell>]         # output the wrapper script (default: sh)
  $cmd_name -h                   # print usage

supported-shells:
  sh, bash, fish, zsh, yash

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
                            COMPREPLY=( \$(compgen -W "sh bash zsh yash fish" -- "\$cur") )
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
                            _values "type" sh bash zsh yash fish
                            ;;
                        -h)
                            ;;
                    esac
                    ;;
            esac
        }
        compdef _cdf cdf
        EOF
    } elsif ($type eq "yash") {
        print <<"        EOF" =~ s/^ {8}//gmr;
        function cdf {
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
        function completion/cdf {
          CWORD=\${WORDS[#]}

          case \$CWORD in
            1)
              case \$TARGETWORD in
                -*) command -f completion/cdf::completecmd ;;
                *)  command -f completion/cdf::completelabel ;;
              esac
              ;;
            *)
              cmd=\${WORDS[2]}
              case \$cmd in
                --)
                  command -f completion/cdf::completelabel
                  ;;
                -a)
                  case \$CWORD in
                    2) command -f completion/cdf::completelabel ;;
                    *) complete -d ;;
                  esac
                  ;;
                -g)
                  command -f completion/cdf::completelabel
                  ;;
                -l)
                  ;;
                -r)
                  command -f completion/cdf::completelabel
                  ;;
                -w)
                  command -f completion/cdf::completewrapper
                  ;;
              esac
              ;;
          esac
        }

        function completion/cdf::completecmd {
          complete -D "chdir to the path so labeled" -- --
          complete -D "save the path with the label" -- -a
          complete -D "get the path so labeled"      -- -g
          complete -D "list labels"                  -- -l
          complete -D "remove the label"             -- -r
          complete -D "output the wrapper script"    -- -w
          complete -D "print usage"                  -- -h
        }

        function completion/cdf::completelabel {
          complete -- \$(cdf -l)
        }

        function completion/cdf::completewrapper {
          complete -- sh bash zsh yash fish
        }
        EOF
    } elsif ($type eq "fish") {
        print <<"        EOF" =~ s/^ {8}//gmr;
        function cdf
          if test (count \$argv) -eq 0
            @{[sh_escape $cmd_path]}
            return
          end
          if test (count \$argv) -ge 1; and string match -q -r "^-" -- \$argv[1]; and test \$argv[1] != "--"
            @{[sh_escape $cmd_path]} \$argv
            return
          end

          if test \$argv[1] = "--"
            set argv \$argv[2..-1]
          end

          set -l path (@{[sh_escape $cmd_path]} -g \$argv[1])
          if test -n "\$path"
            cd \$path
          end
        end

        function __fish_cdf_complete
          set -l cur (commandline -tc)
          set -l words (commandline -pco)
          set -l cword (count \$words)
          switch \$cword
            case 1
              switch \$cur
                case '-*'
                  echo -es -- "--" "\\t" "Chdir to the path so labeled"
                  echo -es -- "-a" "\\t" "Save the path with the label"
                  echo -es -- "-g" "\\t" "Get the path so labeled"
                  echo -es -- "-l" "\\t" "List labels"
                  echo -es -- "-r" "\\t" "Remove the label"
                  echo -es -- "-w" "\\t" "Output the wrapper script"
                  echo -es -- "-h" "\\t" "Print usage"
                case '*'
                  cdf -l | awk '{print \$0 "\\t" "Label"}'
              end
            case '*'
              set -l cmd \$words[2]
              switch \$cmd
                case '--'
                  cdf -l | awk '{print \$0 "\\t" "Label"}'
                case '-a'
                  switch \$cword
                    case 2
                      cdf -l | awk '{print \$0 "\\t" "Label"}'
                    case 3
                      __fish_complete_directories \$cur
                  end
                case '-g'
                  cdf -l | awk '{print \$0 "\\t" "Label"}'
                case '-r'
                  cdf -l | awk '{print \$0 "\\t" "Label"}'
                case '-w'
                  printf "%s\\n" sh bash zsh yash fish | awk '{print \$0 "\\t" "Shell"}'
              end
          end
        end
        complete -c cdf -f -a "(__fish_cdf_complete)"
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
