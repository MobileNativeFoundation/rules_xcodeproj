#!/bin/bash

set -euo pipefail

function patch_dsym() {
  local dsym_name="$1"

  shopt -s extglob
  local binary_name="${dsym_name%.dSYM}"
  binary_name="${binary_name%@(.app|.appex|.bundle|.dext|.kext|.framework|.pluginkit|.systemextension|.xctest|.xpc)}"
  shopt +s extglob

  local binary_path="${dsym_name}/Contents/Resources/DWARF/${binary_name}"

  if [[ ! -f "$binary_path" ]]; then
    echo "dSYM DWARF ${binary_path} does not exist." \
    "Skip dSYM patch."
    return 1
  fi

  local dwarf_uuid
  dwarf_uuid=$(dwarfdump --uuid "${binary_path}" | cut -d ' ' -f 2)
  if [[ -z "${dwarf_uuid// /}" ]]; then
    echo "Failed to get dSYM uuid." \
    "Skip dSYM patch."
    return 1
  fi

  cat > "${dsym_name}/Contents/Resources/${dwarf_uuid}.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <dict>
    <key>DBGVersion</key>
    <string>3</string>
    <key>DBGSourcePathRemapping</key>
    <dict>
      <key>./bazel-out/</key>
      <string>$BAZEL_OUT/</string>
      <key>./external/</key>
      <string>$BAZEL_EXTERNAL/</string>
      <key>./</key>
      <string>$SRCROOT/</string>
    </dict>
  </dict>
</plist>
EOF
}

if [[ -n "${BAZEL_OUTPUTS_DSYM:-}" ]]; then
  cd "${BAZEL_OUT%/*}"

  if (( $(echo "$(sw_vers -productVersion | cut -d '.' -f 1-2)" | sed 's/\.//g') >= 154 )); then
    # 15.4's `rsync` has a bug that requires the src to have write permissions.
    # We normally shouldn't do this as it modifies the bazel output base, so we
    # limit this to only macOS 15.4 or higher.
    # shellcheck disable=SC2046
    chmod -R +w $(xargs -n1 <<< "$BAZEL_OUTPUTS_DSYM")
  fi

  # shellcheck disable=SC2046
  rsync \
    --copy-links \
    --recursive \
    --times \
    --archive \
    --delete \
    ${exclude_list:+--exclude-from="$exclude_list"} \
    --chmod=u+w \
    --out-format="%n%L" \
    $(xargs -n1 <<< "$BAZEL_OUTPUTS_DSYM") \
    "$TARGET_BUILD_DIR"

  cd "${TARGET_BUILD_DIR}"

  export -f patch_dsym
  # shellcheck disable=SC2016
  xargs -n1 sh -c 'patch_dsym $(basename "$1")' _ \
    <<< "$BAZEL_OUTPUTS_DSYM"
fi
