#!/usr/bin/python3

"""An lldb module that registers a stop hook to set swift settings."""

import lldb

_BUNDLE_EXTENSIONS = [
    ".app",
    ".appex",
    ".bundle",
    ".framework",
    ".xctest",
]

_SETTINGS = {
  "arm64_32-apple-watchos7.0.0 watchOSAppExtension.appex/watchOSAppExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-3f6925aafe90/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-3f6925aafe90/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-3f6925aafe90/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-3f6925aafe90/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-3f6925aafe90/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-3f6925aafe90/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k"
    ],
    "includes" : [
      "$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-3f6925aafe90/bin/UI",
      "$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-3f6925aafe90/bin/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 AppClip.app/AppClip" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 iOSApp.app/iOSApp_ExecutableName" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -iquote \"$(BAZEL_EXTERNAL)/com_google_google_maps\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_google_google_maps\" -I \"$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC\" -I \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/iOSApp/Source/CoreUtilsObjC\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64/GoogleMapsBase.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64/GoogleMapsCore.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMaps.xcframework/ios-arm64/GoogleMaps.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64",
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64",
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMaps.xcframework/ios-arm64",
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/UI",
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 UIFramework.iOS.framework/UIFramework.iOS" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 WidgetExtension.appex/WidgetExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-b625d7c0bd00/bin/Lib"
    ]
  },
  "arm64-apple-tvos15.0.0 LibFramework.tvOS.framework/LibFramework.tvOS" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64"
    ],
    "includes" : [

    ]
  },
  "arm64-apple-tvos15.0.0 tvOSApp.app/tvOSApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64"
    ],
    "includes" : [
      "$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/UI",
      "$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/Lib"
    ]
  },
  "arm64-apple-tvos15.0.0 UIFramework.tvOS.framework/UIFramework.tvOS" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64"
    ],
    "includes" : [
      "$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-70b4e492b765/bin/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator AppClip.app/AppClip" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator iMessageAppExtension.appex/iMessageAppExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator iOSApp.app/iOSApp_ExecutableName" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -iquote \"$(BAZEL_EXTERNAL)/com_google_google_maps\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_google_google_maps\" -I \"$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC\" -I \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/iOSApp/Source/CoreUtilsObjC\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator/GoogleMapsBase.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator/GoogleMapsCore.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator/GoogleMaps.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator",
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator",
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator",
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/UI",
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator UIFramework.iOS.framework/UIFramework.iOS" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator WidgetExtension.appex/WidgetExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-9fcfb6a7af56/bin/Lib"
    ]
  },
  "x86_64-apple-macosx11.0.0 CommandLineTool" : {
    "clang" : "-iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin\" -iquote \"$(BAZEL_EXTERNAL)/examples_command_line_external\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/external/examples_command_line_external\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/CommandLine/CommandLineToolLib/lib_impl.swift.modulemap\" -fmodule-map-file=\"$(PROJECT_DIR)/CommandLine/swift_c_module/c_lib.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/examples_command_line_external/ExternalFramework.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/external/examples_command_line_external/Library.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/CommandLine/CommandLineToolLib/private_lib.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -DSECRET_3=\\\"Hello\\\" -DSECRET_2=\\\"World!\\\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/examples_command_line_external"
    ],
    "includes" : [
      "$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/CommandLine/CommandLineToolLib"
    ]
  },
  "x86_64-apple-macosx11.0.0 CommandLineToolTests.xctest/Contents/MacOS/CommandLineToolTests" : {
    "clang" : "-iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin\" -iquote \"$(BAZEL_EXTERNAL)/examples_command_line_external\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/external/examples_command_line_external\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/CommandLine/CommandLineToolLib/lib_impl.swift.modulemap\" -fmodule-map-file=\"$(PROJECT_DIR)/CommandLine/swift_c_module/c_lib.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/examples_command_line_external/ExternalFramework.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/external/examples_command_line_external/Library.swift.modulemap\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/CommandLine/CommandLineToolLib/lib_swift.swift.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -DSECRET_3=\\\"Hello\\\" -DSECRET_2=\\\"World!\\\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin\" -iquote \"$(BAZEL_EXTERNAL)/examples_command_line_external\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/external/examples_command_line_external\" -fmodule-map-file=\"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/CommandLine/CommandLineToolLib/private_lib.swift.modulemap\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(PLATFORM_DIR)/Developer/Library/Frameworks",
      "$(SDKROOT)/Developer/Library/Frameworks",
      "$(BAZEL_EXTERNAL)/examples_command_line_external"
    ],
    "includes" : [
      "$(PLATFORM_DIR)/Developer/usr/lib",
      "$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-c0ef0a258197/bin/CommandLine/CommandLineToolLib"
    ]
  },
  "x86_64-apple-macosx12.0.0 macOSApp.app/Contents/MacOS/macOSApp" : {
    "clang" : "-iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-e4309a660cc1/bin\" -fmodule-map-file=\"$(PROJECT_DIR)/macOSApp/third_party/ExampleFramework.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(PROJECT_DIR)/macOSApp/third_party"
    ],
    "includes" : [

    ]
  },
  "x86_64-apple-macosx12.0.0 macOSAppUITests.xctest/Contents/MacOS/macOSAppUITests" : {
    "clang" : "-iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min12.0-applebin_macos-darwin_x86_64-dbg-ST-e4309a660cc1/bin\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(PLATFORM_DIR)/Developer/Library/Frameworks",
      "$(SDKROOT)/Developer/Library/Frameworks"
    ],
    "includes" : [
      "$(PLATFORM_DIR)/Developer/usr/lib"
    ]
  },
  "x86_64-apple-tvos15.0.0-simulator LibFramework.tvOS.framework/LibFramework.tvOS" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
    ],
    "includes" : [

    ]
  },
  "x86_64-apple-tvos15.0.0-simulator tvOSApp.app/tvOSApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/UI",
      "$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/Lib"
    ]
  },
  "x86_64-apple-tvos15.0.0-simulator tvOSAppUITests.xctest/tvOSAppUITests" : {
    "clang" : "-iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(PLATFORM_DIR)/Developer/Library/Frameworks",
      "$(SDKROOT)/Developer/Library/Frameworks"
    ],
    "includes" : [
      "$(PLATFORM_DIR)/Developer/usr/lib"
    ]
  },
  "x86_64-apple-tvos15.0.0-simulator tvOSAppUnitTests.xctest/tvOSAppUnitTests" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(PLATFORM_DIR)/Developer/Library/Frameworks",
      "$(SDKROOT)/Developer/Library/Frameworks",
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
    ],
    "includes" : [
      "$(PLATFORM_DIR)/Developer/usr/lib",
      "$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/tvOSApp/Source",
      "$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/UI",
      "$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/Lib"
    ]
  },
  "x86_64-apple-tvos15.0.0-simulator UIFramework.tvOS.framework/UIFramework.tvOS" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-b6268cc80bf2/bin/Lib"
    ]
  },
  "x86_64-apple-watchos7.0.0-simulator watchOSAppExtension.appex/watchOSAppExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/UI",
      "$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/Lib"
    ]
  },
  "x86_64-apple-watchos7.0.0-simulator watchOSAppExtensionUnitTests.xctest/watchOSAppExtensionUnitTests" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(PLATFORM_DIR)/Developer/Library/Frameworks",
      "$(SDKROOT)/Developer/Library/Frameworks",
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(PLATFORM_DIR)/Developer/usr/lib",
      "$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/UI",
      "$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin/Lib"
    ]
  },
  "x86_64-apple-watchos7.0.0-simulator watchOSAppUITests.xctest/watchOSAppUITests" : {
    "clang" : "-iquote \"$(PROJECT_DIR)\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-25d904fdfd32/bin\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(PLATFORM_DIR)/Developer/Library/Frameworks",
      "$(SDKROOT)/Developer/Library/Frameworks"
    ],
    "includes" : [
      "$(PLATFORM_DIR)/Developer/usr/lib"
    ]
  }
}

def __lldb_init_module(debugger, _internal_dict):
    # Register the stop hook when this module is loaded in lldb
    ci = debugger.GetCommandInterpreter()
    res = lldb.SBCommandReturnObject()
    ci.HandleCommand(
        "target stop-hook add -P swift_debug_settings.StopHook",
        res,
    )
    if not res.Succeeded():
        print(f"""\
Failed to register Swift debug options stop hook:

{res.GetError()}
Please file a bug report here: \
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md
""")
        return

def _get_relative_executable_path(module):
    for extension in _BUNDLE_EXTENSIONS:
        prefix, _, suffix = module.rpartition(extension)
        if prefix:
            return prefix.split("/")[-1] + extension + suffix
    return module.split("/")[-1]

class StopHook:
    "An lldb stop hook class, that sets swift settings for the current module."

    def __init__(self, _target, _extra_args, _internal_dict):
        pass

    def handle_stop(self, exe_ctx, _stream):
        "Method that is called when the user stops in lldb."
        module = exe_ctx.frame.module
        module_name = module.file.__get_fullpath__()
        target_triple = module.GetTriple()
        executable_path = _get_relative_executable_path(module_name)
        key = f"{target_triple} {executable_path}"

        settings = _SETTINGS.get(key)

        if settings:
            frameworks = " ".join([
                f'"{path}"'
                for path in settings["frameworks"]
            ])
            if frameworks:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-framework-search-paths {frameworks}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-framework-search-paths",
                )

            includes = " ".join([
                f'"{path}"'
                for path in settings["includes"]
            ])
            if includes:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-module-search-paths {includes}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-module-search-paths",
                )

            clang = settings["clang"]
            if clang:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-extra-clang-flags '{clang}'",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-extra-clang-flags",
                )

        return True
