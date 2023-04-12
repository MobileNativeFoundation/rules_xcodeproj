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

readonly execution_root_file="$PWD/%execution_root_file%"
readonly extra_flags_bazelrc="$PWD/%extra_flags_bazelrc%"
readonly generator_build_file="$PWD/%generator_build_file%"
readonly generator_defs_bzl="$PWD/%generator_defs_bzl%"
readonly schemes_json="$PWD/%schemes_json%"
readonly xcodeproj_bazelrc="$PWD/%xcodeproj_bazelrc%"

installer_flags=(
  --xcodeproj_bazelrc "$xcodeproj_bazelrc"
  --extra_flags_bazelrc "$extra_flags_bazelrc"
)

config="build"
original_arg_count=$#
verbose=0
while (("$#")); do
  case "$1" in
    --build_output_groups)
      fail "ERROR: $1 is no longer supported, use" \
      "\`%bazel_path% run %runner_label% -- --generator_output_groups='$2' build\` instead"
      ;;
    --generator_output_groups=*)
      generator_output_groups="${1#*=}"
      shift 1
      ;;
    --config=*)
      config="${1#*=}"
      shift 1
      ;;
    --collect_specs=*)
      specs_archive_path="${1#*=}"
      shift 1
      ;;
    -v|--verbose)
      verbose=1
      shift 1
      ;;
    -*)
      fail "ERROR: Unrecognized pre-command argument: '$1'" \
        "Note: startup options aren't supported"
      ;;
    *)
      break
      ;;
  esac
done

if [[ -n "${specs_archive_path:-}" ]]; then
  installer_flags+=(--collect_specs "$specs_archive_path")
  original_arg_count=0
fi

if [[ $original_arg_count -gt 0 ]]; then
  if [[ $# -eq 0 ]]; then
    fail "ERROR: A bazel command must be provided (e.g. build, clean, etc.)"
  elif [[ $# -gt 1 ]]; then
    fail "ERROR: The bazel command must be a string instead of individual arguments"
  fi
fi

cd "$BUILD_WORKSPACE_DIRECTORY"

# Resolve path to bazel before changing the env variable. This allows bazelisk
# downloaded bazel to be found.
bazel_path=$(which "%bazel_path%" || true)

if [[ -z "$bazel_path" ]]; then
  echo "Failed to find \"%bazel_path%\" in \$PATH (\"$PATH\")." \
    "Please make sure the 'bazel' attribute on %runner_label% is correct, or" \
    "if you are filtering \$PATH in a bazel wrapper, that \$PATH includes" \
    "where \"%bazel_path%\" (maybe as bazlisk) is installed." >&2
  exit 1
fi

installer_flags+=(--bazel_path "$bazel_path")

execution_root=$(<"$execution_root_file")
installer_flags+=(--execution_root "$execution_root")

readonly output_base="${execution_root%/*/*}"
readonly nested_output_base="$output_base/rules_xcodeproj.noindex/build_output_base"

# Set bazel env
%collect_bazel_env%

# Create files for the generator target
output_base_hash=$(/sbin/md5 -q -s "$output_base")
readonly generator_package_directory="/tmp/rules_xcodeproj/generated_v2/$output_base_hash/%generator_package_name%"

mkdir -p "$generator_package_directory"
cp "$generator_build_file" "$generator_package_directory/BUILD"
chmod u+w "$generator_package_directory/BUILD"
cp "$generator_defs_bzl" "$generator_package_directory/defs.bzl"
chmod u+w "$generator_package_directory/defs.bzl"
cp "$schemes_json" "$generator_package_directory/custom_xcode_schemes.json"
chmod u+w "$generator_package_directory/custom_xcode_schemes.json"

cat >> "$generator_package_directory/defs.bzl" <<EOF

# Constants

BAZEL_ENV = $def_env
BAZEL_PATH = "$bazel_path"
WORKSPACE_DIRECTORY = "$BUILD_WORKSPACE_DIRECTORY"
EOF

bazelrcs=(
  --noworkspace_rc
  "--bazelrc=$xcodeproj_bazelrc"
)
if [[ -s ".bazelrc" ]]; then
  bazelrcs+=("--bazelrc=.bazelrc")
fi
if [[ -s "$extra_flags_bazelrc" ]]; then
  bazelrcs+=("--bazelrc=$extra_flags_bazelrc")
fi

developer_dir=$(xcode-select -p)
pre_config_flags=(
  # Be explicit about our desired Xcode version
  "--xcode_version=%xcode_version%"

  # Set `DEVELOPER_DIR` in case a bazel wrapper filters it
  "--repo_env=DEVELOPER_DIR=$developer_dir"

  # Work around https://github.com/bazelbuild/bazel/issues/8902
  # `USE_CLANG_CL` is only used on Windows, we set it here to cause Bazel to
  # re-evaluate the cc_toolchain for a different Xcode version
  "--repo_env=USE_CLANG_CL=%xcode_version%"
)

if [[ %is_fixture% -eq 1 ]]; then
  pre_config_flags+=("--config=fixtures")
fi

readonly bazel_cmd=(
  env
  "${envs[@]}"
  "$bazel_path"

  # Restart Bazel server if `DEVELOPER_DIR` changes to clear `developerDirCache`
  "--host_jvm_args=-Xdock:name=$developer_dir"

  "${bazelrcs[@]}"
  --output_base "$nested_output_base"
)

echo >&2

if [[ $original_arg_count -eq 0 ]]; then
  echo 'Generating "%install_path%"' >&2

  "${bazel_cmd[@]}" \
    run \
    "${pre_config_flags[@]}" \
    "--config=%config%_generator" \
    %extra_generator_flags% \
    "%generator_label%" \
    -- "${installer_flags[@]}"
else
  if [[ $config == "build" ]]; then
    bazel_config="_%config%_build"
  else
    bazel_config="%config%_$config"
  fi

  while IFS='' read -r arg; do cmd_args+=("${arg//\$_GENERATOR_LABEL_/%generator_label%}"); done < <(xargs -n1 <<< "$1")
  cmd="${cmd_args[0]}"

  if [[ $cmd == "build" && -n "${generator_output_groups:-}" ]]; then
    # `--experimental_remote_download_regex`
    readonly base_outputs_regex='.*\.a$|.*\.swiftdoc$|.*\.swiftmodule$|.*\.swiftsourceinfo$'

    if [[ "$config" == "indexbuild" ]]; then
      readonly remote_download_regex="$base_outputs_regex"
    else
      readonly indexstores_regex='.*\.indexstore/.*'
      readonly remote_download_regex="$indexstores_regex|$base_outputs_regex"
    fi

    pre_config_flags+=(
      "--experimental_remote_download_regex=$remote_download_regex"
    )

    # `--output_groups`
    post_config_flags=(
      --output_groups="$generator_output_groups"
      "${cmd_args[@]:1}"
      "%generator_label%"
    )
  else
    post_config_flags=("${cmd_args[@]:1}")
  fi

  if [[ $verbose -eq 1 ]]; then
    echo "Running Bazel command:" >&2
    set -x
  fi

  "${bazel_cmd[@]}" \
    "$cmd" \
    "${pre_config_flags[@]}" \
    "--config=$bazel_config" \
    ${post_config_flags:+"${post_config_flags[@]}"}
fi
