load("@rules_shell//shell:sh_test.bzl", "sh_test")

sh_test(
    name = "preview_framework_scripts",
    srcs = ["preview_framework_scripts_tests.sh"],
    data = ["//xcodeproj/internal/bazel_integration_files"],
)

test_suite(
    name = "bazel_integration_files",
    tests = [":preview_framework_scripts"],
)
