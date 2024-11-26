#!/usr/bin/python3

"""An lldb module that registers a stop hook to set swift settings."""

import lldb
import re

# Order matters, it needs to be from the most nested to the least
_BUNDLE_EXTENSIONS = [
    ".framework",
    ".xctest",
    ".appex",
    ".bundle",
    ".app",
]

_TRIPLE_MATCH = re.compile(r"([^-]+-[^-]+)(-\D+)[^-]*(-.*)?")

_SETTINGS = {
	"arm64-apple-ios AppClip.app/AppClip": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib"
		]
	},
	"arm64-apple-ios ExtensionKitExtension.appex/ExtensionKitExtension": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all"
	},
	"arm64-apple-ios Lib.framework/Lib": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
		]
	},
	"arm64-apple-ios UIFramework.iOS.framework/UIFramework.iOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib"
		]
	},
	"arm64-apple-ios WidgetExtension.appex/WidgetExtension": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib"
		]
	},
	"arm64-apple-ios iOSApp.app/iOSApp": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64 -I$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC -I$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsObjC -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_google_google_maps -DNEEDS_QUOTES=Two\\ words -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap-module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64/GoogleMapsBase.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64/GoogleMapsCore.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64/GoogleMaps.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib/UndesiredSchemes",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer"
		]
	},
	"arm64-apple-ios iOSAppObjCUnitTests.xctest/iOSAppObjCUnitTests": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64 -I$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC -I$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsObjC -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_google_google_maps -DNEEDS_QUOTES=Two\\ words -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap-module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64/GoogleMapsBase.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64/GoogleMapsCore.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64/GoogleMaps.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64",
			"$(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib/UndesiredSchemes",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/usr/lib"
		]
	},
	"arm64-apple-ios iOSAppSwiftUnitTests.xctest/iOSAppSwiftUnitTests": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64 -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64 -I$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC -I$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsObjC -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/external/_main~non_module_deps~FXPageControl -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~FXPageControl -DNEEDS_QUOTES=Two\\ words -DAWESOME -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap-module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64/GoogleMapsBase.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64/GoogleMapsCore.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64/GoogleMaps.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~FXPageControl/FXPageControl_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/Utils/Utils_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Test/TestingUtils/TestingUtils_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_google_google_maps -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_armv7",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/usr/lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib/UndesiredSchemes",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Source",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin/iOSApp/Test/TestingUtils"
		]
	},
	"arm64-apple-ios iOSAppUITests.xctest/iOSAppUITests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-8/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneOS.platform/Developer/usr/lib"
		]
	},
	"arm64-apple-macosx tool.binary": {
		"c": "-F$(PROJECT_DIR)/external/examples_command_line_external -I$(SDKROOT)/usr/include/uuid -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-28/bin -iquote$(PROJECT_DIR)/external/examples_command_line_external -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-28/bin/external/examples_command_line_external -DSECRET_3=\"Hello\" -DSECRET_2=\"World!\" -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-28/bin/CommandLine/CommandLineToolLib/lib_impl_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/CommandLine/swift_interop_hint/c_lib.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/examples_command_line_external/ExternalFramework.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-28/bin/external/examples_command_line_external/Library_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-28/bin/CommandLine/CommandLineToolLib/private_lib_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-28/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/examples_command_line_external"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-28/bin/CommandLine/CommandLineToolLib"
		]
	},
	"arm64-apple-tvos Lib.framework/Lib": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64"
		]
	},
	"arm64-apple-tvos LibFramework.tvOS.framework/LibFramework.tvOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64"
		]
	},
	"arm64-apple-tvos UIFramework.tvOS.framework/UIFramework.tvOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/Lib"
		]
	},
	"arm64-apple-tvos tvOSApp.app/tvOSApp": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-11/bin/UI"
		]
	},
	"arm64_32-apple-watchos Lib.framework/Lib": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k"
		]
	},
	"arm64_32-apple-watchos LibFramework.watchOS.framework/LibFramework.watchOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k"
		]
	},
	"arm64_32-apple-watchos UIFramework.watchOS.framework/UIFramework.watchOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/Lib"
		]
	},
	"arm64_32-apple-watchos watchOSAppExtension.appex/watchOSAppExtension": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_32_armv7k"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-9/bin/UI"
		]
	},
	"x86_64-apple-ios-simulator AppClip.app/AppClip": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator ExtensionKitExtension.appex/ExtensionKitExtension": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all"
	},
	"x86_64-apple-ios-simulator Lib.framework/Lib": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
		]
	},
	"x86_64-apple-ios-simulator UIFramework.iOS.framework/UIFramework.iOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator WidgetExtension.appex/WidgetExtension": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator iMessageAppExtension.appex/iMessageAppExtension": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator iOSApp.app/iOSApp_ExecutableName": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator -I$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC -I$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_google_google_maps -DNEEDS_QUOTES=Two\\ words -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap-module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator/GoogleMapsBase.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator/GoogleMapsCore.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator/GoogleMaps.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib/UndesiredSchemes",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer"
		]
	},
	"x86_64-apple-ios-simulator iOSAppObjCUnitTestSuite.xctest/iOSAppObjCUnitTestSuite": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator -I$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC -I$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_google_google_maps -DNEEDS_QUOTES=Two\\ words -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap-module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator/GoogleMapsBase.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator/GoogleMapsCore.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator/GoogleMaps.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator",
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib/UndesiredSchemes",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib"
		]
	},
	"x86_64-apple-ios-simulator iOSAppObjCUnitTests.xctest/iOSAppObjCUnitTests": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator -I$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC -I$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_google_google_maps -DNEEDS_QUOTES=Two\\ words -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap-module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator/GoogleMapsBase.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator/GoogleMapsCore.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator/GoogleMaps.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator",
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib/UndesiredSchemes",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib"
		]
	},
	"x86_64-apple-ios-simulator iOSAppSwiftUnitTestSuite.xctest/iOSAppSwiftUnitTestSuite": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator -I$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC -I$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/external/_main~non_module_deps~FXPageControl -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~FXPageControl -DNEEDS_QUOTES=Two\\ words -DAWESOME -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap-module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator/GoogleMapsBase.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator/GoogleMapsCore.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator/GoogleMaps.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~FXPageControl/FXPageControl_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/Utils/Utils_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Test/TestingUtils/TestingUtils_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_google_google_maps -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib/UndesiredSchemes",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Test/TestingUtils"
		]
	},
	"x86_64-apple-ios-simulator iOSAppSwiftUnitTests.xctest/iOSAppSwiftUnitTests": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator -F$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator -I$(PROJECT_DIR)/iOSApp/Source/CoreUtilsObjC -I$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/external/_main~non_module_deps~FXPageControl -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~FXPageControl -DNEEDS_QUOTES=Two\\ words -DAWESOME -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_modulemap_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_objc_modulemap-module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsObjC/CoreUtilsObjC_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator/GoogleMapsBase.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator/GoogleMapsCore.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator/GoogleMaps.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~FXPageControl/FXPageControl_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/Utils/Utils_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Test/TestingUtils/TestingUtils_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_google_google_maps -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/ios-arm64_i386_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMaps.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsCore.xcframework/ios-arm64_x86_64-simulator",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_google_google_maps/GoogleMapsBase.xcframework/ios-arm64_x86_64-simulator"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib/UndesiredSchemes",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Source",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin/iOSApp/Test/TestingUtils"
		]
	},
	"x86_64-apple-ios-simulator iOSAppUITestSuite.xctest/iOSAppUITestSuite": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib"
		]
	},
	"x86_64-apple-ios-simulator iOSAppUITests.xctest/iOSAppUITests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-3/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/iPhoneSimulator.platform/Developer/usr/lib"
		]
	},
	"x86_64-apple-macosx BasicTests.xctest/Contents/MacOS/BasicTests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-33/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/Library/Frameworks"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/usr/lib"
		]
	},
	"x86_64-apple-macosx CommandLineTool": {
		"c": "-F$(PROJECT_DIR)/external/examples_command_line_external -I$(SDKROOT)/usr/include/uuid -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin -iquote$(PROJECT_DIR)/external/examples_command_line_external -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/external/examples_command_line_external -DSECRET_3=\"Hello\" -DSECRET_2=\"World!\" -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/CommandLine/CommandLineToolLib/lib_impl_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/CommandLine/swift_interop_hint/c_lib.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/examples_command_line_external/ExternalFramework.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/external/examples_command_line_external/Library_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/CommandLine/CommandLineToolLib/private_lib_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/examples_command_line_external"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/CommandLine/CommandLineToolLib"
		]
	},
	"x86_64-apple-macosx CommandLineToolTests.xctest/Contents/MacOS/CommandLineToolTests": {
		"c": "-F$(PROJECT_DIR)/external/examples_command_line_external -I$(SDKROOT)/usr/include/uuid -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin -iquote$(PROJECT_DIR)/external/examples_command_line_external -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/external/examples_command_line_external -DSECRET_3=\"Hello\" -DSECRET_2=\"World!\" -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/CommandLine/CommandLineToolLib/lib_impl_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/CommandLine/swift_interop_hint/c_lib.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/examples_command_line_external/ExternalFramework.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/external/examples_command_line_external/Library_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/CommandLine/CommandLineToolLib/lib_swift_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin -iquote$(PROJECT_DIR)/external/examples_command_line_external -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/external/examples_command_line_external -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/CommandLine/CommandLineToolLib/private_lib_modulemap/_/module.modulemap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/Library/Frameworks",
			"$(PROJECT_DIR)/external/examples_command_line_external"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/usr/lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-27/bin/CommandLine/CommandLineToolLib"
		]
	},
	"x86_64-apple-macosx Lib.framework/Contents/MacOS/Lib": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/macos-arm64_x86_64 -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-7/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-7/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/macos-arm64_x86_64/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/macos-arm64_x86_64"
		]
	},
	"x86_64-apple-macosx echo_client": {
		"c": "-iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/Sources/CGRPCZlib/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/Sources/CGRPCZlib/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLinux/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLinux/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOWindows/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOWindows/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOAtomics/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOAtomics/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/Sources/_AtomicsShims/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/Sources/_AtomicsShims/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIODarwin/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIODarwin/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLLHTTP/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLLHTTP/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSL/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSL/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSLShims/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSLShims/include -DSWIFT_PACKAGE -D__APPLE_USE_RFC_3542 -DLLHTTP_STRICT_MODE -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/CGRPCZlib_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIOLinux_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIOWindows_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIOAtomics_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/_AtomicsShims_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIODarwin_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIOLLHTTP_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/CNIOBoringSSL_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/CNIOBoringSSLShims_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/Sources/CGRPCZlib/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/Sources/CGRPCZlib/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLinux/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLinux/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOWindows/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOWindows/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOAtomics/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOAtomics/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/Sources/_AtomicsShims/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/Sources/_AtomicsShims/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIODarwin/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIODarwin/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLLHTTP/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLLHTTP/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSL/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSL/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSLShims/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSLShims/include -O0 -fstack-protector -fstack-protector-all",
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_protobuf",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_log",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_collections",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_extras",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_http2",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_transport_services",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/GRPC"
		]
	},
	"x86_64-apple-macosx echo_server": {
		"c": "-iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/Sources/CGRPCZlib/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/Sources/CGRPCZlib/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLinux/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLinux/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOWindows/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOWindows/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOAtomics/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOAtomics/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/Sources/_AtomicsShims/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/Sources/_AtomicsShims/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIODarwin/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIODarwin/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLLHTTP/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLLHTTP/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSL/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSL/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSLShims/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSLShims/include -DSWIFT_PACKAGE -D__APPLE_USE_RFC_3542 -DLLHTTP_STRICT_MODE -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/CGRPCZlib_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIOLinux_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIOWindows_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIOAtomics_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/_AtomicsShims_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIODarwin_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/CNIOLLHTTP_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/CNIOBoringSSL_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/CNIOBoringSSLShims_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics -iquote$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/Sources/CGRPCZlib/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift/Sources/CGRPCZlib/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLinux/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLinux/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOWindows/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOWindows/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOAtomics/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOAtomics/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/Sources/_AtomicsShims/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics/Sources/_AtomicsShims/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIODarwin/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIODarwin/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLLHTTP/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio/Sources/CNIOLLHTTP/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSL/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSL/include -isystem$(PROJECT_DIR)/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSLShims/include -isystem$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl/Sources/CNIOBoringSSLShims/include -O0 -fstack-protector -fstack-protector-all",
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_protobuf",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_log",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_atomics",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_collections",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_extras",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_http2",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_ssl",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_nio_transport_services",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_grpc_grpc_swift",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/GRPC"
		]
	},
	"x86_64-apple-macosx macOSApp.app/Contents/MacOS/macOSApp": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/macos-arm64_x86_64 -F$(PROJECT_DIR)/macOSApp/third_party -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-7/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-7/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/macos-arm64_x86_64/CryptoSwift.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/macOSApp/third_party/ExampleFramework.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-7/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-7/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/macos-arm64_x86_64",
			"$(PROJECT_DIR)/macOSApp/third_party"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-7/bin/Lib"
		]
	},
	"x86_64-apple-macosx macOSAppUITests.xctest/Contents/MacOS/macOSAppUITests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-7/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/Library/Frameworks"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/MacOSX.platform/Developer/usr/lib"
		]
	},
	"x86_64-apple-macosx proto": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin -O0 -fstack-protector -fstack-protector-all",
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/external/rules_swift~~non_module_deps~com_github_apple_swift_protobuf",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-25/bin/Proto"
		]
	},
	"x86_64-apple-macosx tool.binary": {
		"c": "-F$(PROJECT_DIR)/external/examples_command_line_external -I$(SDKROOT)/usr/include/uuid -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-29/bin -iquote$(PROJECT_DIR)/external/examples_command_line_external -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-29/bin/external/examples_command_line_external -DSECRET_3=\"Hello\" -DSECRET_2=\"World!\" -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-29/bin/CommandLine/CommandLineToolLib/lib_impl_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/CommandLine/swift_interop_hint/c_lib.modulemap -fmodule-map-file=$(PROJECT_DIR)/external/examples_command_line_external/ExternalFramework.framework/Modules/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-29/bin/external/examples_command_line_external/Library_modulemap/_/module.modulemap -fmodule-map-file=$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-29/bin/CommandLine/CommandLineToolLib/private_lib_modulemap/_/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-29/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/examples_command_line_external"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-29/bin/CommandLine/CommandLineToolLib"
		]
	},
	"x86_64-apple-tvos-simulator Lib.framework/Lib": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
		]
	},
	"x86_64-apple-tvos-simulator LibFramework.tvOS.framework/LibFramework.tvOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
		]
	},
	"x86_64-apple-tvos-simulator UIFramework.tvOS.framework/UIFramework.tvOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/Lib"
		]
	},
	"x86_64-apple-tvos-simulator tvOSApp.app/tvOSApp": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/UI"
		]
	},
	"x86_64-apple-tvos-simulator tvOSAppUITests.xctest/tvOSAppUITests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/AppleTVSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/AppleTVSimulator.platform/Developer/usr/lib"
		]
	},
	"x86_64-apple-tvos-simulator tvOSAppUnitTests.xctest/tvOSAppUnitTests": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/AppleTVSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/tvos-arm64_x86_64-simulator"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/AppleTVSimulator.platform/Developer/usr/lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/UI",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-6/bin/tvOSApp/Source"
		]
	},
	"x86_64-apple-watchos-simulator Lib.framework/Lib": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
		]
	},
	"x86_64-apple-watchos-simulator LibFramework.watchOS.framework/LibFramework.watchOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
		]
	},
	"x86_64-apple-watchos-simulator UIFramework.watchOS.framework/UIFramework.watchOS": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/Lib"
		]
	},
	"x86_64-apple-watchos-simulator watchOSAppExtension.appex/watchOSAppExtension": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
		],
		"s": [
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/UI"
		]
	},
	"x86_64-apple-watchos-simulator watchOSAppExtensionUnitTests.xctest/watchOSAppExtensionUnitTests": {
		"c": "-F$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -fmodule-map-file=$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator/CryptoSwift.framework/Modules/module.modulemap -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/WatchSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks",
			"$(PROJECT_DIR)/external/_main~non_module_deps~com_github_krzyzanowskim_cryptoswift/CryptoSwift.xcframework/watchos-arm64_i386_x86_64-simulator"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/WatchSimulator.platform/Developer/usr/lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/Lib",
			"$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin/UI"
		]
	},
	"x86_64-apple-watchos-simulator watchOSAppUITests.xctest/watchOSAppUITests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/CONFIGURATION-STABLE-4/bin -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"$(DEVELOPER_DIR)/Platforms/WatchSimulator.platform/Developer/Library/Frameworks",
			"$(SDKROOT)/Developer/Library/Frameworks"
		],
		"s": [
			"$(DEVELOPER_DIR)/Platforms/WatchSimulator.platform/Developer/usr/lib"
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
https://github.com/MobileNativeFoundation/rules_xcodeproj/issues/new?template=bug.md
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
        if not module:
            return

        module_name = module.file.GetDirectory() + "/" + module.file.GetFilename()
        versionless_triple = _TRIPLE_MATCH.sub(r"\1\2\3", module.GetTriple())
        executable_path = _get_relative_executable_path(module_name)
        key = f"{versionless_triple} {executable_path}"

        settings = _SETTINGS.get(key)

        if settings:
            frameworks = " ".join([
                f'"{path}"'
                for path in settings.get("f", [])
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
                for path in settings.get("s", [])
            ])
            if includes:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-module-search-paths {includes}",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-module-search-paths",
                )

            clang = settings.get("c")
            if clang:
                lldb.debugger.HandleCommand(
                    f"settings set -- target.swift-extra-clang-flags '{clang}'",
                )
            else:
                lldb.debugger.HandleCommand(
                    "settings clear target.swift-extra-clang-flags",
                )

        return True
