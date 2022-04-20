load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@rules_cc//cc:defs.bzl", "objc_library")

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
    tags = ["manual"],
    deps = [
        ":lib_defines",
    ],
)

swift_library(
    name = "lib_swift",
    srcs = [
        "SwiftParserExample.swift",
        "lib.swift",
    ],
    generated_header_name = "private/LibSwift-Swift.h",
    generates_header = True,
    module_name = "LibSwift",
    visibility = ["//examples/command_line/Tests:__subpackages__"],
    deps = [
        ":lib_impl",
        "@com_github_keith_swift_syntax//:SwiftSyntax",
        "@com_github_keith_swift_syntax//:SwiftSyntaxParser",
    ],
)

# swift_library(
#     name = "lib_swift",
#     srcs = ["lib.swift"],
#     generated_header_name = "private/LibSwift-Swift.h",
#     generates_header = True,
#     module_name = "LibSwift",
#     visibility = ["//examples/command_line/Tests:__subpackages__"],
#     deps = [
#         ":lib_impl",
#     ],
# )

# swift_library(
#     name = "SwiftParserExample",
#     srcs = ["SwiftParserExample.swift"],
#     generated_header_name = "private/SwiftParserExample-Swift.h",
#     generates_header = True,
#     module_name = "SwiftParserExample",
#     visibility = ["//examples/command_line/Tests:__subpackages__"],
#     deps = [
#         "@com_github_keith_swift_syntax//:SwiftSyntax",
#         "@com_github_keith_swift_syntax//:SwiftSyntaxParser",
#     ],
# )

objc_library(
    name = "lib_headers",
    hdrs = ["dir with space/lib.h"],
    includes = [
        "dir with space",
        "private",
    ],
    deps = [
        # ":SwiftParserExample",
        ":lib_swift",
    ],
)

alias(
    name = "lib",
    actual = ":lib_headers",
    visibility = ["//visibility:public"],
)
