#!/bin/bash

if [[ "${BAZEL_OUT:0:1}" == '/' ]]; then
  readonly bazel_out_prefix=
else
  readonly bazel_out_prefix="$SRCROOT/"
fi

# Look up Swift generated headers in `$BUILD_DIR` first, then fall through to
# `$BAZEL_OUT`
cat > "$DERIVED_FILE_DIR/xcode-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [%roots%],"version": 0}
EOF
