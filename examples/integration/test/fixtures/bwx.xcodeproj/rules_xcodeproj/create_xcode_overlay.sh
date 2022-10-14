#!/bin/bash

if [[ "${BAZEL_OUT:0:1}" == '/' ]]; then
  readonly bazel_out_prefix=
else
  readonly bazel_out_prefix="$SRCROOT/"
fi

# Look up Swift generated headers in `$BUILD_DIR` first, then fall through to
# `$BAZEL_OUT`
cat > "$DERIVED_FILE_DIR/xcode-overlay.yaml" <<EOF
{"case-sensitive": "false", "fallthrough": true, "roots": [{"external-contents": "$BUILD_DIR/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-7aac51e4b353/bin/iOSApp/Test/TestingUtils/SwiftAPI/TestingUtils-Swift.h","name": "${bazel_out_prefix}$BAZEL_OUT/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-7aac51e4b353/bin/iOSApp/Test/TestingUtils/SwiftAPI/TestingUtils-Swift.h","type": "file"},{"external-contents": "$BUILD_DIR/bazel-out/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-7ab8ee5d0803/bin/CommandLine/CommandLineToolLib/private/LibSwift-Swift.h","name": "${bazel_out_prefix}$BAZEL_OUT/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-7ab8ee5d0803/bin/CommandLine/CommandLineToolLib/private/LibSwift-Swift.h","type": "file"}],"version": 0}
EOF
