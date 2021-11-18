#!/usr/bin/env perl
use strict;
use warnings;
use autouse "Cwd" => qw(abs_path getcwd);
use autouse "Encode" => qw(decode_utf8);
use autouse "File::Basename" => qw(basename dirname);
use autouse "File::Path" => qw(make_path);
use autouse "JSON::PP" => qw(encode_json decode_json);

my $CDFFILE;
if ($^O eq "MSWin32") {
    $CDFFILE = $ENV{CDFFILE} // "$ENV{homepath}/.config/cdf/cdf.json";
} else {
    $CDFFILE = $ENV{CDFFILE} // "$ENV{HOME}/.config/cdf/cdf.json";
}

my $supported_shells = [qw(sh ksh bash zsh yash fish tcsh rc nyagos xyzsh xonsh eshell cmd powershell)];

my $cmd_name  = basename($0);
my $cmd_usage = <<EOF;
usage:
  $cmd_name [--] <label>         # chdir to the path so labeled
  $cmd_name -a <label> [<path>]  # save the path with the label
  $cmd_name -g <label>           # get the path so labeled
  $cmd_name -l                   # list labels
  $cmd_name -r <label(s)>        # remove labels
  $cmd_name -w [<shell>]         # output the wrapper script (default: sh)
  $cmd_name -h                   # print usage

supported-shells:
  sh, ksh, bash, zsh, yash, fish, tcsh, rc,
  nyagos, xyzsh, xonsh, eshell, cmd, powershell

environment-variables:
  CDFFILE  # the registry path (default: ~/.config/cdf/cdf.json)
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
        if (-e $CDFFILE && ! -f $CDFFILE) {
            print STDERR "$cmd_name: $mode: \$CDFFILE should be a file\n";
            exit 1;
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
            exit 1;
        }
        if (! -e $CDFFILE) {
            print STDERR "$cmd_name: $mode: \$CDFFILE doesn't exists\n";
            exit 1;
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
            exit 1;
        }

        my $pathes = decode_json(read_file($CDFFILE));

        for my $label (sort { $a cmp $b } keys %$pathes) {
            print "$label\n";
        }

    } elsif ($mode eq "-r") {

        if (@ARGV < 1) {
            print STDERR "$cmd_name: $mode: no input name\n";
            exit 1;
        }
        if (! -e $CDFFILE) {
            print STDERR "$cmd_name: $mode: \$CDFFILE doesn't exists\n";
            exit 1;
        }

        my $labels = [@ARGV];

        my $pathes = decode_json(read_file($CDFFILE));

        for my $label (@$labels) {
            delete $pathes->{$label};
        }

        write_file($CDFFILE, encode_json($pathes) . "\n");

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

                set -- "\$(command -- cdf -g "\$1")"
                if [ -n "\$1" ]; then
                    cd "\$1" || return
                fi
            }
            EOF
        } elsif ($type eq "ksh") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            cdf() {
                if [[ \$# -eq 0 || ( \$# -eq 1 && \$1 = -- ) || ( \$# -ge 1 && \$1 = -* && \$1 != -- ) ]]; then
                    command -- cdf "\$@"
                    return
                fi

                if [[ \$1 = -- ]]; then
                    shift
                fi

                set -- "\$(command -- cdf -g "\$1")"
                if [[ -n \$1 ]]; then
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
                nextpath=\$(command -- cdf -g "\$1")
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
                nextpath=\$(command -- cdf -g "\$1")
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
        } elsif ($type eq "yash") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            function cdf {
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

                set -- "\$(command -- cdf -g "\$1")"
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
                complete -D "remove labels"                -- -r
                complete -D "output the wrapper script"    -- -w
                complete -D "print usage"                  -- -h
            }

            function completion/cdf::completelabel {
                typeset lines
                lines=\$(cdf -l) && while read -r label; do complete -- "\$label"; done <<< "\$lines"
            }

            function completion/cdf::completewrapper {
                complete -- @$supported_shells
            }
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

                set -l nextpath (command cdf -g \$argv[1])
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
        } elsif ($type eq "tcsh") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            alias cdf '\\\\
            set __fn_argv=(\\!:*);\\\\
            eval '"'"'\\\\
            source /dev/stdin \$__fn_argv:q <<__FN_BODY__\\\\
                unset __fn_argv\\\\
                \\\\
                if (\\\$#argv == 0) then\\\\
                    command -- cdf\\\\
                    exit\\\\
                endif\\\\
                if (\\\$#argv == 1 && \\\$argv[1]:q == --) then\\\\
                    command -- cdf\\\\
                    exit\\\\
                endif\\\\
                if (\\\$#argv >= 1 && \\\$argv[1]:q =~ -* && \\\$argv[1]:q \\\\!= --) then\\\\
                    command -- cdf \\\$argv:q\\\\
                    exit\\\\
                endif\\\\
                \\\\
                if (\\\$argv[1]:q == '"'"'"'"'"'"'"'"'--'"'"'"'"'"'"'"'"') then\\\\
                    shift\\\\
                endif\\\\
                \\\\
                set __cdfnextpath=\\\\
                command cdf -g \\\$argv[1]:q | sed '"'"'"'"'"'"'"'"'s/'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'/'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'/g; s/\\\\\\\\!/\\\\\\\\\\\\\\\\!/g; s/\\\$/\\\\\\\\/; 1s/^/set __cdfnextpath='"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'/; \\\$s/\\\\\\\\\\\$/'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'"'/'"'"'"'"'"'"'"'"' | source /dev/stdin\\\\
                true\\\\
                if (\\\$__cdfnextpath:q \\\\!= '"'"'"'"'"'"'"'"''"'"'"'"'"'"'"'"') then\\\\
                    cd \\\$__cdfnextpath:q\\\\
                endif\\\\
                unset __cdfnextpath\\\\
            __FN_BODY__\\\\
            '"'"'\\\\
            '

            alias __cdfcomplete '\\\\
            set __fn_argv=(\\!:*);\\\\
            eval '"'"'\\\\
            source /dev/stdin \$__fn_argv:q <<__FN_BODY__\\\\
                unset __fn_argv\\\\
                \\\\
                set __cdfcompleteargv=(\\\$COMMAND_LINE)\\\\
                if (\\\$COMMAND_LINE:q =~ '"'"'"'"'"'"'"'"'* '"'"'"'"'"'"'"'"') then\\\\
                    set __cdfcompleteargv=(\\\$__cdfcompleteargv:q '"'"'"'"'"'"'"'"''"'"'"'"'"'"'"'"')\\\\
                endif\\\\
                \\\\
                switch (\\\$#__cdfcompleteargv)\\\\
                case 2:\\\\
                    switch (\\\$__cdfcompleteargv[2]:q)\\\\
                    case "-*":\\\\
                        printf "%s\\\\n" -- -a -g -l -r -w -h\\\\
                        breaksw\\\\
                    default:\\\\
                        command -- cdf -l\\\\
                        breaksw\\\\
                    endsw\\\\
                    breaksw\\\\
                default:\\\\
                    switch (\\\$__cdfcompleteargv[2]:q)\\\\
                    case "--":\\\\
                        command -- cdf -l\\\\
                        breaksw\\\\
                    case "-a":\\\\
                        switch (\\\$#__cdfcompleteargv)\\\\
                        case 3:\\\\
                            command -- cdf -l\\\\
                            breaksw\\\\
                        default:\\\\
                            sh -c '"'"'"'"'"'"'"'"'ls -dp -- "\\\$1"* 2> /dev/null'"'"'"'"'"'"'"'"' -- \\\$__cdfcompleteargv[\\\$#__cdfcompleteargv]:q | awk '"'"'"'"'"'"'"'"'/\\\\/\\\$/{print;print}'"'"'"'"'"'"'"'"'\\\\
                            breaksw\\\\
                        endsw\\\\
                        breaksw\\\\
                    case "-g":\\\\
                        command -- cdf -l\\\\
                        breaksw\\\\
                    case "-r":\\\\
                        command -- cdf -l\\\\
                        breaksw\\\\
                    case "-w":\\\\
                        printf "%s\\\\n" @$supported_shells\\\\
                        breaksw\\\\
                    endsw\\\\
                    breaksw\\\\
                endsw\\\\
            __FN_BODY__\\\\
            '"'"'\\\\
            '
            complete cdf 'p/*/`__cdfcomplete`/'
            EOF
        } elsif ($type eq "rc") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            fn cdf {
                if ({~ \$#* 0} || {~ \$#* 1 && ~ \$1 '--'} || {test \$#* -ge 1 && ~ \$1 -* && ! ~ \$1 '--'}) {
                    command -- cdf \$*
                    return
                }

                if (~ \$1 '--') {
                    shift
                }

                ifs='' nextpath=`{command -- cdf -g \$1 | awk 'NR==1{l=\$0;while(getline){print l;l=\$0};printf"%s",l}'} if (test -n \$nextpath) {
                    cd \$nextpath
                }
            }
            EOF
        } elsif ($type eq "nyagos") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            nyagos.alias.cdf = function(args)
                if (#args == 0) or (#args == 1 and args[1] == "--") or (#args >= 1 and args[1]:match([[^-]]) and args[1] ~= "--") then
                    nyagos.exec({"command", "--", "cdf", unpack(args)})
                    return
                end

                if args[1] == "--" then
                    table.remove(args, 1)
                end

                local label        = args[1]
                local quoted_label = "'" .. label:gsub([[']], [['"'"']]) .. "'"
                local next_path    = nyagos.eval("command -- cdf -g " .. quoted_label)
                if next_path ~= nil and next_path ~= "" then
                    nyagos.chdir(next_path)
                end
            end

            nyagos.complete_for.cdf = function(args)
                local cur = args[#args]
                local function to_lines(s)
                    local a = {}
                    for w in s:gmatch("[^\\r\\n]+") do
                        table.insert(a, w)
                    end
                    return a
                end

                if #args == 2 then
                    if cur:match([[^-]]) then
                        return {"--", "-a", "-g", "-l", "-r", "-w", "-h"}
                    else
                        return to_lines(nyagos.eval("command -- cdf -l"))
                    end
                else
                    local cmd = args[2]
                    if cmd == "--" then
                        return to_lines(nyagos.eval("command -- cdf -l"))
                    elseif cmd == "-a" then
                        if #args == 3 then
                            return to_lines(nyagos.eval("command -- cdf -l"))
                        else
                            return nil
                        end
                    elseif cmd == "-g" then
                        return to_lines(nyagos.eval("command -- cdf -l"))
                    elseif cmd == "-l" then
                        return {}
                    elseif cmd == "-r" then
                        return to_lines(nyagos.eval("command -- cdf -l"))
                    elseif cmd == "-w" then
                        return nyagos.fields("@$supported_shells")
                    elseif cmd == "-h" then
                        return {}
                    end
                end
            end
            EOF
        } elsif ($type eq "xyzsh") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            def cdf (
              sys::printf "%s\\n" -a -g -l -r -w -h | each (
                | var -local flag
                if (hash -key \$flag OPTIONS | chomp |!= "") (
                  if (ary -size ARGV | -eq 0) (
                    sys::cdf \$flag || return 1
                    return 0
                  ) else (
                    sys::cdf \$flag \$ARGV || return 1
                    return 0
                  )
                )
              )

              if (ary -size ARGV | -eq 0) (
                sys::cdf || return 1
                return 0
              )

              sys::cdf -g \$(ary -index 0 ARGV) | var -local nextpath
              cd \$nextpath || return 1
            )

            completion cdf sys::cdf (
              sys::cdf -l
            )
            EOF
        } elsif ($type eq "xonsh") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            def __cdf(args):
                if (len(args) == 0) or (len(args) == 1 and args[0] == "--") or (len(args) >= 1 and args[0].startswith("-") and args[0] != "--"):
                    command -- cdf @(args)
                    return

                if (args[0] == "--"):
                    args.pop(0)

                nextpath = ''.join(!(command -- cdf -g @(args[0]))).strip()
                if nextpath != "":
                    cd @(nextpath)

            def __complete_cdf(prefix, line, start, end, ctx):
                """
                Completion for "cdf"
                """

                from xonsh.completers.path import complete_dir

                words = line[:end].split()
                if line.endswith(" "):
                    words.append("")

                raw_comps = []
                completed = False
                comps     = None
                lp        = None
                if start != 0 and words[0] == "cdf":
                    if len(words) == 2:
                        if prefix.startswith("-"):
                            raw_comps += ["--", "-a", "-g", "-l", "-r", "-w", "-h"]
                        else:
                            raw_comps += \$(command -- cdf -l).strip().split("\\n")
                    else:
                        if words[1] == "--":
                            raw_comps += \$(command -- cdf -l).strip().split("\\n")
                        elif words[1] == "-a":
                            if len(words) == 3:
                                raw_comps += \$(command -- cdf -l).strip().split("\\n")
                            else:
                                comps, lp = complete_dir(prefix, line, start, end, ctx, True)
                                completed = True
                        elif words[1] == "-g":
                            raw_comps += \$(command -- cdf -l).strip().split("\\n")
                        elif words[1] == "-r":
                            raw_comps += \$(command -- cdf -l).strip().split("\\n")
                        elif words[1] == "-w":
                            raw_comps += [@{[join ", ", map { "\"$_\"" } @$supported_shells]}]

                if completed:
                    return comps, lp
                else:
                    comps = set(filter(lambda s: s.startswith(prefix), raw_comps))
                    if (len(comps) == 1):
                        comps = set(map(lambda s: s + " ", comps))
                    lp = len(prefix)
                    return comps, lp

            aliases["cdf"] = __cdf

            if \$(completer list).find('cdf : Completion for "cdf"') == -1:
                completer add cdf __complete_cdf
            EOF
        } elsif ($type eq "eshell") {
            print <<"            EOF" =~ s/^ {12}//gmr;
            (defun eshell/cdf (&rest args)
              "Chdir to the favorite directory"
              (let ((argc (length args))
                    (to-args (lambda (&rest ls) (apply 'concat (mapcar (lambda (s) (concat s " ")) (eshell-flatten-list ls))))))
                (cond
                  ((or (= argc 0)
                       (and (= argc 1) (string= (car args) "--"))
                       (and (>= argc 1) (string-match "^-" (car args)) (not (string= (car args) "--"))))
                   (shell-command-to-string (funcall to-args "cdf" args)))
                  (t
                    (let* ((label (if (string= (car args) "--") (cdar args) (car args)))
                           (nextpath (shell-command-to-string (funcall to-args "cdf" "-g" label)))
                           (nextpath-chomped (replace-regexp-in-string "[\\n\\r]+\$" "" nextpath)))
                      (cd nextpath-chomped))))))
            EOF
        } elsif ($type eq "cmd") {
            my $cdf_bin_path = abs_path($0);
            print <<"            EOF" =~ s/^ {12}//gmr;
            \@echo off

            setlocal enabledelayedexpansion

            set n_args=0
            for %%_ in (%*) do set /A n_args+=1
            if %n_args% EQU 0 (
                perl $cdf_bin_path
                exit /b !ERRORLEVEL!
            )

            set mode=%1
            if %n_args% EQU 1 (if %mode% EQU -- (
                perl $cdf_bin_path
                exit /b !ERRORLEVEL!
            ))
            if %n_args% GEQ 1 (if %mode:~0,1% EQU - (if %mode% NEQ -- (
                perl $cdf_bin_path %*
                exit /b !ERRORLEVEL!
            )))

            if %mode% EQU -- (
                shift
            )

            set nextpath=""
            for /F "usebackq delims=" %%v in (`perl $cdf_bin_path -g %1`) do set nextpath=%%v
            if "%nextpath%" EQU """" (
                exit /b 1
            )

            for /F "delims=" %%v in ("%nextpath%") do (
                endlocal
                set "__cdfnextpath=%%v"
            )
            cd %__cdfnextpath%
            set __cdfnextpath=
            EOF
        } elsif ($type eq "powershell") {
            my $cdf_bin_path = abs_path($0);
            print <<"            EOF" =~ s/^ {12}//gmr;
            function cdf {
                if (\$args.Length -eq 0) {
                    perl $cdf_bin_path
                    return
                }
                if (\$args.Length -eq 1 -and ([string]\$args[0]) -eq "--") {
                    perl $cdf_bin_path
                    return
                }
                if (\$args.Length -ge 1 -and ([string]\$args[0]).StartsWith("-") -and ([string]\$args[0]) -ne "--") {
                    perl $cdf_bin_path \$args
                    return
                }

                if (\$args[0] -eq "--") {
                    \$args = \$args[1 .. -1]
                }

                \$nextpath = @(perl $cdf_bin_path -g \$args[0])
                if (\$nextpath.Length -ge 1) {
                    cd ([string]\$nextpath)
                }
            }
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
