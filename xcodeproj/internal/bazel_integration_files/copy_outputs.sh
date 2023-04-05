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

    if [[ -f "$product_basename" ]]; then
      # Product is a binary, so symlink instead of rsync, to allow for Bazel-set
      # rpaths to work
      ln -sfh "$PWD/$product_basename" "$TARGET_BUILD_DIR/$PRODUCT_NAME"
    else
      # Product is a bundle
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

      # Incremental installation can fail if an embedded bundle is recompiled but
      # the Info.plist is not updated. This causes the delta bundle that Xcode
      # actually installs to not have a bundle ID for the embedded bundle. We
      # avoid this potential issue by always including the Info.plist in the delta
      # bundle by touching them.
      # Source: https://github.com/bazelbuild/tulsi/commit/27354027fada7aa3ec3139fd686f85cc5039c564
      # TODO: Pass the exact list of files to touch to this script
      readonly plugins_dir="$TARGET_BUILD_DIR/${PLUGINS_FOLDER_PATH:-}"
      if [[ "${TARGET_DEVICE_PLATFORM_NAME:-}" == "iphoneos" && \
            -d "$plugins_dir" ]]; then
        find "$plugins_dir" -depth 2 -name "Info.plist" -exec touch {} \;
      fi

      # SwiftUI Previews has a hard time finding frameworks (`@rpath`) when using
      # framework schemes, so let's symlink them into
      # `$TARGET_BUILD_DIR` (since we modify `@rpath` to always include
      # `@loader_path/SwiftUIPreviewsFrameworks`)
      if [[ "${ENABLE_PREVIEWS:-}" == "YES" && \
            -n "${PREVIEW_FRAMEWORK_PATHS:-}" ]]; then
        mkdir -p "$TARGET_BUILD_DIR/$WRAPPER_NAME/SwiftUIPreviewsFrameworks"
        cd "$TARGET_BUILD_DIR/$WRAPPER_NAME/SwiftUIPreviewsFrameworks"

        # shellcheck disable=SC2016
        xargs -n1 sh -c 'ln -shfF "$1" $(basename "$1")' _ \
          <<< "$PREVIEW_FRAMEWORK_PATHS"
      fi
    fi
  fi
fi

# TODO: https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/402
# Copy diagnostics, and on a change
# `echo "private let touch = \"$(date +%s)\"" > $DERIVED_FILE_DIR/$forced_swift_compile_file"`
# See git blame for this comment for an example
