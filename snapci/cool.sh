#!/usr/bin/env bash

set -xeuo pipefail

export CI=true

source $(dirname $BASH_SOURCE)/utils.sh

echo "Getting commit SHA"
git_sha=$(git rev-parse --short HEAD) || exit 1

build_and_test || post_comment "Build or test failed!"

ARCHIVE_SHA=$(cat bazel-output-base/execroot/rules_xcodeproj/bazel-out/darwin-opt/bin/distribution/release.tar.gz.sha256 | cut -d ' ' -f 1)
GCS_DIR_NAME="snapengine-maven-publish/bazel-releases/rules/rules_xcodeproj/${BUILD_NUMBER}-${git_sha}/${ARCHIVE_SHA}-release.tar.gz"
GCS_URL="gs://${GCS_DIR_NAME}"
HTTP_URL="https://storage.googleapis.com/${GCS_DIR_NAME}"

echo "Uploading rules_xcodeproj to GCS..."
gsutil cp bazel-output-base/execroot/rules_xcodeproj/bazel-out/darwin-opt/bin/distribution/release.tar.gz "$GCS_URL"

echo "Posting PR Comment..."
escaped_url=$(escape_sashes "${HTTP_URL}")
comment="Rules published:\r\n sha256 = ${ARCHIVE_SHA} \r\n url = ${escaped_url}"

post_comment "$comment"
