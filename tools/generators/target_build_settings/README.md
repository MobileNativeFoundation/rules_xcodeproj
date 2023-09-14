# Compiler build settings generator

The `target_build_settings` generator calculates some build settings (e.g.
`DEBUG_INFORMATION_FORMAT`, `OTHER_CFLAGS`, `OTHER_SWIFT_FLAGS`,
`SWIFT_COMPILATION_MODE`, etc.) for a target.

## Inputs

The generator accepts the command-line arguments for a Bazel `SwiftCompile`
action, and FIXME.

## Output

Here is an example output:

### `target_build_settings`

```
OTHER_SWIFT_FLAGS	"-Xcc -ivfsoverlay -Xcc $(OBJROOT)/bazel-out-overlay.yaml -vfsoverlay $(OBJROOT)/bazel-out-overlay.yaml -DNDEBUG -O -F$(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k -Xcc -F -Xcc $(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k -Xcc -iquote -Xcc $(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -Xcc -iquote -Xcc $(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -Xcc -iquote -Xcc $(PROJECT_DIR) -Xcc -iquote -Xcc $(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin -Xcc -fmodule-map-file=$(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap -Xfrontend -disable-autolink-framework -Xfrontend CryptoSwift -Xfrontend -vfsoverlay -Xfrontend $(SRCROOT)/project/relative/overlay.yaml -Xcc -ivfsoverlay$(BAZEL_EXTERNAL)/overlay.yaml -vfsoverlay $(BAZEL_OUT)/generated/overlay.yaml -Xfrontend -explicit-swift-module-map-file -Xfrontend $(BAZEL_OUT)/generated/map.json -Xfrontend -load-plugin-executable -Xfrontend $(BAZEL_OUT)/generated/macro -application-extension -static -Xcc -Os -Xcc -DNDEBUG=1 -Xcc -Wno-unused-variable -Xcc -Winit-self -Xcc -Wno-extra"
SWIFT_COMPILATION_MODE	wholemodule
SWIFT_OBJC_INTERFACE_HEADER_NAME	"generated/Lib-Swift.h"
SWIFT_VERSION	4.2

```
