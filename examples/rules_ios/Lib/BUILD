load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_build_test",
)
load(
    "@build_bazel_rules_ios//rules:framework.bzl",
    rules_ios_apple_framework = "apple_framework",
)

exports_files(["README.md"])

exports_files(
    ["Info.plist"],
    visibility = ["//Lib:__subpackages__"],
)

ios_build_test(
    name = "ios_Lib",
    minimum_os_version = "15.0",
    tags = ["manual"],
    targets = [":Lib"],
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)

rules_ios_apple_framework(
    name = "Lib",
    srcs = [
        "Resources.swift",
        ":gen_Lib.swift",
    ],
    bundle_id = "rules-xcodeproj.LibFramework",
    data = glob(
        ["Resources/**"],
        exclude = ["**/.DS_Store"],
    ),
    infoplists = ["Info.plist"],
    module_name = "Lib",
    platforms = {
        "ios": "15.0",
    },
    visibility = [
        "//Lib/dist/dynamic:__pkg__",
        "//UI:__pkg__",
        "//WidgetExtension:__subpackages__",
    ],
    xcconfig = {
        "APPLICATION_EXTENSION_API_ONLY": "YES",
    },
    deps = [
        "@com_github_krzyzanowskim_cryptoswift//:CryptoSwift",
    ],
)

genrule(
    name = "gen_Lib.swift",
    outs = ["Lib.swift"],
    cmd = "echo 'public let greeting = \"Hello, world!\"' > $@",
)
