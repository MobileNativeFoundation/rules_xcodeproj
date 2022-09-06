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
    # Compiled outputs (i.e. swiftmodules)
    readonly output_group_prefixes="bc"
  fi
else
  if [[ "$RULES_XCODEPROJ_BUILD_MODE" == "xcode" ]]; then
    # Inputs for compiling, inputs for linking
    readonly output_group_prefixes="xc,xl"
  else
    # Compiled outputs (i.e. swiftmodules) and products (i.e. bundles)
    readonly output_group_prefixes="bc,bp"
  fi
fi

# We need to read from `$output_groups_file` as soon as possible, as concurrent
# writes to it can happen during indexing, which breaks the off-by-one-by-design
# nature of it
IFS=$'\n' read -r -d '' -a output_groups < \
  <( "$CALCULATE_OUTPUT_GROUPS_SCRIPT" \
       "$ACTION" \
       "$non_preview_objroot" \
       "$base_objroot" \
       "$scheme_target_ids_file" \
       $output_group_prefixes \
       && printf '\0' )

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
fi
output_groups_flag="--output_groups=$(IFS=, ; echo "${output_groups[*]}")"

# Set `bazel_cmd` for calling `bazel`

if [ "$ACTION" == "indexbuild" ]; then
  # We use a different output base for Index Build to prevent normal builds and
  # indexing waiting on bazel locks from the other
  output_base="$OBJROOT/bazel_output_base"
fi

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
  USER="$USER"
  "$BAZEL_PATH"
  "${bazelrcs[@]}"
  ${output_base:+--output_base "$output_base"}
)

# Determine Bazel output_path

if [[ "${COLOR_DIAGNOSTICS:-NO}" == "YES" ]]; then
  color=yes
else
  color=no
fi

output_path=$("${bazel_cmd[@]}" \
  info \
  --config=rules_xcodeproj_info \
  --color="$color" \
  --experimental_convenience_symlinks=ignore \
  --symlink_prefix=/ \
  --bes_backend= \
  --bes_results_url= \
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

if [[ "$output_path" != "$absolute_bazel_out" ]]; then
  # Use current path for bazel-out
  # This fixes Index Build to use its version of generated files
  roots="{\"external-contents\": \"$output_path\",\"name\": \"$absolute_bazel_out\",\"type\": \"directory-remap\"}"
else
  roots=
fi
if [[ "$RULES_XCODEPROJ_BUILD_MODE" != "xcode" ]]; then
  # Map `$BUILD_DIR` to execution_root, to fix SwiftUI Previews and indexing
  # edge cases
  roots="${roots:+${roots},}{\"external-contents\": \"$execution_root\",\"name\": \"$BUILD_DIR\",\"type\": \"directory-remap\"}"
fi

cat > "$OBJROOT/bazel-out-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [$roots],"version": 0}
EOF

if [[ "$RULES_XCODEPROJ_BUILD_MODE" == "xcode" ]]; then
  source "$INTERNAL_DIR/create_xcode_overlay.sh"
fi

# Build

if [ "$ACTION" == "indexbuild" ]; then
  config=rules_xcodeproj_indexbuild
elif [ "${ENABLE_PREVIEWS:-}" == "YES" ]; then
  config=rules_xcodeproj_swiftuipreviews
else
  config=rules_xcodeproj_build
fi

mkdir -p /tmp/rules_xcodeproj
date +%s > "/tmp/rules_xcodeproj/top_level_cache_buster"

build_marker="$OBJROOT/bazel_build_start"
touch "$build_marker"

log=$(mktemp)
"$BAZEL_INTEGRATION_DIR/process_bazel_build_log.py" \
  "${bazel_cmd[@]}" \
  build \
  --config=$config \
  --color=yes \
  --experimental_convenience_symlinks=ignore \
  --symlink_prefix=/ \
  "$output_groups_flag" \
  "$GENERATOR_LABEL" \
  2>&1 | tee -i "$log"

for output_group in "${output_groups[@]}"; do
  filelist="$GENERATOR_TARGET_NAME-${output_group//\//_}"
  filelist="${filelist/#/$output_path/$GENERATOR_PACKAGE_BIN_DIR/}"
  filelist="${filelist/%/.filelist}"
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
