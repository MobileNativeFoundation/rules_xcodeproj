#!/bin/bash

# Tests `assemble_project_pbxproj.sh`.

set -euo pipefail

readonly script="$1"

tmp="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/assemble.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

T=$'\t'

# Partials, with objects of the same `isa` spread across them, out of order,
# and the `PBXProject` written in parts with unsorted attributes

cat > "$tmp/prefix" <<EOF
// !\$*UTF8*\$!
{
${T}archiveVersion = 1;
${T}classes = {
${T}};
${T}objectVersion = 70;
${T}objects = {
${T}${T}FF0000000000000000000002 /* Build configuration list for PBXProject "P" */ = {
${T}${T}${T}isa = XCConfigurationList;
${T}${T}${T}buildConfigurations = (
${T}${T}${T}${T}FF0000000000000000000100 /* Debug */,
${T}${T}${T});
${T}${T}${T}defaultConfigurationIsVisible = 0;
${T}${T}${T}defaultConfigurationName = Debug;
${T}${T}};
${T}${T}FF0000000000000000000001 /* Project object */ = {
${T}${T}${T}isa = PBXProject;
${T}${T}${T}buildConfigurationList = FF0000000000000000000002 /* Build configuration list for PBXProject "P" */;
${T}${T}${T}mainGroup = FF0000000000000000000003 /* main */;
${T}${T}${T}attributes = {
${T}${T}${T}${T}LastUpgradeCheck = 9999;
EOF

cat > "$tmp/target_attributes" <<EOF
${T}${T}${T}${T}TargetAttributes = {
${T}${T}${T}${T}};
${T}${T}${T}};
EOF

cat > "$tmp/known_regions" <<EOF
${T}${T}${T}knownRegions = (
${T}${T}${T}${T}en,
${T}${T}${T});
EOF

cat > "$tmp/targets" <<EOF
${T}${T}${T}targets = (
${T}${T}${T});
${T}${T}};
${T}${T}FE00000000000000000000B2 /* b.swift in Sources */ = {isa = PBXBuildFile; fileRef = FE00000000000000000000F2 /* b.swift */; };
${T}${T}FF0000000000000000000100 /* Debug */ = {
${T}${T}${T}isa = XCBuildConfiguration;
${T}${T}${T}buildSettings = {
${T}${T}${T}${T}B = 1;
${T}${T}${T}};
${T}${T}${T}name = Debug;
${T}${T}};

${T}${T}FE00000000000000000000B1 /* a.swift in Sources */ = {isa = PBXBuildFile; fileRef = FE00000000000000000000F1 /* a.swift */; };
EOF

cat > "$tmp/files_and_groups" <<EOF
${T}${T}FE00000000000000000000F2 /* b.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = b.swift; sourceTree = "<group>"; };
${T}${T}FF0000000000000000000003 /* main */ = {
${T}${T}${T}isa = PBXGroup;
${T}${T}${T}children = (
${T}${T}${T}${T}FE00000000000000000000F2 /* b.swift */,
${T}${T}${T}${T}FE00000000000000000000F1 /* a.swift */,
${T}${T}${T});
${T}${T}${T}path = main;
${T}${T}${T}sourceTree = "<group>";
${T}${T}};
${T}${T}FE00000000000000000000F1 /* a.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = a.swift; sourceTree = "<group>"; };
${T}};
${T}rootObject = FF0000000000000000000001 /* Project object */;
}
EOF

cat > "$tmp/expected" <<EOF
// !\$*UTF8*\$!
{
${T}archiveVersion = 1;
${T}classes = {
${T}};
${T}objectVersion = 70;
${T}objects = {

/* Begin PBXBuildFile section */
${T}${T}FE00000000000000000000B1 /* a.swift in Sources */ = {isa = PBXBuildFile; fileRef = FE00000000000000000000F1 /* a.swift */; };
${T}${T}FE00000000000000000000B2 /* b.swift in Sources */ = {isa = PBXBuildFile; fileRef = FE00000000000000000000F2 /* b.swift */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
${T}${T}FE00000000000000000000F1 /* a.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = a.swift; sourceTree = "<group>"; };
${T}${T}FE00000000000000000000F2 /* b.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = b.swift; sourceTree = "<group>"; };
/* End PBXFileReference section */

/* Begin PBXGroup section */
${T}${T}FF0000000000000000000003 /* main */ = {
${T}${T}${T}isa = PBXGroup;
${T}${T}${T}children = (
${T}${T}${T}${T}FE00000000000000000000F2 /* b.swift */,
${T}${T}${T}${T}FE00000000000000000000F1 /* a.swift */,
${T}${T}${T});
${T}${T}${T}path = main;
${T}${T}${T}sourceTree = "<group>";
${T}${T}};
/* End PBXGroup section */

/* Begin PBXProject section */
${T}${T}FF0000000000000000000001 /* Project object */ = {
${T}${T}${T}isa = PBXProject;
${T}${T}${T}attributes = {
${T}${T}${T}${T}LastUpgradeCheck = 9999;
${T}${T}${T}${T}TargetAttributes = {
${T}${T}${T}${T}};
${T}${T}${T}};
${T}${T}${T}buildConfigurationList = FF0000000000000000000002 /* Build configuration list for PBXProject "P" */;
${T}${T}${T}knownRegions = (
${T}${T}${T}${T}en,
${T}${T}${T});
${T}${T}${T}mainGroup = FF0000000000000000000003 /* main */;
${T}${T}${T}targets = (
${T}${T}${T});
${T}${T}};
/* End PBXProject section */

/* Begin XCBuildConfiguration section */
${T}${T}FF0000000000000000000100 /* Debug */ = {
${T}${T}${T}isa = XCBuildConfiguration;
${T}${T}${T}buildSettings = {
${T}${T}${T}${T}B = 1;
${T}${T}${T}};
${T}${T}${T}name = Debug;
${T}${T}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
${T}${T}FF0000000000000000000002 /* Build configuration list for PBXProject "P" */ = {
${T}${T}${T}isa = XCConfigurationList;
${T}${T}${T}buildConfigurations = (
${T}${T}${T}${T}FF0000000000000000000100 /* Debug */,
${T}${T}${T});
${T}${T}${T}defaultConfigurationIsVisible = 0;
${T}${T}${T}defaultConfigurationName = Debug;
${T}${T}};
/* End XCConfigurationList section */
${T}};
${T}rootObject = FF0000000000000000000001 /* Project object */;
}
EOF

printf '%s\n' \
  "$tmp/prefix" \
  "$tmp/target_attributes" \
  "$tmp/known_regions" \
  "$tmp/targets" \
  "$tmp/files_and_groups" \
  > "$tmp/inputs"

/bin/bash "$script" "$tmp/output" "$tmp/inputs"

if ! diff -u "$tmp/expected" "$tmp/output"; then
  echo "FAIL: Assembled project.pbxproj differs from expected" >&2
  exit 1
fi

# Assembling an already assembled file doesn't change it

echo "$tmp/output" > "$tmp/inputs2"
/bin/bash "$script" "$tmp/output2" "$tmp/inputs2"

if ! diff -u "$tmp/expected" "$tmp/output2"; then
  echo "FAIL: Assembling isn't idempotent" >&2
  exit 1
fi

# Malformed partials fail

cat > "$tmp/malformed" <<EOF
{
${T}objects = {
${T}${T}FF0000000000000000000003 /* main */ = {
${T}${T}${T}path = main;
${T}${T}};
${T}};
}
EOF
echo "$tmp/malformed" > "$tmp/inputs3"

if /bin/bash "$script" "$tmp/output3" "$tmp/inputs3" 2>/dev/null; then
  echo "FAIL: Malformed partials (isa not first) didn't fail" >&2
  exit 1
fi

echo "PASS"
