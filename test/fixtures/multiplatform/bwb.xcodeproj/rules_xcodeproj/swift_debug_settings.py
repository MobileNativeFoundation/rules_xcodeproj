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
  "arm64_32-apple-watchos7.0.0 watchOSApp.app/watchOSApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k"
    ],
    "includes" : [
      "$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/examples/multiplatform/Lib"
    ]
  },
  "arm64_32-apple-watchos7.0.0 watchOSAppExtension.appex/watchOSAppExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k"
    ],
    "includes" : [
      "$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/examples/multiplatform/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 AppClip.app/AppClip" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/examples/multiplatform/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 iMessageApp.app/iMessageApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/examples/multiplatform/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 iMessageAppExtension.appex/iMessageAppExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/examples/multiplatform/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 iOSApp.app/iOSApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_EXTERNAL)/com_google_google_maps\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_google_google_maps\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64/GoogleMapsBase.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64/GoogleMapsCore.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMaps.xcframework/ios-arm64/GoogleMaps.framework/Modules/module.modulemap\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64",
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64",
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMaps.xcframework/ios-arm64",
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7",
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/examples/multiplatform/Lib",
      "$(BAZEL_OUT)/watchos-arm64_32-min7.0-applebin_watchos-watchos_arm64_32-dbg-ST-01fecab27ffc/bin/examples/multiplatform/Lib"
    ]
  },
  "arm64-apple-ios15.0.0 WidgetExtension.appex/WidgetExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-arm64-min15.0-applebin_ios-ios_arm64-dbg-ST-28ac48b4d0bf/bin/examples/multiplatform/Lib"
    ]
  },
  "arm64-apple-tvos15.0.0 tvOSApp.app/tvOSApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-d6d3bf2233f2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-d6d3bf2233f2/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-d6d3bf2233f2/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-d6d3bf2233f2/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64"
    ],
    "includes" : [
      "$(BAZEL_OUT)/tvos-arm64-min15.0-applebin_tvos-tvos_arm64-dbg-ST-d6d3bf2233f2/bin/examples/multiplatform/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator AppClip.app/AppClip" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/examples/multiplatform/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator iMessageApp.app/iMessageApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/examples/multiplatform/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator iMessageAppExtension.appex/iMessageAppExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/examples/multiplatform/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator iOSApp.app/iOSApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_EXTERNAL)/com_google_google_maps\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_google_google_maps\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator/GoogleMapsBase.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator/GoogleMapsCore.framework/Modules/module.modulemap\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator/GoogleMaps.framework/Modules/module.modulemap\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator",
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator",
      "$(BAZEL_EXTERNAL)/com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator",
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator",
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/examples/multiplatform/Lib",
      "$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/examples/multiplatform/Lib"
    ]
  },
  "x86_64-apple-ios15.0.0-simulator WidgetExtension.appex/WidgetExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-ST-e7c08a7bb9db/bin/examples/multiplatform/Lib"
    ]
  },
  "x86_64-apple-macosx11.0.0 Tool" : {
    "clang" : "-iquote \".\" -iquote \"$(BAZEL_OUT)/macos-x86_64-min11.0-applebin_macos-darwin_x86_64-dbg-ST-01f14ffe769b/bin\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
    "frameworks" : [

    ],
    "includes" : [

    ]
  },
  "x86_64-apple-tvos15.0.0-simulator tvOSApp.app/tvOSApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-ae85ff5caa67/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-ae85ff5caa67/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-ae85ff5caa67/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-ae85ff5caa67/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/tvos-x86_64-min15.0-applebin_tvos-tvos_x86_64-dbg-ST-ae85ff5caa67/bin/examples/multiplatform/Lib"
    ]
  },
  "x86_64-apple-watchos7.0.0-simulator watchOSApp.app/watchOSApp" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/examples/multiplatform/Lib"
    ]
  },
  "x86_64-apple-watchos7.0.0-simulator watchOSAppExtension.appex/watchOSAppExtension" : {
    "clang" : "-iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin\" -fmodule-map-file=\"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap\" -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote \"$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/external/com_github_krzyzanowskim_cryptoswift\" -iquote \".\" -iquote \"$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin\" -O0 -fstack-protector -fstack-protector-all",
    "frameworks" : [
      "$(BAZEL_EXTERNAL)/com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
    ],
    "includes" : [
      "$(BAZEL_OUT)/watchos-x86_64-min7.0-applebin_watchos-watchos_x86_64-dbg-ST-2fd25852cc8a/bin/examples/multiplatform/Lib"
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
https://github.com/buildbuddy-io/rules_xcodeproj/issues/new?template=bug.md.
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
