#!/bin/bash
set -euo pipefail

# Define constants within the script
TOOLCHAIN_NAME_BASE="%toolchain_name_base%"
TOOLCHAIN_DIR="%toolchain_dir%"
XCODE_VERSION="%xcode_version%"

# Get Xcode version and default toolchain path
DEFAULT_TOOLCHAIN=$(xcrun --find clang | sed 's|/usr/bin/clang$||')
XCODE_RAW_VERSION=$(xcodebuild -version | head -n 1)

TOOL_NAMES_FILE=$(mktemp)
echo "%tool_names_list%" > "$TOOL_NAMES_FILE"

HOME_TOOLCHAIN_NAME="BazelRulesXcodeProj${XCODE_VERSION}"
USER_TOOLCHAIN_PATH="/Users/$(id -un)/Library/Developer/Toolchains/${HOME_TOOLCHAIN_NAME}.xctoolchain"
BUILT_TOOLCHAIN_PATH="$PWD/$TOOLCHAIN_DIR"

mkdir -p "$TOOLCHAIN_DIR"

# Process all files from the default toolchain
find "$DEFAULT_TOOLCHAIN" -type f -o -type l | while read -r file; do
    rel_path="${file#"$DEFAULT_TOOLCHAIN/"}"
    base_name=$(basename "$rel_path")

    # Skip ToolchainInfo.plist as we'll create our own
    if [[ "$rel_path" == "ToolchainInfo.plist" ]]; then
        continue
    fi

    # Check if this file is in the list of tools to be overridden
    should_skip=0
    for tool_name in $(cat "$TOOL_NAMES_FILE"); do
        if [[ "$base_name" == "$tool_name" ]]; then
            # Skip creating a symlink for overridden tools
            should_skip=1
            break
        fi
    done

    if [[ $should_skip -eq 1 ]]; then
        continue
    fi

    # Ensure parent directory exists
    mkdir -p "$TOOLCHAIN_DIR/$(dirname "$rel_path")"

    # Create symlink to the original file
    ln -sf "$file" "$TOOLCHAIN_DIR/$rel_path"
done

# Generate the ToolchainInfo.plist directly with Xcode version information
cat > "$TOOLCHAIN_DIR/ToolchainInfo.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Aliases</key>
    <array>
      <string>${HOME_TOOLCHAIN_NAME}</string>
    </array>
    <key>CFBundleIdentifier</key>
    <string>com.rules_xcodeproj.BazelRulesXcodeProj.${XCODE_VERSION}</string>
    <key>CompatibilityVersion</key>
    <integer>2</integer>
    <key>CompatibilityVersionDisplayString</key>
    <string>${XCODE_RAW_VERSION}</string>
    <key>DisplayName</key>
    <string>${HOME_TOOLCHAIN_NAME}</string>
    <key>ReportProblemURL</key>
    <string>https://github.com/MobileNativeFoundation/rules_xcodeproj</string>
    <key>ShortDisplayName</key>
    <string>${HOME_TOOLCHAIN_NAME}</string>
    <key>Version</key>
    <string>0.1.0</string>
  </dict>
</plist>
EOF

mkdir -p "$(dirname "$USER_TOOLCHAIN_PATH")"
if [[ -e "$USER_TOOLCHAIN_PATH" || -L "$USER_TOOLCHAIN_PATH" ]]; then
    rm -rf "$USER_TOOLCHAIN_PATH"
fi
ln -sf "$BUILT_TOOLCHAIN_PATH" "$USER_TOOLCHAIN_PATH"
