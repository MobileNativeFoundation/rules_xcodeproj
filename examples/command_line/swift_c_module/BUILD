load("@build_bazel_rules_swift//swift:swift.bzl", "swift_c_module")

cc_library(
    name = "lib_impl",
    srcs = [
        "lib.c",
    ],
    hdrs = [
        "lib.h",
    ],
)

alias(
    name = "lib2",
    actual = "lib_impl",
    visibility = ["//visibility:public"],
)

swift_c_module(
    name = "swift_c_module",
    module_map = "lib2.modulemap",
    module_name = "SwiftCModule",
    visibility = ["//visibility:public"],
    deps = [
        ":lib2",
    ],
)
