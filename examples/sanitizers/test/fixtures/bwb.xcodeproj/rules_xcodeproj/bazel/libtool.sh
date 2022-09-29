#!/bin/bash

set -euo pipefail

while test $# -gt 0
do
  case $1 in
  *_dependency_info.dat)
    printf "\0 \0" > "$1"
    break
    ;;
  esac

  shift
done
