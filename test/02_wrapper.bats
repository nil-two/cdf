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

@test 'cdf supports sh' {
  ! command -v sh > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  CDF="$cdf" check sh -c 'eval "$("$CDF" -w); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf supports bash' {
  ! command -v bash > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  CDF=$cdf check bash -c 'eval "$("$CDF" -w bash); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf supports zsh' {
  ! command -v zsh > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  CDF=$cdf check zsh -c 'eval "$("$CDF" -w zsh); cdf usr; pwd"'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf supports yash' {
  ! command -v yash > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  CDF=$cdf check yash -c 'eval "$("$CDF" -w yash)"; cdf usr; pwd'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf supports fish' {
  ! command -v fish > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  CDF=$cdf check fish -c 'source (eval $CDF -w fish | psub); cdf usr; pwd'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf supports tcsh' {
  ! command -v tcsh > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  CDF=$cdf check tcsh -c 'printf '"'"'unalias cdf\n$CDF -w tcsh | source /dev/stdin\ncdf usr\npwd\n'"'"' | source /dev/stdin'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf supports rc' {
  ! command -v rc > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  CDF=$cdf check rc -c 'ifs='"'"''"'"' eval `{cdf -w rc}; cdf usr; pwd'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf supports nyagos' {
  ! command -v nyagos > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  printf "%s\n" $'lua_e "loadstring(nyagos.eval(""%CDF% -w nyagos""))()"\ncdf usr\npwd' | CDF=$cdf nyagos
  CDF=$cdf check rc -c 'ifs='"'"''"'"' eval `{cdf -w rc}; cdf usr; pwd'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf supports xonsh' {
  ! command -v xonsh > /dev/null && skip
  printf "%s\n" "{\"usr\":\"/usr\"}" > "$CDFFILE"

  CDF=$cdf xonsh -c $'execx($($CDF -w xonsh))\ncdf usr\npwd'
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "/usr" ]]
}

# vim: ft=sh
