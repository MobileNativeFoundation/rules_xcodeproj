load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load(":swift_explicit_inputs_tests.bzl", "swift_explicit_inputs_test", "swift_param_file_manifest_test", "swift_param_file_producer")
load(
    ":top_level_target_attributes_args_tests.bzl",
    "top_level_target_attributes_args_test_suite",
)
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

swift_explicit_inputs_test(name = "swift_explicit_inputs")

swift_param_file_producer(
    name = "swift_param_file_producer",
    testonly = True,
    # The analysis test inspects this action without executing its failing input.
    tags = ["manual"],
)

swift_param_file_manifest_test(
    name = "swift_param_file_manifest",
    producer = ":swift_param_file_producer",
)

top_level_target_attributes_args_test_suite(
    name = "top_level_target_attributes_args",
)

test_suite(name = "pbxproj_partials")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)
