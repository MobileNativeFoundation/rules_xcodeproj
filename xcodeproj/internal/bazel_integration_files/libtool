#!/bin/bash

set -euo pipefail

original_args=("$@")

while test $# -gt 0
do
  case $1 in
  -V)
    # Xcode 15+ needs to know the version of libtool
    exec libtool "${original_args[@]}"
    ;;
  *_dependency_info.dat)
    printf "\0 \0" > "$1"
    break
    ;;
  esac

  shift
done
