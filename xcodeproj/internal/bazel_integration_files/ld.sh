#!/bin/bash

set -euo pipefail

while test $# -gt 0
do
  case $1 in
  *_dependency_info.dat)
    ld_version=$(ld -v 2>&1 | grep ^@)
    printf "\0%s\0" "$ld_version" > "$1"
    break
    ;;
  esac

  shift
done
