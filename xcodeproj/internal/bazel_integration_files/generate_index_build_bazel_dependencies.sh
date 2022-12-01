#!/bin/bash

set -euo pipefail

cd "$SRCROOT"

readonly config="${BAZEL_CONFIG}_indexbuild"

# Compiled outputs (i.e. swiftmodules), and generated inputs
readonly output_groups=(
  "bc $BAZEL_TARGET_ID"
  "bg $BAZEL_TARGET_ID"
)

readonly base_outputs_regex='.*\.a$|.*\.swiftdoc$|.*\.swiftmodule$|.*\.swiftsourceinfo$'

# We don't need to download the indexstore data during Index Build
readonly build_pre_config_flags=(
  "--experimental_remote_download_regex=$base_outputs_regex"
)

source "$BAZEL_INTEGRATION_DIR/bazel_build.sh"
