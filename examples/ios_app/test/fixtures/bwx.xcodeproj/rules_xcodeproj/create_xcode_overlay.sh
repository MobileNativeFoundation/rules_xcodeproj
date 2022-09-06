#!/bin/bash

# Look up Swift generated headers in `$BUILD_DIR` first, then fall through to
# `$BAZEL_OUT`
# `${bazel_out_prefix}` comes from sourcing script
cat > "$OBJROOT/xcode-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [{"external-contents": "$BUILD_DIR/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-7aac51e4b353/bin/TestingUtils/SwiftAPI/TestingUtils-Swift.h","name": "${bazel_out_prefix}$BAZEL_OUT/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-7aac51e4b353/bin/TestingUtils/SwiftAPI/TestingUtils-Swift.h","type": "file"}],"version": 0}
EOF
