#!/bin/bash

set -euo pipefail

while test $# -gt 0
do
  case $1 in
  *_dependency_info.dat)
    libtool_version=$(libtool -V | cut -d " " -f4)
    printf "\0%s\0" "$libtool_version" > "$1"
    break
    ;;
  esac

  shift
done
