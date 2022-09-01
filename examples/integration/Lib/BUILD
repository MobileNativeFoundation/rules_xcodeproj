load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "Lib",
    srcs = [":gen_Lib.swift"],
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
    name = "LibFramework",
    bundle_id = "io.budilebuddy.LibFramework",
    extension_safe = True,
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//visibility:public"],
    deps = [":Lib"],
)
