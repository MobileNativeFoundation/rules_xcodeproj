#!/bin/bash

# Look up Swift generated headers in `$BUILD_DIR` first, then fall through to
# `$BAZEL_OUT`
# `${bazel_out_prefix}` comes from sourcing script
cat > "$OBJROOT/xcode-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [{"external-contents": "$BUILD_DIR/bazel-out/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-7ab8ee5d0803/bin/CommandLine/CommandLineToolLib/private/LibSwift-Swift.h","name": "${bazel_out_prefix}$BAZEL_OUT/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-7ab8ee5d0803/bin/CommandLine/CommandLineToolLib/private/LibSwift-Swift.h","type": "file"}],"version": 0}
EOF
