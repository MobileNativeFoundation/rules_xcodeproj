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

readonly xcodeproj_bazelrc="$PWD/%xcodeproj_bazelrc%"
readonly extra_flags_bazelrc="$PWD/%extra_flags_bazelrc%"

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
bazel_path=$(which "%bazel_path%")
installer_flags+=(--bazel_path "$bazel_path")

if [[ %is_fixture% -eq 1 && %is_bazel_6% -eq 1 ]]; then
  execution_root=$("$bazel_path" info --noexperimental_enable_bzlmod execution_root)
else
  execution_root=$("$bazel_path" info execution_root)
fi
installer_flags+=(--execution_root "$execution_root")

readonly output_base="${execution_root%/*/*}"
readonly nested_output_base="$output_base/rules_xcodeproj/build_output_base"

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
xcode_build_version=$(/usr/bin/xcodebuild -version | tail -1 | cut -d " " -f3)
pre_config_flags=(
  # Set `DEVELOPER_DIR` in case a bazel wrapper filters it
  "--repo_env=DEVELOPER_DIR=$developer_dir"

  # Work around https://github.com/bazelbuild/bazel/issues/8902
  # `USE_CLANG_CL` is only used on Windows, we set it here to cause Bazel to
  # re-evaluate the cc_toolchain for a different Xcode version
  "--repo_env=USE_CLANG_CL=$xcode_build_version"
)

if [[ %is_fixture% -eq 1 && %is_bazel_6% -eq 1 ]]; then
  pre_config_flags+=(
    # Until we stop testing Bazel 5, we want the strings to format the same
    "--incompatible_unambiguous_label_stringification=false"

    # bzlmod adjust labels in a way that we can't account for yet
    "--noexperimental_enable_bzlmod"
  )
fi

readonly bazel_cmd=(
  env
  PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  "$bazel_path"

  # Restart Bazel server if `DEVELOPER_DIR` changes to clear `developerDirCache`
  "--host_jvm_args=-Xdock:name=$developer_dir"

  "${bazelrcs[@]}"
  --output_base "$nested_output_base"
)

echo >&2

if [[ $original_arg_count -eq 0 ]]; then
  echo 'Generating "%project_name%.xcodeproj"' >&2

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

  while IFS='' read -r arg; do cmd_args+=("$arg"); done < <(xargs -n1 <<< "$1")
  cmd="${cmd_args[0]}"

  post_config_flags=("${cmd_args[@]:1}")
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
