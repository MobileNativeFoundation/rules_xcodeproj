load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":linker_input_files_tests.bzl",
    "linker_input_files_test_suite",
    "static_library_preview_link_params_test",
)
load(
    ":output_files_tests.bzl",
    "archive_preview_framework_test",
    "output_files_test_suite",
    "preview_resource_bundle_materialization_test",
)

output_files_test_suite(name = "output_files")

linker_input_files_test_suite(name = "linker_input_files")

static_library_preview_link_params_test(
    name = "static_library_preview_link_params",
)

archive_preview_framework_test(
    name = "archive_preview_framework",
)

preview_resource_bundle_materialization_test(
    name = "preview_resource_bundle_materialization",
)

test_suite(
    name = "files",
    tests = [
        ":archive_preview_framework",
        ":linker_input_files",
        ":output_files",
        ":preview_resource_bundle_materialization",
        ":static_library_preview_link_params",
    ],
)

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)
