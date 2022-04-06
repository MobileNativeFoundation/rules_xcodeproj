#!/bin/bash

set -euo pipefail

readonly specs=(
%specs%
)
readonly installers=(
%installers%
)

for spec in "${specs[@]}"; do
  # "fixtures/app/xcodeproj_spec.json" -> "//test/fixtures/app/spec.json"
  dir="${BUILD_WORKSPACE_DIRECTORY}/${spec%/*}"
  dest="$dir/spec.json"

  mkdir -p "$dir"
  python3 -m json.tool "$spec" > "$dest"
done

for installer in "${installers[@]}"; do
  "$installer"
done
