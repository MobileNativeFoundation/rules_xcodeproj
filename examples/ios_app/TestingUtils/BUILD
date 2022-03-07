load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "TestingUtils",
    module_name = "TestingUtils",
    testonly = True,
    srcs = [":gen_TestingUtils.swift"],
    visibility = ["//visibility:public"],
)

genrule(
    name = "gen_TestingUtils.swift",
    outs = ["TestingUtils.swift"],
    cmd = '''echo 'public let expectedGreeting = "Hello, world?"' > $@''',
)
