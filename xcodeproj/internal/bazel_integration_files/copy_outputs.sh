#!/bin/bash

set -euo pipefail

# readonly forced_swift_compile_file="$1"
readonly product_basename="$2"
readonly exclude_list="$3"

# # Touching this file on an error allows indexing to work better
# trap 'echo "private let touch = \"$(date +%s)\"" > "$DERIVED_FILE_DIR/$forced_swift_compile_file"' ERR

if [[ "$ACTION" == indexbuild ]]; then
  # Write to "$SCHEME_TARGET_IDS_FILE" to allow next index to catch up
  echo "$BAZEL_LABEL,$BAZEL_TARGET_ID" > "$SCHEME_TARGET_IDS_FILE"
else
  # If this is the requesting target, wait for Bazel build to finish
  should_wait_for_bazel=false
  while IFS= read -r line; do
    if [[ "$line" == "$BAZEL_LABEL,$BAZEL_TARGET_ID" ]]; then
      should_wait_for_bazel=true
      break
    fi
  done < "$SCHEME_TARGET_IDS_FILE"

  if [[ -n ${BAZEL_OUTPUTS_PRODUCT:-} ]] && [[ "$BAZEL_OUTPUTS_PRODUCT" == *.appex ]]; then
    should_wait_for_bazel=true
  fi

  if [[ "$should_wait_for_bazel" == true ]]; then
    bazel_build_start_marker="$OBJROOT/bazel_build_start"
    bazel_build_finish_marker="$OBJROOT/bazel_build_finish"
    bazel_build_output="$OBJROOT/bazel_build_output"

    while [[ ! -f "$bazel_build_finish_marker" ]] || [[ "$bazel_build_start_marker" -nt "$bazel_build_finish_marker" ]]; do
      if [[ -f "$bazel_build_output" ]] && \
        [[ "$bazel_build_start_marker" -ot "$bazel_build_output" ]] && \
        [[ "$(tail -n 1 "$bazel_build_output")" == *"FAILED: Build did NOT complete successfully" ]]; then
          cat "$bazel_build_output"
          exit 1
      fi

      echo "Waiting for Bazel build to finish..."
      sleep 5
    done

    cat "$bazel_build_output"
  fi

  # Copy product
  if [[ -n ${BAZEL_OUTPUTS_PRODUCT:-} ]]; then
    if [[ "$BAZEL_OUTPUTS_PRODUCT" = *.ipa ]]; then
      suffix=/Payload
    fi

    if [[ "$BAZEL_OUTPUTS_PRODUCT" = *.ipa ]] || [[ "$BAZEL_OUTPUTS_PRODUCT" = *.zip ]]; then
      # Extract archive first
      readonly archive="$BAZEL_OUTPUTS_PRODUCT"
      readonly expanded_dest="$DERIVED_FILE_DIR/expanded_archive"
      readonly product_parent_dir="$expanded_dest${suffix:-}"
      readonly sha_output="$DERIVED_FILE_DIR/archive.sha256"

      existing_sha=$(cat "$sha_output" 2>/dev/null || true)
      sha=$(shasum -a 256 "$archive")

      if [[ \
        "$existing_sha" != "$sha" || \
        ! -d "$product_parent_dir/$product_basename" \
      ]]; then
        mkdir -p "$expanded_dest"
        rm -rf "${expanded_dest:?}/"
        echo "Extracting $archive to $expanded_dest"
        # Set timestamps (-DD) to allow rsync to work properly, since Bazel
        # zeroes out timestamps in the archive
        unzip -q -DD "$archive" -d "$expanded_dest"
        echo "$sha" > "$sha_output"
      fi
      cd "$product_parent_dir"
    else
      cd "${BAZEL_OUTPUTS_PRODUCT%/*}"
    fi

    rsync \
      --copy-links \
      --recursive \
      --times \
      --delete \
      ${exclude_list:+--exclude-from="$exclude_list"} \
      --chmod=u+w \
      --out-format="%n%L" \
      "$product_basename" \
      "$TARGET_BUILD_DIR"

    # SwiftUI Previews has a hard time finding frameworks (`@rpath`) when using
    # framework schemes, so let's copy them to `$BUILD_DIR`
    if [[ "${ENABLE_PREVIEWS:-}" == "YES" && \
          -n "${PREVIEW_FRAMEWORK_PATHS:-}" ]]; then
      # shellcheck disable=SC2046
      rsync \
        --copy-links \
        --recursive \
        --times \
        --delete \
        --chmod=u+w \
        --out-format="%n%L" \
        $(xargs -n1 <<< "$PREVIEW_FRAMEWORK_PATHS") \
        "$BUILD_DIR"
    fi
  fi
fi

# TODO: https://github.com/buildbuddy-io/rules_xcodeproj/issues/402
# Copy diagnostics, and on a change
# `echo "private let touch = \"$(date +%s)\"" > $DERIVED_FILE_DIR/$forced_swift_compile_file"`
# See git blame for this comment for an example
