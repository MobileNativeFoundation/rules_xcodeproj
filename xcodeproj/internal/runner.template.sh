#!/bin/bash

set -euo pipefail

# Functions

# Echos the provided message to stderr and exits with an error (1)
fail() {
  local msg="${1:-}"
  shift 1
  while (("$#")); do
    msg="${msg:-}"$'\n'"${1}"
    shift 1
  done
  echo >&2 "${msg}"
  exit 1
}

# Process Args

readonly bazelrc="$PWD/%bazelrc%"
readonly extra_flags_bazelrc="$PWD/%extra_flags_bazelrc%"
readonly swiftc_stub="$PWD/%swiftc_stub%"

installer_flags=(
  --bazelrc "$bazelrc"
  --extra_flags_bazelrc "$extra_flags_bazelrc"
  --swiftc_stub "$swiftc_stub"
)

while (("$#")); do
  case "$1" in
    "--build_output_groups")
      build_output_groups="$2"
      shift 2
      ;;
    *)
      installer_flags+=("$1")
      shift
      ;;
  esac
done

cd "$BUILD_WORKSPACE_DIRECTORY"

# Resolve path to bazel before changing the env variable. This allows bazelisk
# downloaded bazel to be found. This won't call `tools/bazel` if it exists,
# which we should find a fix for (e.g. by finding a way to resolve to bazelisk
# instead of the downloaded bazel).
bazel_path=$(which "%bazel_path%")
installer_flags+=(--bazel_path "$bazel_path")

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

xcode_build_version=$(/usr/bin/xcodebuild -version | tail -1 | cut -d " " -f3)
pre_config_flags=(
  # Work around https://github.com/bazelbuild/bazel/issues/8902
  # `USE_CLANG_CL` is only used on Windows, we set it here to cause Bazel to
  # re-evaluate the cc_toolchain for a different Xcode version
  "--repo_env=USE_CLANG_CL=$xcode_build_version"
)

# We do want the `tools/bazel` to run if possible
unset BAZELISK_SKIP_WRAPPER

readonly bazel_cmd=(
  env -i
  HOME="$HOME"
  PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  TERM="$TERM"
  USER="$USER"
  "$bazel_path"
  "${bazelrcs[@]}"
)

# Ensure that our top-level cache buster `override_repository` is valid
mkdir -p /tmp/rules_xcodeproj
touch /tmp/rules_xcodeproj/WORKSPACE
echo 'exports_files(["top_level_cache_buster"])' > /tmp/rules_xcodeproj/BUILD
date +%s > "/tmp/rules_xcodeproj/top_level_cache_buster"

if [[ -z "${build_output_groups:-}" ]]; then
  echo
  echo 'Generating "%project_name%.xcodeproj"'

  "${bazel_cmd[@]}" \
    run \
    "${pre_config_flags[@]}" \
    "--config=%config%_generator" \
    %extra_generator_flags% \
    "%generator_label%" \
    -- "${installer_flags[@]}"
else
  echo "Building \"%generator_label% --output_groups=$build_output_groups\""

  "${bazel_cmd[@]}" \
    build \
    "${pre_config_flags[@]}" \
    "--config=_%config%_build" \
    --output_groups="$build_output_groups" \
    "%generator_label%"
fi
