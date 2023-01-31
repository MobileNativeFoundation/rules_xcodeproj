#!/bin/bash

set -euo pipefail

if [[ -n "${BAZEL_OUTPUTS_DSYM:-}" ]]; then
  cd "${BAZEL_OUT%/*}"

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
fi
