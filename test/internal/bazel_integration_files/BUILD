load("@rules_python//python:defs.bzl", "py_test")
load("@rules_shell//shell:sh_test.bzl", "sh_test")

py_test(
    name = "preview_runtime_link_params",
    srcs = ["preview_runtime_link_params_tests.py"],
    data = ["//xcodeproj/internal/bazel_integration_files:preview_runtime_link_params.py"],
    main = "preview_runtime_link_params_tests.py",
)

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
    tests = [
        ":libtool_facade",
        ":preview_runtime_link_params",
    ],
)
