load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@rules_shell//shell:sh_test.bzl", "sh_test")
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

sh_test(
    name = "assemble_project_pbxproj_test",
    srcs = ["assemble_project_pbxproj_test.sh"],
    args = [
        "$(rootpath //xcodeproj/internal/templates:assemble_project_pbxproj.sh)",
    ],
    data = ["//xcodeproj/internal/templates:assemble_project_pbxproj.sh"],
)

test_suite(name = "pbxproj_partials")

bzl_library(
    name = "bzls",
    srcs = glob(["*.bzl"]),
    visibility = ["//test:__pkg__"],
)
