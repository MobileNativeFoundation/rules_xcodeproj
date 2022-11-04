load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)
load(
    ":module_map.bzl",
    "module_map",
)

module_map(
    name = "MixedAnswer_objc_modulemap",
    hdrs = ["MixedAnswer.h"],
    module_name = "MixedAnswer",
)

module_map(
    name = "MixedAnswer_swift_modulemap",
    hdrs = ["MixedAnswer.h"],
    module_name = "MixedAnswer",
    deps = [
        ":MixedAnswerLib_Swift",
    ],
)

objc_library(
    name = "MixedAnswer",
    srcs = ["MixedAnswer.m"],
    hdrs = ["MixedAnswer.h"],
    copts = [
        "-I$(BINDIR)/iOSApp/CoreUtilsMixed",
    ],
    module_map = ":MixedAnswer_objc_modulemap",
    visibility = ["//iOSApp:__subpackages__"],
    deps = [
        ":MixedAnswerLib_Swift",
        ":MixedAnswer_objc_modulemap",
        ":MixedAnswer_swift_modulemap",
    ],
)

swift_library(
    name = "MixedAnswerLib_Swift",
    srcs = ["MixedAnswer.swift"],
    copts = [
        "-Xfrontend",
        "-import-underlying-module",
        "-Xcc",
        "-fmodule-map-file=$(execpath :MixedAnswer_objc_modulemap)",
    ],
    features = ["swift.no_generated_module_map"],
    generated_header_name = "MixedAnswer-Swift.h",
    generates_header = True,
    module_name = "MixedAnswer",
    swiftc_inputs = [
        "MixedAnswer.h",
        ":MixedAnswer_objc_modulemap",
    ],
)
