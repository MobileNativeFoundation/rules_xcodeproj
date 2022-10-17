# It is assumed that this file is `source`ed from another script, with the following variable set:
#
# - BAZEL_CONFIG
# - BAZEL_INTEGRATION_DIR
# - BAZEL_OUT
# - BAZEL_PATH
# - DEVELOPER_DIR
# - GENERATOR_LABEL
# - GENERATOR_TARGET_NAME
# - GENERATOR_PACKAGE_BIN_DIR
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

output_groups_flag="--output_groups=$(IFS=, ; echo "${output_groups[*]}")"
readonly output_groups_flag

# Set `output_base`

# In `runner.template.sh` the generator has the build output base set inside
# of the outer bazel's output path (`bazel-out/`). So here we need to make
# our output base changes relative to that changed path.
readonly build_output_base="$BAZEL_OUT/../../.."
readonly outer_output_base="$build_output_base/../.."

if [ "$ACTION" == "indexbuild" ]; then
  # We use a different output base for Index Build to prevent normal builds and
  # indexing waiting on bazel locks from the other. We nest it inside of the
  # normal output base directory so that it's not cleaned up when running
  # `bazel clean`, but is when running `bazel clean --expunge`. This matches
  # Xcode behavior of not cleaning the Index Build outputs by default.
  readonly output_base="$outer_output_base/rules_xcodeproj/indexbuild_output_base"
else
  readonly output_base="$build_output_base"
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

readonly bazel_cmd=(
  env
  PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  "$BAZEL_PATH"

  # Restart bazel server if `DEVELOPER_DIR` changes to clear `developerDirCache`
  "--host_jvm_args=-Xdock:name=$DEVELOPER_DIR"

  "${bazelrcs[@]}"

  --output_base "$output_base"
)

readonly base_pre_config_flags=(
  # Be explicit about our desired Xcode version
  "--xcode_version=$XCODE_PRODUCT_BUILD_VERSION"

  # Set `DEVELOPER_DIR` in case a bazel wrapper filters it
  "--repo_env=DEVELOPER_DIR=$DEVELOPER_DIR"

  # Work around https://github.com/bazelbuild/bazel/issues/8902
  # `USE_CLANG_CL` is only used on Windows, we set it here to cause Bazel to
  # re-evaluate the cc_toolchain for a different Xcode version
  "--repo_env=USE_CLANG_CL=$XCODE_PRODUCT_BUILD_VERSION"
)

# Determine Bazel output_path

if [[ "${COLOR_DIAGNOSTICS:-NO}" == "YES" ]]; then
  readonly info_color=yes
else
  readonly info_color=no
fi

output_path=$("${bazel_cmd[@]}" \
  info \
  "${base_pre_config_flags[@]}" \
  --config="${BAZEL_CONFIG}_info" \
  --color="$info_color" \
  output_path)
readonly output_path

# Create VFS overlays

if [[ "${BAZEL_OUT:0:1}" == '/' ]]; then
  readonly bazel_out_prefix=
else
  readonly bazel_out_prefix="$SRCROOT/"
fi

readonly absolute_bazel_out="${bazel_out_prefix}$BAZEL_OUT"
if [[ "$output_path" != "$absolute_bazel_out" ]]; then
  # Use current path for bazel-out
  # This fixes Index Build to use its version of generated files
  readonly roots="{\"external-contents\": \"$output_path\",\"name\": \"$absolute_bazel_out\",\"type\": \"directory-remap\"}"
else
  readonly roots=""
fi

cat > "$OBJROOT/bazel-out-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [$roots],"version": 0}
EOF

# Custom Swift toolchains

if [[ -n "${TOOLCHAINS-}" ]]; then
  toolchain="${TOOLCHAINS%% *}"
  if [[ "$toolchain" == "com.apple.dt.toolchain.XcodeDefault" ]]; then
    unset toolchain
  fi
fi

# Build

readonly build_marker="$OBJROOT/bazel_build_start"
touch "$build_marker"

"$BAZEL_INTEGRATION_DIR/process_bazel_build_log.py" \
  "${bazel_cmd[@]}" \
  build \
  "${base_pre_config_flags[@]}" \
  ${build_pre_config_flags:+"${build_pre_config_flags[@]}"} \
  --config="$config" \
  --color=yes \
  ${toolchain:+--define=SWIFT_CUSTOM_TOOLCHAIN="$toolchain"} \
  "$output_groups_flag" \
  "$GENERATOR_LABEL" \
  2>&1

# Collect indexstore filelists

indexstores_filelists=()
for output_group in "${output_groups[@]}"; do
  if ! [[ "$output_group" =~ ^(xi|bi) ]]; then
    continue
  fi

  filelist="$GENERATOR_TARGET_NAME-${output_group//\//_}"
  filelist="${filelist/#/$output_path/$GENERATOR_PACKAGE_BIN_DIR/}"
  filelist="${filelist/%/.filelist}"

  if [[ ! -f "$filelist" ]]; then
    echo "error: Bazel didn't create the indexstore filelist (\"$filelist\")." \
"Please regenerate the project to fix this. If you are still getting this" \
"error after regenerating your project, please file a bug report here:" \
"https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md" \
      >&2
    exit 1
  fi

  indexstores_filelists+=("$filelist")
done
readonly indexstores_filelists
