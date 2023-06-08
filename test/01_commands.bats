#!/usr/bin/env bats

readonly cdf=$BATS_TEST_DIRNAME/../cdf
readonly tmpdir=$BATS_TEST_DIRNAME/../tmp
readonly stdout=$BATS_TEST_DIRNAME/../tmp/stdout
readonly stderr=$BATS_TEST_DIRNAME/../tmp/stderr
readonly exitcode=$BATS_TEST_DIRNAME/../tmp/exitcode

setup() {
  mkdir -p -- "$tmpdir"
  export PATH=$(dirname "$BATS_TEST_DIRNAME"):$PATH
  export CDF_REGISTRY=$tmpdir/registry.json
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{}}" > "$CDF_REGISTRY"
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

@test 'cdf -a: label the working direcotry if label passed' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"aaa\":\"one\",\"bbb\":\"two\"}}" > "$CDF_REGISTRY"
  check "$cdf" -a ccc
  check "$cdf" -g ccc
  [[ $(cat "$stdout") == "$PWD" ]]
}

@test 'cdf -a: label the path if label and path passed' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"aaa\":\"one\",\"bbb\":\"two\"}}" > "$CDF_REGISTRY"
  check "$cdf" -a ccc /usr
  check "$cdf" -g ccc
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf -a: overwrite the label if the label already exists' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"aaa\":\"one\",\"bbb\":\"two\"}}" > "$CDF_REGISTRY"
  check "$cdf" -a aaa
  check "$cdf" -g aaa
  [[ $(cat "$stdout") == "$PWD" ]]
}

@test 'cdf -a: output error if no arguments passed' {
  check "$cdf" -a
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -g: print the labeled path' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"aaa\":\"one\",\"bbb\":\"two\"}}" > "$CDF_REGISTRY"
  check "$cdf" -g aaa
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "one" ]]
}

@test 'cdf -g: output error if no arguments passed' {
  check "$cdf" -g
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -g: output error if the label does not exist' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"aaa\":\"one\",\"bbb\":\"two\"}}" > "$CDF_REGISTRY"
  check "$cdf" -g aaa
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "one" ]]
}

@test 'cdf -g: output error if CDF_REGISTRY does not exist' {
  rm -f -- "$CDF_REGISTRY"
  check "$cdf" -g aaa
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -l: list labels' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"aaa\":\"one\",\"bbb\":\"two\"}}" > "$CDF_REGISTRY"
  check "$cdf" -l
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == $'aaa\nbbb' ]]
}

@test 'cdf -l: list labels even if there is no labels' {
  check "$cdf" -l
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "" ]]
}

@test 'cdf -l: output error if CDF_REGISTRY does not exist' {
  rm -f -- "$CDF_REGISTRY"
  check "$cdf" -l
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -r: remove labels' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"aaa\":\"one\",\"bbb\":\"two\",\"ccc\":\"three\"}}" > "$CDF_REGISTRY"
  check "$cdf" -r aaa bbb
  [[ $(cat "$exitcode") == 0 ]]
  check "$cdf" -g aaa
  [[ $(cat "$exitcode") == 1 ]]
  check "$cdf" -g bbb
  [[ $(cat "$exitcode") == 1 ]]
  check "$cdf" -g ccc
  [[ $(cat "$exitcode") == 0 ]]
}

@test 'cdf -r: remove labels even if the label does not exist' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"aaa\":\"one\",\"bbb\":\"two\"}}" > "$CDF_REGISTRY"
  check "$cdf" -r ccc
  [[ $(cat "$exitcode") == 0 ]]
}

@test 'cdf -r: output error if no arguments passed' {
  check "$cdf" -r
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -r: output error if CDF_REGISTRY does not exist' {
  rm -f -- "$CDF_REGISTRY"
  check "$cdf" -r fn
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -w: print the wrapper for sh if no arguments passed' {
  check "$cdf" -w
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^'cdf() {' ]]
}

@test 'cdf -w: print the wrapper for the shell if shell passed' {
  check "$cdf" -w fish
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^'function cdf' ]]
}

@test 'cdf -w: output error if the shell does not supported' {
  check "$cdf" -w vim
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -h: print usage' {
  check "$cdf" -h
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^usage ]]
}

# vim: ft=bash
