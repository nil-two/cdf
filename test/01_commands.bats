#!/usr/bin/env bats

cmd=$BATS_TEST_DIRNAME/../cdf
tmpdir=$BATS_TEST_DIRNAME/../tmp
stdout=$BATS_TEST_DIRNAME/../tmp/stdout
stderr=$BATS_TEST_DIRNAME/../tmp/stderr
exitcode=$BATS_TEST_DIRNAME/../tmp/exitcode

setup() {
  mkdir -p -- "$tmpdir"
  export CDF_REGISTRY="$tmpdir/registry.json"
  printf "%s\n" '{"version":"3.0","labels":{}}' > "$CDF_REGISTRY"
}

teardown() {
  rm -rf -- "$tmpdir"
}

check() {
  printf "%s\n" "" > "$stdout"
  printf "%s\n" "" > "$stderr"
  printf "%s\n" "0" > "$exitcode"
  "$@" > "$stdout" 2> "$stderr" || printf "%s\n" "$?" > "$exitcode"
}

@test 'cdf -a: label the working directory if label passed' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -a ccc
  check "$cmd" -p ccc
  [[ $(cat "$stdout") == "$PWD" ]]
}

@test 'cdf -a: label the path if label and path passed' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -a ccc /usr
  check "$cmd" -p ccc
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf -a: overwrite the label if the label already exists' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -a aaa
  check "$cmd" -p aaa
  [[ $(cat "$stdout") == "$PWD" ]]
}

@test 'cdf -a: output error if no arguments passed' {
  check "$cmd" -a
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -a: -a is a shorthand of --add' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" --add ccc
  check "$cmd" -p ccc
  [[ $(cat "$stdout") == "$PWD" ]]
}

@test 'cdf -l: list sorted labels' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","ccc":"three","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -l
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == $'aaa\nbbb\nccc' ]]
}

@test 'cdf -l: list sorted labels even if there are no labels' {
  check "$cmd" -l
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "" ]]
}

@test 'cdf -l: -l is a shorthand of --list' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","ccc":"three","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -l
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == $'aaa\nbbb\nccc' ]]
}

@test 'cdf -L: list sorted labels and paths' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","ccc":"three","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -L
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == $'aaa\tone\nbbb\ttwo\nccc\tthree' ]]
}

@test 'cdf -L: list sorted labels even if there are no labels' {
  check "$cmd" -L
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "" ]]
}

@test 'cdf -L: -L is a shorthand of --list-with-paths' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","ccc":"three","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -L
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == $'aaa\tone\nbbb\ttwo\nccc\tthree' ]]
}

@test 'cdf -p: print the labeled path' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -p aaa
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "one" ]]
}

@test 'cdf -p: output error if no arguments passed' {
  check "$cmd" -p
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -p: output error if the label does not exist' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -p aaa
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "one" ]]
}

@test 'cdf -p: -p is a shorthand of --print' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -p aaa
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "one" ]]
}

@test 'cdf -r: remove labels' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two","ccc":"three"}}' > "$CDF_REGISTRY"
  check "$cmd" -r aaa bbb
  [[ $(cat "$exitcode") == 0 ]]
  check "$cmd" -p aaa
  [[ $(cat "$exitcode") == 1 ]]
  check "$cmd" -p bbb
  [[ $(cat "$exitcode") == 1 ]]
  check "$cmd" -p ccc
  [[ $(cat "$exitcode") == 0 ]]
}

@test 'cdf -r: remove labels even if the label does not exist' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two"}}' > "$CDF_REGISTRY"
  check "$cmd" -r ccc
  [[ $(cat "$exitcode") == 0 ]]
}

@test 'cdf -r: output error if no arguments passed' {
  check "$cmd" -r
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -r: -r is a shorthand of --remove' {
  printf "%s\n" '{"version":"3.0","labels":{"aaa":"one","bbb":"two","ccc":"three"}}' > "$CDF_REGISTRY"
  check "$cmd" -r aaa bbb
  [[ $(cat "$exitcode") == 0 ]]
  check "$cmd" -p aaa
  [[ $(cat "$exitcode") == 1 ]]
  check "$cmd" -p bbb
  [[ $(cat "$exitcode") == 1 ]]
  check "$cmd" -p ccc
  [[ $(cat "$exitcode") == 0 ]]
}

@test 'cdf -w: print the wrapper for sh if no arguments passed' {
  check "$cmd" -w
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^'cdf() {' ]]
}

@test 'cdf -w: print the wrapper for the shell if shell passed' {
  check "$cmd" -w bash
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ '_cdf() {' ]]
}

@test 'cdf -w: output error if the shell is not supported' {
  check "$cmd" -w vim
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -w: -w is a shorthand of --wrapper' {
  check "$cmd" -w
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^'cdf() {' ]]
}

@test 'cdf --help: print usage' {
  check "$cmd" --help
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^usage ]]
}

# vim: ft=bash
