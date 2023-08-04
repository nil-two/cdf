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

@test 'cdf wapper: support sh' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"usr\":\"/usr\"}}" > "$CDF_REGISTRY"
  CDF=$cdf check sh -c 'eval "$("$CDF" -w); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf wapper: support bash' {
  printf "%s\n" "{\"version\":\"3.0\",\"labels\":{\"usr\":\"/usr\"}}" > "$CDF_REGISTRY"
  CDF=$cdf check bash -c 'eval "$("$CDF" -w bash); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

# vim: ft=bash
