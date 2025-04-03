#!/bin/bash

set -euo pipefail

root="$PWD"

for dir in examples/*/ ; do
    cd "$root/$dir"
    if [[ ! -f "WORKSPACE" || ! -d "test/fixtures" ]]; then
      continue
    fi

    # TODO: rules_ios only builds with up-to Bazel 7
    if [[ "$dir" == "examples/rules_ios/" ]]; then
      overriden_bazel_version="7.4.1"
    fi

    echo
    echo "Updating \"${dir%/}\" fixtures"
    echo
    USE_BAZEL_VERSION="${overriden_bazel_version:-}" bazel run --config=cache //test/fixtures:update
done
