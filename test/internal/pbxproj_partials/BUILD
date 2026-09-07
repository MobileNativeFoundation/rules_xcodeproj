load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":swift_explicit_inputs_tests.bzl", "swift_explicit_inputs_test", "swift_param_file_manifest_test", "swift_param_file_producer")
load(
    ":write_files_and_groups_tests.bzl",
    "write_files_and_groups_test_suite",
)
load(
    ":write_pbxproj_prefix_tests.bzl",
    "write_pbxproj_prefix_test_suite",
)
load(
    ":write_pbxtargetdependencies_tests.bzl",
    "write_pbxtargetdependencies_test_suite",
)
load(
    ":write_swift_debug_settings_tests.bzl",
    "write_swift_debug_settings_test_suite",
)
load(
    ":write_target_build_settings_tests.bzl",
    "write_target_build_settings_test_suite",
)

write_files_and_groups_test_suite(name = "write_files_and_groups")

write_pbxproj_prefix_test_suite(name = "write_pbxproj_prefix")

write_pbxtargetdependencies_test_suite(name = "write_pbxtargetdependencies")

write_swift_debug_settings_test_suite(name = "write_swift_debug_settings")

write_target_build_settings_test_suite(name = "write_target_build_settings")

test_suite(name = "pbxproj_partials")

swift_explicit_inputs_test(name = "swift_explicit_inputs")

swift_param_file_producer(
    name = "swift_param_file_producer",
    testonly = True,
    tags = ["manual"],
)

swift_param_file_manifest_test(
    name = "swift_param_file_manifest",
    producer = ":swift_param_file_producer",
)

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)
