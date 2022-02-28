#!/bin/bash

set -euo pipefail

if ! diff=$(\
  diff <(python -m json.tool "%spec%") \
    <(python -m json.tool "%expected_spec%") \
); then
  echo "Spec doesn't match expected:"
  echo "$diff"
  exit 1
fi

if ! diff=$(diff "%xcodeproj%" "%expected_xcodeproj%"); then
  pwd
  echo "xcodeproj doesn't match expected:"
  echo "$diff"
  exit 1
fi
