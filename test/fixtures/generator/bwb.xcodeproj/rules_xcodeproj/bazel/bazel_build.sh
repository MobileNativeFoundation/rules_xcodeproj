#!/bin/bash

set -euo pipefail

# Calculate Bazel `--output_groups`

# In Xcode 14 the "Index" directory was renamed to "Index.noindex".
# `$INDEX_DATA_STORE_DIR` is set to `$OBJROOT/INDEX_DIR/DataStore`, so we can
# use it to determine the name of the directory regardless of Xcode version.
readonly index_dir="${INDEX_DATA_STORE_DIR%/*}"
readonly index_dir_name="${index_dir##*/}"

# Xcode doesn't adjust `$OBJROOT` in scheme action scripts when building for
# previews. So we need to look in the non-preview build directory for this file.
readonly non_preview_objroot="${OBJROOT/\/Intermediates.noindex\/Previews\/*//Intermediates.noindex}"
readonly base_objroot="${non_preview_objroot/\/$index_dir_name\/Build\/Intermediates.noindex//Build/Intermediates.noindex}"
readonly scheme_target_ids_file="$non_preview_objroot/scheme_target_ids"

if [ "$ACTION" == "indexbuild" ]; then
  if [[ "$RULES_XCODEPROJ_BUILD_MODE" == "xcode" ]]; then
    # Inputs for compiling
    readonly output_group_prefixes="xc"
  else
    # Compiled outputs (i.e. swiftmodules), and generated inputs
    readonly output_group_prefixes="bc,bg"
  fi
else
  if [[ "$RULES_XCODEPROJ_BUILD_MODE" == "xcode" ]]; then
    # Inputs for compiling, inputs for linking, and index store data
    readonly output_group_prefixes="xc,xl,xi"
  else
    # Compiled outputs (i.e. swiftmodules), products (i.e. bundles), generated
    # inputs, and index store data
    readonly output_group_prefixes="bc,bp,bg,bi"
  fi
fi

# We need to read from `$output_groups_file` as soon as possible, as concurrent
# writes to it can happen during indexing, which breaks the off-by-one-by-design
# nature of it
IFS=$'\n' read -r -d '' -a labels_and_output_groups < \
  <( "$CALCULATE_OUTPUT_GROUPS_SCRIPT" \
       "$ACTION" \
       "$non_preview_objroot" \
       "$base_objroot" \
       "$scheme_target_ids_file" \
       $output_group_prefixes \
       && printf '\0' )

raw_labels=()
output_groups=()
for (( i=0; i<${#labels_and_output_groups[@]}; i+=2 )); do
  raw_labels+=("${labels_and_output_groups[i]}")
  output_groups+=("${labels_and_output_groups[i+1]}")
done

if [ -z "${output_groups:-}" ]; then
  if [ "$ACTION" == "indexbuild" ]; then
    if [[ "$RULES_XCODEPROJ_BUILD_MODE" == "xcode" ]]; then
      output_groups=("all_xc")
    else
      echo "error: Can't yet determine Index Build output group." \
"Next build should succeed. If not, please file a bug report here:" \
"https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md" \
        >&2
      exit 1
    fi
  else
    echo "error: BazelDependencies invoked without any output groups set." \
"Please file a bug report here:" \
"https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md" \
      >&2
    exit 1
  fi
else
  labels=()
  while IFS= read -r -d '' label; do
    labels+=("$label")
  done < <(printf "%s\0" "${raw_labels[@]}" | sort -uz)
fi
output_groups_flag="--output_groups=$(IFS=, ; echo "${output_groups[*]}")"

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

bazel_cmd=(
  env -i
  HOME="$HOME"
  PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  TERM="$TERM"
  USER="$USER"
  "$BAZEL_PATH"
  "${bazelrcs[@]}"
)
pre_config_flags=(
  # Be explicit about our desired Xcode version
  "--xcode_version=$XCODE_PRODUCT_BUILD_VERSION"

  # Work around https://github.com/bazelbuild/bazel/issues/8902
  # `USE_CLANG_CL` is only used on Windows, we set it here to cause Bazel to
  # re-evaluate the cc_toolchain for a different Xcode version
  "--repo_env=USE_CLANG_CL=$XCODE_PRODUCT_BUILD_VERSION"
)

# Determine Bazel output_path

if [ "$ACTION" == "indexbuild" ]; then
  # We use a different output base for Index Build to prevent normal builds and
  # indexing waiting on bazel locks from the other. We nest it inside of the
  # normal output base directory so that it's not cleaned up when running
  # `bazel clean`, but is when running `bazel clean --expunge`. This matches
  # Xcode behavior of not cleaning the Index Build outputs by default.

  bazel_cmd+=(
    --output_base "${BAZEL_OUT%/*/*/*}/rules_xcodeproj/indexbuild_output_base"
  )
fi

if [[ "${COLOR_DIAGNOSTICS:-NO}" == "YES" ]]; then
  color=yes
else
  color=no
fi

output_path=$("${bazel_cmd[@]}" \
  info \
  "${pre_config_flags[@]}" \
  --config="${BAZEL_CONFIG}_info" \
  --color="$color" \
  output_path)
execution_root="${output_path%/*}"

# Create `bazel.lldbinit``

if [[ "$ACTION" != "indexbuild" && "${ENABLE_PREVIEWS:-}" != "YES" ]]; then
  # shellcheck disable=SC2046
  "$BAZEL_INTEGRATION_DIR/create_lldbinit.sh" \
    "$execution_root" \
    $(xargs -n1 <<< "${RESOLVED_EXTERNAL_REPOSITORIES:-}") \
    > "$BAZEL_LLDB_INIT"
fi

# Create VFS overlays

if [[ "${BAZEL_OUT:0:1}" == '/' ]]; then
  bazel_out_prefix=
else
  bazel_out_prefix="$SRCROOT/"
fi
absolute_bazel_out="${bazel_out_prefix}$BAZEL_OUT"

if [[ "$RULES_XCODEPROJ_BUILD_MODE" == "xcode" ]]; then
  source "$INTERNAL_DIR/create_xcode_overlay.sh"
fi

if [[ "$output_path" != "$absolute_bazel_out" ]]; then
  # Use current path for bazel-out
  # This fixes Index Build to use its version of generated files
  roots="{\"external-contents\": \"$output_path\",\"name\": \"$absolute_bazel_out\",\"type\": \"directory-remap\"}"
else
  roots=""
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

apply_sanitizers=1
if [ "$ACTION" == "indexbuild" ]; then
  config="${BAZEL_CONFIG}_indexbuild"

  # Index Build doesn't need sanitizers
  apply_sanitizers=0
elif [ "${ENABLE_PREVIEWS:-}" == "YES" ]; then
  config="${BAZEL_CONFIG}_swiftuipreviews"
else
  config="_${BAZEL_CONFIG}_build"
fi

# Runtime Sanitizers
if [[ $apply_sanitizers -eq 1 ]]; then
  if [ "${ENABLE_ADDRESS_SANITIZER:-}" == "YES" ]; then
    pre_config_flags+=(--features=asan)
  fi
  if [ "${ENABLE_THREAD_SANITIZER:-}" == "YES" ]; then
    pre_config_flags+=(--features=tsan)
  fi
  if [ "${ENABLE_UNDEFINED_BEHAVIOR_SANITIZER:-}" == "YES" ]; then
    pre_config_flags+=(--features=ubsan)
  fi
fi

# Ensure that our top-level cache buster `override_repository` is valid
mkdir -p /tmp/rules_xcodeproj
touch /tmp/rules_xcodeproj/WORKSPACE
echo 'exports_files(["top_level_cache_buster"])' > /tmp/rules_xcodeproj/BUILD
date +%s > "/tmp/rules_xcodeproj/top_level_cache_buster"

build_marker="$OBJROOT/bazel_build_start"
touch "$build_marker"

# TODO: Include labels in some sort of BES metadata
# See https://github.com/buildbuddy-io/rules_xcodeproj/issues/1224 for why we
# don't set the labels in the target pattern
"$BAZEL_INTEGRATION_DIR/process_bazel_build_log.py" \
  "${bazel_cmd[@]}" \
  build \
  "${pre_config_flags[@]}" \
  --config="$config" \
  --color=yes \
  ${toolchain:+--define=SWIFT_CUSTOM_TOOLCHAIN="$toolchain"} \
  --experimental_convenience_symlinks=ignore \
  --symlink_prefix=/ \
  "$output_groups_flag" \
  "$GENERATOR_LABEL" \
  2>&1

indexstores_filelists=()
for output_group in "${output_groups[@]}"; do
  filelist="$GENERATOR_TARGET_NAME-${output_group//\//_}"
  filelist="${filelist/#/$output_path/$GENERATOR_PACKAGE_BIN_DIR/}"
  filelist="${filelist/%/.filelist}"

  if [[ "$output_group" =~ ^(xi|bi) ]]; then
    indexstores_filelists+=("$filelist")
  fi

  if [[ "$filelist" -ot "$build_marker" ]]; then
    echo "error: Bazel didn't generate the correct files (it should have" \
"generated outputs for output group \"$output_group\", but the timestamp for" \
"\"$filelist\" was from before the build). Please regenerate the project to" \
"fix this." >&2
    echo "error: If your bazel version is less than 5.2, you may need to" \
"\`bazel clean\` and/or \`bazel shutdown\` to work around a bug in project" \
"generation." >&2
    echo "error: If you are still getting this error after all of that," \
"please file a bug report here:" \
"https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md" \
      >&2
    exit 1
  fi
done

# Async actions
#
# For these commands to run in the background, both stdout and stderr need to be
# redirected, otherwise Xcode will block the run script.

log_dir="$OBJROOT/rules_xcodeproj_logs"
mkdir -p "$log_dir"

# Report errors from previous async actions
shopt -s nullglob
for log in "$log_dir"/*.async.log; do
  if [[ -s "$log" ]]; then
    command=$(basename "${log%.async.log}")
    echo "warning: Previous run of \"$command\" had output:" >&2
    sed "s|^|warning: |" "$log" >&2
    echo "warning: If you believe this is a bug, please file a report here:" \
"https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md" \
      >&2
  fi
done

# Import indexes
if [ -n "${indexstores_filelists:-}" ]; then
  "$BAZEL_INTEGRATION_DIR/import_indexstores.sh" \
    "$execution_root" \
    "${indexstores_filelists[@]}" \
    >"$log_dir/import_indexstores.async.log" 2>&1 &
fi
