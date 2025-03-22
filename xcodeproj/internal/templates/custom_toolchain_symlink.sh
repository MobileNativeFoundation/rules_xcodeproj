#!/bin/bash
set -euo pipefail

# Define constants within the script
TOOLCHAIN_NAME_BASE="%toolchain_name_base%"
TOOLCHAIN_DIR="%toolchain_dir%"
XCODE_VERSION="%xcode_version%"

# Get Xcode version and default toolchain path
DEFAULT_TOOLCHAIN=$(xcrun --find clang | sed 's|/usr/bin/clang$||')
XCODE_RAW_VERSION=$(xcodebuild -version | head -n 1)

# Define toolchain names
HOME_TOOLCHAIN_NAME="BazelRulesXcodeProj${XCODE_VERSION}"
USER_TOOLCHAIN_PATH="/Users/$(id -un)/Library/Developer/Toolchains/${HOME_TOOLCHAIN_NAME}.xctoolchain"
BUILT_TOOLCHAIN_PATH="$PWD/$TOOLCHAIN_DIR"

mkdir -p "$TOOLCHAIN_DIR"

# Parse overrides into a file for safer processing
OVERRIDES_FILE=$(mktemp)
echo "%overrides_list%" > "$OVERRIDES_FILE"

# Process all files from the default toolchain
find "$DEFAULT_TOOLCHAIN" -type f -o -type l | while read -r file; do
    base_name="$(basename "$file")"
    rel_path="${file#"$DEFAULT_TOOLCHAIN/"}"

    # Skip ToolchainInfo.plist as we'll create our own
    if [[ "$rel_path" == "ToolchainInfo.plist" ]]; then
        continue
    fi

    # Ensure parent directory exists
    mkdir -p "$TOOLCHAIN_DIR/$(dirname "$rel_path")"

    # Check if this file has an override
    override_found=false
    override_value=""

    for override in $(cat "$OVERRIDES_FILE"); do
        KEY="${override%%=*}"
        VALUE="${override#*=}"

        if [[ "$KEY" == "$base_name" ]]; then
            override_value="$VALUE"
            override_found=true
            break
        fi
    done

    # Apply the override or create symlink
    if [[ "$override_found" == "true" ]]; then
        # Make path absolute
        override_path="$PWD/$override_value"
        cp "$override_path" "$TOOLCHAIN_DIR/$rel_path"

        # Make executable if original is executable
        if [[ -x "$file" ]]; then
            chmod +x "$TOOLCHAIN_DIR/$rel_path"
        fi
    else
        # If no override found, symlink the original
        ln -sf "$file" "$TOOLCHAIN_DIR/$rel_path"
    fi
done

# Clean up
rm -f "$OVERRIDES_FILE"

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
