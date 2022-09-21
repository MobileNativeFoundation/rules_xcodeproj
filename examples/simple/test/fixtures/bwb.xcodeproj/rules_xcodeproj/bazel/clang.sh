#!/bin/bash

set -euo pipefail

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
