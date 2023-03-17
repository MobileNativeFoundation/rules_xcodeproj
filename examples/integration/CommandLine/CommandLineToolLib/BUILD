load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

objc_library(
    name = "lib_defines",
    defines = [
        "SECRET_3=\\\"Hello\\\"",
        "SECRET_2=\\\"World!\\\"",
    ],
)

objc_library(
    name = "lib_impl",
    srcs = [
        "lib.m",
        "private.h",
    ],
    sdk_includes = ["uuid"],
    tags = ["manual"],
    deps = [
        ":lib_defines",
    ],
)

cc_library(
    name = "private_lib",
    srcs = ["private_lib.c"],
    hdrs = ["private_lib.h"],
    copts = [
        # This isn't needed bty anything, it's to exercise an edge case in
        # `FilePath` detection.
        "-Ibazel-out",
        "-Iexternal",
    ],
    tags = ["swift_module=_Lib"],
)

swift_library(
    name = "private_swift_lib",
    srcs = ["private_lib.swift"],
    module_name = "_SwiftLib",
)

swift_library(
    name = "lib_swift",
    srcs = ["lib.swift"],
    generated_header_name = "private/LibSwift-Swift.h",
    generates_header = True,
    module_name = "LibSwift",
    private_deps = [
        ":private_lib",
        ":private_swift_lib",
    ],
    visibility = ["//CommandLine/Tests:__subpackages__"],
    deps = [
        ":lib_impl",
        "//CommandLine/swift_c_module",
        "@examples_command_line_external//:ExternalFramework",
        "@examples_command_line_external//:Library",
    ],
)

objc_library(
    name = "lib_headers",
    hdrs = ["dir with space/lib.h"],
    includes = [
        "dir with space",
        "private",
    ],
    deps = [
        ":lib_swift",
    ],
)

alias(
    name = "CommandLineToolLib",
    actual = ":lib_headers",
    visibility = ["//CommandLine/CommandLineTool:__subpackages__"],
)
