load("@rules_python//python:defs.bzl", "py_test")

py_test(
    name = "preview_runtime_link_params",
    srcs = ["preview_runtime_link_params_tests.py"],
    data = ["//xcodeproj/internal/bazel_integration_files:preview_runtime_link_params.py"],
    main = "preview_runtime_link_params_tests.py",
)

test_suite(
    name = "bazel_integration_files",
    tests = [":preview_runtime_link_params"],
)
