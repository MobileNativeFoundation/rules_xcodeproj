#!/bin/bash

set -euo pipefail

if ! diff=$(\
  diff <(python -m json.tool --sort-keys "%spec%") \
    <(python -m json.tool --sort-keys "%expected_spec%") \
); then
  echo "Spec doesn't match expected:"
  echo "$diff"
  echo
  echo 'Run `bazel run //test/fixtures:update` if you wish to accept these '\
'changes.'
  exit 1
fi

if ! diff=$(diff "%xcodeproj%" "%expected_xcodeproj%"); then
  pwd
  echo "xcodeproj doesn't match expected:"
  echo "$diff"
  echo
  echo 'Run `bazel run //test/fixtures:update` if you wish to accept these '\
'changes.'
  exit 1
fi
