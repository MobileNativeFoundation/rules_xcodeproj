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
	"x86_64-apple-ios-simulator Lib": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		]
	},
	"x86_64-apple-ios-simulator MixedAnswer": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		]
	},
	"x86_64-apple-ios-simulator Source": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		],
		"s": [
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator UI": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		],
		"s": [
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator WidgetExtension": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		],
		"s": [
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator WidgetExtension.appex/WidgetExtension": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/WidgetExtension/WidgetExtension.library_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		],
		"s": [
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator iOS.framework": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		]
	},
	"x86_64-apple-ios-simulator iOSApp.app/iOSApp_ExecutableName": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		],
		"s": [
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator iOSAppMixedUnitTests.xctest/iOSAppMixedUnitTests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/MixedUnitTests/iOSAppMixedUnitTests_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/MixedUnitTests/iOSAppMixedUnitTests_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/MixedUnitTests/iOSAppMixedUnitTests_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/MixedUnitTests/iOSAppMixedUnitTests_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/MixedUnitTests/iOSAppMixedUnitTests_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
			"__BAZEL_XCODE_SDKROOT__/Developer/Library/Frameworks",
			"/build_bazel_rules_ios/frameworks"
		],
		"s": [
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator iOSAppObjCUnitTests.xctest/iOSAppObjCUnitTests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"/build_bazel_rules_ios/frameworks"
		],
		"s": [
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib"
		]
	},
	"x86_64-apple-ios-simulator iOSAppSwiftUnitTests.xctest/iOSAppSwiftUnitTests": {
		"c": "-iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/SwiftUnitTests/iOSAppSwiftUnitTests_swift_vfs.yaml -F/build_bazel_rules_ios/frameworks -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/SwiftUnitTests/iOSAppSwiftUnitTests_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/SwiftUnitTests/iOSAppSwiftUnitTests_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/SwiftUnitTests/iOSAppSwiftUnitTests_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Test/SwiftUnitTests/iOSAppSwiftUnitTests_private_hmap.hmap -D__SWIFTC__ -I$(PROJECT_DIR) -O0 -DDEBUG=1 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/iOSApp.library_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI/UI_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib/Lib_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all -iquote$(PROJECT_DIR) -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin -ivfsoverlay$(CURRENT_EXECUTION_ROOT)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_swift_vfs.yaml -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_public_hmap.hmap -I$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_angled_hmap.hmap -iquote$(PROJECT_DIR)/bazel-out/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer/MixedAnswer_private_hmap.hmap -O0 -fstack-protector -fstack-protector-all",
		"f": [
			"__BAZEL_XCODE_DEVELOPER_DIR__/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks",
			"__BAZEL_XCODE_SDKROOT__/Developer/Library/Frameworks",
			"/build_bazel_rules_ios/frameworks"
		],
		"s": [
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/UI",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/iOSApp/Source/CoreUtilsMixed/MixedAnswer",
			"$(BAZEL_OUT)/ios-x86_64-min15.0-applebin_ios-ios_x86_64-dbg-STABLE-1/bin/Lib"
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

        module_name = module.file.__get_fullpath__()
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
