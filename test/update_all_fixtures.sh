#!/bin/bash

set -euo pipefail

root="$PWD"

for dir in examples/*/ ; do
    cd "$root/$dir"
    if [[ ! -f "WORKSPACE" || ! -d "test/fixtures" ]]; then
      continue
    fi

    if [[ "$dir" == "examples/rules_ios/" ]]; then
      bazel_version="7.1.1"
    else
      bazel_version="last_green"
    fi

    echo
    echo "Updating \"${dir%/}\" fixtures"
    echo
    USE_BAZEL_VERSION="$bazel_version" bazel run --config=cache //test/fixtures:update
done
