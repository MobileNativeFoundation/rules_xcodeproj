load(
    "@build_bazel_rules_swift//swift:swift_interop_hint.bzl",
    "swift_interop_hint",
)

cc_library(
    name = "c_lib",
    srcs = [
        "c_lib.c",
    ],
    hdrs = [
        "c_lib.h",
    ],
    aspect_hints = [":c_lib_swift_interop"],
    visibility = ["//CommandLine:__subpackages__"],
)

swift_interop_hint(
    name = "c_lib_swift_interop",
    module_map = "c_lib.modulemap",
    module_name = "SwiftCModule",
)
