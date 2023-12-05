# Compiler build settings generator

The `target_build_settings` generator calculates some build settings (e.g.
`DEBUG_INFORMATION_FORMAT`, `OTHER_CFLAGS`, `OTHER_SWIFT_FLAGS`,
`SWIFT_COMPILATION_MODE`, etc.) for a target and write them to a file. It also
calculates the Swift debug settings for a target and write them to a file.

## Inputs

The generator accepts the following command-line arguments:

- Positional `colorize`
- Positional `build-settings-output-path`
- Positional `swift-debug-settings-output-path`
- If `swift-debug-settings-output-path` is set: positional `include-self-swift-debug-settings`
- If `swift-debug-settings-output-path` is set: positional `transitive-swift-debug-setting-paths-count`
- If `swift-debug-settings-output-path` is set: positional list `<transitive-swift-debug-setting-paths> ...`
- Positional `device-family`
- Positional `extension-safe`
- Positional `generates-dsyms`
- Positional `info-plist`
- Positional `entitlements`
- Positional `certificate-name`
- Positional `provisioning-profile-name`
- Positional `team-id`
- Positional `provisioning-profile-is-xcode-managed`
- Positional `package-bin-dir`
- Positional `preview-framework-paths`
- Positional `previews-include-path`
- The command-line arguments for a Bazel `SwiftCompile`
action
- `---` to signify the end of the Swift arguments
- Positional `c-params-output-path`
- The command-line arguments for a C/Objective-C `CppCompile`/`ObjcCompile` action
- `---` to signify the end of the C arguments
- Positional `cxx-params-output-path`
- The command-line arguments for a
C++/Objective-C++ `CppCompile`/`ObjcCompile` action

Here is an example invocation:

```shell
$ target_build_settings \
    0 \
    /tmp/pbxproj_partials/target_build_settings \
    /tmp/pbxproj_partials/swift_debug_settings \
    1 \
    2 \
    /tmp/pbxproj_partials/transitive_swift_debug_settings_0 \
    /tmp/pbxproj_partials/transitive_swift_debug_settings_1 \
    4 \
    0 \
    1 \
    bazel-out/generated/Info.plist \
    project/level/app.entitlements \
    '' \
    '' \
    '' \
    0 \
    bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib \
    '' \
    '' \
    -target \
    arm64_32-apple-watchos7.0 \
    -sdk \
    __BAZEL_XCODE_SDKROOT__ \
    -debug-prefix-map \
    __BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR \
    -file-prefix-map \
    __BAZEL_XCODE_DEVELOPER_DIR__=DEVELOPER_DIR \
    -emit-object \
    -output-file-map \
    bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/Lib.output_file_map.json \
    -Xfrontend \
    -no-clang-module-breadcrumbs \
    -swift-version \
    4.2 \
    -emit-module-path \
    bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/Lib.swiftmodule \
    -emit-objc-header-path \
    bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/generated/Lib-Swift.h \
    -enable-bare-slash-regex \
    -DNDEBUG \
    -O \
    -whole-module-optimization \
    -Xfrontend \
    -no-serialize-debugging-options \
    -g \
    -Xwrapped-swift=-debug-prefix-pwd-is-dot \
    -Xwrapped-swift=-file-prefix-pwd-is-dot \
    -module-cache-path \
    bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/_swift_module_cache \
    -Fexternal/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k \
    -Xcc \
    -Fexternal/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k \
    -Xcc \
    -iquoteexternal/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift \
    -Xcc \
    -iquotebazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift \
    -Xcc \
    -iquote. \
    -Xcc \
    -iquotebazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin \
    -Xcc \
    -fmodule-map-file=external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap \
    -Xfrontend \
    -color-diagnostics \
    -num-threads \
    12 \
    -module-name \
    Lib \
    -Xwrapped-swift=-global-index-store-import-path=bazel-out/_global_index_store \
    -index-store-path \
    bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/Lib.indexstore \
    -Xfrontend \
    -disable-autolink-framework \
    -Xfrontend \
    CryptoSwift \
    -Xfrontend \
    -vfsoverlay \
    -Xfrontend \
    project/relative/overlay.yaml \
    -Xcc \
    -ivfsoverlay=external/overlay.yaml \
    -vfsoverlay \
    bazel-out/generated/overlay.yaml \
    -Xfrontend \
    -explicit-swift-module-map-file \
    -Xfrontend \
    bazel-out/generated/map.json \
    -Xfrontend \
    -load-plugin-executable \
    -Xfrontend \
    bazel-out/generated/macro \
    -parse-as-library \
    -application-extension \
    -static \
    -Xcc \
    -Os \
    -Xcc \
    -DNDEBUG=1 \
    -Xcc \
    -Wno-unused-variable \
    -Xcc \
    -Winit-self \
    -Xcc \
    -Wno-extra \
    Lib/Resources.swift \
    bazel-out/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-opt-ST-c58d72818890/bin/Lib/Lib.swift \
    --- \
    /tmp/pbxproj_partials/c.compile.params \
    -Os \
    -ivfsoverlay=external/overlay.yaml \
    --config \
    some.cfg \
    --- \
    /tmp/pbxproj_partials/cxx.compile.params \
    -Os \
    -D_FORTIFY_SOURCE=2 \
    -ivfsoverlay \
    bazel-out/generated/overlay.yaml
```

## Output

Here is an example output:

### `target_build_settings`

```
OTHER_SWIFT_FLAGS	"-Xcc -working-directory -Xcc $(PROJECT_DIR) -working-directory $(PROJECT_DIR) -Xcc -ivfsoverlay$(OBJROOT)/bazel-out-overlay.yaml -vfsoverlay $(OBJROOT)/bazel-out-overlay.yaml -DNDEBUG -O -I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_apple_swift_argument_parser -I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/tools/lib/ToolCommon -I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_apple_swift_collections -I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_kylef_pathkit -I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjson -I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_tadija_aexml -I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_tuist_xcodeproj -Xcc -I -Xcc $(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter/Sources/JJLISO8601DateFormatter/include -Xcc -I -Xcc $(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter/Sources/JJLISO8601DateFormatter/include -Xcc -I -Xcc $(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily/Sources/ZippyJSONCFamily/include -Xcc -I -Xcc $(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily/Sources/ZippyJSONCFamily/include -Xcc -iquote -Xcc $(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter -Xcc -iquote -Xcc $(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter -Xcc -iquote -Xcc $(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily -Xcc -iquote -Xcc $(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily -Xcc -iquote -Xcc $(PROJECT_DIR) -Xcc -iquote -Xcc $(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin -Xcc -fmodule-map-file=$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter/JJLISO8601DateFormatter.swift.modulemap -Xcc -fmodule-map-file=$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily/ZippyJSONCFamily.swift.modulemap -static -Xcc -Os -Xcc -DNDEBUG=1 -Xcc -Wno-unused-variable -Xcc -Winit-self -Xcc -Wno-extra"
SWIFT_COMPILATION_MODE	wholemodule

```

### `swift_debug_settings`

```
69
-I$(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter/Sources/JJLISO8601DateFormatter/include
-I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter/Sources/JJLISO8601DateFormatter/include
-I$(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily/Sources/ZippyJSONCFamily/include
-I$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily/Sources/ZippyJSONCFamily/include
-iquote$(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter
-iquote$(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-fmodule-map-file=$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter/JJLISO8601DateFormatter.swift.modulemap
-fmodule-map-file=$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily/ZippyJSONCFamily.swift.modulemap
-Os
-DNDEBUG=1
-Wno-unused-variable
-Winit-self
-Wno-extra
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-Os
-Wno-unused-variable
-Winit-self
-Wno-extra
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-Os
-Wno-unused-variable
-Winit-self
-Wno-extra
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-Os
-Wno-unused-variable
-Winit-self
-Wno-extra
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-Os
-Wno-unused-variable
-Winit-self
-Wno-extra
-iquote$(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_jjliso8601dateformatter
-iquote$(BAZEL_EXTERNAL)/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjsoncfamily
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-Os
-Wno-unused-variable
-Winit-self
-Wno-extra
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-Os
-Wno-unused-variable
-Winit-self
-Wno-extra
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-Os
-Wno-unused-variable
-Winit-self
-Wno-extra
-iquote$(PROJECT_DIR)
-iquote$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin
-Os
-Wno-unused-variable
-Winit-self
-Wno-extra
0
7
$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_apple_swift_argument_parser
$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/tools/lib/ToolCommon
$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_apple_swift_collections
$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_kylef_pathkit
$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_michaeleisel_zippyjson
$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_tadija_aexml
$(BAZEL_OUT)/macos-arm64-min12.0-applebin_macos-darwin_arm64-opt-ST-89c7f8a7bb2e/bin/external/_main~non_module_deps~com_github_tuist_xcodeproj

```
