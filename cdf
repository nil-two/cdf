#!/usr/bin/env perl
use strict;
use warnings;
use autouse "Cwd" => qw(abs_path getcwd);
use autouse "Encode" => qw(decode_utf8);
use autouse "File::Basename" => qw(dirname);
use autouse "File::Path" => qw(make_path);
use autouse "JSON::PP" => qw(encode_json decode_json);

my $CDF_REGISTRY = $ENV{CDF_REGISTRY} // "$ENV{HOME}/.config/cdf/registry.json";

my $registry_version = "3.0";
my $registry_default = {
    version => $registry_version,
    labels => {},
};

my $cmd_name = $0 =~ s/.*\///r;
my $cmd_usage = <<EOF;
usage:
  $cmd_name [--]                         # select a label and chdir to the labeled path
  $cmd_name [--] <label>                 # chdir to the labeled path
  $cmd_name {-a|--add} <label> [<path>]  # label the path (default: working directory)
  $cmd_name {-l|--list}                  # list labels
  $cmd_name {-L|--list-with-paths}       # list labels with paths
  $cmd_name {-p|--print} <label>         # print the labeled path
  $cmd_name {-r|--remove} <label(s)>     # remove labels
  $cmd_name {-w|--wrapper} [<shell>]     # output the wrapper script (default: sh)
  $cmd_name --help                       # print usage

supported-shells:
  sh, bash, zsh

environment-variables:
  CDF_REGISTRY  the registry path (default: ~/.config/cdf/registry.json)
  CDF_FILTER    the interactive filtering command for selecting a label
EOF
my $cmd_guide_to_enable_shell_integration = <<EOF;
$cmd_name: shell integration not enabled
Please add the following config to your shell's profile.

eval "\$($cmd_name -w)"

EOF

my $wrapper_script_for_sh = <<'EOF';
cdf() {
  if [ $# -ge 1 ] && [ "$1" != "${1#-}" ] && [ "$1" != "--" ]; then
    command -- cdf "$@"
    return
  fi

  if [ "$1" = "--" ]; then
    shift
  fi

  if [ $# -eq 0 ]; then
    if [ -z "${CDF_FILTER:-percol}" ]; then
      echo "cdf: CDF_FILTER is not set" >&2
      return 1
    fi
    set -- "$(command -- cdf --list | sh -c "${CDF_FILTER:-percol}")"
    if [ -n "$1" ]; then
      set -- "$(command -- cdf --print "$1")"
      if [ -n "$1" ]; then
        cd "$1" || return
      fi
    fi
  else
    set -- "$(command -- cdf --print "$1")"
    if [ -n "$1" ]; then
      cd "$1" || return
    fi
  fi
}
EOF
my $wrapper_script_for_bash = $wrapper_script_for_sh . <<'EOF';

_cdf() {
  local cur prev words cword split
  _init_completion || return

  local defaultIFS=$' \t\n'
  local IFS=$defaultIFS

  local modes=(
    --add
    --list
    --list-with-paths
    --print
    --remove
    --wrapper
    --help
  )
  local wrapper_target_shells=(
    sh
    bash
    zsh
  )

  case $COMP_CWORD in
    1)
      case $cur in
        -*)
          COMPREPLY=( $(compgen -W '"${modes[@]}"' -- "$cur") )
          ;;
        *)
          IFS=$'\n'; COMPREPLY=( $(compgen -W '$(cdf --list)' -- "$cur") ); IFS=$defaultIFS
          ;;
      esac
      ;;
    *)
      case ${COMP_WORDS[1]} in
        --)
          IFS=$'\n'; COMPREPLY=( $(compgen -W '$(cdf --list)' -- "$cur") ); IFS=$defaultIFS
          ;;
        -a|--add)
          case $COMP_CWORD in
            2)
              IFS=$'\n'; COMPREPLY=( $(compgen -W '$(cdf --list)' -- "$cur") ); IFS=$defaultIFS
              ;;
            *)
              _filedir -d
              ;;
          esac
          ;;
        -p|--print)
          IFS=$'\n'; COMPREPLY=( $(compgen -W '$(cdf --list)' -- "$cur") ); IFS=$defaultIFS
          ;;
        -r|--remove)
          IFS=$'\n'; COMPREPLY=( $(compgen -W '$(cdf --list)' -- "$cur") ); IFS=$defaultIFS
          ;;
        -w|--wrapper)
          COMPREPLY=( $(compgen -W '"${wrapper_target_shells[@]}"' -- "$cur") )
          ;;
      esac
      ;;
  esac
}

complete -F _cdf cdf
EOF
my $wrapper_script_for_zsh = $wrapper_script_for_sh . <<'EOF';

_cdf() {
  local labels
  local modes=(
    --"[chdir to the labeled path]"
    {-a,--add}"[label the path (default: working directory)]"
    {-l,--list}"[list labels]"
    {-L,--list-with-paths}"[list labels with paths]"
    {-p,--print}"[print the labeled path]"
    {-r,--remove}"[remove labels]"
    {-w,--wrapper}"[output the wrapper script (default: sh)]"
    --help"[print usage]"
  )
  local wrapper_target_shells=(
    sh
    bash
    zsh
  )

  case $CURRENT in
    2)
      case ${words[$CURRENT]} in
        -*)
          _values "modes" $modes
          ;;
        *)
          labels=( ${(f)"$(cdf --list-with-paths | awk '{gsub("\t", "["); gsub("$", "]"); print}')"} )
          _values "label" $labels
          ;;
      esac
      ;;
    *)
      case ${words[2]} in
        --)
          labels=( ${(f)"$(cdf --list-with-paths | awk '{gsub("\t", "["); gsub("$", "]"); print}')"} )
          _values "label" $labels
          ;;
        -a|--add)
          case $CURRENT in
            3)
              labels=( ${(f)"$(cdf --list-with-paths | awk '{gsub("\t", "["); gsub("$", "]"); print}')"} )
              _values "label" $labels
              ;;
            *)
              _path_files -/
              ;;
          esac
          ;;
        -l|--list)
          ;;
        -l|--list-with-paths)
          ;;
        -p|--print)
          labels=( ${(f)"$(cdf --list-with-paths | awk '{gsub("\t", "["); gsub("$", "]"); print}')"} )
          _values "label" $labels
          ;;
        -r|--remove)
          labels=( ${(f)"$(cdf --list-with-paths | awk '{gsub("\t", "["); gsub("$", "]"); print}')"} )
          _values "label" $labels
          ;;
        -w|--wrapper)
          _values "shell" $wrapper_target_shells
          ;;
        --help)
          ;;
      esac
      ;;
  esac
}

compdef _cdf cdf
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

sub load_registry {
    if (-f $CDF_REGISTRY) {
        return decode_json(read_file($CDF_REGISTRY));
    } else {
        return $registry_default;
    }
}

sub save_registry {
    my ($registry) = @_;
    make_path(dirname($CDF_REGISTRY));
    write_file($CDF_REGISTRY, "@{[encode_json($registry)]}\n");
}

sub do_add {
    if (@ARGV < 1) {
        print STDERR "$cmd_name: add: no input label\n";
        return 1;
    }

    my $label = $ARGV[0];
    my $path  = $ARGV[1] // getcwd();

    my $registry = load_registry();

    $registry->{labels}{$label} = abs_path($path);

    save_registry($registry);

    return 0;
}

sub do_list {
    my $registry = load_registry();

    for my $label (sort { $a cmp $b } keys %{$registry->{labels}}) {
        print "$label\n";
    }

    return 0;
}

sub do_list_with_labels {
    my $registry = load_registry();

    for my $label (sort { $a cmp $b } keys %{$registry->{labels}}) {
        printf "%s\t%s\n", $label, $registry->{labels}{$label};
    }

    return 0;
}

sub do_print {
    if (@ARGV < 1) {
        print STDERR "$cmd_name: print: no input label\n";
        return 1;
    }

    my $label = $ARGV[0];

    my $registry = load_registry();
    if (!exists($registry->{labels}{$label})) {
        print STDERR "$cmd_name: print: label not found -- '$label'\n";
        return 1;
    }

    print "$registry->{labels}{$label}\n";

    return 0;
}

sub do_remove {
    if (@ARGV < 1) {
        print STDERR "$cmd_name: remove: no input labels\n";
        return 1;
    }

    my $labels = [@ARGV];

    my $registry = load_registry();

    for my $label (@$labels) {
        delete $registry->{labels}{$label};
    }

    save_registry($registry);

    return 0;
}

sub do_wrapper {
    my $shell = $ARGV[0] // "sh";

    if ($shell eq "sh") {
        print $wrapper_script_for_sh;
        return 0;
    } elsif ($shell eq "bash") {
        print $wrapper_script_for_bash;
        return 0;
    } elsif ($shell eq "zsh") {
        print $wrapper_script_for_zsh;
        return 0;
    } else {
        print STDERR "$cmd_name: wrapper: unsupported shell -- '$shell'\n";
        return 1;
    }
}

sub do_help {
    my ($args) = @_;

    print $cmd_usage;

    return 0;
}

sub main {
    foreach (@ARGV) {
        $_ = decode_utf8($_);
    }
    if ((@ARGV == 0) || (@ARGV == 1 && $ARGV[0] eq "--")) {
        print STDERR $cmd_usage;
        exit 1;
    }
    if ((@ARGV >= 1 && $ARGV[0] =~ /^[^-]/) || (@ARGV >= 2 && $ARGV[0] eq "--")) {
        print STDERR $cmd_guide_to_enable_shell_integration;
        exit 1;
    }

    my $mode = shift @ARGV;
    if ($mode eq "-a" || $mode eq "--add") {
        exit do_add;
    } elsif ($mode eq "-l" || $mode eq "--list") {
        exit do_list;
    } elsif ($mode eq "-L" || $mode eq "--list-with-paths") {
        exit do_list_with_labels;
    } elsif ($mode eq "-p" || $mode eq "--print") {
        exit do_print;
    } elsif ($mode eq "-r" || $mode eq "--remove") {
        exit do_remove;
    } elsif ($mode eq "-w" || $mode eq "--wrapper") {
        exit do_wrapper;
    } elsif ($mode eq "--help") {
        exit do_help;
    } else {
        print STDERR "$cmd_name: unrecognized mode -- '$mode'\n";
        print STDERR "Try '$cmd_name --help' for more information.\n";
        exit 1;
    }
}

main;
