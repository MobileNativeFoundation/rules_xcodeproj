#!/bin/bash

set -euo pipefail

readonly specs=(
%specs%
)
readonly installers=(
%installers%
)

for spec in "${specs[@]}"; do
  # "example/ios_app/something.json" -> "//test/fixtures/ios_app/spec.json"
  dir="${spec#*/}"
  dir="${BUILD_WORKSPACE_DIRECTORY}/test/fixtures/${dir%/*}"
  dest="$dir/spec.json"

  mkdir -p "$dir"
  python -m json.tool "$spec" > "$dest"
done

for installer in "${installers[@]}"; do
  "$installer"
done
