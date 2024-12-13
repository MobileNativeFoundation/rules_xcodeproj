#!/bin/bash

set -euo pipefail

root="$PWD"

for dir in examples/*/ ; do
    cd "$root/$dir"
    if [[ ! -f "WORKSPACE" || ! -d "test/fixtures" ]]; then
      continue
    fi

    if [[ "$dir" == "examples/rules_ios/" ]]; then
      bazel_version="7.4.1"
    else
      # See https://github.com/MobileNativeFoundation/rules_xcodeproj/pull/3029
      #
      # Temporary change to make CI pass until the fix is in `last_green`
      bazel_version="dd2464a5933e0a5a6765024573832717b71989bf"
    fi

    echo
    echo "Updating \"${dir%/}\" fixtures"
    echo
    USE_BAZEL_VERSION="$bazel_version" bazel run --config=cache //test/fixtures:update
done
