#!/bin/bash

set -euo pipefail

# Set version
echo "5.4.0" > "$BUILD_WORKSPACE_DIRECTORY/.bazelversion"

# Replace/remove Bazel 6 flags
if [[ -f "$BUILD_WORKSPACE_DIRECTORY/shared.bazelrc" ]]; then
  readonly shared_bazelrc="$BUILD_WORKSPACE_DIRECTORY/shared.bazelrc"
else
  readonly shared_bazelrc="$BUILD_WORKSPACE_DIRECTORY/../../shared.bazelrc"
fi

sed -i '' 's/--experimental_remote_build_event_upload=minimal/--incompatible_remote_build_event_upload_respect_no_cache/g' "$shared_bazelrc"
