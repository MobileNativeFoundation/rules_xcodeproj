load("@rules_shell//shell:sh_test.bzl", "sh_test")

sh_test(
    name = "libtool_facade",
    srcs = ["libtool_facade_tests.sh"],
    data = [
        "//xcodeproj/internal/bazel_integration_files",
        "//xcodeproj/internal/templates:installer.sh",
    ],
)

test_suite(
    name = "bazel_integration_files",
    tests = [":libtool_facade"],
)
