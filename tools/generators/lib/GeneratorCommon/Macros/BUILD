load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_compiler_plugin",
    "swift_test",
)

alias(
    name = "Macros",
    actual = ":GeneratorCommonMacros",
    tags = ["manual"],
    visibility = ["//tools/generators/lib/GeneratorCommon:__subpackages__"],
)

swift_compiler_plugin(
    name = "GeneratorCommonMacros",
    srcs = glob(["src/**/*.swift"]),
    module_name = "GeneratorCommonMacros",
    visibility = [
        "@rules_xcodeproj//xcodeproj:generated",
    ],
    deps = [
        "@SwiftSyntax",
        "@SwiftSyntax//:SwiftCompilerPlugin",
        "@SwiftSyntax//:SwiftSyntaxBuilder",
        "@SwiftSyntax//:SwiftSyntaxMacros",
    ],
)

swift_test(
    name = "GeneratorCommonMacrosTests",
    srcs = glob(["test/**/*.swift"]) + [
        # # FIXME: Remove when moving to `swift_compiler_plugin`
        # "src/InjectableMacro.swift",
        # "src/IndentRemovableSyntax.swift",
    ],
    deps = [
        ":GeneratorCommonMacros",
        "@SwiftSyntax",
        "@SwiftSyntax//:SwiftSyntaxBuilder",
        "@SwiftSyntax//:SwiftSyntaxMacros",
        "@SwiftSyntax//:SwiftSyntaxMacrosTestSupport",
    ],
    visibility = ["@rules_xcodeproj//xcodeproj:generated"],
)
