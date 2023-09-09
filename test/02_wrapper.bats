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
  CMD=$cmd PATH="$(dirname "$CMD"):$PATH" "$@" > "$stdout" 2> "$stderr" || printf "%s\n" "$?" > "$exitcode"
}

@test 'cdf wapper: support sh' {
  printf "%s\n" '{"version":"3.0","labels":{"usr":"/usr"}}' > "$CDF_REGISTRY"
  check sh -c 'eval "$("$CMD" -w); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf wapper: support bash' {
  printf "%s\n" '{"version":"3.0","labels":{"usr":"/usr"}}' > "$CDF_REGISTRY"
  check bash -c 'eval "$("$CMD" -w bash); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf wapper: support zsh' {
  printf "%s\n" '{"version":"3.0","labels":{"usr":"/usr"}}' > "$CDF_REGISTRY"
  check zsh -c 'eval "$("$CMD" -w zsh); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf wapper: support yash' {
  printf "%s\n" '{"version":"3.0","labels":{"usr":"/usr"}}' > "$CDF_REGISTRY"
  check yash -c 'eval "$("$CMD" -w yash); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf wapper: support fish' {
  printf "%s\n" '{"version":"3.0","labels":{"usr":"/usr"}}' > "$CDF_REGISTRY"
  check fish -c 'source ($CMD -w fish | psub); cdf usr; pwd'
  cat "$stderr"
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

# vim: ft=bash
