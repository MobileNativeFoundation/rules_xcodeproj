#!/bin/bash

set -euo pipefail

readonly bazelrc="$PWD/%bazelrc%"

cd "$BUILD_WORKSPACE_DIRECTORY"

bazelrcs=(
  --noworkspace_rc
  "--bazelrc=$bazelrc"
)
if [[ -s ".bazelrc" ]]; then
  bazelrcs+=("--bazelrc=.bazelrc")
fi

echo 'Generating "%project_name%.xcodeproj"'

"%bazel_path%" \
  "${bazelrcs[@]}" \
  run \
  --config=rules_xcodeproj_generator \
  "%generator_label%" \
  -- "$@"
