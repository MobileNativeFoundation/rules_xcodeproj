load("@rules_python//python:defs.bzl", "py_test")

py_test(
    name = "calculate_output_groups",
    srcs = ["calculate_output_groups_tests.py"],
    data = ["//xcodeproj/internal/bazel_integration_files:calculate_output_groups.py"],
    main = "calculate_output_groups_tests.py",
)

test_suite(
    name = "bazel_integration_files",
    tests = [":calculate_output_groups"],
)
