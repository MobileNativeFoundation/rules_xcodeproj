load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
    "swift_macro",
    "swift_test",
)

swift_macro(
    name = "StringifyMacroPlugin",
    srcs = [
        "StringifyMacro.swift",
        "StringifyMacroPlugin.swift",
    ],
    module_name = "StringifyMacroPlugin",
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
    deps = [
        "@SwiftSyntax",
        "@SwiftSyntax//:SwiftCompilerPlugin",
        "@SwiftSyntax//:SwiftSyntaxBuilder",
        "@SwiftSyntax//:SwiftSyntaxMacros",
    ],
)

swift_library(
    name = "Stringify",
    srcs = ["Stringify.swift"],
    macros = [":StringifyMacroPlugin"],
    module_name = "Stringify",
    visibility = ["//visibility:public"],
)

swift_test(
    name = "StringifyMacroTests",
    srcs = [
        "StringifyMacroTests.swift",
        # FIXME: Remove when moving to `swift_compiler_plugin`
        "StringifyMacro.swift",
    ],
    deps = [
        ":StringifyMacroPlugin",
        "@SwiftSyntax",
        "@SwiftSyntax//:SwiftSyntaxBuilder",
        "@SwiftSyntax//:SwiftSyntaxMacros",
        "@SwiftSyntax//:SwiftSyntaxMacrosTestSupport",
    ],
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)
