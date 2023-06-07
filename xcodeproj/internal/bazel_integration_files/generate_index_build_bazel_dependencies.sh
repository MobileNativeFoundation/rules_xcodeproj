#!/bin/bash

set -euo pipefail

cd "$SRCROOT"

readonly config="${BAZEL_CONFIG}_indexbuild"

# Compiled outputs (i.e. swiftmodules) and generated inputs
readonly output_groups=(
  "bc $BAZEL_TARGET_ID"
  "bi $BAZEL_TARGET_ID"
)

readonly targetid_regex='@{0,2}(.*)//(.*):(.*) ([^\ ]+)$'
if [[ "$BAZEL_TARGET_ID" =~ $targetid_regex ]]; then
  repo="${BASH_REMATCH[1]}"
  if [[ "$repo" == "@" ]]; then
    repo=""
  fi

  package="${BASH_REMATCH[2]}"
  target="${BASH_REMATCH[3]}"
  configuration="${BASH_REMATCH[4]}"
  filelist="$configuration/bin/${repo:+"external/$repo/"}$package/$target-bi.filelist"

  indexstores_filelists+=("$filelist")
fi

readonly build_pre_config_flags=(
  "--experimental_remote_download_regex=.*\.indexstore/.*|.*\.a$|.*\.swiftdoc$|.*\.swiftmodule$|.*\.swiftsourceinfo$"
)

source "$BAZEL_INTEGRATION_DIR/bazel_build.sh"

# Import indexes
if [ -n "${indexstores_filelists:-}" ]; then
  "$BAZEL_INTEGRATION_DIR/import_indexstores.sh" \
    "$PROJECT_DIR" \
    "${indexstores_filelists[@]/#/$output_path/}"
fi
