load(
    "@build_bazel_rules_apple//apple:ios.bzl",
    "ios_build_test",
    "ios_framework",
)
load("@build_bazel_rules_apple//apple:tvos.bzl", "tvos_framework")
load("@build_bazel_rules_apple//apple:watchos.bzl", "watchos_framework")
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

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

swift_library(
    name = "Lib",
    srcs = [
        "Resources.swift",
        ":gen_Lib.swift",
    ],
    copts = ["-application-extension"],
    data = glob(
        ["Resources/**"],
        exclude = ["**/.DS_Store"],
    ),
    module_name = "Lib",
    tags = ["manual"],
    visibility = [
        "//AppClip:__subpackages__",
        "//Lib:__subpackages__",
        "//UI:__subpackages__",
        "//WidgetExtension:__subpackages__",
        "//iMessageApp:__subpackages__",
    ],
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

genrule(
    name = "gen-exported-symbols-list",
    outs = ["exported-symbols.lds"],
    cmd = """\
echo '_$$s3Lib8greetingSSvau' > $@
echo '_$$s3Lib18libResourcesStringSSvau' >> $@
echo '_$$sSo8NSBundleC3LibE12libResourcesABvau' >> $@
""",
)

ios_framework(
    name = "LibFramework.iOS",
    bundle_id = "rules-xcodeproj.LibFramework",
    extension_safe = True,
    families = ["iphone"],
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//UI:__pkg__"],
    deps = [":Lib"],
)

tvos_framework(
    name = "LibFramework.tvOS",
    bundle_id = "rules-xcodeproj.LibFramework",
    exported_symbols_lists = [
        ":gen-exported-symbols-list",
    ],
    extension_safe = True,
    infoplists = ["Info.plist"],
    minimum_os_version = "15.0",
    version = "//iOSApp:Version",
    visibility = ["//UI:__pkg__"],
    deps = [":Lib"],
)

watchos_framework(
    name = "LibFramework.watchOS",
    bundle_id = "rules-xcodeproj.LibFramework",
    extension_safe = True,
    infoplists = ["Info.plist"],
    minimum_os_version = "7.0",
    version = "//iOSApp:Version",
    visibility = ["//UI:__pkg__"],
    deps = [":Lib"],
)
