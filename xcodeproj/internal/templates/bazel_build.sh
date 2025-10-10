# It is assumed that this file is `source`ed from another script, with the following variable set:
#
# - BAZEL_CONFIG
# - BAZEL_INTEGRATION_DIR
# - BAZEL_OUT
# - DEVELOPER_DIR
# - GENERATOR_LABEL
# - HOME
# - INTERNAL_DIR
# - OBJROOT
# - RULES_XCODEPROJ_BUILD_MODE
# - SRCROOT
# - TERM
# - USER
# - XCODE_PRODUCT_BUILD_VERSION
# - (optional) build_pre_config_flags
# - config
# - (optional) labels
# - output_groups
# - (optional) target_ids

output_groups_flag="--output_groups=$(IFS=, ; echo "${output_groups[*]}")"
readonly output_groups_flag

# Set `output_base`

# In `runner.sh` the generator has the build output base set inside of the outer
# bazel's output path (`bazel-out/`). So here we need to make our output base
# changes relative to that changed path.
readonly output_base="$BAZEL_OUTPUT_BASE"

# Set `bazel_cmd` for calling `bazel`

bazelrcs=(
  --noworkspace_rc
  "--bazelrc=$BAZEL_INTEGRATION_DIR/xcodeproj.bazelrc"
)
if [[ -s ".bazelrc" ]]; then
  bazelrcs+=("--bazelrc=.bazelrc")
fi
if [[ -s "$BAZEL_INTEGRATION_DIR/xcodeproj_extra_flags.bazelrc" ]]; then
  bazelrcs+=("--bazelrc=$BAZEL_INTEGRATION_DIR/xcodeproj_extra_flags.bazelrc")
fi
readonly bazelrcs

readonly allowed_vars=(
  "BUILD_WORKSPACE_DIRECTORY"
  "DEVELOPER_DIR"
  "HOME"
  "SSH_AUTH_SOCK"
  "TERM"
  "USER"
)
passthrough_env=()
for var in "${allowed_vars[@]}"; do
  if [[ -n "${!var:-}" ]]; then
    passthrough_env+=("$var=${!var}")
  fi
done

bazel_cmd=(
  env -i
  "${passthrough_env[@]}"
%bazel_env%
  "%bazel_path%"

  # Restart bazel server if `DEVELOPER_DIR` changes to clear `developerDirCache`
  "--host_jvm_args=-Xdock:name=$DEVELOPER_DIR"

  "${bazelrcs[@]}"

  --output_base "$output_base"
)
if [ "$ACTION" == "indexbuild" ]; then
  # Allow normal builds to cancel Index Builds
  bazel_cmd+=("--preemptible")
fi
readonly bazel_cmd

readonly base_pre_config_flags=(
  # Be explicit about our desired Xcode version
  "--xcode_version=$DEVELOPER_DIR"

  # Set `DEVELOPER_DIR` in case a bazel wrapper filters it
  "--repo_env=DEVELOPER_DIR=$DEVELOPER_DIR"

  # Work around https://github.com/bazelbuild/bazel/issues/8902
  # `USE_CLANG_CL` is only used on Windows, we set it here to cause Bazel to
  # re-evaluate the cc_toolchain for a different Xcode version
  "--repo_env=USE_CLANG_CL=$XCODE_PRODUCT_BUILD_VERSION"
  "--repo_env=XCODE_VERSION=$XCODE_PRODUCT_BUILD_VERSION"

  # Don't block the end of the build for BES upload (artifacts OR events)
  "--bes_upload_mode=NOWAIT_FOR_UPLOAD_COMPLETE"
)

# Custom Swift toolchains

if [[ -n "${TOOLCHAINS-}" ]]; then
  # We remove all Metal toolchains from the list first
  toolchains_array=($TOOLCHAINS)
  filtered_toolchains=()
  for tc in "${toolchains_array[@]}"; do
    if [[ "$tc" != "com.apple.dt.toolchain.Metal"* ]]; then
      filtered_toolchains+=("$tc")
    fi
  done

  if [[ ${#filtered_toolchains[@]} -gt 0 ]]; then
    toolchain="${filtered_toolchains[0]}"
    if [[ "$toolchain" == "com.apple.dt.toolchain.XcodeDefault" ]]; then
      unset toolchain
    fi
  fi
fi

# Build

echo "Starting Bazel build"

"$BAZEL_INTEGRATION_DIR/process_bazel_build_log.py" \
  "${bazel_cmd[@]}" \
  build \
  "${base_pre_config_flags[@]}" \
  ${build_pre_config_flags:+"${build_pre_config_flags[@]}"} \
  --config="$config" \
  --color=yes \
  ${toolchain:+--action_env=TOOLCHAINS="$toolchain"} \
  "$output_groups_flag" \
  "%generator_label%" \
  ${labels:+"--build_metadata=PATTERN=${labels[*]}"} \
  2>&1

# Verify that we actually built what we requested

if [[ -n "${target_ids:-}" ]]; then
  if [[ ! -s "%target_ids_list%" ]]; then
      echo "error: \"%target_ids_list%\" was not created. This can happen if" \
"you apply build-affecting flags to \"rules_xcodeproj_generator\" config, or" \
"with the \"--@rules_xcodeproj//xcodeproj:extra_generator_flags\" flag." \
"Please ensure that all build-affecting flags are moved to the" \
"\"rules_xcodeproj\" config or" \
"\"--@rules_xcodeproj//xcodeproj:extra_common_flags\" flag. If you are still" \
"getting this error after adjusting your setup and regenerating your project," \
"please file a bug report here:" \
"https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md" \
        >&2
      exit 1
  fi

  # We need to sort the inputs for `comm` to work on macOS 15.4+
  diff_output=$(
    comm -23 \
      <(printf '%s\n' "${target_ids[@]}" | sort) \
      <(sort "%target_ids_list%")
  )

  if [ -n "$diff_output" ]; then
      missing_target_ids=("${diff_output[@]}")
      echo "error: There were some target IDs that weren't known to Bazel" \
"(e.g. \"${missing_target_ids[0]}\"). Please regenerate the project to fix" \
"this. If you are still getting this error after regenerating your project," \
"please file a bug report here:" \
"https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md" \
        >&2
      exit 1
  fi
fi
