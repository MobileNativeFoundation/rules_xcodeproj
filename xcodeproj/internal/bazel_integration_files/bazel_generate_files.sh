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
  exit 0
fi

if [[ "$RULES_XCODEPROJ_BUILD_MODE" == "bazel" ]]; then
  readonly output_group_prefixes="bg"
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

labels=()
while IFS= read -r -d '' label; do
  labels+=("$label")
done < <(printf "%s\0" "${raw_labels[@]}" | sort -uz)

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

# Custom Swift toolchains

if [[ -n "${TOOLCHAINS-}" ]]; then
  toolchain="${TOOLCHAINS%% *}"
  if [[ "$toolchain" == "com.apple.dt.toolchain.XcodeDefault" ]]; then
    unset toolchain
  fi
fi

# Build

config="_${BAZEL_CONFIG}_build"

# Ensure that our top-level cache buster `override_repository` is valid
mkdir -p /tmp/rules_xcodeproj
touch /tmp/rules_xcodeproj/WORKSPACE
echo 'exports_files(["top_level_cache_buster"])' > /tmp/rules_xcodeproj/BUILD
date +%s > "/tmp/rules_xcodeproj/top_level_cache_buster"

build_marker="$OBJROOT/bazel_build_start"
touch "$build_marker"

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
  "${labels[@]}" \
  "$GENERATOR_LABEL" \
  2>&1

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
