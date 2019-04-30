#!/usr/bin/env bats

readonly cdf=$BATS_TEST_DIRNAME/../cdf
readonly tmpdir=$BATS_TEST_DIRNAME/../tmp
readonly stdout=$BATS_TEST_DIRNAME/../tmp/stdout
readonly stderr=$BATS_TEST_DIRNAME/../tmp/stderr
readonly exitcode=$BATS_TEST_DIRNAME/../tmp/exitcode

setup() {
  if [[ $BATS_TEST_NUMBER == 1 ]]; then
    mkdir -p -- "$tmpdir"
    export PATH=$PATH:$(dirname "$BATS_TEST_DIRNAME")
    export PATH=$(printf "%s\n" "$PATH" | awk '{gsub(":", "\n"); print}' | paste -sd:)
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

@test 'cdf -a: save the path of current direcotry with label if label passed' {
  printf "%s\n" "{\"aaa\":\"one\",\"bbb\":\"two\"}" > "$CDFFILE"

  check "$cdf" -a ccc
  [[ $(cat "$exitcode") == 0 ]]

  check "$cdf" -g ccc
  [[ $(cat "$stdout") == "$PWD" ]]
}

@test 'cdf -a: save the path with label if label and path passed' {
  printf "%s\n" "{\"aaa\":\"one\",\"bbb\":\"two\"}" > "$CDFFILE"

  check "$cdf" -a ccc /usr
  [[ $(cat "$exitcode") == 0 ]]

  check "$cdf" -g ccc
  [[ $(cat "$stdout") == "/usr" ]]
}

@test 'cdf -a: overwrite the path if the label already exists' {
  printf "%s\n" "{\"aaa\":\"one\",\"bbb\":\"two\"}" > "$CDFFILE"

  check "$cdf" -a aaa
  [[ $(cat "$exitcode") == 0 ]]

  check "$cdf" -g aaa
  [[ $(cat "$stdout") == "$PWD" ]]
}

@test 'cdf -a: output error if no arguments passed' {
  check "$cdf" -a
  [[ $(cat "$exitcode") == 2 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -a: output error if CDFFILE doesn'"'"'t exist' {
  check "$cdf" -a
  [[ $(cat "$exitcode") == 2 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -g: print the path so labeld' {
  printf "%s\n" "{\"aaa\":\"one\",\"bbb\":\"two\"}" > "$CDFFILE"

  check "$cdf" -g aaa
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "one" ]]
}

@test 'cdf -g: output error if no arguments passed' {
  check "$cdf" -g
  [[ $(cat "$exitcode") == 2 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -g: output error if the label doesn'"'"'t exist' {
  printf "%s\n" "{\"aaa\":\"one\",\"bbb\":\"two\"}" > "$CDFFILE"

  check "$cdf" -g aaa
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "one" ]]
}

@test 'cdf -g: output error if CDFFILE doesn'"'"'t exist' {
  rm -f -- "$CDFFILE"

  check "$cdf" -g aaa
  [[ $(cat "$exitcode") == 2 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -l: list labels' {
  printf "%s\n" "{\"aaa\":\"one\",\"bbb\":\"two\"}" > "$CDFFILE"

  check "$cdf" -l
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == $'aaa\nbbb' ]]
}

@test 'cdf -l: list labels even if there is no labels' {
  check "$cdf" -l
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") == "" ]]
}

@test 'cdf -l: output error if CDFFILE doesn'"'"'t exist' {
  rm -f -- "$CDFFILE"

  check "$cdf" -l
  [[ $(cat "$exitcode") == 2 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -r: remove labels' {
  printf "%s\n" "{\"aaa\":\"one\",\"bbb\":\"two\",\"ccc\":\"three\"}" > "$CDFFILE"

  check "$cdf" -r aaa bbb
  [[ $(cat "$exitcode") == 0 ]]

  check "$cdf" -g aaa
  [[ $(cat "$exitcode") == 1 ]]

  check "$cdf" -g bbb
  [[ $(cat "$exitcode") == 1 ]]

  check "$cdf" -g ccc
  [[ $(cat "$exitcode") == 0 ]]
}

@test 'cdf -r: remove the label even if the label doesn'"'"'t exist' {
  printf "%s\n" "{\"aaa\":\"one\",\"bbb\":\"two\"}" > "$CDFFILE"

  check "$cdf" -r ccc
  [[ $(cat "$exitcode") == 0 ]]
}

@test 'cdf -r: output error if no arguments passed' {
  check "$cdf" -r
  [[ $(cat "$exitcode") == 2 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -r: output error if CDFFILE doesn'"'"'t exist' {
  rm -f -- "$CDFFILE"

  check "$cdf" -r fn
  [[ $(cat "$exitcode") == 2 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -w: print the wrapper for sh if no arguments passed' {
  check "$cdf" -w
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^'cdf() {' ]]
}

@test 'cdf -w: print the wrapper for the shell if shell name passed' {
  check "$cdf" -w fish
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^'function cdf' ]]
}

@test 'cdf -w: output error if the shell unsupported' {
  check "$cdf" -w vim
  [[ $(cat "$exitcode") == 2 ]]
  [[ $(cat "$stderr") != "" ]]
}

@test 'cdf -h: print usage' {
  check "$cdf" -h
  [[ $(cat "$exitcode") == 0 ]]
  [[ $(cat "$stdout") =~ ^usage ]]
}

# vim: ft=sh
