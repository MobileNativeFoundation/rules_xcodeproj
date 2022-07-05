#!/bin/bash

set -euo pipefail

passthrough_args=("${@:1}")

while test $# -gt 0
do
  case $1 in
  *_dependency_info.dat)
    ld_version=$(ld -v 2>&1 | grep ^@)
    printf "\0%s\0" "$ld_version" > "$1"
    break
    ;;

  -isysroot)
    shift
    # PATH/DEVELOPER_DIR isn't set when this is called, so we need to calculate
    # the developer dir from the sysroot to invoke clang (used below)
    developer_dir="${1/\/Platforms\/*/}"
    ;;

  *.preview-thunk.dylib)
    # Pass through for SwiftUI Preview thunk compilation
    # TODO: Make this work with custom toolchains
    exec "$developer_dir/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang" "${passthrough_args[@]}"
    ;;
  esac
  shift
done
