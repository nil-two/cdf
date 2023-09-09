#!/usr/bin/env bats

cmd=$BATS_TEST_DIRNAME/../cdf
tmpdir=$BATS_TEST_DIRNAME/../tmp
stdout=$BATS_TEST_DIRNAME/../tmp/stdout
stderr=$BATS_TEST_DIRNAME/../tmp/stderr
exitcode=$BATS_TEST_DIRNAME/../tmp/exitcode

setup() {
  mkdir -p -- "$tmpdir"
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

@test 'cdf: print usage if no arguments passed' {
  check "$cmd"
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") =~ ^usage ]]
}

@test 'cdf: print usage if double-dash passed' {
  check "$cmd" --
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") =~ ^usage ]]
}

@test 'cdf: output guidance to use cdf --help if unknown command passed' {
  check "$cmd" --vim
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf: output guidance to use cdf -w if label passed' {
  check "$cmd" fn
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") =~ ^"cdf: shell integration not enabled" ]]
}

@test 'cdf: output guidance to use cdf -w if label passed with double-dash' {
  check "$cmd" -- fn
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") =~ ^'cdf: shell integration not enabled' ]]
}

# vim: ft=bash
