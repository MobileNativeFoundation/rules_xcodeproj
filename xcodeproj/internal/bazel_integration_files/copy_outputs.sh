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
