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

  # NOTE: use `which` to find the path to `rsync`.
  # In macOS 15.4, the system `rsync` is using `openrsync` which contains some permission issues.
  # This allows users to workaround the issue by overriding the system `rsync` with a working version.
  # Remove this once we no longer support macOS versions with broken `rsync`.
  # shellcheck disable=SC2046
  PATH="/opt/homebrew/bin:/usr/local/bin:$PATH" \
    rsync \
    --copy-links \
    --recursive \
    --times \
    --archive \
    --delete \
    ${exclude_list:+--exclude-from="$exclude_list"} \
    --perms \
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
