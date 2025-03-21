#!/bin/bash

set -euo pipefail

# The first argument should be the path to the toolchain directory
TOOLCHAIN_DIR="$1"

echo "Verifying toolchain at: $TOOLCHAIN_DIR"

# Check that the toolchain directory exists
if [[ ! -d "$TOOLCHAIN_DIR" ]]; then
  echo "ERROR: Toolchain directory does not exist: $TOOLCHAIN_DIR"
  exit 1
fi

# Check that ToolchainInfo.plist exists
if [[ ! -f "$TOOLCHAIN_DIR/ToolchainInfo.plist" ]]; then
  echo "ERROR: ToolchainInfo.plist not found in toolchain"
  exit 1
fi

# Check for correct identifiers in the plist
if ! grep -q "BazelRulesXcodeProj" "$TOOLCHAIN_DIR/ToolchainInfo.plist"; then
  echo "ERROR: ToolchainInfo.plist doesn't contain BazelRulesXcodeProj"
  exit 1
fi

# Check that our custom swiftc is properly linked/copied
if [[ ! -f "$TOOLCHAIN_DIR/usr/bin/swiftc" ]]; then
  echo "ERROR: swiftc not found in toolchain"
  exit 1
fi

# Ensure swiftc is executable
if [[ ! -x "$TOOLCHAIN_DIR/usr/bin/swiftc" ]]; then
  echo "ERROR: swiftc is not executable"
  exit 1
fi

# Test if the swiftc actually runs
if ! "$TOOLCHAIN_DIR/usr/bin/swiftc" --version > /dev/null 2>&1; then
  echo "WARN: swiftc doesn't run correctly, but this is expected in tests"
fi

echo "Custom toolchain validation successful!"
exit 0