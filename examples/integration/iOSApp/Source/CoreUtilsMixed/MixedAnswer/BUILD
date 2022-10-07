load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library"
)
load(
    ":module_map.bzl",
    "module_map"
)

module_map(
    name = "MixedAnswer_objc_modulemap",
    hdrs = ["MixedAnswer.h"],
    module_name = "MixedAnswer",
)

module_map(
    name = "MixedAnswer_swift_modulemap",
    hdrs = ["MixedAnswer.h"],
    deps = [
        ":MixedAnswerLib_Swift"
    ],
    module_name = "MixedAnswer",
)

objc_library(
    name = "MixedAnswer",
    module_name = "MixedAnswer",
    hdrs = ["MixedAnswer.h"],
    srcs = ["MixedAnswer.m"],
    deps = [
        ":MixedAnswer_objc_modulemap",
        ":MixedAnswer_swift_modulemap",
        ":MixedAnswerLib_Swift"
    ],
    copts = [
        "-I$(BINDIR)/iOSApp/CoreUtilsMixed"
    ],
    visibility = ["//iOSApp:__subpackages__"]
)

swift_library(
    name = "MixedAnswerLib_Swift",
    srcs = ["MixedAnswer.swift"],
    module_name = "MixedAnswer",
    generates_header = True,
    generated_header_name = "MixedAnswer-Swift.h",
    swiftc_inputs = ["MixedAnswer.h", ":MixedAnswer_objc_modulemap"],
    features = ["swift.no_generated_module_map"],
    copts = [
        "-Xfrontend",
        "-import-underlying-module",
        "-Xcc",
        "-fmodule-map-file=$(execpath :MixedAnswer_objc_modulemap)",
    ],
)
