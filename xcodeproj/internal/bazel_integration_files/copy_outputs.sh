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

stage_preview_frameworks() (
  local destination_dir="$1" owner="${DERIVED_FILE_DIR:-}"
  local receipt="$1/.rules_xcodeproj_preview_frameworks"
  local lock="$receipt.lockfile"
  local framework_path parsed_framework_paths framework_index seen_framework_index
  local name identity recorded_owner recorded_source index owner_index
  local temporary_link_dir="" temporary_receipt="" staging_status=0
  local -a framework_paths framework_names=()
  local -a owned_names=() owned_ids=() owned_targets=() owned_sources=()

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

  # Validate every source before changing any destination or ownership metadata.
  for framework_path in "${framework_paths[@]}"; do
    local framework_name="${framework_path##*/}"
    if [[ "$framework_name" != *.framework ]]; then
      echo >&2 "error: Preview framework path does not name a .framework: $framework_path"
      return 1
    fi
    if [[ ! -d "$framework_path" ]]; then
      echo >&2 "error: Preview framework is not a materialized directory: $framework_path"
      return 1
    fi
    for (( seen_framework_index=0; seen_framework_index<${#framework_names[@]}; seen_framework_index++ )); do
      if [[ "${framework_names[seen_framework_index]}" == "$framework_name" ]]; then
        echo >&2 "error: Multiple Preview frameworks have the same basename: $framework_name"
        return 1
      fi
    done
    framework_names+=("$framework_name")
  done

  if [[ "${BAZEL_NATIVE_PREVIEWS:-}" == YES ]]; then
    if [[ "$owner" != /* || "$owner" == *$'\n'* || "$owner" == *$'\r'* ]]; then
      echo >&2 "error: Invalid Preview framework owner: $owner"
      return 1
    fi
    for framework_path in "${framework_paths[@]}"; do
      if [[ "$framework_path" != /* || "$framework_path" == *$'\n'* || "$framework_path" == *$'\r'* ]]; then
        echo >&2 "error: Invalid absolute Preview framework source: $framework_path"
        return 1
      fi
    done
    mkdir -p "$destination_dir"
    if [[ -L "$lock" || ( -e "$lock" && ! -f "$lock" ) ]]; then
      echo >&2 "error: Invalid Preview framework ownership lock: $lock"
      return 1
    fi
    exec 9>> "$lock"
    if ! /usr/bin/python3 -c 'import fcntl, signal; signal.alarm(10); fcntl.flock(9, fcntl.LOCK_EX)'; then
      echo >&2 "error: Unable to acquire Preview framework ownership lock: $lock"
      return 1
    fi
    if [[ -L "$receipt" || ( -e "$receipt" && ! -f "$receipt" ) ]]; then
      echo >&2 "error: Invalid Preview framework ownership receipt: $receipt"
      return 1
    fi
    if [[ -f "$receipt" ]]; then
      while IFS= read -r name || [[ -n "$name" ]]; do
        if ! IFS= read -r identity || ! IFS= read -r recorded_owner || ! IFS= read -r recorded_source || \
           [[ "$name" != *.framework || "$name" == */* || ! "$identity" =~ ^[0-9]+:[0-9]+$ || \
              "$recorded_owner" != /* || "$recorded_source" != /* ]]; then
          echo >&2 "error: Invalid Preview framework ownership receipt: $receipt"
          return 1
        fi
        owned_names+=("$name")
        owned_ids+=("$identity")
        owned_targets+=("$recorded_owner")
        owned_sources+=("$recorded_source")
      done < "$receipt"
    fi
  fi

  check_preview_framework_destination() {
    local destination="$1" source="$2" name="${1##*/}"
    local index identity old_source current_owner=NO other_owner=NO
    if [[ -L "$destination" ]]; then
      # BSD stat defaults to lstat: identify the link, never its referent.
      identity="$(stat -f '%d:%i' "$destination")"
      old_source="$(readlink "$destination")"
      for (( index=0; index<${#owned_names[@]}; index++ )); do
        if [[ "${owned_names[index]}" != "$name" ]]; then continue; fi
        if [[ "${owned_ids[index]}" != "$identity" || "${owned_sources[index]}" != "$old_source" ]]; then
          echo >&2 "error: Preview framework destination is no longer owned: $destination"
          return 1
        fi
        if [[ "${owned_targets[index]}" == "$owner" ]]; then current_owner=YES; else other_owner=YES; fi
      done
      if [[ "$old_source" == "$source" ]]; then return; fi
      # Unknown links keep same-referent compatibility, but are never adopted.
      if [[ "$current_owner" == NO && "$other_owner" == NO && "$destination" -ef "$source" ]]; then return; fi
      if [[ "$current_owner" == YES && "$other_owner" == NO ]]; then return; fi
      echo >&2 "error: Preview framework destination points to a different source: $destination"
      return 1
    fi
    # A focused native framework can already be its consumer's sibling.
    # Accept Xcode's directory unchanged; never adopt it.
    if [[ "$destination" -ef "$source" ]]; then return; fi
    if [[ -e "$destination" ]]; then
      echo >&2 "error: Preview framework destination already exists and is not a symlink: $destination"
      return 1
    fi
    # Removing a link does not release another target's recorded source claim.
    for (( index=0; index<${#owned_names[@]}; index++ )); do
      if [[ "${owned_names[index]}" == "$name" && "${owned_targets[index]}" != "$owner" && \
            "${owned_sources[index]}" != "$source" ]]; then
        echo >&2 "error: Preview framework destination points to a different source: $destination"
        return 1
      fi
    done
  }

  for (( framework_index=0; framework_index<${#framework_paths[@]}; framework_index++ )); do
    check_preview_framework_destination "$destination_dir/${framework_names[framework_index]}" "${framework_paths[framework_index]}"
  done
  mkdir -p "$destination_dir"
  trap 'staging_status=$?
    if [[ -n "$temporary_link_dir" ]]; then rm -f "$temporary_link_dir/link"; rmdir "$temporary_link_dir"; fi
    if [[ -n "$temporary_receipt" ]]; then rm -f "$temporary_receipt"; fi
    exit "$staging_status"' EXIT
  for (( framework_index=0; framework_index<${#framework_paths[@]}; framework_index++ )); do
    name="${framework_names[framework_index]}"
    framework_path="${framework_paths[framework_index]}"
    local destination="$destination_dir/$name"
    if [[ "${BAZEL_NATIVE_PREVIEWS:-}" != YES ]]; then
      if [[ "$destination" -ef "$framework_path" ]]; then continue; fi
      if ! ln -s "$framework_path" "$destination" 2>/dev/null; then
        if [[ -L "$destination" && "$destination" -ef "$framework_path" ]]; then continue; fi
        echo >&2 "error: Unable to stage Preview framework: $destination"
        return 1
      fi
      continue
    fi

    owner_index="${#owned_names[@]}"
    local known=NO
    for (( index=0; index<${#owned_names[@]}; index++ )); do
      if [[ "${owned_names[index]}" != "$name" ]]; then continue; fi
      known=YES
      if [[ "${owned_targets[index]}" == "$owner" ]]; then owner_index="$index"; fi
    done
    # Old unreceipted links and genuine native products stay unowned.
    if [[ "$destination" -ef "$framework_path" && ( ! -L "$destination" || "$known" == NO ) ]]; then continue; fi
    if [[ -L "$destination" && "$(readlink "$destination")" == "$framework_path" ]]; then
      if [[ "$owner_index" != "${#owned_names[@]}" ]]; then continue; fi
    else
      temporary_link_dir="$(mktemp -d "$destination_dir/.rules_xcodeproj_preview_framework.XXXXXX")"
      ln -s "$framework_path" "$temporary_link_dir/link"
      check_preview_framework_destination "$destination" "$framework_path"
      # Unlike mv, replace cannot accidentally move the link into a directory.
      /usr/bin/python3 -c 'import os, sys; os.replace(*sys.argv[1:])' "$temporary_link_dir/link" "$destination"
      rmdir "$temporary_link_dir"
      temporary_link_dir=""
    fi

    identity="$(stat -f '%d:%i' "$destination")"
    for (( index=0; index<${#owned_names[@]}; index++ )); do
      if [[ "${owned_names[index]}" == "$name" ]]; then owned_ids[index]="$identity"; fi
    done
    owned_names[owner_index]="$name"
    owned_ids[owner_index]="$identity"
    owned_targets[owner_index]="$owner"
    owned_sources[owner_index]="$(readlink "$destination")"
    temporary_receipt="$(mktemp "$receipt.XXXXXX")"
    {
      for (( index=0; index<${#owned_names[@]}; index++ )); do
        printf '%s\n%s\n%s\n%s\n' "${owned_names[index]}" "${owned_ids[index]}" \
          "${owned_targets[index]}" "${owned_sources[index]}"
      done
    } > "$temporary_receipt"
    mv -f "$temporary_receipt" "$receipt"
    temporary_receipt=""
  done
)


if [[ "$ACTION" != indexbuild ]]; then
  product_is_bundle=NO
  outputs_product="${BAZEL_OUTPUTS_PRODUCT:-}"

  if [[ "${BAZEL_NATIVE_PREVIEWS:-}" == "YES" ]]; then
    # The Preview configuration builds the selected product with Xcode. Its Bazel
    # output group is intentionally absent. Ignore a stale product from an
    # earlier ordinary build; Preview frameworks still need to be staged below.
    outputs_product=
  elif [[ -n "$outputs_product" ]]; then
    # Generated product paths are relative to the selected Bazel execution
    # root. SRCROOT/bazel-out can point to a different output base.
    if [[ "$outputs_product" != /* ]]; then
      outputs_product="$PROJECT_DIR/$outputs_product"
    fi
    if [[ ! -e "$outputs_product" ]]; then
      echo >&2 \
        "error: Bazel output product is not materialized: $outputs_product"
      exit 1
    fi
  fi
  readonly outputs_product

  # Copy product
  if [[ -n "$outputs_product" ]]; then
    cd "${outputs_product%/*}"

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

  fi

  # Legacy Xcode Previews use the nested directory included in a bundle's
  # generated loader rpath. Native Preview configurations instead use direct
  # `$TARGET_BUILD_DIR` siblings, including for static library products.
  if [[ -n "${PREVIEW_FRAMEWORK_PATHS:-}" ]]; then
    if [[ "${BAZEL_NATIVE_PREVIEWS:-}" == "YES" ]]; then
      stage_preview_frameworks "$TARGET_BUILD_DIR"
    elif [[ "${ENABLE_PREVIEWS:-}" == "YES" ]]; then
      if [[ "$product_is_bundle" == YES ]]; then
        stage_preview_frameworks \
          "$TARGET_BUILD_DIR/$WRAPPER_NAME/SwiftUIPreviewsFrameworks"
      fi
    fi
  fi
fi


# TODO: https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/402
# Copy diagnostics, and on a change
# `echo "private let touch = \"$(date +%s)\"" > $DERIVED_FILE_DIR/$forced_swift_compile_file"`
# See git blame for this comment for an example
