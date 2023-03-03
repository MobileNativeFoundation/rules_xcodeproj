#!/bin/bash

set -euo pipefail

root="$PWD"

echo "Updating root fixtures"
echo

bazel run --config=cache --config=fixtures //test/fixtures:update

for dir in examples/*/ ; do
    cd "$root/$dir"
    if [[ ! -f "WORKSPACE" ]]; then
      continue
    fi

    echo
    echo "Updating \"${dir%/}\" fixtures"
    echo
    bazel run --config=cache --config=fixtures //test/fixtures:update
done
