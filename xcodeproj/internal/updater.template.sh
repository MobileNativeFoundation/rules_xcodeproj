#!/bin/bash

set -euo pipefail

readonly project_names=(
%project_names%
)
readonly specs=(
%specs%
)
readonly installers=(
%installers%
)

for i in "${!specs[@]}"; do
  # "fixtures/app/xcodeproj_spec.json" -> "//test/fixtures/app/name_spec.json"
  spec="${specs[i]}"
  name="${project_names[i]}"
  dir="$BUILD_WORKSPACE_DIRECTORY/${spec%/*}"
  dest="$dir/${name}_spec.json"

  mkdir -p "$dir"
  python3 -m json.tool "$spec" > "$dest"
done

for installer in "${installers[@]}"; do
  "$installer"
done
