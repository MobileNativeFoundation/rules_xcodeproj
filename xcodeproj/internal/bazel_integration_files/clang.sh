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
    if [[ -n "${TOOLCHAIN_DIR:-}" ]]; then
      # Use the toolchain's clang
      clang="$TOOLCHAIN_DIR/usr/bin/clang"
    else
      # Use default Xcode default toolchain if no toolchain is provided
      DEV_DIR_PREFIX=$(awk '{ sub(/.*-isysroot /, ""); sub(/.Contents\/Developer.*/, ""); print}' <<< "${@:1}")
      clang="$DEV_DIR_PREFIX/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
    fi

    "$clang" "${@:1}"
    break
    ;;
  esac

  shift
done
