#!/bin/bash

set -euo pipefail

# find the first argument that has a _dependency_info.dat extension
for arg in "$@"; do
  if [[ "$arg" == *_dependency_info.dat ]]; then
    ld_version=$(ld -v 2>&1 | grep ^@)
    printf "\0%s\0" "$ld_version" > "$arg"
  fi
done

while test $# -gt 0
do
  case $1 in
  -MF)
    shift
    touch "$1"
    ;;
  --serialize-diagnostics)
    shift
    cp "${BASH_SOURCE%/*}/cc.dia" "$1"
    ;;
  *.o)
    break
    ;;
  -v)
    # TODO: Make this work with custom toolchains
    DEV_DIR_PREFIX=$(awk '{ sub(/.*-isysroot /, ""); sub(/.Contents\/Developer.*/, ""); print}' <<< "${@:1}")
    clang="$DEV_DIR_PREFIX/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
    "$clang" "${@:1}"
    break
    ;;
  esac

  shift
done
