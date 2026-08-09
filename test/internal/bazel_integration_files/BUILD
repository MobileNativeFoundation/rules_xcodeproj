load("@rules_shell//shell:sh_test.bzl", "sh_test")

sh_test(
    name = "clang_facade",
    srcs = ["clang_facade_tests.sh"],
    data = ["//xcodeproj/internal/bazel_integration_files"],
)

sh_test(
    name = "libtool_facade",
    srcs = ["libtool_facade_tests.sh"],
    data = ["//xcodeproj/internal/bazel_integration_files"],
)

sh_test(
    name = "preview_framework_scripts",
    srcs = ["preview_framework_scripts_tests.sh"],
    data = [
        "//xcodeproj/internal/bazel_integration_files",
        "//xcodeproj/internal/templates:generate_bazel_dependencies.sh",
    ],
)

test_suite(
    name = "bazel_integration_files",
    tests = [
        ":clang_facade",
        ":libtool_facade",
        ":preview_framework_scripts",
    ],
)
