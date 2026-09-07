load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(
    ":linker_input_files_tests.bzl",
    "linker_input_files_test_suite",
    "static_library_preview_link_params_test",
)

linker_input_files_test_suite(name = "linker_input_files")

static_library_preview_link_params_test(name = "static_library_preview_link_params")

test_suite(
    name = "files",
    tests = [":linker_input_files", ":static_library_preview_link_params"],
)

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)
