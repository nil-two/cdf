#!/usr/bin/env bats

readonly cdf=$BATS_TEST_DIRNAME/../cdf
readonly tmpdir=$BATS_TEST_DIRNAME/../tmp
readonly stdout=$BATS_TEST_DIRNAME/../tmp/stdout
readonly stderr=$BATS_TEST_DIRNAME/../tmp/stderr
readonly exitcode=$BATS_TEST_DIRNAME/../tmp/exitcode

setup() {
  if [[ $BATS_TEST_NUMBER == 1 ]]; then
    mkdir -p -- "$tmpdir"
  fi
  export PATH=$PATH:$(dirname "$BATS_TEST_DIRNAME")
  export PATH=$(printf "%s\n" "$PATH" | awk '{gsub(":", "\n"); print}' | paste -sd:)
  export CDFFILE=$tmpdir/cdf.json
  printf "%s\n" "{}" > "$CDFFILE"
}

teardown() {
  if [[ ${#BATS_TEST_NAMES[@]} == $BATS_TEST_NUMBER ]]; then
    rm -rf -- "$tmpdir"
  fi
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

# vim: ft=sh
