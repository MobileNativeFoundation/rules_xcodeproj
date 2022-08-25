#!/bin/bash

set -euo pipefail

readonly bazelrc="$PWD/%bazelrc%"
readonly extra_flags_bazelrc="$PWD/%extra_flags_bazelrc%"

cd "$BUILD_WORKSPACE_DIRECTORY"

bazelrcs=(
  --noworkspace_rc
  "--bazelrc=$bazelrc"
)
if [[ -s ".bazelrc" ]]; then
  bazelrcs+=("--bazelrc=.bazelrc")
fi
if [[ -s "$extra_flags_bazelrc" ]]; then
  bazelrcs+=("--bazelrc=$extra_flags_bazelrc")
fi

echo 'Generating "%project_name%.xcodeproj"'

"%bazel_path%" \
  "${bazelrcs[@]}" \
  run \
  --config=rules_xcodeproj_generator \
  %extra_generator_flags% \
  "%generator_label%" \
  -- "$@" \
  --extra_flags_bazelrc "$extra_flags_bazelrc"
