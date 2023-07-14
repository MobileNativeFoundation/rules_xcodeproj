#!/bin/bash

set -euo pipefail

# Reset tool overrides, so `bazel` sees the correct version. This is needed
# for rules_swift_package_manager to work correctly. We do this here as well as
# in `BazelDependencies` build settings, because we need the overrides at the
# target level, so we can't unset any target build settings, and we don't want
# to do it only in `bazel_build.sh`, because we want pre/post-build scripts to
# get the reset in `BazelDependencies`.
export CC=
export CXX=
export LD=
export LDPLUSPLUS=
export LIBTOOL=libtool
export SWIFT_EXEC=swiftc

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
