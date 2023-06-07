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
  printf "%s\n" "{}" > "$CDF_REGISTRY"
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
  check "$cdf"
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") =~ ^usage ]]
}

@test 'cdf: print usage if double dash passed' {
  check "$cdf" --
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") =~ ^usage ]]
}

@test 'cdf: output message to use "cdf -h" if unknown command passed' {
  check "$cdf" --vim
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf: outputs guidance to use "cdf -w" if label passed' {
  check "$cdf" fn
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") =~ ^"cdf: shell integration not enabled" ]]
}

@test 'cdf: outputs guidance to use "cdf -w" if label passed with double dash' {
  check "$cdf" -- fn
  [[ $(cat "$exitcode") == 1 ]]
  [[ $(cat "$stderr") =~ ^'cdf: shell integration not enabled' ]]
}

# vim: ft=bash
