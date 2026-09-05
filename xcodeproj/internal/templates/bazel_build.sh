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
readonly build_output_base="$BAZEL_OUTPUT_BASE"

if [[
  "$ACTION" == "indexbuild" &&
  "${BAZEL_SEPARATE_INDEXBUILD_OUTPUT_BASE:-}" == "YES"
]]; then
  # We use a different output base for Index Build to prevent normal builds and
  # indexing waiting on bazel locks from the other. We nest it inside of the
  # normal output base directory so that it's not cleaned up when running
  # `bazel clean`, but is when running `bazel clean --expunge`. This matches
  # Xcode behavior of not cleaning the Index Build outputs by default.
  readonly output_base="${build_output_base%/*}/indexbuild_output_base"
  readonly workspace_name="${PROJECT_DIR##*/}"
  readonly output_path="$output_base/execroot/$workspace_name/bazel-out"

  # Use current path for "bazel-out/" and "external/"
  # This fixes Index Build to use its version of generated and external files
  readonly vfs_overlay_roots="{\"external-contents\": \"$output_path\",\"name\": \"$BAZEL_OUT\",\"type\": \"directory-remap\"},{\"external-contents\": \"$output_base/external\",\"name\": \"$BAZEL_EXTERNAL\",\"type\": \"directory-remap\"}"
else
  readonly output_base="$build_output_base"
  readonly output_path="$BAZEL_OUT"
  readonly vfs_overlay_roots=""
fi

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
  "HTTP_PROXY"
  "http_proxy"
  "HTTPS_PROXY"
  "https_proxy"
  "NO_PROXY"
  "no_proxy"
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

readonly build_proxy_bazel_real="${BAZEL_REAL:-}"
source "$BAZEL_INTEGRATION_DIR/bazel_env.sh"
if [[ -n "${SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR:-}" ]]; then
  build_proxy_envs=()
  for item in "${envs[@]}"; do
    [[ "$item" != BUILD_WORKSPACE_DIRECTORY=* ]] || continue
    if [[ -n "$build_proxy_bazel_real" && "$item" == BAZEL_REAL=* ]]; then
      continue
    fi
    build_proxy_envs+=("$item")
  done
  envs=("${build_proxy_envs[@]}")
  if [[ -n "$build_proxy_bazel_real" ]]; then
    envs+=("BAZEL_REAL=$build_proxy_bazel_real")
  fi
  # Workspace wrappers use this standard Bazel marker to distinguish an Xcode inner invocation
  # from a developer asking the wrapper to regenerate its outer rules release.
  envs+=("BUILD_WORKSPACE_DIRECTORY=$PWD")
fi

bazel_cmd=(
  env -i
  "${passthrough_env[@]}"
  "${envs[@]}"
  "%bazel_path%"

  # Restart bazel server if `DEVELOPER_DIR` changes to clear `developerDirCache`
  "--host_jvm_args=-Xdock:name=$DEVELOPER_DIR"

  "${bazelrcs[@]}"

  --output_base "$output_base"
)
if [[
  "$ACTION" == "indexbuild" &&
  "${BAZEL_SEPARATE_INDEXBUILD_OUTPUT_BASE:-}" != "YES"
]]; then
  # Allow normal builds to cancel Index Builds
  bazel_cmd+=("--preemptible")
fi
readonly bazel_cmd

readonly base_pre_config_flags=(
  # Be explicit about our desired Xcode version
  "--xcode_version=$XCODE_PRODUCT_BUILD_VERSION"

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


if [[ "${BAZEL_SEPARATE_INDEXBUILD_OUTPUT_BASE:-}" == "YES" ]]; then
  # Create VFS overlay
  cat > "$OBJROOT/bazel-out-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [$vfs_overlay_roots],"version": 0}
EOF
fi

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

if [[ -n "${SWIFTBUILD_BAZEL_PROXY_INVOCATION_RECEIPT:-}" ]]; then
  receipt_args=(
    "$SWIFTBUILD_BAZEL_PROXY_INVOCATION_RECEIPT"
    --working-directory "$SRCROOT"
    --command build
    "--startup-option=--host_jvm_args=-Xdock:name=$DEVELOPER_DIR"
    "--startup-option=--output_base=$output_base"
    --target "%generator_label%"
    --mode "action=$ACTION"
    --mode "config=$config"
    --mode "coverage=${CLANG_COVERAGE_MAPPING:-NO}"
    --mode "previews=${ENABLE_PREVIEWS:-NO}"
    --materialization "contract=manifest-v2"
  )
  for bazelrc in "${bazelrcs[@]}"; do
    receipt_args+=("--bazelrc=${bazelrc#--bazelrc=}")
  done
  for option in "${base_pre_config_flags[@]}" "${build_pre_config_flags[@]}"; do
    if [[
      "$option" != --build_event_json_file=* &&
      "$option" != --build_event_max_named_set_of_file_entries=* &&
      "$option" != --execution_log_compact_file=* &&
      "$option" != --execution_log_json_file=* &&
      "$option" != --execution_log_binary_file=* &&
      "$option" != --noexecution_log_sort
    ]]; then
      receipt_args+=("--command-option=$option")
    fi
  done
  receipt_args+=("--command-option=--config=$config")
  receipt_args+=("--command-option=--color=yes")
  if [[ -n "${toolchain:-}" ]]; then
    receipt_args+=("--command-option=--action_env=TOOLCHAINS=$toolchain")
  fi
  receipt_args+=("--command-option=$output_groups_flag")
  for label in "${labels[@]:-}"; do
    [[ -n "$label" ]] && receipt_args+=(--label "$label")
  done
  for output_group in "${output_groups[@]}"; do
    receipt_args+=(--output-group "$output_group")
  done
  for target_id in "${target_ids[@]:-}"; do
    [[ -n "$target_id" ]] && receipt_args+=(--target-id "$target_id")
  done
  for item in "${passthrough_env[@]}" "${envs[@]}"; do
    receipt_args+=(--environment-key "${item%%=*}")
  done
  if [[ -n "${SWIFTBUILD_BAZEL_PROXY_BEP_PATH:-}" ]]; then
    receipt_args+=(--bep-path "$SWIFTBUILD_BAZEL_PROXY_BEP_PATH")
  fi
  "$BAZEL_INTEGRATION_DIR/write_build_proxy_invocation_receipt.py" \
    "${receipt_args[@]}"
fi

echo "Starting Bazel build"

build_log_cmd=(
  "$BAZEL_INTEGRATION_DIR/process_bazel_build_log.py"
  "${bazel_cmd[@]}"
  build
  "${base_pre_config_flags[@]}"
  ${build_pre_config_flags:+"${build_pre_config_flags[@]}"}
  --config="$config"
  --color=yes
)
if [[ -n "${toolchain:-}" ]]; then
  build_log_cmd+=("--action_env=TOOLCHAINS=$toolchain")
fi
build_log_cmd+=(
  "$output_groups_flag"
  "%generator_label%"
)
if [[ -n "${labels:-}" ]]; then
  build_log_cmd+=("--build_metadata=PATTERN=${labels[*]}")
fi
readonly build_log_cmd

if [[ -n "${SWIFTBUILD_BAZEL_PROXY_REQUEST_DIR:-}" ]]; then
  "${build_log_cmd[@]}" 2>&1 &
  readonly proxy_build_pid=$!
  cancel_proxy_build() {
    kill -TERM "$proxy_build_pid" 2>/dev/null || true
    wait "$proxy_build_pid" 2>/dev/null || true
    exit 143
  }
  trap cancel_proxy_build TERM INT
  set +e
  wait "$proxy_build_pid"
  proxy_build_status=$?
  set -e
  trap - TERM INT
  if [[ $proxy_build_status -ne 0 ]]; then
    exit "$proxy_build_status"
  fi
else
  "${build_log_cmd[@]}" 2>&1
fi

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
