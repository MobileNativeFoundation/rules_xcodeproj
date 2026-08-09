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
  "Testing.framework"
  "XCTest.framework"
  "XCTestCore.framework"
  "XCTestSupport.framework"
  "XCUIAutomation.framework"
  "XCUnit.framework"
)

readonly rsync="$BAZEL_INTEGRATION_DIR/rsync"

stage_preview_frameworks() {
  local destination_dir="$1"
  local framework_path
  local parsed_framework_paths
  local framework_index
  local seen_framework_index
  local -a framework_paths
  local -a framework_names=()

  if ! parsed_framework_paths="$(xargs -n1 <<< "$PREVIEW_FRAMEWORK_PATHS")"; then
    echo >&2 "error: Unable to parse Preview framework paths"
    return 1
  fi
  if [[ -z "$parsed_framework_paths" ]]; then
    echo >&2 "error: No Preview framework paths were provided"
    return 1
  fi
  IFS=$'\n' read -r -d '' -a framework_paths < \
    <(printf '%s\0' "$parsed_framework_paths")

  if [[ ( -e "$destination_dir" || -L "$destination_dir" ) && \
        ! -d "$destination_dir" ]]; then
    echo >&2 "error: Preview framework destination is not a directory: $destination_dir"
    return 1
  fi

  for framework_path in "${framework_paths[@]}"; do
    local framework_name="${framework_path##*/}"
    local destination="$destination_dir/$framework_name"

    if [[ "$framework_name" != *.framework ]]; then
      echo >&2 "error: Preview framework path does not name a .framework: $framework_path"
      return 1
    fi
    if [[ ! -d "$framework_path" ]]; then
      echo >&2 "error: Preview framework is not a materialized directory: $framework_path"
      return 1
    fi

    for (( seen_framework_index=0; \
           seen_framework_index<${#framework_names[@]}; \
           seen_framework_index++ )); do
      if [[ "${framework_names[seen_framework_index]}" == "$framework_name" ]]; then
        echo >&2 "error: Multiple Preview frameworks have the same basename: $framework_name"
        return 1
      fi
    done
    framework_names+=("$framework_name")

    if [[ -L "$destination" ]]; then
      if [[ "$destination" -ef "$framework_path" ]]; then
        continue
      fi
      echo >&2 "error: Preview framework destination points to a different source: $destination"
      return 1
    fi
    if [[ -e "$destination" ]]; then
      echo >&2 "error: Preview framework destination already exists and is not a symlink: $destination"
      return 1
    fi
  done

  mkdir -p "$destination_dir"
  for (( framework_index=0; \
         framework_index<${#framework_paths[@]}; \
         framework_index++ )); do
    local destination="$destination_dir/${framework_names[framework_index]}"
    if [[ ! -L "$destination" ]]; then
      if ! ln -s "${framework_paths[framework_index]}" "$destination" \
        2>/dev/null; then
        if [[ -L "$destination" && \
              "$destination" -ef "${framework_paths[framework_index]}" ]]; then
          continue
        fi
        echo >&2 "error: Unable to stage Preview framework: $destination"
        return 1
      fi
    fi
  done
}

if [[ "$ACTION" != indexbuild ]]; then
  # Copy product
  if [[ -n ${BAZEL_OUTPUTS_PRODUCT:-} ]]; then
    cd "${BAZEL_OUTPUTS_PRODUCT%/*}"

    product_is_bundle=NO
    if [[ -f "$BAZEL_OUTPUTS_PRODUCT_BASENAME" ]]; then
      # Product is a binary, so symlink instead of rsync, to allow for Bazel-set
      # rpaths to work
      ln -sfh "$PWD/$BAZEL_OUTPUTS_PRODUCT_BASENAME" "$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"
    else
      # Product is a bundle
      product_is_bundle=YES
      "$rsync" \
        --copy-links \
        --recursive \
        --times \
        --delete \
        ${exclude_list:+--exclude-from="$exclude_list"} \
        --perms \
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
      if [[ -d "$plugins_dir" ]]; then
        find "$plugins_dir" -depth 2 -name "Info.plist" -exec touch {} \;
      fi

    fi

    # Legacy Xcode Previews use the nested directory included in a bundle's
    # generated loader rpath. Shared XOJIT Previews reuse the ordinary product,
    # whose runtime search includes direct `$TARGET_BUILD_DIR` siblings. Static
    # library products are files, so they only support the XOJIT destination.
    if [[ -n "${PREVIEW_FRAMEWORK_PATHS:-}" ]]; then
      if [[ "${ENABLE_PREVIEWS:-}" == "YES" ]]; then
        if [[ "$product_is_bundle" == YES ]]; then
          stage_preview_frameworks \
            "$TARGET_BUILD_DIR/$WRAPPER_NAME/SwiftUIPreviewsFrameworks"
        fi
      elif [[ "${ENABLE_XOJIT_PREVIEWS:-}" == "YES" ]]; then
        stage_preview_frameworks "$TARGET_BUILD_DIR"
      fi
    fi
  fi
fi

# TODO: https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/402
# Copy diagnostics, and on a change
# `echo "private let touch = \"$(date +%s)\"" > $DERIVED_FILE_DIR/$forced_swift_compile_file"`
# See git blame for this comment for an example
