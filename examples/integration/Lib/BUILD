load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_dynamic_framework",
    "ios_framework",
)
load(
    "@build_bazel_rules_apple//apple:tvos.bzl",
    "tvos_dynamic_framework",
    "tvos_framework",
)
load(
    "@build_bazel_rules_apple//apple:watchos.bzl",
    "watchos_dynamic_framework",
    "watchos_framework",
)
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

exports_files(["README.md"])

exports_files(
    ["Info.plist"],
    visibility = ["//Lib:__subpackages__"],
)

swift_library(
    name = "Lib",
    srcs = [":gen_Lib.swift"],
    copts = ["-application-extension"],
    module_name = "Lib",
    tags = ["manual"],
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_krzyzanowskim_cryptoswift//:CryptoSwift",
    ],
    alwayslink = True,
)

genrule(
    name = "gen_Lib.swift",
    outs = ["Lib.swift"],
    cmd = "echo 'public let greeting = \"Hello, world!\"' > $@",
)

ios_framework(
    name = "LibFramework.iOS",
    bundle_id = "io.budilebuddy.LibFramework",
    extension_safe = True,
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":Lib"],
)

ios_dynamic_framework(
    name = "Lib.framework.iOS",
    bundle_id = "io.budilebuddy.LibFramework",
    bundle_name = "Lib",
    extension_safe = True,
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":Lib"],
)

tvos_framework(
    name = "LibFramework.tvOS",
    bundle_id = "io.budilebuddy.LibFramework",
    extension_safe = True,
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":Lib"],
)

tvos_dynamic_framework(
    name = "Lib.framework.tvOS",
    bundle_id = "io.budilebuddy.LibFramework",
    bundle_name = "Lib",
    extension_safe = True,
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":Lib"],
)

watchos_framework(
    name = "LibFramework.watchOS",
    bundle_id = "io.budilebuddy.LibFramework",
    extension_safe = True,
    infoplists = ["Info.plist"],
    minimum_os_version = "7.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":Lib"],
)

watchos_dynamic_framework(
    name = "Lib.framework.watchOS",
    bundle_id = "io.budilebuddy.LibFramework",
    bundle_name = "Lib",
    extension_safe = True,
    infoplists = ["Info.plist"],
    minimum_os_version = "7.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":Lib"],
)
