#!/bin/bash

set -euo pipefail

root="$PWD"

for dir in examples/*/ ; do
    cd "$root/$dir"
    if [[ ! -f "WORKSPACE" || ! -d "test/fixtures" ]]; then
      continue
    fi

    # rules_ios only supports up-to Bazel 7
    if [[ "$dir" == "examples/rules_ios/" ]]; then
      export USE_BAZEL_VERSION="7.x"
    fi

    echo
    echo "Updating \"${dir%/}\" fixtures"
    echo
    bazel run --config=cache //test/fixtures:update
done
