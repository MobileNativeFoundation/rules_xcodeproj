load("@rules_python//python:defs.bzl", "py_test")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

py_test(
    name = "calculate_output_groups",
    srcs = ["calculate_output_groups_tests.py"],
    data = ["//xcodeproj/internal/bazel_integration_files:calculate_output_groups.py"],
    main = "calculate_output_groups_tests.py",
)

sh_test(
    name = "libtool_facade",
    srcs = ["libtool_facade_tests.sh"],
    data = [
        "//xcodeproj/internal/bazel_integration_files",
        "//xcodeproj/internal/templates:installer.sh",
    ],
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
        ":calculate_output_groups",
        ":libtool_facade",
        ":preview_framework_scripts",
    ],
)
