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

installer_flags=(
  --bazelrc "$bazelrc"
  --extra_flags_bazelrc "$extra_flags_bazelrc"
)

download=1
while (("$#")); do
  case "$1" in
    "--build_output_groups")
      build_output_groups="$2"
      shift 2
      ;;
    "--download")
      # WARNING: You'll need to `bazel clean` if flipping this flag, since Bazel
      # doesn't re-download when `--experimental_remote_download_regex` changes.
      download=1
      shift
      ;;
    "--nodownload")
      # WARNING: You'll need to `bazel clean` if flipping this flag, since Bazel
      # doesn't re-download when `--experimental_remote_download_regex` changes.
      download=0
      shift
      ;;
    *)
      installer_flags+=("$1")
      shift
      ;;
  esac
done

cd "$BUILD_WORKSPACE_DIRECTORY"

# Resolve path to bazel before changing the env variable. This allows bazelisk
# downloaded bazel to be found.
bazel_path=$(which "%bazel_path%")
installer_flags+=(--bazel_path "$bazel_path")

output_base=$("$bazel_path" info output_base)

readonly nested_output_base_prefix="$output_base/execroot/_rules_xcodeproj"
readonly nested_output_base="$nested_output_base_prefix/build_output_base"

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

developer_dir=$(xcode-select -p)
xcode_build_version=$(/usr/bin/xcodebuild -version | tail -1 | cut -d " " -f3)
pre_config_flags=(
  # Set `DEVELOPER_DIR` in case a bazel wrapper filters it
  "--repo_env=DEVELOPER_DIR=$developer_dir"

  # Work around https://github.com/bazelbuild/bazel/issues/8902
  # `USE_CLANG_CL` is only used on Windows, we set it here to cause Bazel to
  # re-evaluate the cc_toolchain for a different Xcode version
  "--repo_env=USE_CLANG_CL=$xcode_build_version"
)

readonly bazel_cmd=(
  env
  PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  "$bazel_path"

  # Restart Bazel server if `DEVELOPER_DIR` changes to clear `developerDirCache`
  "--host_jvm_args=-Xdock:name=$developer_dir"

  "${bazelrcs[@]}"
  --output_base "$nested_output_base"
)

echo

if [[ -z "${build_output_groups:-}" ]]; then
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

  # TODO: Support different build actions (e.g. Index Build, SwiftUI Previews,
  # ASAN, etc.)
  if [[ $download -eq 1 ]]; then
    readonly swift_outputs_regex='.*\.swiftdoc$|.*\.swiftmodule$|.*\.swiftsourceinfo$'
    readonly indexstores_regex='.*\.indexstore/.*'
    pre_config_flags+=(
      "--experimental_remote_download_regex=$indexstores_regex|$swift_outputs_regex"
    )
  fi

  "${bazel_cmd[@]}" \
    build \
    "${pre_config_flags[@]}" \
    "--config=_%config%_build" \
    --output_groups="$build_output_groups" \
    "%generator_label%"
fi
