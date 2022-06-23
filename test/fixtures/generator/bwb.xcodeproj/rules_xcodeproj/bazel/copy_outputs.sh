#!/bin/bash

set -euo pipefail

readonly forced_swift_compile_file="$1"
readonly product_basename="$2"
readonly exclude_list="$3"

# Touching this file on an error allows indexing to work better
trap 'touch "$DERIVED_FILE_DIR/$forced_swift_compile_file"' ERR

if [[ "$ACTION" == indexbuild ]]; then
  # Write to "$BAZEL_BUILD_OUTPUT_GROUPS_FILE" to allow next index to catch up
  echo "i $BAZEL_TARGET_ID" > "$BAZEL_BUILD_OUTPUT_GROUPS_FILE"
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
  fi
fi

mkdir -p "$OBJECT_FILE_DIR-normal/$ARCHS"

# Copy swiftmodule
if [[ -n ${BAZEL_OUTPUTS_SWIFTMODULE:-} ]]; then
  SAVEIFS=$IFS; IFS=$'\n'
  # shellcheck disable=2206 # `read` doesn't work correctly for this case
  swiftmodule=($BAZEL_OUTPUTS_SWIFTMODULE)
  IFS=$SAVEIFS

  log="$(mktemp)"
  rsync \
    "${swiftmodule[@]}" \
    --copy-links \
    --times \
    --chmod=u+w \
    --out-format="%n%L" \
    "$OBJECT_FILE_DIR-normal/$ARCHS" \
    | tee -i "$log"
  if [[ -s "$log" ]]; then
    touch "$DERIVED_FILE_DIR/$forced_swift_compile_file"
  fi
fi

# Copy swift generated header
if [[ -n ${BAZEL_OUTPUTS_SWIFT_GENERATED_HEADER:-} ]]; then
  header="$OBJECT_FILE_DIR-normal/$ARCHS/$SWIFT_OBJC_INTERFACE_HEADER_NAME"
  mkdir -p "${header%/*}"
  cp \
    "$BAZEL_OUTPUTS_SWIFT_GENERATED_HEADER" \
    "$header"
  chmod u+w "$header"
fi
