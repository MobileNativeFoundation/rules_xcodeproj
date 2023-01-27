#!/bin/bash

set -euo pipefail

cd "$BUILD_WORKSPACE_DIRECTORY"

# Go to parent directory and create a release archive
echo
echo "Changing to parent directory"
pushd "../../" > /dev/null
echo "Building release.tar.gz"
echo
bazel --output_base=setup-bazel-output-base build //distribution:release

archive_path="$(bazel --output_base=setup-bazel-output-base info output_path)/darwin_arm64-opt/bin/distribution/release.tar.gz"
integrity="sha256-$(cut -d' ' -f 1 $archive_path.sha256 | xxd -r -p | openssl base64 -A)"

echo
echo "archive_path: $archive_path"
echo "integrity: $integrity"

# Adjust MODULE.bazel to point to the release archive
echo
echo "Changing back to root directory"
popd > /dev/null

echo "Adjusting MODULE.bazel to point to release.tar.gz"
perl -i -p0e \
  "s|local_path_override\(\s*module_name = \"rules_xcodeproj\",\n\s*path.*|archive_override(\n    module_name = \"rules_xcodeproj\",\n    integrity = \"$integrity\",\n    urls = [\"file://$archive_path\"],|" \
  MODULE.bazel
