load("@build_bazel_rules_swift//swift:swift.bzl", "swift_c_module")

cc_library(
    name = "c_lib",
    srcs = [
        "c_lib.c",
    ],
    hdrs = [
        "c_lib.h",
    ],
)

swift_c_module(
    name = "swift_c_module",
    module_map = "c_lib.modulemap",
    module_name = "SwiftCModule",
    visibility = ["//CommandLine:__subpackages__"],
    deps = [
        ":c_lib",
    ],
)
