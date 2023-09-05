#!/bin/bash

set -euo pipefail

# readonly forced_swift_compile_file="$1"
readonly exclude_list="$2"

# # Touching this file on an error allows indexing to work better
# trap 'echo "private let touch = \"$(date +%s)\"" > "$DERIVED_FILE_DIR/$forced_swift_compile_file"' ERR

readonly test_frameworks=(
  "libXCTestBundleInject.dylib"
  "libXCTestSwiftSupport.dylib"
  "IDEBundleInjection.framework"
  "XCTAutomationSupport.framework"
  "XCTest.framework"
  "XCTestCore.framework"
  "XCTestSupport.framework"
  "XCUIAutomation.framework"
  "XCUnit.framework"
)

if [[ "$ACTION" != indexbuild ]]; then
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
        ! -d "$product_parent_dir/$BAZEL_OUTPUTS_PRODUCT_BASENAME" \
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

    if [[ -f "$BAZEL_OUTPUTS_PRODUCT_BASENAME" ]]; then
      # Product is a binary, so symlink instead of rsync, to allow for Bazel-set
      # rpaths to work
      ln -sfh "$PWD/$BAZEL_OUTPUTS_PRODUCT_BASENAME" "$TARGET_BUILD_DIR/$PRODUCT_NAME"
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
        "$BAZEL_OUTPUTS_PRODUCT_BASENAME" \
        "$TARGET_BUILD_DIR"

      if [[ -n "${TEST_HOST:-}" ]]; then
        # We need to re-sign test frameworks that Xcode placed into the test
        # host un-signed
        readonly test_host_app="${TEST_HOST%/*}"

        # Only engage signing workflow if the test host is signed
        if [[ -f "$test_host_app/embedded.mobileprovision" ]]; then
          codesigning_authority=$(codesign -dvv "$TEST_HOST"  2>&1 >/dev/null | /usr/bin/sed -n  -E 's/^Authority=(.*)/\1/p'| head -n 1)

          for framework in "${test_frameworks[@]}"; do
            framework="$test_host_app/Frameworks/$framework"
            if [[ -e "$framework" ]]; then
              codesign -f \
                --preserve-metadata=identifier,entitlements,flags \
                --timestamp=none \
                --generate-entitlement-der \
                -s "$codesigning_authority" \
                "$framework"
            fi
          done
        fi
      fi

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
